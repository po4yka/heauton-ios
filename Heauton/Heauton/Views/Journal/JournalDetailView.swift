import SwiftData
import SwiftUI

struct JournalDetailView: View {
    @Bindable var entry: JournalEntry
    @State private var showingEditor = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text(entry.title)
                        .font(.firaCodeTitle(.bold))

                    HStack {
                        Text(entry.formattedDate)
                            .font(.firaCodeCaption())
                            .foregroundStyle(.secondary)

                        if let mood = entry.mood {
                            Text("•")
                                .foregroundStyle(.secondary)
                            Text(mood.emoji + " " + mood.displayName)
                                .font(.firaCodeCaption())
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Divider()

                // Content
                Text(entry.content)
                    .font(.firaCodeBody(.regular))
                    .textSelection(.enabled)

                // Tags
                if !entry.tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(entry.tags, id: \.self) { tag in
                                Text(tag)
                                    .font(.firaCodeCaption())
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.blue.opacity(0.1))
                                    .foregroundStyle(.blue)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }

                // Metadata
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "doc.text")
                            .foregroundStyle(.secondary)
                        Text("\(entry.wordCount) words")
                            .font(.firaCodeCaption())
                            .foregroundStyle(.secondary)
                    }

                    if let updatedAt = entry.updatedAt {
                        HStack {
                            Image(systemName: "clock")
                                .foregroundStyle(.secondary)
                            Text("Updated \(updatedAt, format: .relative(presentation: .named))")
                                .font(.firaCodeCaption())
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack {
                    Button {
                        entry.isFavorite.toggle()
                    } label: {
                        Label(
                            "Favorite",
                            systemImage: entry.isFavorite ? "heart.fill" : "heart"
                        )
                        .foregroundStyle(entry.isFavorite ? .red : .primary)
                    }

                    Button {
                        showingEditor = true
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                }
            }
        }
        .sheet(isPresented: $showingEditor) {
            JournalEntryEditorView(entry: entry)
        }
    }
}

#Preview {
    NavigationStack {
        JournalDetailView(
            entry: JournalEntry(
                title: "A Reflective Day",
                content: """
                Today was filled with moments of clarity and insight. \
                I spent time reading Marcus Aurelius and reflecting on the nature of control and acceptance.
                """,
                mood: .reflective,
                tags: ["Philosophy", "Stoicism"]
            )
        )
    }
    // swiftlint:disable:next force_try
    .modelContainer(try! SharedModelContainer.create())
}
