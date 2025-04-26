import Foundation

struct CurrentlyPlayingTrack: Codable, Identifiable {
    // Auto-generated UUID for Identifiable conformance
    let id = UUID()
    // Only decode the “item” key from Spotify’s JSON
    let item: Item

    private enum CodingKeys: String, CodingKey {
        case item
    }

    struct Item: Codable {
        let name: String
        let artists: [Artist]
        let album: Album
    }

    struct Artist: Codable {
        let name: String
    }

    struct Album: Codable {
        struct Image: Codable {
            let url: String
        }
        let images: [Image]
    }

    // Convenience accessors
    var name: String { item.name }
    var artist: String { item.artists.first?.name ?? "Unknown Artist" }
    var albumArtURL: String { item.album.images.first?.url ?? "" }
}
