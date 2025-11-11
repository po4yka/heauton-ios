import Foundation
import SwiftData

/// Delivery method for scheduled quotes
enum DeliveryMethod: String, Codable, Sendable {
    case notification
    case widget
    case both

    var displayName: String {
        switch self {
        case .notification: "Notification"
        case .widget: "Widget"
        case .both: "Both"
        }
    }
}

/// Model for scheduling daily quote delivery
@Model
final class QuoteSchedule: @unchecked Sendable {
    @Attribute(.unique)
    var id: UUID

    /// Time of day to show quote
    var scheduledTime: Date

    /// Toggle schedule on/off
    var isEnabled: Bool

    /// Track last shown quote
    var lastDeliveredQuote: Quote?

    /// Prevent duplicates same day
    var lastDeliveryDate: Date?

    /// How to deliver the quote
    var deliveryMethod: DeliveryMethod

    /// Filter quotes by category
    var categories: [String]?

    /// Don't repeat quotes from N days
    var excludeRecentDays: Int

    init(
        id: UUID = UUID(),
        scheduledTime: Date = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date.now) ?? Date.now,
        isEnabled: Bool = true,
        lastDeliveredQuote: Quote? = nil,
        lastDeliveryDate: Date? = nil,
        deliveryMethod: DeliveryMethod = .both,
        categories: [String]? = nil,
        excludeRecentDays: Int = 7
    ) {
        self.id = id
        self.scheduledTime = scheduledTime
        self.isEnabled = isEnabled
        self.lastDeliveredQuote = lastDeliveredQuote
        self.lastDeliveryDate = lastDeliveryDate
        self.deliveryMethod = deliveryMethod
        self.categories = categories
        self.excludeRecentDays = excludeRecentDays
    }

    // MARK: - Helper Methods

    /// Returns formatted time display
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: scheduledTime)
    }

    /// Check if quote was delivered today
    var wasDeliveredToday: Bool {
        guard let lastDeliveryDate else {
            return false
        }
        return Calendar.current.isDateInToday(lastDeliveryDate)
    }
}
