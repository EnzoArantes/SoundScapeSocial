//
//  DisoverView.swift
//  SoundScapeSocial
//
//  Created by Enzo Arantes on 4/25/25.
//

import SwiftUI

struct DiscoverView: View {
  @EnvironmentObject private var spotifyAuth: SpotifyAuthManager
  @StateObject private var vm = DiscoverViewModel()
  @State private var currentIndex = 0

  var body: some View {
    ZStack {
      Color.appBackground.ignoresSafeArea()

      if vm.tracks.isEmpty {
        ProgressView("Loading…")
          .foregroundColor(.textPrimary)

      } else if currentIndex < vm.tracks.count {
        SwipeCardView(track: vm.tracks[currentIndex]) { dir in
          if dir == .right {
            print("Liked \(vm.tracks[currentIndex].name)")
          }
          withAnimation { currentIndex += 1 }
        }

      } else {
        Text("No more tracks")
          .foregroundColor(.textPrimary)
      }
    }
    .onAppear {
      vm.updateAuth(spotifyAuth)
    }
  }
}


#Preview {
    DiscoverView()
}
