import SwiftUI

/// The app's front door.
///
/// Replaces the four-way tab bar. Discover, For You, Friends and the former
/// "You" screen all still exist unchanged; they are simply entered from this
/// grid instead of from sibling tabs.
struct HomeView: View {
    @EnvironmentObject private var spotifyAuth: SpotifyAuthManager
    @EnvironmentObject private var nowPlaying: NowPlayingStore

    @State private var showingFriends = false

    private let columns = [
        GridItem(.flexible(), spacing: HomeGridMetrics.spacing),
        GridItem(.flexible(), spacing: HomeGridMetrics.spacing)
    ]

    /// Cells after the two fixed ones on the top row. Append here to grow the
    /// grid; no layout changes needed.
    private let entries: [HomeEntry] = [.discover, .forYou, .addFriends]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground
                    .ignoresSafeArea()

                ScrollView {
                    LazyVGrid(columns: columns, spacing: HomeGridMetrics.spacing) {
                        // Top-left: own listening. Display only, not tappable.
                        NowPlayingCell(
                            track: nowPlaying.track,
                            statusMessage: nowPlaying.statusMessage
                        )

                        // Top-right: doorway to the friends carousel.
                        NavigationLink(value: HomeDestination.friendsCarousel) {
                            HomeEntryCell(entry: .friendsCarousel)
                        }
                        .buttonStyle(.plain)

                        ForEach(entries) { entry in
                            switch entry.action {
                            case .push(let destination):
                                NavigationLink(value: destination) {
                                    HomeEntryCell(entry: entry)
                                }
                                .buttonStyle(.plain)

                            case .presentFriends:
                                Button {
                                    showingFriends = true
                                } label: {
                                    HomeEntryCell(entry: entry)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("SoundScape")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(value: HomeDestination.you) {
                        Image(systemName: "person.crop.circle")
                    }
                    .accessibilityLabel("Your account")
                }
            }
            .navigationDestination(for: HomeDestination.self) { destination in
                switch destination {
                case .friendsCarousel:
                    FriendsCarouselView()
                case .discover:
                    DiscoverView()
                        .navigationTitle("Discover")
                        .navigationBarTitleDisplayMode(.inline)
                case .forYou:
                    ForYouView()
                        .navigationBarTitleDisplayMode(.inline)
                case .you:
                    MainAppView()
                        .navigationTitle("You")
                        .navigationBarTitleDisplayMode(.inline)
                }
            }
            // Presented rather than pushed: FriendsView owns its own
            // NavigationView, and nesting navigation containers doubles the bar.
            .sheet(isPresented: $showingFriends) {
                FriendsView()
            }
        }
        // Home drives the poll loop while it is on screen.
        .task(id: spotifyAuth.accessToken) {
            await nowPlaying.poll(token: spotifyAuth.accessToken)
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(SpotifyAuthManager())
        .environmentObject(NowPlayingStore())
}
