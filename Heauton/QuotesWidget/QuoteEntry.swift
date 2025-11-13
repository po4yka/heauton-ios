import Foundation
import WidgetKit

/// Timeline entry for the quote widget
struct QuoteEntry: TimelineEntry {
    let date: Date
    let quote: QuoteSnapshot
}

/// Lightweight snapshot of a quote for display in widgets
struct QuoteSnapshot {
    let text: String
    let author: String
    let source: String?

    /// Default placeholder quote
    static let placeholder = QuoteSnapshot(
        text: "The unexamined life is not worth living.",
        author: "Socrates",
        source: "Apology"
    )

    /// Create a snapshot from a Quote model
    static func from(_ quote: Quote) -> QuoteSnapshot {
        QuoteSnapshot(
            text: quote.text,
            author: quote.author,
            source: quote.source
        )
    }
}
