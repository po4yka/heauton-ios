import Foundation
import SwiftUI

/// ViewModel for JournalEntryEditorView following MVVM + @Observable pattern
/// Handles journal entry creation and editing logic
@Observable
@MainActor
final class JournalEntryEditorViewModel {
    // MARK: - Dependencies

    private let journalService: JournalServiceProtocol
    private let entry: JournalEntry?

    // MARK: - Published State

    var title: String
    var content: String
    var selectedMood: JournalMood?
    var tags: [String]
    var isSaving = false
    var saveError: Error?

    // MARK: - Validation

    private let maxTitleLength = 200
    private let maxContentLength = 100_000 // ~50 pages
    private let maxTagLength = 50
    private let maxTags = 20

    // MARK: - Computed Properties

    var canSave: Bool {
        isValidTitle && isValidContent && !isSaving
    }

    var isValidTitle: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            title.count <= maxTitleLength
    }

    var isValidContent: Bool {
        !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            content.count <= maxContentLength
    }

    var titleValidationError: String? {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty, !title.isEmpty {
            return "Title cannot be only whitespace"
        }
        if title.count > maxTitleLength {
            return "Title is too long (\(title.count)/\(maxTitleLength) characters)"
        }
        return nil
    }

    var contentValidationError: String? {
        if content.count > maxContentLength {
            return "Content is too long (\(content.count)/\(maxContentLength) characters)"
        }
        return nil
    }

    var isEditMode: Bool {
        entry != nil
    }

    var navigationTitle: String {
        isEditMode ? "Edit Entry" : "New Entry"
    }

    var wordCount: Int {
        content.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .count
    }

    // MARK: - Initialization

    init(
        entry: JournalEntry? = nil,
        journalService: JournalServiceProtocol
    ) {
        self.entry = entry
        self.journalService = journalService
        title = entry?.title ?? ""
        content = entry?.content ?? ""
        selectedMood = entry?.mood
        tags = entry?.tags ?? []
    }

    // MARK: - Public Methods

    /// Save the journal entry (create new or update existing)
    func saveEntry() async -> Bool {
        guard canSave else { return false }

        isSaving = true
        saveError = nil

        do {
            if let existingEntry = entry {
                // Update existing entry using new API
                try await journalService.updateEntry(
                    existingEntry,
                    title: title,
                    content: content,
                    mood: selectedMood,
                    tags: tags
                )
            } else {
                // Create new entry
                _ = try await journalService.createEntry(
                    title: title,
                    content: content,
                    mood: selectedMood,
                    tags: tags,
                    linkedQuoteId: nil
                )
            }

            isSaving = false
            return true
        } catch {
            saveError = error
            isSaving = false
            return false
        }
    }

    /// Toggle mood selection
    func toggleMood(_ mood: JournalMood) {
        selectedMood = selectedMood == mood ? nil : mood
    }

    /// Add a tag with validation
    func addTag(_ tag: String) -> Bool {
        let trimmed = tag.trimmingCharacters(in: .whitespacesAndNewlines)

        // Validation
        guard !trimmed.isEmpty else { return false }
        guard trimmed.count <= maxTagLength else { return false }
        guard tags.count < maxTags else { return false }
        guard !tags.contains(trimmed) else { return false }

        // Sanitize tag (remove special characters except spaces and hyphens)
        let allowedCharacters = CharacterSet.alphanumerics
            .union(.whitespaces)
            .union(CharacterSet(charactersIn: "-"))
        let sanitized = trimmed.components(separatedBy: allowedCharacters.inverted).joined()

        guard !sanitized.isEmpty else { return false }

        tags.append(sanitized)
        return true
    }

    /// Remove a tag
    func removeTag(_ tag: String) {
        tags.removeAll { $0 == tag }
    }

    /// Validate tag input before adding
    func validateTag(_ tag: String) -> String? {
        let trimmed = tag.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.isEmpty {
            return "Tag cannot be empty"
        }
        if trimmed.count > maxTagLength {
            return "Tag is too long (max \(maxTagLength) characters)"
        }
        if tags.count >= maxTags {
            return "Maximum \(maxTags) tags allowed"
        }
        if tags.contains(trimmed) {
            return "Tag already exists"
        }
        return nil
    }

    /// Clear all fields
    func clear() {
        title = ""
        content = ""
        selectedMood = nil
        tags = []
        saveError = nil
    }
}
