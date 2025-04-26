import SwiftUI
import FirebaseAuth

struct MainTabView: View {
    @EnvironmentObject var spotifyAuth: SpotifyAuthManager
    @State private var currentTrack: CurrentlyPlayingTrack?
    @State private var signedIn = Auth.auth().currentUser != nil

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
                VStack {
                    Text("Welcome, \(welcomeEmail)")
                        .foregroundColor(.textColor)
                        .padding(.bottom, 20)
                    Button("Login with Spotify") {
                        spotifyAuth.accessToken = nil
                        spotifyAuth.sessionManager.session = nil
                        spotifyAuth.initiateLogin()
                    }
                    .padding()
                    .background(Color.primaryPurple)
                    .foregroundColor(.textColor)
                    .cornerRadius(8)
                }
            } else {
                TabView {
                    MainAppView(currentTrack: $currentTrack)
                        .tabItem { Label("You", systemImage: "person.crop.circle") }
                    DiscoverView()
                        .tabItem { Label("Discover", systemImage: "music.note.list") }
                    FriendsView()
                        .tabItem { Label("Friends", systemImage: "person.2.fill") }
                }
            }
        }
        .animation(.easeInOut, value: signedIn)
        .animation(.easeInOut, value: spotifyAuth.accessToken)
        .onAppear {
            Auth.auth().addStateDidChangeListener { _, user in
                signedIn = (user != nil)
                if user == nil {
                    currentTrack = nil
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
            .environmentObject(SpotifyAuthManager())
    }
}
