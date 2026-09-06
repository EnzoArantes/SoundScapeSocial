import Foundation
import FirebaseAuth
import FirebaseFirestore

/// Owns "what the signed-in listener is playing right now".
///
/// Lifted out of `MainAppView` so more than one screen can read the same value.
/// Home's own-listening cell and the You screen both observe this object rather
/// than each running their own poll loop.
///
/// Spotify has no push event for "track ended", so this polls, scheduling the
/// next check from the time left in the current track.
@MainActor
final class NowPlayingStore: ObservableObject {

    @Published private(set) var track: CurrentlyPlayingTrack?
    @Published var statusMessage: String?

    private let db = Firestore.firestore()
    private var lastSharedURI: String?
    private var uid: String? { Auth.auth().currentUser?.uid }

    private enum Poll {
        static let minimum: Duration = .seconds(3)
        static let maximum: Duration = .seconds(30)
        static let paused: Duration = .seconds(15)
        static let nothingPlaying: Duration = .seconds(20)
        static let afterError: Duration = .seconds(30)
        /// Land just past the end of the track, not exactly on it.
        static let endOfTrackBuffer: Duration = .milliseconds(1500)
    }

    /// Drive this from a view's `.task(id:)` so polling follows that view's
    /// lifetime: SwiftUI cancels the task when the view disappears.
    func poll(token: String?) async {
        while !Task.isCancelled {
            let wait = await refresh(token: token)
            if Task.isCancelled { return }
            do {
                try await Task.sleep(for: wait)
            } catch {
                return // cancelled while sleeping
            }
        }
    }

    /// Forget the current listener's state, e.g. after sign-out.
    func clear() {
        track = nil
        lastSharedURI = nil
        statusMessage = nil
    }

    // MARK: - One pass

    /// Performs one check and returns how long to wait before the next one.
    private func refresh(token: String?) async -> Duration {
        guard let token, !token.isEmpty else {
            statusMessage = "Connect Spotify to see what's playing."
            track = nil
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
                track = nil
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

    private func apply(_ incoming: CurrentlyPlayingTrack) {
        statusMessage = nil
        track = incoming

        // Share once per track, not once per poll.
        if incoming.uri != lastSharedURI {
            lastSharedURI = incoming.uri
            shareToFirestore(incoming)
        }
    }

    /// Wake up just after the current track ends, within sensible bounds.
    private func nextDelay(for track: CurrentlyPlayingTrack) -> Duration {
        guard track.isPlaying != false else { return Poll.paused }
        guard let remainingMs = track.remainingMs else { return Poll.maximum }

        let target = Duration.milliseconds(remainingMs) + Poll.endOfTrackBuffer
        return min(max(target, Poll.minimum), Poll.maximum)
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
