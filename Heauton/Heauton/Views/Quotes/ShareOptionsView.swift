import SwiftUI

struct ShareOptionsView: View {
    let quote: Quote

    @Environment(\.dismiss)
    private var dismiss
    @Environment(\.appDependencies)
    private var dependencies

    @State private var selectedStyle: ShareStyle = .card
    @State private var includeImage = true
    @State private var isLoading = false
    @State private var showingShareSheet = false
    @State private var shareItems: [Any] = []

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Preview
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Preview")
                            .font(.firaCodeHeadline())
                            .foregroundStyle(.secondary)

                        if includeImage {
                            QuoteCardView(quote: quote, style: selectedStyle)
                                .frame(height: 300)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .shadow(radius: 8)
                        } else {
                            Text(getPreviewText())
                                .font(.firaCodeBody(.regular))
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.secondary.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding()
                }

                // Options
                VStack(spacing: 16) {
                    // Style picker
                    Picker("Style", selection: $selectedStyle) {
                        ForEach([ShareStyle.minimal, .card, .attributed], id: \.self) { style in
                            Text(style.displayName).tag(style)
                        }
                    }
                    .pickerStyle(.segmented)

                    // Include image toggle
                    Toggle("Include Image", isOn: $includeImage)
                        .font(.firaCodeBody(.medium))

                    // Share button
                    Button {
                        shareQuote()
                    } label: {
                        if isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(isLoading)
                }
                .padding()
            }
            .navigationTitle("Share Quote")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                ShareSheet(items: shareItems) { completed in
                    if completed {
                        dismiss()
                    }
                }
            }
        }
    }

    private func getPreviewText() -> String {
        Task {
            await dependencies.quoteSharingService.formatQuoteText(quote, style: selectedStyle)
        }

        // Synchronous version for preview
        switch selectedStyle {
        case .minimal:
            var text = "\"\(quote.text)\"\n\n"
            text += "— \(quote.author)"
            if let source = quote.source {
                text += ", \(source)"
            }
            return text
        case .card:
            var text = "Daily Quote\n\n"
            text += "\"\(quote.text)\"\n\n"
            text += "— \(quote.author)"
            if let source = quote.source {
                text += ", \(source)"
            }
            text += "\n\nShared from Heauton"
            return text
        case .attributed:
            var text = "\"\(quote.text)\"\n\n"
            text += "— \(quote.author)"
            if let source = quote.source {
                text += "\nSource: \(source)"
            }
            if let mood = quote.mood {
                text += "\n\nMood: \(mood)"
            }
            if let categories = quote.categories, !categories.isEmpty {
                text += "\nCategories: \(categories.joined(separator: ", "))"
            }
            return text
        }
    }

    private func shareQuote() {
        isLoading = true

        Task {
            let items = await dependencies.quoteSharingService.createShareItems(
                quote,
                includeImage: includeImage
            )

            await MainActor.run {
                shareItems = items
                isLoading = false
                showingShareSheet = true
            }
        }
    }
}

#Preview {
    ShareOptionsView(
        quote: Quote(
            author: "Marcus Aurelius",
            text: "You have power over your mind - not outside events. Realize this, and you will find strength.",
            source: "Meditations",
            categories: ["Stoicism", "Philosophy"],
            mood: "Inspiring"
        )
    )
    .environment(\.appDependencies, AppDependencyContainer.shared)
}
