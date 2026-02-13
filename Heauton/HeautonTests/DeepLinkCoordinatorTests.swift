@testable import Heauton
import XCTest

@MainActor
final class DeepLinkCoordinatorTests: XCTestCase {
    func testHandleQuoteDeepLinkSetsHomeTabAndPendingQuote() async {
        let coordinator = DeepLinkCoordinator()
        let quoteID = UUID()

        await coordinator.handle(.quote(quoteID))

        XCTAssertEqual(coordinator.selectedTab, DeepLink.TabDestination.home.tabIndex)
        XCTAssertEqual(coordinator.pendingQuoteID, quoteID)
        XCTAssertNil(coordinator.pendingJournalID)
        XCTAssertNil(coordinator.pendingExerciseID)
    }

    func testHandleJournalDeepLinkSetsJournalTabAndPendingJournal() async {
        let coordinator = DeepLinkCoordinator()
        let journalID = UUID()

        await coordinator.handle(.journal(journalID))

        XCTAssertEqual(coordinator.selectedTab, DeepLink.TabDestination.journal.tabIndex)
        XCTAssertEqual(coordinator.pendingJournalID, journalID)
        XCTAssertNil(coordinator.pendingQuoteID)
    }

    func testHandleExerciseDeepLinkSetsExercisesTabAndPendingExercise() async {
        let coordinator = DeepLinkCoordinator()
        let exerciseID = UUID()

        await coordinator.handle(.exercise(exerciseID))

        XCTAssertEqual(coordinator.selectedTab, DeepLink.TabDestination.exercises.tabIndex)
        XCTAssertEqual(coordinator.pendingExerciseID, exerciseID)
        XCTAssertNil(coordinator.pendingQuoteID)
    }

    func testHandleTabDeepLinkSwitchesTab() async {
        let coordinator = DeepLinkCoordinator()

        await coordinator.handle(.tab(.library))

        XCTAssertEqual(coordinator.selectedTab, DeepLink.TabDestination.library.tabIndex)
    }

    func testHandleSettingsDeepLinkSetsOpenSettingsFlag() async {
        let coordinator = DeepLinkCoordinator()

        await coordinator.handle(.settings)

        XCTAssertTrue(coordinator.shouldOpenSettings)
    }

    func testHandleURLParsesAndRoutes() async {
        let coordinator = DeepLinkCoordinator()
        let quoteID = UUID()
        let url = URL(string: "heauton://quote/\(quoteID.uuidString)")!

        await coordinator.handleURL(url)

        XCTAssertEqual(coordinator.selectedTab, DeepLink.TabDestination.home.tabIndex)
        XCTAssertEqual(coordinator.pendingQuoteID, quoteID)
    }

    func testHandleInvalidURLKeepsStateUnchanged() async {
        let coordinator = DeepLinkCoordinator()
        coordinator.selectedTab = DeepLink.TabDestination.progress.tabIndex

        let invalidURL = URL(string: "https://example.com/not-deeplink")!
        await coordinator.handleURL(invalidURL)

        XCTAssertEqual(coordinator.selectedTab, DeepLink.TabDestination.progress.tabIndex)
        XCTAssertNil(coordinator.pendingQuoteID)
        XCTAssertFalse(coordinator.shouldOpenSettings)
    }

    func testClearPendingNavigationResetsIntentState() async {
        let coordinator = DeepLinkCoordinator()
        await coordinator.handle(.quote(UUID()))
        await coordinator.handle(.settings)

        coordinator.clearPendingNavigation()

        XCTAssertNil(coordinator.pendingQuoteID)
        XCTAssertNil(coordinator.pendingJournalID)
        XCTAssertNil(coordinator.pendingExerciseID)
        XCTAssertFalse(coordinator.shouldOpenSettings)
    }
}
