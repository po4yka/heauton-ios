import Foundation
import OSLog
import SwiftData
import UserNotifications

/// Manages notifications for daily quote delivery
actor NotificationManager: NotificationManagerProtocol {
    private let logger = Logger(subsystem: AppConstants.Logging.subsystem, category: "Notifications")
    private let notificationCenter = UNUserNotificationCenter.current()
    private let quoteNotificationIdentifier = "daily-quote"

    // MARK: - Authorization

    func requestAuthorization() async throws -> Bool {
        let options: UNAuthorizationOptions = [.alert, .sound, .badge]
        return try await notificationCenter.requestAuthorization(options: options)
    }

    // MARK: - Schedule Notifications

    func scheduleQuoteNotification(quote: Quote, time: Date) async throws {
        // Cancel existing notifications first
        await cancelAllNotifications()

        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = "Daily Inspiration"

        // Truncate quote text and add indicator if needed
        let (truncatedText, wasTruncated) = truncateQuoteWithIndicator(quote.text, maxLength: 200)
        content.body = truncatedText

        // If truncated, add subtitle to inform user there's more content
        if wasTruncated {
            content.subtitle = "\(quote.author) • Tap to read the full quote"
        } else {
            content.subtitle = quote.author
        }

        content.sound = .default

        // Create deep link for this quote
        let deepLink = DeepLink.quote(quote.id)

        content.userInfo = [
            "quoteID": quote.id.uuidString,
            "isTruncated": wasTruncated,
            "deepLinkURL": deepLink.url?.absoluteString ?? "",
        ]

        // Set category for notification actions (future: add actions like "Share", "Favorite")
        content.categoryIdentifier = AppConstants.quoteNotificationCategory

        // Create date components for scheduling
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: time)

        // Create trigger to fire daily at specified time
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: components,
            repeats: true
        )

        // Create the request
        let request = UNNotificationRequest(
            identifier: quoteNotificationIdentifier,
            content: content,
            trigger: trigger
        )

        // Schedule the notification
        try await notificationCenter.add(request)
        logger.info("Scheduled daily quote notification for \(quote.author)")
    }

    // MARK: - Cancel Notifications

    func cancelAllNotifications() async {
        notificationCenter.removePendingNotificationRequests(
            withIdentifiers: [quoteNotificationIdentifier]
        )
    }

    // MARK: - Query Notifications

    func getPendingNotifications() async -> [String] {
        let requests = await notificationCenter.pendingNotificationRequests()
        return requests.map(\.identifier)
    }

    // MARK: - Handle Notification Response

    func handleNotificationResponse(quoteID: UUID) async {
        // Track notification tap event
        await TelemetryService.shared.recordFeatureUsage(
            "notification_tapped",
            properties: ["quoteID": quoteID.uuidString]
        )
        logger.info("Notification tapped for quote: \(quoteID.uuidString)")
    }

    // MARK: - Helper Methods

    /// Truncates quote text with intelligent word boundary detection
    /// Returns tuple of (truncated text, was truncated)
    private func truncateQuoteWithIndicator(_ text: String, maxLength: Int) -> (String, Bool) {
        // If text fits, return as-is
        if text.count <= maxLength {
            return (text, false)
        }

        // Find a good break point at word boundary
        let targetIndex = text.index(text.startIndex, offsetBy: maxLength - 3) // Leave room for "..."

        // Try to break at last space before target
        var breakIndex = targetIndex
        while breakIndex > text.startIndex {
            if text[breakIndex].isWhitespace {
                break
            }
            breakIndex = text.index(before: breakIndex)
        }

        // If we went too far back (less than 50% of target), just use target
        let distanceFromStart = text.distance(from: text.startIndex, to: breakIndex)
        if distanceFromStart < maxLength / 2 {
            breakIndex = targetIndex
        }

        let truncated = String(text[..<breakIndex]).trimmingCharacters(in: .whitespacesAndNewlines) + "..."
        return (truncated, true)
    }

    private func truncateQuote(_ text: String, maxLength: Int) -> String {
        let (truncated, _) = truncateQuoteWithIndicator(text, maxLength: maxLength)
        return truncated
    }
}
