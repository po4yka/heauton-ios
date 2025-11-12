import SwiftUI

/// View for rendering quote cards for sharing
struct QuoteCardView: View {
    let quote: Quote
    let style: ShareStyle

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                // Quote icon
                Image(systemName: "quote.bubble.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.white.opacity(0.3))

                // Quote text
                Text("\"\(quote.text)\"")
                    .font(.firaCodeBody(.medium))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .lineSpacing(8)
                    .padding(.horizontal, 32)

                // Author and source
                VStack(spacing: 4) {
                    Text("— \(quote.author)")
                        .font(.firaCodeSubheadline(.semiBold))
                        .foregroundStyle(.white.opacity(0.9))

                    if let source = quote.source {
                        Text(source)
                            .font(.firaCodeCaption(.regular))
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }

                Spacer()

                // Branding
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.caption2)
                    Text("Heauton")
                        .font(.firaCodeCaption(.medium))
                }
                .foregroundStyle(.white.opacity(0.5))
                .padding(.bottom, 20)
            }
            .padding()
        }
        .frame(width: 400, height: 600)
    }

    private var gradientColors: [Color] {
        switch style {
        case .minimal:
            [.gray.opacity(0.8), .gray]
        case .card:
            [.blue.opacity(0.8), .purple.opacity(0.8)]
        case .attributed:
            [.indigo.opacity(0.8), .pink.opacity(0.8)]
        }
    }
}

#Preview {
    QuoteCardView(
        quote: Quote(
            author: "Marcus Aurelius",
            text: "You have power over your mind - not outside events. Realize this, and you will find strength.",
            source: "Meditations"
        ),
        style: .card
    )
}
