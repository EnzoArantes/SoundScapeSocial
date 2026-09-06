import SwiftUI

/// A screen reachable by pushing onto Home's `NavigationStack`.
enum HomeDestination: Hashable {
    /// Placeholder today. Filled in by the friends-carousel work.
    case friendsCarousel
    case discover
    case forYou
    /// The former "You" tab: sign-out plus the now-playing card.
    case you
}

/// What tapping a Home cell does.
///
/// Sheets exist as a separate case because `FriendsView` owns its own
/// `NavigationView`; pushing it would nest navigation containers.
enum HomeAction: Hashable {
    case push(HomeDestination)
    case presentFriends
}

/// One entry-point cell on the Home grid.
///
/// To add a cell later: add a `HomeDestination` case, declare a `HomeEntry`
/// below, and append it to `HomeView.entries`. Nothing else has to change.
struct HomeEntry: Identifiable, Hashable {
    let id: String
    let title: String
    let subtitle: String
    let systemImage: String
    let action: HomeAction
}

extension HomeEntry {
    /// Top-right doorway cell. Destination is a placeholder for now.
    static let friendsCarousel = HomeEntry(
        id: "friendsCarousel",
        title: "Friends",
        subtitle: "See what they're playing",
        systemImage: "person.2.wave.2.fill",
        action: .push(.friendsCarousel)
    )

    static let discover = HomeEntry(
        id: "discover",
        title: "Discover",
        subtitle: "Swipe through new tracks",
        systemImage: "music.note.list",
        action: .push(.discover)
    )

    static let forYou = HomeEntry(
        id: "forYou",
        title: "For You",
        subtitle: "Picked from your taste",
        systemImage: "sparkles",
        action: .push(.forYou)
    )

    static let addFriends = HomeEntry(
        id: "addFriends",
        title: "Add Friends",
        subtitle: "Find people by email",
        systemImage: "person.badge.plus",
        action: .presentFriends
    )
}
