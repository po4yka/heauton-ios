import OSLog
import SwiftData
import SwiftUI

struct QuotesLibraryView: View {
    @Environment(\.modelContext)
    private var modelContext
    @Query private var allQuotes: [Quote]

    @State private var filter = QuoteFilter.default
    @State private var filteredQuotes: [Quote] = []
    @State private var showingFilter = false
    @State private var searchText = ""
    @State private var viewMode: ViewMode = .list

    private let logger = Logger(subsystem: "com.heauton.app", category: "QuotesLibrary")

    enum ViewMode {
        case list, grid
    }

    var body: some View {
        NavigationStack {
            ZStack {
                if filteredQuotes.isEmpty {
                    ContentUnavailableView {
                        Label("No Quotes Found", systemImage: "magnifyingglass")
                    } description: {
                        Text("Try adjusting your filters or adding new quotes")
                    }
                } else {
                    Group {
                        switch viewMode {
                        case .list:
                            listView
                        case .grid:
                            gridView
                        }
                    }
                }
            }
            .navigationTitle("Library")
            .searchable(text: $searchText, prompt: "Search quotes")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 8) {
                        // View mode toggle
                        Button {
                            viewMode = viewMode == .list ? .grid : .list
                        } label: {
                            Label(
                                "View Mode",
                                systemImage: viewMode == .list ? "square.grid.2x2" : "list.bullet"
                            )
                        }

                        // Filter button with badge
                        Button {
                            showingFilter = true
                        } label: {
                            Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
                                .symbolVariant(filter.isActive ? .fill : .none)
                        }
                        .overlay(alignment: .topTrailing) {
                            if filter.isActive {
                                Circle()
                                    .fill(.lsShadowGrey)
                                    .frame(width: 8, height: 8)
                                    .offset(x: 4, y: -4)
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $showingFilter) {
                FilterView(filter: $filter)
            }
            .onChange(of: searchText) { _, newValue in
                filter.searchText = newValue.isEmpty ? nil : newValue
                applyFilter()
            }
            .onChange(of: filter) { _, _ in
                applyFilter()
            }
            .onAppear {
                applyFilter()
            }
        }
    }

    private var listView: some View {
        List {
            ForEach(filteredQuotes) { quote in
                NavigationLink {
                    QuoteDetailView(quote: quote)
                } label: {
                    QuoteRowView(quote: quote)
                }
            }
        }
        .listStyle(.plain)
    }

    private var gridView: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 150), spacing: 16),
            ], spacing: 16) {
                ForEach(filteredQuotes) { quote in
                    NavigationLink {
                        QuoteDetailView(quote: quote)
                    } label: {
                        QuoteCardGridItem(quote: quote)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
    }

    private func applyFilter() {
        do {
            let repository = SwiftDataQuotesRepository(modelContext: modelContext)
            Task {
                filteredQuotes = try await repository.fetchQuotes(filter: filter)
            }
        } catch {
            logger.error("Error applying filter: \(error.localizedDescription)")
            filteredQuotes = allQuotes
        }
    }
}

// MARK: - Supporting Views

private struct QuoteRowView: View {
    let quote: Quote

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(quote.text)
                .font(.firaCodeBody(.regular))
                .lineLimit(3)

            HStack {
                Text(quote.author)
                    .font(.firaCodeCaption(.medium))
                    .foregroundStyle(.secondary)

                Spacer()

                if quote.isFavorite {
                    Image(systemName: "heart.fill")
                        .font(.caption)
                        .foregroundStyle(.accentFavorite)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct QuoteCardGridItem: View {
    let quote: Quote

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(quote.text)
                .font(.firaCodeCaption(.regular))
                .lineLimit(6)
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()

            Text(quote.author)
                .font(.firaCodeCaption2(.medium))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding()
        .frame(height: 150)
        .background(Color.secondary.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    QuotesLibraryView()
        // swiftlint:disable:next force_try
        .modelContainer(try! SharedModelContainer.create())
}
