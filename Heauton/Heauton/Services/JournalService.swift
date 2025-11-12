import Foundation
import SwiftData

/// Data Transfer Object for decrypted journal entries
/// Prevents exposing decrypted content in the model layer
struct DecryptedJournalEntry: Sendable {
    let entry: JournalEntry
    let decryptedContent: String

    var id: UUID { entry.id }
    var title: String { entry.title }
    var createdAt: Date { entry.createdAt }
    var updatedAt: Date? { entry.updatedAt }
    var mood: JournalMood? { entry.mood }
    var tags: [String] { entry.tags }
    var isFavorite: Bool { entry.isFavorite }
    var linkedQuoteId: UUID? { entry.linkedQuoteId }
    var wordCount: Int { entry.wordCount }
    var isEncrypted: Bool { entry.isEncrypted }
}

/// Service for managing journal entries and prompts
actor JournalService: JournalServiceProtocol {
    private let modelContext: ModelContext
    private let encryptionService: EncryptionServiceProtocol

    init(modelContext: ModelContext, encryptionService: EncryptionServiceProtocol) {
        self.modelContext = modelContext
        self.encryptionService = encryptionService
    }

    // MARK: - Entry Management

    func createEntry(
        title: String,
        content: String,
        mood: JournalMood?,
        tags: [String],
        linkedQuoteId: UUID?
    ) async throws -> DecryptedJournalEntry {
        // Encrypt the content
        let encryptedData = try await encryptionService.encryptString(content)

        let entry = JournalEntry(
            title: title,
            content: "", // Never store plaintext content
            encryptedContentData: encryptedData,
            isEncrypted: true,
            mood: mood,
            tags: tags,
            linkedQuoteId: linkedQuoteId
        )
        modelContext.insert(entry)
        try modelContext.save()

        // Return DTO with decrypted content for immediate display
        return DecryptedJournalEntry(entry: entry, decryptedContent: content)
    }

    func updateEntry(
        _ entry: JournalEntry,
        title: String,
        content: String,
        mood: JournalMood?,
        tags: [String]
    ) async throws {
        entry.title = title
        entry.mood = mood
        entry.tags = tags
        entry.updatedAt = Date.now

        // Re-encrypt the content
        let encryptedData = try await encryptionService.encryptString(content)
        entry.encryptedContentData = encryptedData
        entry.isEncrypted = true
        entry.content = "" // Ensure plaintext is never stored

        // Update word count based on new content
        entry.wordCount = content.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .count

        try modelContext.save()
    }

    func deleteEntry(_ entry: JournalEntry) async throws {
        modelContext.delete(entry)
        try modelContext.save()
    }

    func fetchEntries(
        sortBy: JournalSortOption,
        filterBy: JournalFilter?
    ) async throws -> [DecryptedJournalEntry] {
        var descriptor = FetchDescriptor<JournalEntry>()

        // Store search text for post-decryption filtering
        let searchText = filterBy?.searchText

        // Apply filter (excluding content search since content is encrypted)
        if let filter = filterBy {
            descriptor.predicate = buildPredicate(from: filter, excludeContentSearch: true)
        }

        // Apply sorting
        descriptor.sortBy = sortDescriptors(for: sortBy)

        let entries = try modelContext.fetch(descriptor)

        // Decrypt content and return DTOs
        var decryptedEntries: [DecryptedJournalEntry] = []
        for entry in entries {
            let decryptedContent: String
            if entry.isEncrypted, let encryptedData = entry.encryptedContentData {
                do {
                    decryptedContent = try await encryptionService.decryptString(encryptedData)
                } catch {
                    // If decryption fails, return error message
                    decryptedContent = "[Encrypted content - unable to decrypt]"
                }
            } else {
                // Fallback for legacy unencrypted entries
                decryptedContent = entry.content
            }

            decryptedEntries.append(
                DecryptedJournalEntry(entry: entry, decryptedContent: decryptedContent)
            )
        }

        // Post-decryption content search filtering
        // This is necessary because encrypted content cannot be searched in the database
        if let searchText, !searchText.isEmpty {
            decryptedEntries = decryptedEntries.filter { decryptedEntry in
                // Check if content matches (title/tags already matched in DB query,
                // but we need to keep those OR also match content)
                // Since DB query already filtered by (title OR tags), we just need to
                // keep entries that also match in content, OR were already matched by title/tags
                decryptedEntry.title.localizedStandardContains(searchText) ||
                    decryptedEntry.tags.contains { $0.localizedStandardContains(searchText) } ||
                    decryptedEntry.decryptedContent.localizedStandardContains(searchText)
            }
        }

        return decryptedEntries
    }

    /// Fetches a single entry by ID and returns decrypted DTO
    func fetchEntry(id: UUID) async throws -> DecryptedJournalEntry? {
        let descriptor = FetchDescriptor<JournalEntry>(
            predicate: #Predicate { $0.id == id }
        )
        guard let entry = try modelContext.fetch(descriptor).first else {
            return nil
        }

        let decryptedContent: String = if entry.isEncrypted, let encryptedData = entry.encryptedContentData {
            try await encryptionService.decryptString(encryptedData)
        } else {
            entry.content
        }

        return DecryptedJournalEntry(entry: entry, decryptedContent: decryptedContent)
    }

    // MARK: - Prompt Management

    func selectRandomPrompt(category: PromptCategory?) async throws -> JournalPrompt? {
        var descriptor = FetchDescriptor<JournalPrompt>(
            predicate: #Predicate { $0.isActive == true }
        )

        // Filter by category if specified
        if let category {
            descriptor.predicate = #Predicate<JournalPrompt> { prompt in
                prompt.isActive == true && prompt.category == category
            }
        }

        let prompts = try modelContext.fetch(descriptor)

        // Filter out recently used prompts
        let availablePrompts = prompts.filter { !$0.wasUsedRecently }

        // Return random from available, or any if all were used recently
        return availablePrompts.randomElement() ?? prompts.randomElement()
    }

    func markPromptAsUsed(_ prompt: JournalPrompt) async throws {
        prompt.markAsUsed()
        try modelContext.save()
    }

    // MARK: - Private Helper Methods

    private func buildPredicate(
        from filter: JournalFilter,
        excludeContentSearch: Bool = false
    ) -> Predicate<JournalEntry>? {
        var predicates: [Predicate<JournalEntry>] = []

        // Search text filter
        // NOTE: For encrypted entries, content field is empty, so we only search
        // title and tags in the database. Content search is performed post-decryption.
        if let searchText = filter.searchText, !searchText.isEmpty {
            let search = searchText
            if excludeContentSearch {
                // Only search in title and tags (content is encrypted and empty)
                predicates.append(#Predicate<JournalEntry> { entry in
                    entry.title.localizedStandardContains(search) ||
                        entry.tags.contains { $0.localizedStandardContains(search) }
                })
            } else {
                // Legacy: search in content too (for unencrypted entries)
                predicates.append(#Predicate<JournalEntry> { entry in
                    entry.title.localizedStandardContains(search) ||
                        entry.content.localizedStandardContains(search) ||
                        entry.tags.contains { $0.localizedStandardContains(search) }
                })
            }
        }

        // Favorites filter
        if filter.favoritesOnly {
            predicates.append(#Predicate<JournalEntry> { entry in
                entry.isFavorite == true
            })
        }

        // Mood filter
        if let mood = filter.mood {
            predicates.append(#Predicate<JournalEntry> { entry in
                entry.mood == mood
            })
        }

        // Date range filter
        if let dateRange = filter.dateRange {
            let start = dateRange.start
            let end = dateRange.end
            predicates.append(#Predicate<JournalEntry> { entry in
                entry.createdAt >= start && entry.createdAt <= end
            })
        }

        guard !predicates.isEmpty else { return nil }

        return predicates.reduce(predicates[0]) { result, predicate in
            #Predicate<JournalEntry> { entry in
                result.evaluate(entry) && predicate.evaluate(entry)
            }
        }
    }

    private func sortDescriptors(
        for option: JournalSortOption
    ) -> [SortDescriptor<JournalEntry>] {
        switch option {
        case .newest:
            [SortDescriptor(\.createdAt, order: .reverse)]
        case .oldest:
            [SortDescriptor(\.createdAt, order: .forward)]
        case .updated:
            [
                SortDescriptor(\.updatedAt, order: .reverse),
                SortDescriptor(\.createdAt, order: .reverse),
            ]
        case .pinned:
            [
                SortDescriptor(\.createdAt, order: .reverse),
            ]
        }
    }
}
