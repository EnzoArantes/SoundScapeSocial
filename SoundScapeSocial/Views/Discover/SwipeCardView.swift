//
//  SwipeCardView.swift
//  SoundScapeSocial
//
//  Created by Enzo Arantes on 4/25/25.
//
import SwiftUI
import UIKit

enum SwipeDirection { case left, right }

struct SwipeCardView: View {
    let track: SpotifyPreviewTrack
    var onSwipe: (SwipeDirection) -> Void

    @GestureState private var drag: CGSize = .zero

    var body: some View {
        ZStack {
            // Your album art — use a spinner placeholder if you like:
            AsyncImage(url: URL(string: track.artworkURL)) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .frame(width: 300, height: 400)
                case .success(let img):
                    img.resizable().scaledToFill()
                case .failure:
                    Color.gray
                @unknown default:
                    Color.gray
                }
            }
            .frame(width: 300, height: 400)
            .clipped()
            .cornerRadius(16)
            .shadow(radius: 8)

            // Only the bottom text panel gets a translucent background:
            VStack {
                Spacer()
                VStack(spacing: 4) {
                    Text(track.name)
                        .font(.headline)
                        .foregroundColor(.white)
                    Text(track.artistNames)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding()
                .background(Color.black.opacity(0.4))
                .cornerRadius(16, corners: [.bottomLeft, .bottomRight])
            }
            .frame(width: 300, height: 400)  // match the card size so the panel sits at bottom
        }
        .offset(x: drag.width, y: drag.height)
        .rotationEffect(.degrees(Double(drag.width / 20)))
        .gesture(
            DragGesture()
                .updating($drag) { value, state, _ in state = value.translation }
                .onEnded { value in
                    if value.translation.width > 100 {
                        finalize(.right)
                    } else if value.translation.width < -100 {
                        finalize(.left)
                    }
                }
        )
        .onTapGesture {
            if let url = track.externalURL {
                UIApplication.shared.open(url)
            }
        }
    }

    private func finalize(_ dir: SwipeDirection) {
        onSwipe(dir)
    }
}

// Preview stays the same, no dark stripe here:
struct SwipeCardView_Previews: PreviewProvider {
    static var sampleTrack = SpotifyPreviewTrack(
        id: "1",
        name: "Sample Song",
        artists: [.init(name: "Artist")],
        album: .init(images: [.init(url: "https://via.placeholder.com/300")]),
        preview_url: nil,
        uri: "spotify:track:123"
    )

    static var previews: some View {
        SwipeCardView(track: sampleTrack) { _ in }
            .padding()
            .background(Color.backgroundDark)
    }
}
