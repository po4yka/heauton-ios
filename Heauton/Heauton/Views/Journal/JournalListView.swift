import SwiftData
import SwiftUI

struct JournalListView: View {
    @Environment(\.modelContext)
    private var modelContext
    @Environment(\.appDependencies)
    private var dependencies
    @Query(sort: \JournalEntry.createdAt, order: .reverse)
    private var entries: [JournalEntry]

    @State private var showingNewEntry = false
    @State private var searchText = ""

    var filteredEntries: [JournalEntry] {
        if searchText.isEmpty {
            return entries
        }
        return entries.filter { entry in
            entry.title.localizedStandardContains(searchText) ||
                entry.content.localizedStandardContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if filteredEntries.isEmpty {
                    emptyStateView
                } else {
                    entriesList
                }
            }
            .navigationTitle("Journal")
            .searchable(text: $searchText, prompt: "Search entries")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingNewEntry = true
                    } label: {
                        Label("New Entry", systemImage: "square.and.pencil")
                    }
                }
            }
            .sheet(isPresented: $showingNewEntry) {
                JournalEntryEditorView()
            }
        }
    }

    private var emptyStateView: some View {
        ContentUnavailableView {
            Label("No Journal Entries", systemImage: "book.closed")
        } description: {
            Text("Start journaling your thoughts and reflections")
        } actions: {
            Button("Create First Entry") {
                showingNewEntry = true
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var entriesList: some View {
        List {
            ForEach(filteredEntries) { entry in
                NavigationLink {
                    JournalDetailView(entry: entry)
                } label: {
                    JournalEntryRow(entry: entry)
                }
            }
            .onDelete(perform: deleteEntries)
        }
    }

    private func deleteEntries(at offsets: IndexSet) {
        for index in offsets {
            let entry = filteredEntries[index]
            modelContext.delete(entry)
        }
    }
}

// MARK: - Supporting Views

struct JournalEntryRow: View {
    let entry: JournalEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(entry.title)
                    .font(.firaCodeHeadline())
                    .lineLimit(1)

                Spacer()

                if let mood = entry.mood {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(mood.color)
                            .frame(width: 8, height: 8)

                        Text(mood.emoji)
                            .font(.caption)
                            .foregroundStyle(Color.appTextSecondary)
                    }
                }
            }

            Text(entry.preview)
                .font(.firaCodeBody(.regular))
                .foregroundStyle(.secondary)
                .lineLimit(2)

            HStack {
                Text(entry.formattedDate)
                    .font(.firaCodeCaption())
                    .foregroundStyle(.tertiary)

                Spacer()

                if !entry.tags.isEmpty {
                    Text(entry.tags.prefix(2).joined(separator: ", "))
                        .font(.firaCodeCaption())
                        .foregroundStyle(Color.appPrimary)
                }

                if entry.isFavorite {
                    Image(systemName: "heart.fill")
                        .font(.caption2)
                        .foregroundStyle(Color.accentFavorite)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    JournalListView()
        // swiftlint:disable:next force_try
        .modelContainer(try! SharedModelContainer.create())
        .environment(\.appDependencies, AppDependencyContainer.shared)
}
