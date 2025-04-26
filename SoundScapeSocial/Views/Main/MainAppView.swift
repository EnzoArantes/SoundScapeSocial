import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct MainAppView: View {
    @EnvironmentObject var spotifyAuth: SpotifyAuthManager
    @Binding var currentTrack: CurrentlyPlayingTrack?
    @State private var fetchStatus: String?
    @State private var isProcessing = false
    
    private let db = Firestore.firestore()
    private var uid: String { Auth.auth().currentUser?.uid ?? "" }
    
    var body: some View {
        ZStack {
            Color.backgroundDark
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // MARK: – Sign-Out Controls
                HStack(spacing: 16) {
                    Button("Sign out of Spotify") {
                        spotifyAuth.accessToken = nil
                        spotifyAuth.sessionManager.session = nil
                    }
                    .font(.subheadline)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 12)
                    .background(Color.secondaryPurple)
                    .foregroundColor(.textColor)
                    .cornerRadius(8)
                    
                    Button("Sign Out") {
                        do {
                            try Auth.auth().signOut()
                        } catch {
                            print("Sign out error:", error)
                        }
                    }
                    .font(.subheadline)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 12)
                    .background(Color.primaryPurple)
                    .foregroundColor(.textColor)
                    .cornerRadius(8)
                }
                
                // MARK: – Fetch Now Playing
                Button(action: fetchNowPlaying) {
                    HStack {
                        Image(systemName: "arrow.clockwise.circle.fill")
                        Text("Fetch Now Playing")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.secondaryPurple)
                    .foregroundColor(.textColor)
                    .cornerRadius(12)
                }
                .disabled(isProcessing)
                
                // MARK: – Status Message
                if let status = fetchStatus {
                    Text(status)
                        .font(.caption)
                        .foregroundColor(.yellow)
                        .padding(.horizontal)
                }
                
                Spacer()
                
                // MARK: – Now Playing Card
                if let track = currentTrack {
                    VStack(spacing: 16) {
                        AsyncImage(url: URL(string: track.albumArtURL)) { phase in
                            if let img = phase.image {
                                img.resizable().scaledToFill()
                            } else if phase.error != nil {
                                Color.red
                            } else {
                                Color.gray
                            }
                        }
                        .frame(width: 240, height: 240)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .shadow(radius: 8)
                        
                        Text(track.name)
                            .font(.title2).bold()
                            .foregroundColor(.textColor)
                            .lineLimit(1)
                        
                        Text(track.artist)
                            .font(.subheadline)
                            .foregroundColor(.textColor.opacity(0.8))
                            .lineLimit(1)
                        
                        Button(action: {
                            addToFavorites(track)
                            saveToSpotifyLibrary(trackUri: track.uri)
                        }) {
                            HStack {
                                Image(systemName: "heart.circle.fill")
                                Text("Add to Favorites")
                                    .font(.headline)
                            }
                            .padding(.vertical, 10)
                            .padding(.horizontal, 24)
                            .background(Color.primaryPurple)
                            .foregroundColor(.textColor)
                            .cornerRadius(12)
                        }
                    }
                    .padding()
                    .background(Color.secondaryPurple.opacity(0.15))
                    .cornerRadius(20)
                    .padding(.horizontal)
                }
                
                Spacer()
            }
            .padding(.top)
        }
    }
    
    // MARK: – Spotify Fetch
    private func fetchNowPlaying() {
        guard let token = spotifyAuth.accessToken,
              let url = URL(string: "https://api.spotify.com/v1/me/player/currently-playing")
        else {
            fetchStatus = "Not logged into Spotify"
            return
        }
        
        isProcessing = true
        fetchStatus = nil
        
        var req = URLRequest(url: url)
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: req) { data, response, error in
            defer { DispatchQueue.main.async { isProcessing = false } }
            
            if let error = error {
                DispatchQueue.main.async {
                    fetchStatus = "Error: \(error.localizedDescription)"
                }
                return
            }
            guard let http = response as? HTTPURLResponse else {
                DispatchQueue.main.async {
                    fetchStatus = "Invalid response"
                }
                return
            }
            if http.statusCode != 200 {
                DispatchQueue.main.async {
                    fetchStatus = http.statusCode == 204
                    ? "No track playing"
                    : "HTTP \(http.statusCode)"
                }
                return
            }
            guard let data = data,
                  let decoded = try? JSONDecoder().decode(CurrentlyPlayingTrack.self, from: data)
            else {
                DispatchQueue.main.async {
                    fetchStatus = "Decode failed"
                }
                return
            }
            DispatchQueue.main.async {
                currentTrack = decoded
                shareToFirestore(decoded)
            }
            shareToFirestore(decoded)
        }.resume()
    }
    
    // MARK: – Add to Firestore Favorites
    private func addToFavorites(_ track: CurrentlyPlayingTrack) {
        // Clean up the track name into a safe doc ID
        let safeID = track.name
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .joined()
        
        let favRef = db
            .collection("users")
            .document(uid)
            .collection("favorites")
            .document(safeID)
        
        let data: [String:Any] = [
            "name": track.name,
            "artist": track.artist,
            "timestamp": Timestamp(date: Date())
        ]
        
        favRef.setData(data, merge: true) { error in
            DispatchQueue.main.async {
                if let err = error {
                    print("Favorite write error:", err)
                    fetchStatus = "Failed to add favorite"
                } else {
                    print("✅ Added to favorites!")
                    fetchStatus = "★ Added to favorites!"
                }
            }
        }
    }
    
    private func saveToSpotifyLibrary(trackUri: String) {
        guard let token = spotifyAuth.accessToken else {
            fetchStatus = "Not logged into Spotify"
            return
        }
        // Extract the Spotify ID (e.g. "3n3Ppam7vgaVa1iaRUc9Lp" from "spotify:track:3n3Ppam7vgaVa1iaRUc9Lp")
        let components = trackUri.split(separator: ":")
        guard components.count == 3, components[1] == "track" else {
            fetchStatus = "Invalid track URI"
            return
        }
        let trackID = String(components[2])
        let urlString = "https://api.spotify.com/v1/me/tracks?ids=\(trackID)"
        guard let url = URL(string: urlString) else { return }
        
        var req = URLRequest(url: url)
        req.httpMethod = "PUT"
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: req) { _, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    fetchStatus = "Spotify save error: \(error.localizedDescription)"
                } else if let http = response as? HTTPURLResponse, http.statusCode == 200 {
                    fetchStatus = "★ Saved to Spotify!"
                } else {
                    let code = (response as? HTTPURLResponse)?.statusCode ?? -1
                    fetchStatus = "Spotify HTTP \(code)"
                }
            }
        }.resume()
    }
    
    
    /// Publish my current track so friends can pick it up
    private func shareToFirestore(_ track: CurrentlyPlayingTrack) {
        guard let email = Auth.auth().currentUser?.email else { return }
        let doc: [String:Any] = [
            "name":        track.name,
            "artist":      track.artist,
            "albumArtURL": track.albumArtURL,
            "uri":         track.uri,         // ← include the Spotify URI here
            "email":       email,
            "timestamp":   Timestamp(date: Date())
        ]
        // Ensure my own profile has my email
        db.collection("users").document(uid)
          .setData(["email": email], merge: true)

        // Write into public_tracks so friends can see it
        db.collection("public_tracks").document(uid)
          .setData(doc, merge: true)
    }
    
}

struct MainAppView_Previews: PreviewProvider {
    static var previews: some View {
        MainAppView(currentTrack: .constant(nil))
            .environmentObject(SpotifyAuthManager())
    }
}
