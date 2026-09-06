import Foundation

/// One song suggested by the `recommendSongs` Cloud Function.
struct SongRecommendation: Codable, Identifiable, Hashable {
    let artist: String
    let track: String
    let reason: String

    /// The backend does not return an ID, so derive a stable one for SwiftUI.
    var id: String { "\(artist)|\(track)" }

    /// Opens the track in the Spotify app, falling back to a web search.
    var spotifySearchURL: URL? {
        let query = "\(track) \(artist)"
        guard let encoded = query.addingPercentEncoding(
            withAllowedCharacters: .urlQueryAllowed
        ), !encoded.isEmpty else {
            return nil
        }
        return URL(string: "spotify:search:\(encoded)")
    }
}
