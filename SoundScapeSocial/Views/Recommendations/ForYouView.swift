import SwiftUI

struct ForYouView: View {
    @EnvironmentObject private var spotifyAuth: SpotifyAuthManager
    @StateObject private var vm = RecommendationsViewModel()
    @Environment(\.openURL) private var openURL

    var body: some View {
        ZStack {
            Color.backgroundDark
                .ignoresSafeArea()

            switch vm.state {
            case .idle, .loading:
                ProgressView("Finding songs for you…")
                    .tint(.primaryPurple)
                    .foregroundColor(.textColor)

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
                .foregroundColor(.primaryPurple)

            Text(text)
                .font(.subheadline)
                .foregroundColor(.textColor.opacity(0.8))
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
                .foregroundColor(.textColor)
            Text("Picked from your top artists and tracks.")
                .font(.subheadline)
                .foregroundColor(.textColor.opacity(0.7))
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
                .background(Color.primaryPurple)
                .foregroundColor(.textColor)
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
                    .foregroundColor(.textColor)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                Text(recommendation.artist)
                    .font(.subheadline)
                    .foregroundColor(.primaryPurple)
                    .lineLimit(1)

                Text(recommendation.reason)
                    .font(.caption)
                    .foregroundColor(.textColor.opacity(0.7))
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color.secondaryPurple.opacity(0.18))
            .cornerRadius(16)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ForYouView()
        .environmentObject(SpotifyAuthManager())
}
