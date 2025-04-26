import SwiftUI
import FirebaseCore
import SpotifyiOS

@main
struct SoundScapeSocialApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    /// Just a normal instance—no @StateObject needed here
    let spotifyAuth = SpotifyAuthManager()

    init() {
        FirebaseApp.configure()
        // Give your AppDelegate the same instance
        AppDelegate.spotifyAuth = spotifyAuth
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(spotifyAuth)
        }
    }
}


class AppDelegate: NSObject, UIApplicationDelegate {
    static var spotifyAuth: SpotifyAuthManager!

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        return true
    }

    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey : Any] = [:]
    ) -> Bool {
        // Forward the Spotify callback to the same manager instance
        return AppDelegate.spotifyAuth.sessionManager.application(
            app,
            open: url,
            options: options
        )
    }
}
