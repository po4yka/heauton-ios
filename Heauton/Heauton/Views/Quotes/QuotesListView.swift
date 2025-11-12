import SwiftData
import SwiftUI

struct QuotesListView: View {
    @Environment(\.modelContext)
    private var modelContext
    @Environment(\.deepLinkCoordinator)
    private var coordinator
    @Query(sort: \Quote.createdAt, order: .reverse)
    private var quotes: [Quote]

    @State private var viewModel: QuotesListViewModel?
    @State private var navigationPath = NavigationPath()

    var body: some View {
        NavigationStack(path: $navigationPath) {
            Group {
                if let vm = viewModel, vm.displayQuotes(from: quotes).isEmpty {
                    if vm.isSearchActive {
                        ContentUnavailableView.search(text: vm.searchQuery)
                    } else {
                        ContentUnavailableView(
                            "No Quotes",
                            systemImage: "quote.bubble",
                            description: Text(
                                vm.showFavoritesOnly ? "No favorite quotes yet" :
                                    "Add some philosophical quotes to get started"
                            )
                        )
                    }
                } else if let vm = viewModel {
                    List {
                        if vm.isSearchActive {
                            Section {
                                ForEach(vm.displayQuotes(from: quotes)) { quote in
                                    NavigationLink(value: quote) {
                                        SearchResultRowView(
                                            quote: quote,
                                            searchResult: vm.searchResults.first { $0.quoteId == quote.id }
                                        )
                                    }
                                }
                            } header: {
                                let count = vm.displayQuotes(from: quotes).count
                                Text("\(count) result\(count == 1 ? "" : "s")")
                            }
                        } else {
                            ForEach(vm.displayQuotes(from: quotes)) { quote in
                                NavigationLink(value: quote) {
                                    QuoteRowView(quote: quote)
                                }
                            }
                            .onDelete { offsets in
                                withAnimation {
                                    vm.deleteQuotes(at: offsets, from: vm.displayQuotes(from: quotes))
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Philosopher Quotes")
            .searchable(
                text: Binding(
                    get: { viewModel?.searchQuery ?? "" },
                    set: { viewModel?.searchQuery = $0 }
                ),
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Search quotes, authors, or sources"
            )
            .onChange(of: viewModel?.searchQuery ?? "") { _, newValue in
                Task {
                    await viewModel?.performSearch(query: newValue)
                }
            }
            .overlay {
                if viewModel?.isSearching == true {
                    ProgressView("Searching...")
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
            .navigationDestination(for: Quote.self) { quote in
                QuoteDetailView(quote: quote)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        viewModel?.showSettings = true
                    } label: {
                        Label("Settings", systemImage: "gear")
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        viewModel?.toggleFavoritesFilter()
                    } label: {
                        Label(
                            viewModel?.showFavoritesOnly == true ? "Show All" : "Favorites",
                            systemImage: viewModel?.showFavoritesOnly == true ? "heart.fill" : "heart"
                        )
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        withAnimation {
                            viewModel?.addSampleQuote()
                        }
                    } label: {
                        Label("Add Quote", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: Binding(
                get: { viewModel?.showSettings ?? false },
                set: { viewModel?.showSettings = $0 }
            )) {
                SettingsView()
            }
            .onAppear {
                if viewModel == nil {
                    viewModel = QuotesListViewModel(modelContext: modelContext)
                }
            }
            .onChange(of: coordinator.pendingQuoteID) { _, newQuoteID in
                guard let quoteID = newQuoteID else { return }

                // Find the quote in the list
                if let quote = quotes.first(where: { $0.id == quoteID }) {
                    // Clear existing path and navigate to quote
                    navigationPath = NavigationPath()
                    navigationPath.append(quote)

                    // Clear the pending ID
                    coordinator.pendingQuoteID = nil
                }
            }
        }
    }
}

private struct QuoteRowView: View {
    let quote: Quote

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(quote.text)
                .font(.firaCodeBody())
                .lineLimit(3)

            HStack(alignment: .top) {
                if let source = quote.source {
                    Text("\(quote.author) • \(source)")
                        .font(.firaCodeCaption())
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                } else {
                    Text(quote.author)
                        .font(.firaCodeCaption())
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 8)

                if quote.isFavorite {
                    Image(systemName: "heart.fill")
                        .foregroundStyle(.red)
                        .font(.firaCodeCaption())
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct SearchResultRowView: View {
    let quote: Quote
    let searchResult: SearchResult?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Show snippet if available, otherwise show quote text
            if let snippet = searchResult?.snippet, !snippet.isEmpty {
                Text(snippet)
                    .font(.firaCodeBody())
                    .lineLimit(3)
            } else {
                Text(quote.text)
                    .font(.firaCodeBody())
                    .lineLimit(3)
            }

            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    if let source = quote.source {
                        Text("\(quote.author) • \(source)")
                            .font(.firaCodeCaption())
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    } else {
                        Text(quote.author)
                            .font(.firaCodeCaption())
                            .foregroundStyle(.secondary)
                    }

                    // Show match type and relevance
                    if let result = searchResult {
                        HStack(spacing: 4) {
                            Image(systemName: matchTypeIcon(result.matchType))
                                .font(.firaCodeCaption2())
                            Text(matchTypeLabel(result.matchType))
                                .font(.firaCodeCaption2())
                        }
                        .foregroundStyle(.tertiary)
                    }
                }

                Spacer(minLength: 8)

                VStack(alignment: .trailing, spacing: 4) {
                    if quote.isFavorite {
                        Image(systemName: "heart.fill")
                            .foregroundStyle(.red)
                            .font(.firaCodeCaption())
                    }

                    // Show relevance score
                    if let score = searchResult?.relevanceScore, score > 0 {
                        Text("\(Int(score * 100))%")
                            .font(.firaCodeCaption2())
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func matchTypeIcon(_ type: SearchResult.MatchType) -> String {
        switch type {
        case .exactMatch:
            "checkmark.circle.fill"
        case .authorMatch:
            "person.fill"
        case .contentMatch:
            "text.quote"
        case .sourceMatch:
            "book.fill"
        }
    }

    private func matchTypeLabel(_ type: SearchResult.MatchType) -> String {
        switch type {
        case .exactMatch:
            "Exact match"
        case .authorMatch:
            "Author match"
        case .contentMatch:
            "Content match"
        case .sourceMatch:
            "Source match"
        }
    }
}

#Preview {
    QuotesListView()
        .modelContainer(for: Quote.self, inMemory: true)
}
