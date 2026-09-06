import SwiftUI

/// Horizontal carousel of what friends are listening to right now.
///
/// Reuses rather than reimplements:
/// - `FriendCardView` (FriendsView.swift) renders each card. It already draws
///   the artwork via `MusicNodeView`, the track and artist, the friend's
///   incoming reaction, and the three reaction buttons. Its reaction internals
///   are private, so it is used whole rather than picked apart.
/// - `FriendsViewModel` (FriendsView.swift) supplies the data and owns the
///   write path: `react(to:reaction:)` is passed straight through as the
///   card's `onReact`, so reaction logic is not duplicated here.
///
/// Data cadence: `FriendsViewModel` is push-based. Its `init` attaches
/// Firestore snapshot listeners, so this screen loads when it appears and then
/// stays current on its own. It reads Firestore only, uses no Spotify token,
/// and writes nothing on read, so it does not reopen the token-expiry or
/// write-amplification problems that ruled out polling. See the note in the
/// report for the manual-refresh seam.
struct FriendsCarouselView: View {

    /// A second, independent instance from the one `FriendsView` holds. Both
    /// attach their own listeners; only one of the two screens is on screen at
    /// a time, and each tears its listeners down in `deinit`.
    @StateObject private var vm = FriendsViewModel()

    /// Drives which card is centered, and therefore which one is interactive.
    @State private var centeredFriendID: String?

    private let spacing: CGFloat = 16
    /// Leaves roughly an eighth of the width on each side for the neighbours
    /// to peek in and be clipped by the screen edges.
    private let cardWidthFraction: CGFloat = 0.72

    var body: some View {
        ZStack {
            Color.appBackground
                .ignoresSafeArea()

            if vm.friends.isEmpty {
                emptyState
            } else {
                carousel
            }
        }
        .navigationTitle("Friends")
        .navigationBarTitleDisplayMode(.inline)
        // Keep a valid centered card as the friend list arrives or changes.
        .onChange(of: vm.friends.map(\.id), initial: true) { _, ids in
            if let current = centeredFriendID, ids.contains(current) { return }
            centeredFriendID = ids.first
        }
    }

    // MARK: - Carousel

    private var carousel: some View {
        // GeometryReader is used only to size the cards and the side inset that
        // centers them. The scale and opacity falloff is driven by
        // `.scrollTransition`, not by geometry math.
        GeometryReader { proxy in
            let cardWidth: CGFloat = proxy.size.width * cardWidthFraction
            let sideInset: CGFloat = max(0, (proxy.size.width - cardWidth) / 2)

            scrollView(cardWidth: cardWidth, sideInset: sideInset, height: proxy.size.height)
        }
    }

    private func scrollView(cardWidth: CGFloat, sideInset: CGFloat, height: CGFloat) -> some View {
        ScrollView(.horizontal) {
            LazyHStack(alignment: .center, spacing: spacing) {
                ForEach(vm.friends) { friend in
                    card(for: friend, width: cardWidth)
                }
            }
            .scrollTargetLayout()
            .padding(.horizontal, sideInset)
            .frame(height: height)
        }
        .scrollTargetBehavior(.viewAligned)
        .scrollIndicators(.hidden)
        .scrollPosition(id: $centeredFriendID)
    }

    /// One carousel item: the existing friend card plus centering emphasis.
    private func card(for friend: FriendData, width: CGFloat) -> some View {
        let isCentered: Bool = friend.id == centeredFriendID

        return FriendCardView(friend: friend, onReact: vm.react)
            .frame(width: width)
            // Scale and fade neighbours out as they move away from center.
            // `scrollTransition` builds a VisualEffect, so only effects that
            // exist there belong in this closure; the shadow is applied below.
            .scrollTransition(.interactive, axis: .horizontal) { content, phase in
                let distance: Double = abs(phase.value)
                return content
                    .scaleEffect(1.0 - distance * 0.16)
                    .opacity(1.0 - distance * 0.45)
            }
            // Lifts the centered card above its neighbours.
            .shadow(
                color: Color.black.opacity(isCentered ? 0.35 : 0.0),
                radius: 18,
                x: 0,
                y: 10
            )
            .animation(.easeInOut(duration: 0.2), value: isCentered)
            // Only the centered friend takes reaction taps, so a half-visible
            // neighbour cannot be tapped by mistake.
            .allowsHitTesting(isCentered)
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.2.wave.2.fill")
                .font(.system(size: 44))
                .foregroundColor(.brandAccent)

            Text("No friends yet")
                .font(.title3.weight(.semibold))
                .foregroundColor(.textPrimary)

            Text("Add someone from the Add Friends cell on Home to see what they're playing.")
                .font(.subheadline)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }
}

#Preview {
    NavigationStack { FriendsCarouselView() }
}
