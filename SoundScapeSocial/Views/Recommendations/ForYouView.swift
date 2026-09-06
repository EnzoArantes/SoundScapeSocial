import SwiftUI

struct ForYouView: View {
    @EnvironmentObject private var spotifyAuth: SpotifyAuthManager
    @StateObject private var vm = RecommendationsViewModel()
    @Environment(\.openURL) private var openURL

    var body: some View {
        ZStack {
            Color.appBackground
                .ignoresSafeArea()

            switch vm.state {
            case .idle, .loading:
                ProgressView("Finding songs for you…")
                    .tint(.brandAccent)
                    .foregroundColor(.textPrimary)

            case .message(let text):
                messageState(text)

            case .loaded(let recommendations):
                list(recommendations)
            }
        }
        .task(id: spotifyAuth.accessToken) {
            await vm.load(token: spotifyAuth.accessToken)
        }
    }

    // MARK: - States

    private func messageState(_ text: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.largeTitle)
                .foregroundColor(.brandAccent)

            Text(text)
                .font(.subheadline)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            retryButton
        }
    }

    private func list(_ recommendations: [SongRecommendation]) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                header

                ForEach(recommendations) { recommendation in
                    RecommendationRow(recommendation: recommendation) {
                        if let url = recommendation.spotifySearchURL {
                            openURL(url)
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 24)
        }
        .refreshable {
            await vm.load(token: spotifyAuth.accessToken)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("For You")
                .font(.largeTitle).bold()
                .foregroundColor(.textPrimary)
            Text("Picked from your top artists and tracks.")
                .font(.subheadline)
                .foregroundColor(.textSecondary)
        }
        .padding(.top)
        .padding(.bottom, 4)
    }

    private var retryButton: some View {
        Button {
            Task { await vm.load(token: spotifyAuth.accessToken) }
        } label: {
            Text("Try Again")
                .font(.headline)
                .padding(.vertical, 10)
                .padding(.horizontal, 24)
                .background(Color.brandFill)
                .foregroundColor(.onBrand)
                .cornerRadius(12)
        }
        .disabled(vm.isLoading)
    }
}

// MARK: - Row

struct RecommendationRow: View {
    let recommendation: SongRecommendation
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 6) {
                Text(recommendation.track)
                    .font(.headline)
                    .foregroundColor(.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                Text(recommendation.artist)
                    .font(.subheadline)
                    .foregroundColor(.brandAccent)
                    .lineLimit(1)

                Text(recommendation.reason)
                    .font(.caption)
                    .foregroundColor(.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color.appSurface)
            .cornerRadius(16)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ForYouView()
        .environmentObject(SpotifyAuthManager())
}
