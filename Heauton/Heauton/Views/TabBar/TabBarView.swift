import SwiftData
import SwiftUI

struct TabBarView: View {
    @Environment(\.deepLinkCoordinator)
    private var coordinator

    var body: some View {
        @Bindable var bindableCoordinator = coordinator

        TabView(selection: $bindableCoordinator.selectedTab) {
            // Home tab - Main quotes list
            QuotesListView()
                .tabItem {
                    Label("Home", systemImage: "house")
                }
                .tag(0)

            // Journal tab - Personal journaling and reflection
            JournalListView()
                .tabItem {
                    Label("Journal", systemImage: "book.closed")
                }
                .tag(1)

            // Exercises tab - Meditation and breathing exercises
            ExercisesLibraryView()
                .tabItem {
                    Label("Exercises", systemImage: "figure.mind.and.body")
                }
                .tag(2)

            // Add tab - Quick add action
            AddQuoteView()
                .tabItem {
                    Label("Add", systemImage: "plus")
                }
                .tag(3)

            // Library tab - Browse and filter quotes
            QuotesLibraryView()
                .tabItem {
                    Label("Library", systemImage: "books.vertical")
                }
                .tag(4)

            // Progress tab - Track wellness progress and achievements
            ProgressDashboardView()
                .tabItem {
                    Label("Progress", systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(5)
        }
        .tint(.appPrimary)
    }
}

// MARK: - Placeholder Views

struct IdeasView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "Ideas",
                systemImage: "lightbulb",
                description: Text("Coming soon: Explore philosophical concepts and ideas")
            )
            .navigationTitle("Ideas")
        }
    }
}

struct AddQuoteView: View {
    @Environment(\.modelContext)
    private var modelContext
    @State private var author = ""
    @State private var text = ""
    @State private var source = ""
    @State private var showingSuccess = false

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Quote Details")) {
                    TextField("Author", text: $author)
                        .textContentType(.name)

                    TextField("Source (optional)", text: $source)

                    ZStack(alignment: .topLeading) {
                        if text.isEmpty {
                            Text("Quote text")
                                .foregroundStyle(.tertiary)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 8)
                        }
                        TextEditor(text: $text)
                            .frame(minHeight: 100)
                    }
                }

                Section {
                    Button(action: addQuote) {
                        HStack {
                            Spacer()
                            Text("Add Quote")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .disabled(author.isEmpty || text.isEmpty)
                }
            }
            .navigationTitle("Add Quote")
            .alert("Quote Added", isPresented: $showingSuccess) {
                Button("OK") {
                    clearForm()
                }
            } message: {
                Text("Your quote has been added successfully")
            }
        }
    }

    private func addQuote() {
        let newQuote = Quote(
            author: author,
            text: text,
            source: source.isEmpty ? nil : source
        )
        modelContext.insert(newQuote)
        showingSuccess = true
    }

    private func clearForm() {
        author = ""
        text = ""
        source = ""
    }
}

struct ExploreView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "Explore",
                systemImage: "safari",
                description: Text("Coming soon: Discover quotes by category, theme, or philosopher")
            )
            .navigationTitle("Explore")
        }
    }
}

// HistoryView and related components moved to HistoryView.swift

#Preview {
    TabBarView()
        .modelContainer(for: [Quote.self, UserEvent.self], inMemory: true)
}
