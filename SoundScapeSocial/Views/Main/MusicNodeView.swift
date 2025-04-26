//
//  MusicNodeView.swift
//  SoundScapeSocial
//
//  Created by Enzo Arantes on 4/25/25.
//
import SwiftUI

struct MusicNodeView: View {
  let track: CurrentlyPlayingTrack
  let size: CGFloat

  @State private var pulse = false

  var body: some View {
    VStack(spacing: 8) {
      AsyncImage(url: URL(string: track.albumArtURL)) { phase in
        if let image = phase.image {
          image
            .resizable()
            .scaledToFill()
        } else if phase.error != nil {
          Color.red // error placeholder
        } else {
          Color.gray // loading placeholder
        }
      }
      .frame(width: size, height: size)
      .clipShape(Circle())
      .shadow(radius: 4)
      .scaleEffect(pulse ? 1.1 : 0.9)
      .onAppear {
        withAnimation(.easeInOut(duration: 1).repeatForever()) {
          pulse.toggle()
        }
      }

      Text(track.name)
        .font(.caption)
        .lineLimit(1)
        .foregroundColor(.textColor)
    }
  }
}

struct MusicNodeView_Previews: PreviewProvider {
  static var previews: some View {
    // We must supply `uri:` now that Item has that field:
    let dummyItem = CurrentlyPlayingTrack.Item(
      name: "Sample Song",
      artists: [.init(name: "Sample Artist")],
      album: .init(images: [.init(url: "https://via.placeholder.com/150")]),
      uri: "spotify:track:1234567890abcdef"
    )
    let dummyTrack = CurrentlyPlayingTrack(item: dummyItem)

    MusicNodeView(track: dummyTrack, size: 120)
      .previewLayout(.sizeThatFits)
      .padding()
  }
}
