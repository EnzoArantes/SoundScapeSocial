//
//  RootView.swift
//  SoundScapeSocial
//
//  Replaces MainTabView. Same auth gating as before; the four-way TabView it
//  used to host is now HomeView's grid.
//

import SwiftUI
import FirebaseAuth

struct RootView: View {
    @EnvironmentObject var spotifyAuth: SpotifyAuthManager
    @StateObject private var nowPlaying = NowPlayingStore()
    @State private var signedIn = Auth.auth().currentUser != nil
    @State private var authListener: AuthStateDidChangeListenerHandle?

    private var welcomeEmail: String {
        Auth.auth().currentUser?.email ?? "User"
    }

    var body: some View {
        ZStack {
            Color.appBackground
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
                HomeView()
            }
        }
        .environmentObject(nowPlaying)
        .animation(.easeInOut, value: signedIn)
        .animation(.easeInOut, value: spotifyAuth.accessToken)
        .onAppear {
            guard authListener == nil else { return }
            authListener = Auth.auth().addStateDidChangeListener { _, user in
                signedIn = (user != nil)
                if user == nil {
                    Task { @MainActor in nowPlaying.clear() }
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

struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        RootView()
            .environmentObject(SpotifyAuthManager())
    }
}
