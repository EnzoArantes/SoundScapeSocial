//
//  FriendsView.swift
//  SoundScapeSocial
//
//  Created by Enzo Arantes on 4/25/25.
//
// FriendsView.swift
// FriendsView.swift
import SwiftUI
import FirebaseAuth
import FirebaseFirestore

enum ReactionType: String {
    case thumbsUp = "like"
    case thumbsDown = "dislike"
    case fire = "fire"
}

struct FriendData: Identifiable {
    let id: String
    let email: String
    var track: CurrentlyPlayingTrack?
    var myReaction: ReactionType?
    var theirReaction: ReactionType?
}

class FriendsViewModel: ObservableObject {
    @Published var friends: [FriendData] = []

    private let db = Firestore.firestore()
    private var friendsListener: ListenerRegistration?
    private var trackListeners = [String: ListenerRegistration]()
    private var myReactionListeners = [String: ListenerRegistration]()
    private var incomingReactionListeners = [String: ListenerRegistration]()
    private var uid: String { Auth.auth().currentUser?.uid ?? "" }

    init() {
        listenForFriends()
    }
    deinit {
        friendsListener?.remove()
        trackListeners.values.forEach { $0.remove() }
        myReactionListeners.values.forEach { $0.remove() }
        incomingReactionListeners.values.forEach { $0.remove() }
    }

    private func listenForFriends() {
        friendsListener = db.collection("users").document(uid)
            .collection("friends")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self, error == nil, let docs = snapshot?.documents else { return }
                self.cleanupListeners()
                self.friends = docs.map { doc in
                    FriendData(
                        id: doc.documentID,
                        email: doc.data()["email"] as? String ?? "",
                        track: nil,
                        myReaction: nil,
                        theirReaction: nil
                    )
                }
                for friend in self.friends {
                    self.listenForTrackUpdates(friendID: friend.id)
                    self.listenForMyReaction(friendID: friend.id)
                    self.listenForIncomingReaction(friendID: friend.id)
                }
            }
    }

    private func cleanupListeners() {
        trackListeners.values.forEach { $0.remove() }
        myReactionListeners.values.forEach { $0.remove() }
        incomingReactionListeners.values.forEach { $0.remove() }
        trackListeners.removeAll()
        myReactionListeners.removeAll()
        incomingReactionListeners.removeAll()
    }

    private func listenForTrackUpdates(friendID: String) {
        trackListeners[friendID]?.remove()
        trackListeners[friendID] = db.collection("public_tracks").document(friendID)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self, error == nil, let data = snapshot?.data() else { return }
                guard let name = data["name"] as? String,
                      let artist = data["artist"] as? String,
                      let url = data["albumArtURL"] as? String else { return }
                let item = CurrentlyPlayingTrack.Item(
                    name: name,
                    artists: [CurrentlyPlayingTrack.Artist(name: artist)],
                    album: CurrentlyPlayingTrack.Album(images: [CurrentlyPlayingTrack.Album.Image(url: url)])
                )
                let track = CurrentlyPlayingTrack(item: item)
                DispatchQueue.main.async {
                    if let idx = self.friends.firstIndex(where: { $0.id == friendID }) {
                        self.friends[idx].track = track
                    }
                }
            }
    }

    private func listenForMyReaction(friendID: String) {
        myReactionListeners[friendID]?.remove()
        myReactionListeners[friendID] = db.collection("users").document(friendID)
            .collection("reactions").document(uid)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self, error == nil else { return }
                let raw = snapshot?.data()?["reaction"] as? String
                let reaction = raw.flatMap { ReactionType(rawValue: $0) }
                DispatchQueue.main.async {
                    if let idx = self.friends.firstIndex(where: { $0.id == friendID }) {
                        self.friends[idx].myReaction = reaction
                    }
                }
            }
    }

    private func listenForIncomingReaction(friendID: String) {
        incomingReactionListeners[friendID]?.remove()
        incomingReactionListeners[friendID] = db.collection("users").document(uid)
            .collection("reactions").document(friendID)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self, error == nil else { return }
                let raw = snapshot?.data()?["reaction"] as? String
                let reaction = raw.flatMap { ReactionType(rawValue: $0) }
                DispatchQueue.main.async {
                    if let idx = self.friends.firstIndex(where: { $0.id == friendID }) {
                        self.friends[idx].theirReaction = reaction
                    }
                }
            }
    }

    func addFriend(byEmail email: String) {
        db.collection("users").whereField("email", isEqualTo: email)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self, error == nil, let doc = snapshot?.documents.first else { return }
                let friendID = doc.documentID
                self.db.collection("users").document(self.uid)
                    .collection("friends").document(friendID)
                    .setData(["email": email], merge: true)
                if let myEmail = Auth.auth().currentUser?.email {
                    self.db.collection("users").document(friendID)
                        .collection("friends").document(self.uid)
                        .setData(["email": myEmail], merge: true)
                }
            }
    }

    func react(to friendID: String, reaction: ReactionType) {
        db.collection("users").document(friendID)
            .collection("reactions").document(uid)
            .setData([
                "reaction": reaction.rawValue,
                "timestamp": Timestamp(date: Date())
            ], merge: true)
    }
}

