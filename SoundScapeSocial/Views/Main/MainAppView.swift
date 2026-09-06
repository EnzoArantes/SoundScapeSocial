import SwiftUI
import FirebaseAuth
import FirebaseFirestore

/// The former "You" tab, now pushed from Home's account button.
///
/// Polling and the now-playing value moved to `NowPlayingStore` so Home's
/// own-listening cell and this screen read the same source. Everything this
/// screen does otherwise is unchanged.
struct MainAppView: View {
    @EnvironmentObject var spotifyAuth: SpotifyAuthManager
    @EnvironmentObject private var nowPlaying: NowPlayingStore

    private let db = Firestore.firestore()
    private var uid: String? { Auth.auth().currentUser?.uid }

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
                if let statusMessage = nowPlaying.statusMessage {
                    Text(statusMessage)
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Spacer()

                // MARK: – Now Playing Card
                if let track = nowPlaying.track {
                    VStack(spacing: 16) {
                        AsyncImage(url: URL(string: track.albumArtURL)) { phase in
                            if let img = phase.image {
                                img.resizable().scaledToFill()
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
            .animation(.easeInOut, value: nowPlaying.track?.uri)
        }
        // Home stops polling once it is pushed off screen, so keep it running
        // here for as long as this screen is visible.
        .task(id: spotifyAuth.accessToken) {
            await nowPlaying.poll(token: spotifyAuth.accessToken)
        }
    }

    // MARK: – Add to Firestore Favorites
    private func addToFavorites(_ track: CurrentlyPlayingTrack) {
        guard let uid, !uid.isEmpty else {
            nowPlaying.statusMessage = "Sign in again to save favorites"
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
            nowPlaying.statusMessage = "Couldn't build an ID for this track"
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
                    nowPlaying.statusMessage = "Failed to add favorite"
                } else {
                    nowPlaying.statusMessage = "★ Added to favorites!"
                }
            }
        }
    }

    private func saveToSpotifyLibrary(trackUri: String) {
        guard let token = spotifyAuth.accessToken else {
            nowPlaying.statusMessage = "Not logged into Spotify"
            return
        }

        let components = trackUri.split(separator: ":")
        guard components.count == 3, components[1] == "track" else {
            nowPlaying.statusMessage = "Invalid track URI"
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
                    nowPlaying.statusMessage = "Spotify save error: \(error.localizedDescription)"
                } else if let http = response as? HTTPURLResponse, http.statusCode == 200 {
                    nowPlaying.statusMessage = "★ Saved to Spotify!"
                } else {
                    let code = (response as? HTTPURLResponse)?.statusCode ?? -1
                    nowPlaying.statusMessage = "Spotify HTTP \(code)"
                }
            }
        }.resume()
    }
}

struct MainAppView_Previews: PreviewProvider {
    static var previews: some View {
        MainAppView()
            .environmentObject(SpotifyAuthManager())
            .environmentObject(NowPlayingStore())
    }
}
