@testable import Heauton
import XCTest

/// Tests for deep linking functionality
final class DeepLinkTests: XCTestCase {
    // MARK: - URL Parsing Tests

    func testParseQuoteDeepLink() {
        // Given
        let quoteID = UUID()
        let urlString = "heauton://quote/\(quoteID.uuidString)"
        let url = URL(string: urlString)!

        // When
        let deepLink = DeepLink.parse(from: url)

        // Then
        XCTAssertEqual(deepLink, .quote(quoteID))
    }

    func testParseJournalDeepLink() {
        // Given
        let journalID = UUID()
        let urlString = "heauton://journal/\(journalID.uuidString)"
        let url = URL(string: urlString)!

        // When
        let deepLink = DeepLink.parse(from: url)

        // Then
        XCTAssertEqual(deepLink, .journal(journalID))
    }

    func testParseExerciseDeepLink() {
        // Given
        let exerciseID = UUID()
        let urlString = "heauton://exercise/\(exerciseID.uuidString)"
        let url = URL(string: urlString)!

        // When
        let deepLink = DeepLink.parse(from: url)

        // Then
        XCTAssertEqual(deepLink, .exercise(exerciseID))
    }

    func testParseTabDeepLink() {
        // Given
        let urlString = "heauton://tab/home"
        let url = URL(string: urlString)!

        // When
        let deepLink = DeepLink.parse(from: url)

        // Then
        XCTAssertEqual(deepLink, .tab(.home))
    }

    func testParseSettingsDeepLink() {
        // Given
        let urlString = "heauton://settings"
        let url = URL(string: urlString)!

        // When
        let deepLink = DeepLink.parse(from: url)

        // Then
        XCTAssertEqual(deepLink, .settings)
    }

    func testParseInvalidScheme() {
        // Given
        let url = URL(string: "https://example.com/quote/123")!

        // When
        let deepLink = DeepLink.parse(from: url)

        // Then
        XCTAssertNil(deepLink)
    }

    func testParseInvalidUUID() {
        // Given
        let url = URL(string: "heauton://quote/invalid-uuid")!

        // When
        let deepLink = DeepLink.parse(from: url)

        // Then
        XCTAssertEqual(deepLink, .unknown)
    }

    func testParseUnknownHost() {
        // Given
        let url = URL(string: "heauton://unknown/path")!

        // When
        let deepLink = DeepLink.parse(from: url)

        // Then
        XCTAssertEqual(deepLink, .unknown)
    }

    // MARK: - URL Construction Tests

    func testQuoteDeepLinkURL() {
        // Given
        let quoteID = UUID()
        let deepLink = DeepLink.quote(quoteID)

        // When
        let url = deepLink.url

        // Then
        XCTAssertNotNil(url)
        XCTAssertEqual(url?.scheme, "heauton")
        XCTAssertEqual(url?.host, "quote")
        XCTAssertEqual(url?.path, "/\(quoteID.uuidString)")
    }

    func testJournalDeepLinkURL() {
        // Given
        let journalID = UUID()
        let deepLink = DeepLink.journal(journalID)

        // When
        let url = deepLink.url

        // Then
        XCTAssertNotNil(url)
        XCTAssertEqual(url?.scheme, "heauton")
        XCTAssertEqual(url?.host, "journal")
        XCTAssertEqual(url?.path, "/\(journalID.uuidString)")
    }

    func testTabDeepLinkURL() {
        // Given
        let deepLink = DeepLink.tab(.journal)

        // When
        let url = deepLink.url

        // Then
        XCTAssertNotNil(url)
        XCTAssertEqual(url?.scheme, "heauton")
        XCTAssertEqual(url?.host, "tab")
        XCTAssertEqual(url?.path, "/journal")
    }

    func testUnknownDeepLinkURL() {
        // Given
        let deepLink = DeepLink.unknown

        // When
        let url = deepLink.url

        // Then
        XCTAssertNil(url)
    }

    // MARK: - Notification UserInfo Tests

    func testFromNotificationWithQuoteID() {
        // Given
        let quoteID = UUID()
        let userInfo: [AnyHashable: Any] = [
            "quoteID": quoteID.uuidString,
            "isTruncated": true,
        ]

        // When
        let deepLink = DeepLink.fromNotification(userInfo: userInfo)

        // Then
        XCTAssertEqual(deepLink, .quote(quoteID))
    }