struct FriendsView: View {
    @StateObject private var vm = FriendsViewModel()
    @State private var newEmail = ""

    var body: some View {
        NavigationView {
            ZStack {
                Color.backgroundDark
                    .ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        HStack {
                            TextField("Friend’s email", text: $newEmail)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .autocapitalization(.none)
                            Button("Add") {
                                vm.addFriend(byEmail: newEmail.trimmingCharacters(in: .whitespaces))
                                newEmail = ""
                            }
                            .disabled(newEmail.trimmingCharacters(in: .whitespaces).isEmpty)
                        }
                        .padding([.horizontal, .top])
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: 16)], spacing: 16) {
                            ForEach(vm.friends) { friend in
                                VStack(spacing: 8) {
                                    if let track = friend.track {
                                        MusicNodeView(track: track, size: 100)
                                        Text(track.artist)
                                            .font(.caption)
                                            .foregroundColor(Color.textColor.opacity(0.8))
                                            .lineLimit(1)
                                    } else {
                                        Circle()
                                            .fill(Color.secondaryPurple)
                                            .frame(width: 100, height: 100)
                                            .overlay(
                                                Image(systemName: "questionmark")
                                                    .foregroundColor(.textColor)
                                            )
                                    }
                                    if let their = friend.theirReaction {
                                        HStack(spacing: 4) {
                                            Text("They reacted:")
                                                .font(.caption2)
                                                .foregroundColor(.textColor)
                                            switch their {
                                            case .thumbsUp:
                                                Image(systemName: "hand.thumbsup.fill")
                                            case .thumbsDown:
                                                Image(systemName: "hand.thumbsdown.fill")
                                            case .fire:
                                                Image(systemName: "flame.fill")
                                            }
                                        }
                                    }
                                    HStack(spacing: 12) {
                                        Button { vm.react(to: friend.id, reaction: .thumbsUp) } label: {
                                            Image(systemName: friend.myReaction == .thumbsUp ? "hand.thumbsup.fill" : "hand.thumbsup")
                                                .font(.title2)
                                        }
                                        Button { vm.react(to: friend.id, reaction: .thumbsDown) } label: {
                                            Image(systemName: friend.myReaction == .thumbsDown ? "hand.thumbsdown.fill" : "hand.thumbsdown")
                                                .font(.title2)
                                        }
                                        Button { vm.react(to: friend.id, reaction: .fire) } label: {
                                            Image(systemName: friend.myReaction == .fire ? "flame.fill" : "flame")
                                                .font(.title2)
                                        }
                                    }
                                }
                                .padding()
                                .background(Color.backgroundDark.opacity(0.8))
                                .cornerRadius(12)
                                .shadow(radius: 4)
                                .contentShape(Rectangle())
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom)
                    }
                }
            }
            .navigationTitle("Friends")
        }
    }
}

#Preview {
    FriendsView()
}
