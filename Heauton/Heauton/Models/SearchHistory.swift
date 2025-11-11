import Foundation
import SwiftData

/// Model for tracking search queries for suggestions and history
@Model
final class SearchHistory: @unchecked Sendable {
    @Attribute(.unique)
    var id: UUID

    /// The search query text
    var query: String

    /// When the search was performed
    var searchedAt: Date

    /// Number of results returned for this query
    var resultCount: Int

    /// Whether the user clicked on any result
    var hadInteraction: Bool

    init(
        id: UUID = UUID(),
        query: String,
        searchedAt: Date = .now,
        resultCount: Int = 0,
        hadInteraction: Bool = false
    ) {
        self.id = id
        self.query = query
        self.searchedAt = searchedAt
        self.resultCount = resultCount
        self.hadInteraction = hadInteraction
    }
}
