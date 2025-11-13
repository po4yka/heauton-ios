import Foundation
import SwiftData
import WidgetKit

/// Timeline provider for the quotes widget
struct QuotesProvider: TimelineProvider {
    /// Provides a placeholder entry for widget preview
    func placeholder(in _: Context) -> QuoteEntry {
        QuoteEntry(date: .now, quote: .placeholder)
    }

    /// Provides a snapshot for widget gallery and transient displays
    func getSnapshot(in context: Context, completion: @escaping (QuoteEntry) -> Void) {
        let entry = if context.isPreview {
            // Use placeholder for previews
            QuoteEntry(date: .now, quote: .placeholder)
        } else {
            // Try to load a real quote
            if let quote = loadRandomQuote() {
                QuoteEntry(date: .now, quote: quote)
            } else {
                QuoteEntry(date: .now, quote: .placeholder)
            }
        }

        completion(entry)
    }

    /// Provides a timeline of entries for the widget
    func getTimeline(in _: Context, completion: @escaping (Timeline<QuoteEntry>) -> Void) {
        let quote = loadRandomQuote() ?? .placeholder
        let entry = QuoteEntry(date: .now, quote: quote)

        // Get refresh interval from settings (default to 30 minutes if not set)
        let refreshInterval = UserDefaults.appGroup.integer(forKey: "widgetRefreshInterval")
        let intervalMinutes = refreshInterval > 0 ? refreshInterval : 30

        // Calculate next update time
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: intervalMinutes, to: .now) ?? .now

        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    /// Loads a random quote from the shared SwiftData store
    private func loadRandomQuote() -> QuoteSnapshot? {
        let modelContainer = SharedModelContainer.create()
        let context = ModelContext(modelContainer)

        do {
            let descriptor = FetchDescriptor<Quote>(
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )
            let quotes = try context.fetch(descriptor)

            guard !quotes.isEmpty else { return nil }

            // Pick a random quote
            if let randomQuote = quotes.randomElement() {
                return QuoteSnapshot.from(randomQuote)
            }

            return nil
        } catch {
            // Failed to fetch quotes - return nil to use placeholder
            return nil
        }
    }
}
