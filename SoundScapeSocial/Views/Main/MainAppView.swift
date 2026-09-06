import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct MainAppView: View {
    @EnvironmentObject var spotifyAuth: SpotifyAuthManager
    @Binding var currentTrack: CurrentlyPlayingTrack?
    @State private var statusMessage: String?
    @State private var lastSharedURI: String?

    private let db = Firestore.firestore()
    private var uid: String? { Auth.auth().currentUser?.uid }

    /// Polling cadence for the now-playing endpoint. Spotify has no push event
    /// for "track ended", so the next check is scheduled from the time left in
    /// the current track and clamped so a skip is still noticed quickly.
    private enum Poll {
        static let minimum: Duration = .seconds(3)
        static let maximum: Duration = .seconds(30)
        static let paused: Duration = .seconds(15)
        static let nothingPlaying: Duration = .seconds(20)
        static let afterError: Duration = .seconds(30)
        /// Land just past the end of the track, not exactly on it.
        static let endOfTrackBuffer: Duration = .milliseconds(1500)
    }

    var body: some View {
        ZStack {
            Color.appBackground
                .ignoresSafeArea()

            VStack(spacing: 24) {
                // MARK: – Sign-Out Controls
                HStack(spacing: 16) {
                    Button("Sign out of Spotify") {
                        spotifyAuth.accessToken = nil
                        spotifyAuth.sessionManager.session = nil
                    }
                    .font(.subheadline)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 12)
                    .background(Color.appSurface)
                    .foregroundColor(.textPrimary)
                    .cornerRadius(8)

                    Button("Sign Out") {
                        do {
                            try Auth.auth().signOut()
                        } catch {
                            print("Sign out error:", error)
                        }
                    }
                    .font(.subheadline)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 12)
                    .background(Color.brandFill)
                    .foregroundColor(.onBrand)
                    .cornerRadius(8)
                }

                // MARK: – Status Message
                if let statusMessage {
                    Text(statusMessage)
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Spacer()

                // MARK: – Now Playing Card
                if let track = currentTrack {
                    VStack(spacing: 16) {
                        AsyncImage(url: URL(string: track.albumArtURL)) { phase in
                            if let img = phase.image {
                                img.resizable().scaledToFill()
                            } else if phase.error != nil {
                                Color.appSurface
                            } else {
                                Color.appSurface
                            }
                        }
                        .frame(width: 240, height: 240)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .shadow(radius: 8)

                        Text(track.name)
                            .font(.title2).bold()
                            .foregroundColor(.textPrimary)
                            .lineLimit(1)

                        Text(track.artist)
                            .font(.subheadline)
                            .foregroundColor(.textSecondary)
                            .lineLimit(1)

                        Button(action: {
                            addToFavorites(track)
                            saveToSpotifyLibrary(trackUri: track.uri)
                        }) {
                            HStack {
                                Image(systemName: "heart.circle.fill")
                                Text("Add to Favorites")
                                    .font(.headline)
                            }
                            .padding(.vertical, 10)
                            .padding(.horizontal, 24)
                            .background(Color.brandFill)
                            .foregroundColor(.onBrand)
                            .cornerRadius(12)
                        }
                    }
                    .padding()
                    .background(Color.appSurface)
                    .cornerRadius(20)
                    .padding(.horizontal)
                    .transition(.opacity)
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "music.note")
                            .font(.system(size: 44))
                            .foregroundColor(.brandAccent)
                        Text("Play something on Spotify and it will show up here.")
                            .font(.subheadline)
                            .foregroundColor(.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                }

                Spacer()
            }
            .padding(.top)
            .animation(.easeInOut, value: currentTrack?.uri)
        }
        // Polls only while this view is on screen; SwiftUI cancels the task on
        // disappear, and restarts it if the Spotify token changes.
        .task(id: spotifyAuth.accessToken) {
            await pollNowPlaying()
        }
    }

    // MARK: – Polling

    @MainActor
    private func pollNowPlaying() async {
        while !Task.isCancelled {
            let wait = await refreshNowPlaying()
            if Task.isCancelled { return }
            do {
                try await Task.sleep(for: wait)
            } catch {
                return // cancelled while sleeping
            }
        }
    }

    /// Performs one check and returns how long to wait before the next one.
    @MainActor
    private func refreshNowPlaying() async -> Duration {
        guard let token = spotifyAuth.accessToken, !token.isEmpty else {
            statusMessage = "Connect Spotify to see what's playing."
            currentTrack = nil
            return Poll.nothingPlaying
        }

        guard let url = URL(string: "https://api.spotify.com/v1/me/player/currently-playing") else {
            return Poll.afterError
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.cachePolicy = .reloadIgnoringLocalCacheData

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                statusMessage = "Unexpected response from Spotify."
                return Poll.afterError
            }

            switch http.statusCode {
            case 200:
                guard let decoded = try? JSONDecoder().decode(
                    CurrentlyPlayingTrack.self, from: data
                ) else {
                    statusMessage = "Could not read the current track."
                    return Poll.afterError
                }
                apply(decoded)
                return nextDelay(for: decoded)

            case 204:
                statusMessage = nil
                currentTrack = nil
                lastSharedURI = nil
                return Poll.nothingPlaying

            case 401:
                // Renewing the token needs a secret-holding backend the app does
                // not have, so the only recovery is reconnecting Spotify.
                statusMessage = "Your Spotify session expired. Reconnect Spotify."
                return Poll.afterError

            case 429:
                let retryAfter = http.value(forHTTPHeaderField: "Retry-After")
                    .flatMap(Int.init) ?? 30
                statusMessage = "Spotify is rate limiting. Retrying shortly."
                return .seconds(max(retryAfter, 5))

            default:
                statusMessage = "Spotify returned HTTP \(http.statusCode)."
                return Poll.afterError
            }
        } catch {
            if Task.isCancelled { return Poll.minimum }
            statusMessage = "Network error: \(error.localizedDescription)"
            return Poll.afterError
        }
    }

    @MainActor
    private func apply(_ track: CurrentlyPlayingTrack) {
        statusMessage = nil
        currentTrack = track

        // Share once per track, not once per poll.
        if track.uri != lastSharedURI {
            lastSharedURI = track.uri
            shareToFirestore(track)
        }
    }

    /// Wake up just after the current track ends, within sensible bounds.
    private func nextDelay(for track: CurrentlyPlayingTrack) -> Duration {
        guard track.isPlaying != false else { return Poll.paused }
        guard let remainingMs = track.remainingMs else { return Poll.maximum }

        let target = Duration.milliseconds(remainingMs) + Poll.endOfTrackBuffer
        return min(max(target, Poll.minimum), Poll.maximum)
    }

    // MARK: – Add to Firestore Favorites
    private func addToFavorites(_ track: CurrentlyPlayingTrack) {
        guard let uid, !uid.isEmpty else {
            statusMessage = "Sign in again to save favorites"
            return
        }

        // A title made only of punctuation sanitizes to "", which is an illegal
        // Firestore document ID. Fall back to the Spotify track ID, then give up.
        let sanitizedName = track.name
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .joined()
        let trackID = track.uri.split(separator: ":").last.map(String.init) ?? ""
        let safeID = sanitizedName.isEmpty ? trackID : sanitizedName

        guard !safeID.isEmpty else {
            statusMessage = "Couldn't build an ID for this track"
            return
        }

        let favRef = db
            .collection("users")
            .document(uid)
            .collection("favorites")
            .document(safeID)

        let data: [String: Any] = [
            "name": track.name,
            "artist": track.artist,
            "timestamp": Timestamp(date: Date())
        ]

        favRef.setData(data, merge: true) { error in
            DispatchQueue.main.async {
                if let err = error {
                    print("Favorite write error:", err)
                    statusMessage = "Failed to add favorite"
                } else {
                    statusMessage = "★ Added to favorites!"
                }
            }
        }
    }

    private func saveToSpotifyLibrary(trackUri: String) {
        guard let token = spotifyAuth.accessToken else {
            statusMessage = "Not logged into Spotify"
            return
        }

        let components = trackUri.split(separator: ":")
        guard components.count == 3, components[1] == "track" else {
            statusMessage = "Invalid track URI"
            return
        }
        let trackID = String(components[2])
        let urlString = "https://api.spotify.com/v1/me/tracks?ids=\(trackID)"
        guard let url = URL(string: urlString) else { return }

        var req = URLRequest(url: url)
        req.httpMethod = "PUT"
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: req) { _, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    statusMessage = "Spotify save error: \(error.localizedDescription)"
                } else if let http = response as? HTTPURLResponse, http.statusCode == 200 {
                    statusMessage = "★ Saved to Spotify!"
                } else {
                    let code = (response as? HTTPURLResponse)?.statusCode ?? -1
                    statusMessage = "Spotify HTTP \(code)"
                }
            }
        }.resume()
    }

    private func shareToFirestore(_ track: CurrentlyPlayingTrack) {
        guard let uid, !uid.isEmpty,
              let email = Auth.auth().currentUser?.email else { return }
        let doc: [String: Any] = [
            "name":        track.name,
            "artist":      track.artist,
            "albumArtURL": track.albumArtURL,
            "uri":         track.uri,
            "email":       email,
            "timestamp":   Timestamp(date: Date())
        ]

        db.collection("users").document(uid)
          .setData(["email": email], merge: true)

        db.collection("public_tracks").document(uid)
          .setData(doc, merge: true)
    }
}

struct MainAppView_Previews: PreviewProvider {
    static var previews: some View {
        MainAppView(currentTrack: .constant(nil))
            .environmentObject(SpotifyAuthManager())
    }
}
