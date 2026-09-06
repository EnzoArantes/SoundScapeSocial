import SwiftUI

/// Placeholder destination behind Home's top-right cell.
///
/// The navigation path into this screen is wired and working. The carousel of
/// what friends are playing, plus live reactions, lands here next; that work
/// reuses `FriendsViewModel` and `MusicNodeView` rather than reimplementing
/// them.
struct FriendsCarouselView: View {
    var body: some View {
        ZStack {
            Color.appBackground
                .ignoresSafeArea()

            VStack(spacing: 12) {
                Image(systemName: "person.2.wave.2.fill")
                    .font(.system(size: 44))
                    .foregroundColor(.brandAccent)

                Text("Coming soon")
                    .font(.title3.weight(.semibold))
                    .foregroundColor(.textPrimary)

                Text("The friends carousel will live here.")
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
        }
        .navigationTitle("Friends")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack { FriendsCarouselView() }
}