    func testFromNotificationWithJournalID() {
        // Given
        let journalID = UUID()
        let userInfo: [AnyHashable: Any] = [
            "journalID": journalID.uuidString,
        ]

        // When
        let deepLink = DeepLink.fromNotification(userInfo: userInfo)

        // Then
        XCTAssertEqual(deepLink, .journal(journalID))
    }

    func testFromNotificationWithExerciseID() {
        // Given
        let exerciseID = UUID()
        let userInfo: [AnyHashable: Any] = [
            "exerciseID": exerciseID.uuidString,
        ]

        // When
        let deepLink = DeepLink.fromNotification(userInfo: userInfo)

        // Then
        XCTAssertEqual(deepLink, .exercise(exerciseID))
    }

    func testFromNotificationWithNoValidID() {
        // Given
        let userInfo: [AnyHashable: Any] = [
            "title": "Daily Inspiration",
            "body": "A quote from Marcus Aurelius",
        ]

        // When
        let deepLink = DeepLink.fromNotification(userInfo: userInfo)

        // Then
        XCTAssertNil(deepLink)
    }

    func testFromNotificationWithInvalidUUID() {
        // Given
        let userInfo: [AnyHashable: Any] = [
            "quoteID": "not-a-valid-uuid",
        ]

        // When
        let deepLink = DeepLink.fromNotification(userInfo: userInfo)

        // Then
        XCTAssertNil(deepLink)
    }

    // MARK: - Round Trip Tests

    func testQuoteDeepLinkRoundTrip() {
        // Given
        let originalID = UUID()
        let originalDeepLink = DeepLink.quote(originalID)

        // When
        guard let url = originalDeepLink.url else {
            XCTFail("Failed to create URL")
            return
        }
        let parsedDeepLink = DeepLink.parse(from: url)

        // Then
        XCTAssertEqual(parsedDeepLink, originalDeepLink)
    }

    func testJournalDeepLinkRoundTrip() {
        // Given
        let originalID = UUID()
        let originalDeepLink = DeepLink.journal(originalID)

        // When
        guard let url = originalDeepLink.url else {
            XCTFail("Failed to create URL")
            return
        }
        let parsedDeepLink = DeepLink.parse(from: url)

        // Then
        XCTAssertEqual(parsedDeepLink, originalDeepLink)
    }

    func testTabDeepLinkRoundTrip() {
        // Given
        let originalDeepLink = DeepLink.tab(.progress)

        // When
        guard let url = originalDeepLink.url else {
            XCTFail("Failed to create URL")
            return
        }
        let parsedDeepLink = DeepLink.parse(from: url)

        // Then
        XCTAssertEqual(parsedDeepLink, originalDeepLink)
    }

    // MARK: - Tab Destination Tests

    func testTabDestinationIndexes() {
        XCTAssertEqual(DeepLink.TabDestination.home.tabIndex, 0)
        XCTAssertEqual(DeepLink.TabDestination.journal.tabIndex, 1)
        XCTAssertEqual(DeepLink.TabDestination.exercises.tabIndex, 2)
        XCTAssertEqual(DeepLink.TabDestination.add.tabIndex, 3)
        XCTAssertEqual(DeepLink.TabDestination.library.tabIndex, 4)
        XCTAssertEqual(DeepLink.TabDestination.progress.tabIndex, 5)
    }

    func testAllTabDestinations() {
        // Test that all tab destinations can be parsed
        for destination in DeepLink.TabDestination.allCases {
            let urlString = "heauton://tab/\(destination.rawValue)"
            let url = URL(string: urlString)!
            let deepLink = DeepLink.parse(from: url)

            XCTAssertEqual(deepLink, .tab(destination))
        }
    }

    // MARK: - Description Tests

    func testDeepLinkDescriptions() {
        let quoteID = UUID()
        XCTAssertEqual(DeepLink.quote(quoteID).description, "quote(\(quoteID))")

        let journalID = UUID()
        XCTAssertEqual(DeepLink.journal(journalID).description, "journal(\(journalID))")

        XCTAssertEqual(DeepLink.tab(.home).description, "tab(home)")
        XCTAssertEqual(DeepLink.settings.description, "settings")
        XCTAssertEqual(DeepLink.unknown.description, "unknown")
    }
}
