import Foundation

struct SpotifyPreviewTrack: Identifiable, Codable {
    let id: String
    let name: String
    let artists: [Artist]
    let album: Album
    let preview_url: String?
    
    let uri: String
    var externalURL: URL? {
        guard let trackID = uri.split(separator: ":").last, !trackID.isEmpty else {
            return nil
        }
        return URL(string: "spotify:track:\(trackID)")
    }
    
    struct Artist: Codable { let name: String }
    struct Album: Codable {
        struct Image: Codable { let url: String }
        let images: [Image]
    }
    
    var previewURL: String? { preview_url }
    var artworkURL: String { album.images.first?.url ?? "" }
    var artistNames: String { artists.map(\.name).joined(separator: ", ") }
}
