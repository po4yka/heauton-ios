import Foundation

/// Utility for normalizing text for search indexing
///
/// # Text Normalization Algorithm
///
/// This algorithm prepares text for full-text search by applying Unicode normalization,
/// case folding, and diacritic removal to ensure consistent matching across languages.
///
/// ## Normalization Steps
///
/// 1. **NFKC Normalization**: Canonical decomposition followed by canonical composition
///    - Example: "ﬁ" (ligature) → "fi" (two characters)
///    - Example: "①" (circled one) → "1" (digit one)
///
/// 2. **Lowercase Conversion**: All text converted to lowercase
///    - Example: "Café" → "café"
///    - Ensures case-insensitive matching
///
/// 3. **Diacritic Removal**: Accent marks removed from characters
///    - Example: "café" → "cafe"
///    - Example: "naïve" → "naive"
///    - Example: "Zürich" → "zurich"
///
/// 4. **Whitespace Trimming**: Leading/trailing whitespace removed
///
/// ## Why NFKC?
///
/// NFKC (Normalization Form KC) is chosen because:
/// - **Compatibility**: Converts visually similar characters to standard forms
/// - **Canonical**: Ensures unique representation of characters
/// - **Composing**: Combines base + combining characters into single codepoints
///
/// Alternative forms considered:
/// - **NFC**: Doesn't handle compatibility characters (e.g., ﬁ ligature)
/// - **NFD**: Keeps characters decomposed, less efficient for search
/// - **NFKD**: Keeps compatibility decomposition, larger index size
///
/// ## Search Matching Examples
///
/// After normalization, these all match:
/// - "café", "cafe", "Café", "CAFÉ", "Cafe"
/// - "naïve", "naive", "Naïve", "NAIVE"
/// - "①", "1", "１" (fullwidth)
///
/// ## Performance
///
/// - **Time Complexity**: O(n) where n is string length
/// - **Space Complexity**: O(n) for normalized output
/// - **Typical overhead**: ~10-20% longer than original string
///
/// ## Unicode Safety
///
/// - Handles all Unicode planes (BMP, SMP, SIP, TIP)
/// - Preserves emoji and special characters
/// - Safe for all languages (Latin, Cyrillic, Greek, CJK, etc.)
nonisolated enum TextNormalizer {
    /// Normalizes text for indexing and search
    /// - Parameter text: The text to normalize
    /// - Returns: Normalized text suitable for indexing
    static func normalize(_ text: String) -> String {
        text
            .applyingNFKCNormalization()
            .lowercased()
            .removingDiacritics()
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Normalizes text while preserving some structure for display
    /// - Parameter text: The text to normalize
    /// - Returns: Normalized text with preserved casing
    static func normalizePreservingCase(_ text: String) -> String {
        text
            .applyingNFKCNormalization()
            .removingDiacritics()
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - String Extensions

private extension String {
    /// Applies Unicode NFKC (Normalization Form KC) normalization
    /// This decomposes characters and then recomposes them canonically
    /// - Returns: NFKC normalized string
    nonisolated func applyingNFKCNormalization() -> String {
        precomposedStringWithCompatibilityMapping
    }

    /// Removes diacritics (accent marks) from characters
    /// For example: "café" becomes "cafe", "naïve" becomes "naive"
    /// - Returns: String with diacritics removed
    nonisolated func removingDiacritics() -> String {
        folding(
            options: .diacriticInsensitive,
            locale: .current
        )
    }
}

// MARK: - Token Extraction

nonisolated extension TextNormalizer {
    /// Extracts searchable tokens from text
    /// - Parameter text: The text to tokenize
    /// - Returns: Array of normalized tokens
    static func extractTokens(from text: String) -> [String] {
        let normalized = normalize(text)

        // Split by whitespace and punctuation
        let tokens = normalized.components(separatedBy: .punctuationCharacters)
            .flatMap { $0.components(separatedBy: .whitespaces) }
            .filter { !$0.isEmpty }

        return tokens
    }

    /// Extracts unique tokens from text
    /// - Parameter text: The text to tokenize
    /// - Returns: Set of unique normalized tokens
    static func extractUniqueTokens(from text: String) -> Set<String> {
        Set(extractTokens(from: text))
    }
}

// MARK: - Text Cleaning

nonisolated extension TextNormalizer {
    /// Cleans text by removing extra whitespace and normalizing line breaks
    /// - Parameter text: The text to clean
    /// - Returns: Cleaned text
    static func clean(_ text: String) -> String {
        // Normalize line breaks
        let normalized = text.replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")

        // Remove multiple consecutive spaces
        let components = normalized.components(separatedBy: .whitespaces)
        let cleaned = components.filter { !$0.isEmpty }.joined(separator: " ")

        return cleaned
    }

    /// Prepares text for FTS5 indexing
    /// - Parameter text: The text to prepare
    /// - Returns: Text ready for FTS5 indexing
    static func prepareForIndexing(_ text: String) -> String {
        clean(normalize(text))
    }
}
