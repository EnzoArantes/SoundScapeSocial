import Foundation

struct CurrentlyPlayingTrack: Codable, Identifiable {

    let id = UUID()

    let item: Item

    /// How far into the track playback is, in milliseconds.
    /// Used to schedule the next poll for the moment the track ends.
    var progressMs: Int?
    /// False while the listener has playback paused.
    var isPlaying: Bool?

    private enum CodingKeys: String, CodingKey {
        case item
        case progressMs = "progress_ms"
        case isPlaying = "is_playing"
    }

    struct Item: Codable {
        let name: String
        let artists: [Artist]
        let album: Album
        let uri: String
        /// Total track length in milliseconds.
        var durationMs: Int?

        private enum CodingKeys: String, CodingKey {
            case name, artists, album, uri
            case durationMs = "duration_ms"
        }
    }

    struct Artist: Codable {
        let name: String
    }

    struct Album: Codable {
        struct Image: Codable { let url: String }
        let images: [Image]
    }

    // MARK: Convenience accessors
    var name: String { item.name }
    var artist: String { item.artists.first?.name ?? "Unknown Artist" }
    var albumArtURL: String { item.album.images.first?.url ?? "" }
    var uri: String { item.uri }

    /// Milliseconds left in the track, when Spotify reported both values.
    var remainingMs: Int? {
        guard let durationMs = item.durationMs, let progressMs else { return nil }
        return max(0, durationMs - progressMs)
    }
}
