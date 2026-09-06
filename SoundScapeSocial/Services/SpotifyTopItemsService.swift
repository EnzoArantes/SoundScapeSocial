import Foundation

/// The listening profile sent to the recommendation backend.
struct SpotifyTopItems {
    var artists: [String]
    var tracks: [String]

    var isEmpty: Bool { artists.isEmpty && tracks.isEmpty }

    static let empty = SpotifyTopItems(artists: [], tracks: [])
}

enum SpotifyTopItemsError: LocalizedError {
    /// 403: the token was issued before `user-top-read` was requested.
    case missingScope
    /// 401: the token expired or was revoked.
    case unauthorized
    case http(Int)
    case invalidURL

    var errorDescription: String? {
        switch self {
        case .missingScope:
            return "Reconnect Spotify to share your top artists."
        case .unauthorized:
            return "Your Spotify session expired. Sign in again."
        case .http(let code):
            return "Spotify returned HTTP \(code)."
        case .invalidURL:
            return "Could not build the Spotify request."
        }
    }
}

/// Reads the signed-in listener's top artists and tracks from the Spotify Web API.
///
/// Requires the `user-top-read` scope, requested in `SpotifyAuthManager`.
struct SpotifyTopItemsService {

    /// Spotify allows 1-50; the backend caps each list at 20 anyway.
    private let limit = 20
    private let timeRange = "medium_term"

    func fetchTopItems(token: String) async throws -> SpotifyTopItems {
        async let artists = fetchArtistNames(token: token)
        async let tracks = fetchTrackNames(token: token)
        return SpotifyTopItems(artists: try await artists, tracks: try await tracks)
    }

    // MARK: - Requests

    private func fetchArtistNames(token: String) async throws -> [String] {
        let payload: TopArtistsResponse = try await get(type: "artists", token: token)
        return payload.items.map(\.name)
    }

    private func fetchTrackNames(token: String) async throws -> [String] {
        let payload: TopTracksResponse = try await get(type: "tracks", token: token)
        return payload.items.map { item in
            if let artist = item.artists.first?.name {
                return "\(item.name) by \(artist)"
            }
            return item.name
        }
    }

    private func get<T: Decodable>(type: String, token: String) async throws -> T {
        var components = URLComponents(string: "https://api.spotify.com/v1/me/top/\(type)")
        components?.queryItems = [
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "time_range", value: timeRange)
        ]
        guard let url = components?.url else {
            throw SpotifyTopItemsError.invalidURL
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw SpotifyTopItemsError.http(-1)
        }

        switch http.statusCode {
        case 200:
            return try JSONDecoder().decode(T.self, from: data)
        case 401:
            throw SpotifyTopItemsError.unauthorized
        case 403:
            throw SpotifyTopItemsError.missingScope
        default:
            throw SpotifyTopItemsError.http(http.statusCode)
        }
    }

    // MARK: - Wire format

    private struct TopArtistsResponse: Decodable {
        struct Artist: Decodable { let name: String }
        let items: [Artist]
    }

    private struct TopTracksResponse: Decodable {
        struct Track: Decodable {
            struct Artist: Decodable { let name: String }
            let name: String
            let artists: [Artist]
        }
        let items: [Track]
    }
}
