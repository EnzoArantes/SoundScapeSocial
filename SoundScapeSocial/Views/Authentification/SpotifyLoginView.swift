//
//  SpotifyLoginView.swift
//  SoundScapeSocial
//
//  Created by Enzo Arantes on 4/26/25.
//

import SwiftUI

struct SpotifyLoginView: View {
    let email: String
    let action: () -> Void

    var body: some View {
        ZStack {
            Color.backgroundDark
                .ignoresSafeArea()

            VStack(spacing: 24) {
                // If you have a Spotify logo asset, name it "SpotifyLogo" in Assets.xcassets
                Image("SpotifyLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .shadow(radius: 4)

                VStack(spacing: 4) {
                    Text("Welcome,")
                        .font(.title2)
                        .foregroundColor(.textColor.opacity(0.7))
                    Text(email)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.textColor)
                }

                Text("Connect your Spotify account to discover and share what you’re listening to.")
                    .font(.subheadline)
                    .foregroundColor(.textColor.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Button(action: action) {
                    HStack {
                        Image(systemName: "music.note")
                        Text("Login with Spotify")
                            .fontWeight(.semibold)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .shadow(radius: 2)
                }
                .padding(.horizontal, 32)
            }
            .padding()
            .background(Color.secondaryPurple.opacity(0.1))
            .cornerRadius(20)
            .padding(.horizontal)
        }
    }
}

struct SpotifyLoginView_Previews: PreviewProvider {
    static var previews: some View {
        SpotifyLoginView(email: "you@example.com") {
            // no-op
        }
    }
}
