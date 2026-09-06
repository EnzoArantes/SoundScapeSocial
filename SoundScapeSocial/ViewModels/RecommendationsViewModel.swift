import Foundation

@MainActor
final class RecommendationsViewModel: ObservableObject {

    enum State: Equatable {
        case idle
        case loading
        case loaded([SongRecommendation])
        case message(String)
    }

    @Published private(set) var state: State = .idle

    private let topItemsService = SpotifyTopItemsService()
    private let recommendationService = RecommendationService()

    var isLoading: Bool { state == .loading }

    /// Fetches the listener's Spotify profile, then asks the backend for songs.
    func load(token: String?) async {
        guard let token, !token.isEmpty else {
            state = .message("Connect Spotify to get recommendations.")
            return
        }

        state = .loading

        let items: SpotifyTopItems
        do {
            items = try await topItemsService.fetchTopItems(token: token)
        } catch {
            state = .message(error.localizedDescription)
            return
        }

        guard !items.isEmpty else {
            state = .message(RecommendationError.noListeningHistory.localizedDescription)
            return
        }

        do {
            let recommendations = try await recommendationService.recommendations(for: items)
            state = recommendations.isEmpty
                ? .message("No recommendations came back. Try again shortly.")
                : .loaded(recommendations)
        } catch {
            state = .message(error.localizedDescription)
        }
    }
}
