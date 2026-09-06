import SwiftUI

/// Top-left Home cell: what the signed-in listener is playing right now.
///
/// Display only, and deliberately not tappable. It reads the same
/// `NowPlayingStore` value the You screen shows, so the two never disagree.
struct NowPlayingCell: View {
    let track: CurrentlyPlayingTrack?
    let statusMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let track {
                HStack(alignment: .top, spacing: 10) {
                    artwork(url: track.albumArtURL)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Now Playing")
                            .font(.caption2.weight(.semibold))
                            .foregroundColor(.brandAccent)
                            .textCase(.uppercase)
                        Text(track.name)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.textPrimary)
                            .lineLimit(2)
                        Text(track.artist)
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                            .lineLimit(1)
                    }
                }
                Spacer(minLength: 0)
            } else {
                Image(systemName: "music.note")
                    .font(.title2)
                    .foregroundColor(.brandAccent)

                Spacer(minLength: 0)

                Text("Nothing playing")
                    .font(.headline)
                    .foregroundColor(.textPrimary)

                Text(statusMessage ?? "Start something on Spotify")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.leading)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: HomeGridMetrics.cellHeight)
        .padding()
        .background(Color.appSurface)
        .cornerRadius(20)
    }

    private func artwork(url: String) -> some View {
        AsyncImage(url: URL(string: url)) { phase in
            if let image = phase.image {
                image.resizable().scaledToFill()
            } else {
                Color.appBackground
            }
        }
        .frame(width: 56, height: 56)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    NowPlayingCell(track: nil, statusMessage: nil)
        .padding()
        .background(Color.appBackground)
}
