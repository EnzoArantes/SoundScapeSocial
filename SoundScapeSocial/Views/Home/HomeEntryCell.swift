import SwiftUI

/// The standard tappable Home cell: icon, title, supporting line.
///
/// Presentation only. The caller wraps it in whatever triggers navigation, so
/// the same cell works behind a `NavigationLink` or a `Button`.
struct HomeEntryCell: View {
    let entry: HomeEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: entry.systemImage)
                .font(.title2)
                .foregroundColor(.brandAccent)

            Spacer(minLength: 0)

            Text(entry.title)
                .font(.headline)
                .foregroundColor(.textPrimary)
                .lineLimit(1)

            Text(entry.subtitle)
                .font(.caption)
                .foregroundColor(.textSecondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
                .multilineTextAlignment(.leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: HomeGridMetrics.cellHeight)
        .padding()
        .background(Color.appSurface)
        .cornerRadius(20)
    }
}

/// Shared sizing so every cell in the grid lines up.
enum HomeGridMetrics {
    static let cellHeight: CGFloat = 150
    static let spacing: CGFloat = 16
}

#Preview {
    HomeEntryCell(entry: .discover)
        .padding()
        .background(Color.appBackground)
}
