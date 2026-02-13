import Foundation
import Observation
import SwiftUI

/// Coordinates deep link routing and exposes navigation intents to SwiftUI views.
@Observable
@MainActor
final class DeepLinkCoordinator {
    /// Current selected tab index in the main tab view.
    var selectedTab = DeepLink.TabDestination.home.tabIndex

    /// Pending entity IDs used by views to perform one-shot navigation.
    var pendingQuoteID: UUID?
    var pendingJournalID: UUID?
    var pendingExerciseID: UUID?

    /// Settings presentation intent.
    var shouldOpenSettings = false

    /// Parses and handles a URL-based deep link.
    func handleURL(_ url: URL) async {
        guard let deepLink = DeepLink.parse(from: url) else {
            return
        }
        await handle(deepLink)
    }

    /// Handles a parsed deep link.
    func handle(_ deepLink: DeepLink) async {
        switch deepLink {
        case .quote(let id):
            selectedTab = DeepLink.TabDestination.home.tabIndex
            pendingQuoteID = id

        case .journal(let id):
            selectedTab = DeepLink.TabDestination.journal.tabIndex
            pendingJournalID = id

        case .exercise(let id):
            selectedTab = DeepLink.TabDestination.exercises.tabIndex
            pendingExerciseID = id

        case .tab(let destination):
            selectedTab = destination.tabIndex

        case .settings:
            shouldOpenSettings = true

        case .unknown:
            break
        }
    }

    /// Clears any pending navigation state after it has been consumed.
    func clearPendingNavigation() {
        pendingQuoteID = nil
        pendingJournalID = nil
        pendingExerciseID = nil
        shouldOpenSettings = false
    }
}

@MainActor
private struct DeepLinkCoordinatorKey: EnvironmentKey {
    static let defaultValue = DeepLinkCoordinator()
}

extension EnvironmentValues {
    var deepLinkCoordinator: DeepLinkCoordinator {
        get { self[DeepLinkCoordinatorKey.self] }
        set { self[DeepLinkCoordinatorKey.self] = newValue }
    }
}
