import SwiftData
import SwiftUI

struct QuoteDetailView: View {
    @Bindable var quote: Quote
    @State private var showingShareOptions = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Quote text
                Text("\"\(quote.text)\"")
                    .font(.firaCodeTitle2(.medium))
                    .multilineTextAlignment(.leading)

                // Author
                VStack(alignment: .leading, spacing: 8) {
                    Text(quote.author)
                        .font(.firaCodeTitle3(.semiBold))

                    if let source = quote.source {
                        Text(source)
                            .font(.firaCodeSubheadline())
                            .foregroundStyle(.secondary)
                    }
                }

                Divider()

                // Metadata
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundStyle(.secondary)
                        Text(
                            "Added: \(quote.createdAt, format: .dateTime.month().day().year())"
                        )
                        .font(.firaCodeCaption())
                        .foregroundStyle(.secondary)
                    }

                    if let updatedAt = quote.updatedAt {
                        HStack {
                            Image(systemName: "clock")
                                .foregroundStyle(.secondary)
                            Text(
                                "Updated: \(updatedAt, format: .dateTime.month().day().year())"
                            )
                            .font(.firaCodeCaption())
                            .foregroundStyle(.secondary)
                        }
                    }
                }

                Spacer()
            }
            .padding()
        }
        .navigationTitle("Quote")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 16) {
                    Button {
                        showingShareOptions = true
                    } label: {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }

                    Button {
                        toggleFavorite()
                    } label: {
                        Label(
                            quote.isFavorite ? "Remove from Favorites" : "Add to Favorites",
                            systemImage: quote.isFavorite ? "heart.fill" : "heart"
                        )
                        .foregroundStyle(quote.isFavorite ? Color.lsShadowGrey : Color.primary)
                    }
                }
            }
        }
        .sheet(isPresented: $showingShareOptions) {
            ShareOptionsView(quote: quote)
        }
    }

    private func toggleFavorite() {
        withAnimation {
            quote.isFavorite.toggle()
            quote.updatedAt = .now
        }
    }
}

#Preview {
    NavigationStack {
        QuoteDetailView(
            quote: Quote(
                author: "Socrates",
                text: "The unexamined life is not worth living.",
                source: "Apology"
            )
        )
    }
    .modelContainer(for: Quote.self, inMemory: true)
}
