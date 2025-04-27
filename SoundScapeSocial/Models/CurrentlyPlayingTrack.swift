import Foundation

struct CurrentlyPlayingTrack: Codable, Identifiable {

    let id = UUID()

    let item: Item

    private enum CodingKeys: String, CodingKey {
        case item
    }

    struct Item: Codable {
        let name: String
        let artists: [Artist]
        let album: Album
        let uri: String

        private enum CodingKeys: String, CodingKey {
            case name, artists, album, uri
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
}
