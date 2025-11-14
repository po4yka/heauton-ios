import Foundation
@testable import Heauton

/// Mock Journal Service for testing ViewModels
actor MockJournalService: JournalServiceProtocol {
    var createdEntries: [JournalEntry] = []
    var updatedEntries: [JournalEntry] = []
    var deletedEntries: [JournalEntry] = []
    var shouldThrowError = false
    var fetchedEntries: [JournalEntry] = []

    func createEntry(
        title: String,
        content: String,
        mood: JournalMood?,
        tags: [String],
        linkedQuoteId: UUID?
    ) async throws -> DecryptedJournalEntry {
        if shouldThrowError {
            throw MockError.operationFailed
        }

        let entry = JournalEntry(
            title: title,
            content: content,
            mood: mood,
            tags: tags,
            linkedQuoteId: linkedQuoteId
        )
        createdEntries.append(entry)
        return DecryptedJournalEntry(entry: entry, decryptedContent: content)
    }

    func updateEntry(
        _ entry: JournalEntry,
        title _: String,
        content _: String,
        mood _: JournalMood?,
        tags _: [String]
    ) async throws {
        if shouldThrowError {
            throw MockError.operationFailed
        }
        updatedEntries.append(entry)
    }

    func deleteEntry(_ entry: JournalEntry) async throws {
        if shouldThrowError {
            throw MockError.operationFailed
        }
        deletedEntries.append(entry)
    }

    func fetchEntries(
        sortBy _: JournalSortOption,
        filterBy _: JournalFilter?
    ) async throws -> [DecryptedJournalEntry] {
        if shouldThrowError {
            throw MockError.operationFailed
        }
        return fetchedEntries.map { entry in
            DecryptedJournalEntry(entry: entry, decryptedContent: entry.content)
        }
    }

    func fetchEntry(id: UUID) async throws -> DecryptedJournalEntry? {
        if shouldThrowError {
            throw MockError.operationFailed
        }
        guard let entry = fetchedEntries.first(where: { $0.id == id }) else {
            return nil
        }
        return DecryptedJournalEntry(entry: entry, decryptedContent: entry.content)
    }

    func selectRandomPrompt(category _: PromptCategory?) async throws -> JournalPrompt? {
        nil
    }

    func markPromptAsUsed(_: JournalPrompt) async throws {
        // No-op
    }
}

enum MockError: Error {
    case operationFailed
}
