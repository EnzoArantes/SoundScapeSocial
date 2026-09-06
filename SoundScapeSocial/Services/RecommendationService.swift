import Foundation
import FirebaseFunctions

enum RecommendationError: LocalizedError {
    case notSignedIn
    case noListeningHistory
    case backendUnavailable
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .notSignedIn:
            return "Sign in to get recommendations."
        case .noListeningHistory:
            return "Listen to a few more songs on Spotify, then try again."
        case .backendUnavailable:
            return "Recommendations are unavailable right now. Try again shortly."
        case .unknown(let message):
            return message
        }
    }
}

/// Calls the `recommendSongs` callable Cloud Function.
///
/// The function lives in `us-central1` and is deployed from the separate
/// `soundscape-backend` repository. It requires an authenticated caller.
struct RecommendationService {

    private struct Request: Encodable {
        let topArtists: [String]
        let topTracks: [String]
    }

    private struct Response: Decodable {
        let recommendations: [SongRecommendation]
    }

    private let functions = Functions.functions(region: "us-central1")

    func recommendations(for items: SpotifyTopItems) async throws -> [SongRecommendation] {
        let callable: Callable<Request, Response> = functions.httpsCallable(
            "recommendSongs",
            requestAs: Request.self,
            responseAs: Response.self
        )

        do {
            let response = try await callable.call(
                Request(topArtists: items.artists, topTracks: items.tracks)
            )
            return response.recommendations
        } catch let error as NSError {
            throw Self.mapped(error)
        }
    }

    /// Translates a Functions error into something worth showing a listener.
    private static func mapped(_ error: NSError) -> RecommendationError {
        guard error.domain == FunctionsErrorDomain,
              let code = FunctionsErrorCode(rawValue: error.code) else {
            return .backendUnavailable
        }

        switch code {
        case .unauthenticated:
            return .notSignedIn
        case .invalidArgument:
            return .noListeningHistory
        case .internal, .unavailable, .deadlineExceeded, .resourceExhausted:
            return .backendUnavailable
        default:
            return .unknown(error.localizedDescription)
        }
    }
}
