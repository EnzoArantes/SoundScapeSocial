//
//  FriendsView.swift
//  SoundScapeSocial
//
//  Created by Enzo Arantes on 4/25/25.
//

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
    private var uid: String? { Auth.auth().currentUser?.uid }

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
        guard let uid, !uid.isEmpty else { return }
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
        guard !friendID.isEmpty else { return }
        trackListeners[friendID]?.remove()
        let listener = db
          .collection("public_tracks")
          .document(friendID)
          .addSnapshotListener { [weak self] snapshot, _ in
            guard
              let self = self,
              let data = snapshot?.data(),
              let name = data["name"] as? String,
              let artist = data["artist"] as? String,
              let albumURL = data["albumArtURL"] as? String
            else { return }
            let uri = data["uri"] as? String ?? ""
            let item = CurrentlyPlayingTrack.Item(
              name:    name,
              artists: [ .init(name: artist) ],
              album:   .init(images: [ .init(url: albumURL) ]),
              uri:     uri
            )
            let track = CurrentlyPlayingTrack(item: item)
            DispatchQueue.main.async {
              if let idx = self.friends.firstIndex(where: { $0.id == friendID }) {
                self.friends[idx].track = track
              }
            }
        }
        trackListeners[friendID] = listener
    }

    private func listenForMyReaction(friendID: String) {
        guard let uid, !uid.isEmpty, !friendID.isEmpty else { return }
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
        guard let uid, !uid.isEmpty, !friendID.isEmpty else { return }
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
        guard let uid, !uid.isEmpty else { return }
        db.collection("users").whereField("email", isEqualTo: email)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self, error == nil, let doc = snapshot?.documents.first else { return }
                let friendID = doc.documentID
                guard !friendID.isEmpty else { return }
                self.db.collection("users").document(uid)
                    .collection("friends").document(friendID)
                    .setData(["email": email], merge: true)
                if let myEmail = Auth.auth().currentUser?.email {
                    self.db.collection("users").document(friendID)
                        .collection("friends").document(uid)
                        .setData(["email": myEmail], merge: true)
                }
            }
    }

    func react(to friendID: String, reaction: ReactionType) {
        guard let uid, !uid.isEmpty, !friendID.isEmpty else { return }
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

    private let columns = [ GridItem(.adaptive(minimum: 140), spacing: 20) ]

    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        // Friend addition
                        HStack {
                            TextField("Friend’s email", text: $newEmail)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .autocapitalization(.none)
                            Button(action: addFriend) {
                                Text("Add")
                                    .font(.headline)
                            }
                            .disabled(newEmail.trimmingCharacters(in: .whitespaces).isEmpty)
                        }
                        .padding([.horizontal, .top])

                        // Friends grid
                        LazyVGrid(columns: columns, spacing: 20) {
                            ForEach(vm.friends) { friend in
                                FriendCardView(friend: friend, onReact: vm.react)
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

    private func addFriend() {
        let email = newEmail.trimmingCharacters(in: .whitespaces)
        vm.addFriend(byEmail: email)
        newEmail = ""
    }
}

// MARK: - FriendCardView
struct FriendCardView: View {
    let friend: FriendData
    let onReact: (String, ReactionType) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Album art or placeholder
            if let track = friend.track {
                MusicNodeView(track: track, size: 120)
                    .frame(maxWidth: .infinity)
            } else {
                Circle()
                    .fill(Color.brandFill)
                    .frame(width: 120, height: 120)
                    .overlay(
                        Image(systemName: "questionmark")
                            .font(.largeTitle)
                            .foregroundColor(.onBrand)
                    )
                    .frame(maxWidth: .infinity)
            }

            // Track info
            if let track = friend.track {
                Text(track.name)
                    .font(.headline)
                    .foregroundColor(.textPrimary)
                    .lineLimit(1)
                Text(track.artist)
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)
                    .lineLimit(1)
            }

            // Incoming reaction
            if let their = friend.theirReaction {
                HStack(spacing: 6) {
                    Text("They reacted:")
                        .font(.subheadline).bold()
                        .foregroundColor(.textPrimary)
                    Image(systemName: iconName(for: their, filled: true))
                        .font(.title2)
                        .foregroundColor(.brandAccent)
                }
            }

            // My reactions
            myReactions
        }
        .padding()
        .background(Color.appSurface)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
    }

    private var myReactions: some View {
        HStack(spacing: 24) {
            reactionButton(.thumbsUp)
            reactionButton(.thumbsDown)
            reactionButton(.fire)
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }

    private func reactionButton(_ type: ReactionType) -> some View {
        let isSelected = friend.myReaction == type
        return Button {
            onReact(friend.id, type)
        } label: {
            Image(systemName: iconName(for: type, filled: isSelected))
                .font(.title)
                .foregroundColor(isSelected ? .brandAccent : .textSecondary)
        }
    }

    private func iconName(for reaction: ReactionType, filled: Bool) -> String {
        switch reaction {
        case .thumbsUp:
            return filled ? "hand.thumbsup.fill" : "hand.thumbsup"
        case .thumbsDown:
            return filled ? "hand.thumbsdown.fill" : "hand.thumbsdown"
        case .fire:
            return filled ? "flame.fill" : "flame"
        }
    }
}

#Preview {
    FriendsView()
}
