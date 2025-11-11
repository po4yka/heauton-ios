import Foundation
import SwiftData

/// Types of content that can be shared
enum ShareType: String, Codable, Sendable {
    case quote
    case journalEntry
}

/// Model for tracking shares of quotes and journal entries
@Model
final class Share: @unchecked Sendable {
    @Attribute(.unique)
    var id: UUID

    /// Type of content shared
    var type: ShareType

    /// ID of the shared content (Quote or JournalEntry)
    var contentId: UUID

    /// Platform where content was shared (e.g., "Messages", "Mail", "Copy Link")
    var platform: String

    /// When the share occurred
    var sharedAt: Date

    /// Optional note about the share
    var note: String?

    init(
        id: UUID = UUID(),
        type: ShareType,
        contentId: UUID,
        platform: String,
        sharedAt: Date = .now,
        note: String? = nil
    ) {
        self.id = id
        self.type = type
        self.contentId = contentId
        self.platform = platform
        self.sharedAt = sharedAt
        self.note = note
    }
}
