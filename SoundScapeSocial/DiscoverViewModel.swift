import Foundation
import Combine

class DiscoverViewModel: ObservableObject {
    @Published var tracks: [SpotifyPreviewTrack] = []
    private var cancellables = Set<AnyCancellable>()
    private var auth: SpotifyAuthManager?

    init(auth: SpotifyAuthManager? = nil) {
        self.auth = auth
        bindAndFetchIfReady()
    }

    func updateAuth(_ auth: SpotifyAuthManager) {
        self.auth = auth
        bindAndFetchIfReady()
    }

    private func bindAndFetchIfReady() {
        guard let auth = auth else { return }
        if auth.accessToken != nil {
            fetchTracks()
        }
        cancellables.removeAll()
        auth.$accessToken
            .compactMap { $0 }
            .sink { [weak self] _ in self?.fetchTracks() }
            .store(in: &cancellables)
    }

    private func fetchTracks() {
        guard let token = auth?.accessToken else {
            print("⚠️ No access token, aborting discovery fetch")
            return
        }
        let market = Locale.current.region?.identifier ?? "US"
        let query = "genre:%22pop%22"
        let urlString = "https://api.spotify.com/v1/search?q=\(query)&type=track&market=\(market)&limit=20"
        guard let url = URL(string: urlString) else {
            print("⚠️ Bad URL: \(urlString)")
            return
        }

        var req = URLRequest(url: url)
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: req) { data, response, error in
            if let error = error {
                print("❌ Network error:", error)
                return
            }
            if let http = response as? HTTPURLResponse {
                print("🔢 HTTP status:", http.statusCode)
            }
            if let data = data, let body = String(data: data, encoding: .utf8) {
                print("📃 Response body:\n", body)
            }
            guard let data = data, !data.isEmpty else { return }

            do {
                struct SearchResponse: Codable {
                    struct Tracks: Codable { let items: [SpotifyPreviewTrack] }
                    let tracks: Tracks
                }
                let resp = try JSONDecoder().decode(SearchResponse.self, from: data)
                DispatchQueue.main.async {
                    self.tracks = resp.tracks.items
                }
            } catch {
                print("❌ Decode error:", error)
            }
        }.resume()
    }
}
