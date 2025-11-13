import SwiftUI
import WidgetKit

/// Main Widget configuration for Philosopher Quotes
@main
struct QuotesWidget: Widget {
    let kind: String = "QuotesWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: QuotesProvider()) { entry in
            QuoteWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Philosophy Quote")
        .description("Displays meaningful quotes from famous philosophers on your Home Screen and Lock Screen.")
        .supportedFamilies([
            // Home Screen widgets
            .systemSmall,
            .systemMedium,
            .systemLarge,
            // Lock Screen widgets
            .accessoryInline,
            .accessoryRectangular,
            .accessoryCircular,
        ])
    }
}
