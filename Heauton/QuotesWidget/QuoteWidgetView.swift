import SwiftUI
import WidgetKit

/// Main widget entry view that adapts to different widget families
struct QuoteWidgetEntryView: View {
    @Environment(\.widgetFamily)
    var widgetFamily
    var entry: QuoteEntry

    var body: some View {
        switch widgetFamily {
        case .systemSmall:
            SmallWidgetView(quote: entry.quote)
        case .systemMedium:
            MediumWidgetView(quote: entry.quote)
        case .systemLarge:
            LargeWidgetView(quote: entry.quote)
        case .accessoryInline:
            InlineWidgetView(quote: entry.quote)
        case .accessoryRectangular:
            RectangularWidgetView(quote: entry.quote)
        case .accessoryCircular:
            CircularWidgetView(quote: entry.quote)
        @unknown default:
            SmallWidgetView(quote: entry.quote)
        }
    }
}

// MARK: - Home Screen Widget Views

/// Small widget view for Home Screen
struct SmallWidgetView: View {
    let quote: QuoteSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\"\(quote.text)\"")
                .font(.firaCodeCaption())
                .lineLimit(5)
                .minimumScaleFactor(0.8)

            Spacer()

            Text(quote.author)
                .font(.firaCodeCaption2())
                .foregroundStyle(.secondary)
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

/// Medium widget view for Home Screen
struct MediumWidgetView: View {
    let quote: QuoteSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("\"\(quote.text)\"")
                .font(.firaCodeBody())
                .lineLimit(4)
                .minimumScaleFactor(0.9)

            Spacer()

            HStack {
                Text(quote.author)
                    .font(.firaCodeCaption())
                    .foregroundStyle(.secondary)

                if let source = quote.source {
                    Text("• \(source)")
                        .font(.firaCodeCaption())
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

/// Large widget view for Home Screen
struct LargeWidgetView: View {
    let quote: QuoteSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("\"\(quote.text)\"")
                .font(.firaCodeTitle3(.medium))
                .lineLimit(8)

            Spacer()

            VStack(alignment: .leading, spacing: 4) {
                Text(quote.author)
                    .font(.firaCodeSubheadline(.semiBold))
                    .foregroundStyle(.primary)

                if let source = quote.source {
                    Text(source)
                        .font(.firaCodeCaption())
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

// MARK: - Lock Screen Widget Views

/// Inline widget view for Lock Screen
struct InlineWidgetView: View {
    let quote: QuoteSnapshot

    var body: some View {
        Text("\"\(quote.text)\" — \(quote.author)")
            .lineLimit(1)
    }
}

/// Rectangular widget view for Lock Screen
struct RectangularWidgetView: View {
    let quote: QuoteSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\"\(quote.text)\"")
                .font(.firaCodeCaption())
                .lineLimit(3)
                .minimumScaleFactor(0.8)

            Text("— \(quote.author)")
                .font(.firaCodeCaption2())
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Circular widget view for Lock Screen
struct CircularWidgetView: View {
    let quote: QuoteSnapshot

    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: "quote.bubble.fill")
                .font(.firaCodeTitle3())
                .foregroundStyle(.secondary)

            Text(quote.author.split(separator: " ").first ?? "")
                .font(.firaCodeCaption2())
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
    }
}

// MARK: - Previews

#Preview(as: .systemSmall) {
    QuotesWidget()
} timeline: {
    QuoteEntry(date: .now, quote: .placeholder)
}

#Preview(as: .systemMedium) {
    QuotesWidget()
} timeline: {
    QuoteEntry(date: .now, quote: .placeholder)
}

#Preview(as: .accessoryRectangular) {
    QuotesWidget()
} timeline: {
    QuoteEntry(date: .now, quote: .placeholder)
}
