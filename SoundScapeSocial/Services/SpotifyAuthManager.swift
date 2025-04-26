import Foundation
import SpotifyiOS
import Combine

class SpotifyAuthManager: NSObject, ObservableObject, SPTSessionManagerDelegate {
    private let configuration = SPTConfiguration(
        clientID:    "2be07743815147f4897fd8d571ebca59",
        redirectURL: URL(string: "soundscapesocial://spotify-auth")!
    )
    
    lazy var sessionManager: SPTSessionManager = {
        SPTSessionManager(configuration: configuration, delegate: self)
    }()
    
    @Published var accessToken: String?
    
    func initiateLogin() {
        accessToken = nil
        let scopes: SPTScope = [
            .userReadCurrentlyPlaying,
            .userReadPlaybackState,
            .userLibraryModify   // new
        ]
        sessionManager.initiateSession(
            with: scopes,
            options: .default,
            campaign: nil
        )
    }
    
    func sessionManager(manager: SPTSessionManager, didInitiate session: SPTSession) {
        print("✅ Spotify session initiated. Access token: \(session.accessToken)")
        DispatchQueue.main.async {
            self.accessToken = session.accessToken
        }
    }
    
    func sessionManager(manager: SPTSessionManager, didFailWith error: Error) {
        print("❌ Spotify login failed:", error.localizedDescription)
    }
}
