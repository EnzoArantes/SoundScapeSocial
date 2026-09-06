//
//  MainTabView.swift
//  SoundScapeSocial
//
//  Created by Enzo Arantes on 4/25/25.
//

import SwiftUI
import FirebaseAuth

struct MainTabView: View {
    @EnvironmentObject var spotifyAuth: SpotifyAuthManager
    @State private var currentTrack: CurrentlyPlayingTrack?
    @State private var signedIn = Auth.auth().currentUser != nil
    @State private var authListener: AuthStateDidChangeListenerHandle?

    private var welcomeEmail: String {
        Auth.auth().currentUser?.email ?? "User"
    }

    var body: some View {
        ZStack {
            Color.backgroundDark
                .ignoresSafeArea()

            if !signedIn {
                EmailAuthView()

            } else if spotifyAuth.accessToken == nil {
                SpotifyLoginView(email: welcomeEmail) {
                    // Clear any previous session and start a fresh one
                    spotifyAuth.accessToken = nil
                    spotifyAuth.sessionManager.session = nil
                    spotifyAuth.initiateLogin()
                }

            } else {
                TabView {
                    MainAppView(currentTrack: $currentTrack)
                        .tabItem { Label("You", systemImage: "person.crop.circle") }

                    DiscoverView()
                        .tabItem { Label("Discover", systemImage: "music.note.list") }

                    ForYouView()
                        .tabItem { Label("For You", systemImage: "sparkles") }

                    FriendsView()
                        .tabItem { Label("Friends", systemImage: "person.2.fill") }
                }
            }
        }
        .animation(.easeInOut, value: signedIn)
        .animation(.easeInOut, value: spotifyAuth.accessToken)
        .onAppear {
            guard authListener == nil else { return }
            authListener = Auth.auth().addStateDidChangeListener { _, user in
                signedIn = (user != nil)
                if user == nil {
                    currentTrack = nil
                }
            }
        }
        .onDisappear {
            guard let handle = authListener else { return }
            Auth.auth().removeStateDidChangeListener(handle)
            authListener = nil
        }
    }
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
            .environmentObject(SpotifyAuthManager())
    }
}
