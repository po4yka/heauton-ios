@testable import Heauton
import XCTest

/// Unit tests for TextNormalizer
final class TextNormalizerTests: XCTestCase {
    // MARK: - Normalization Tests

    func testNFKCNormalization() {
        // Test compatibility decomposition
        let input = "ﬁ" // ligature fi
        let normalized = TextNormalizer.normalize(input)

        // Should decompose ligature
        XCTAssertNotEqual(input, normalized)
        XCTAssertTrue(normalized.contains("fi") || normalized == "fi")
    }

    func testNFKCNormalizationWithFullwidthCharacters() {
        let input = "Ｈｅｌｌｏ" // Fullwidth Latin letters
        let normalized = TextNormalizer.normalize(input)

        // Should convert to regular ASCII
        XCTAssertEqual(normalized, "hello")
    }

    func testLowercaseConversion() {
        let testCases: [(String, String)] = [
            ("HELLO", "hello"),
            ("MiXeD CaSe", "mixed case"),
            ("café", "cafe"),
            ("CAFÉ", "cafe"),
            ("123ABC", "123abc"),
        ]

        for (input, expected) in testCases {
            let result = TextNormalizer.normalize(input)
            XCTAssertEqual(result, expected, "Failed for input: \(input)")
        }
    }

    func testDiacriticRemoval() {
        let testCases: [(String, String)] = [
            ("café", "cafe"),
            ("naïve", "naive"),
            ("résumé", "resume"),
            ("Zürich", "zurich"),
            ("São Paulo", "sao paulo"),
            ("crème brûlée", "creme brulee"),
            ("Ångström", "angstrom"),
        ]

        for (input, expected) in testCases {
            let result = TextNormalizer.normalize(input)
            XCTAssertEqual(result, expected, "Failed for input: \(input)")
        }
    }

    func testDiacriticRemovalComplex() {
        let input = "El Niño está en la montaña"
        let expected = "el nino esta en la montana"
        let result = TextNormalizer.normalize(input)

        XCTAssertEqual(result, expected)
    }

    // MARK: - Token Extraction Tests

    func testExtractTokensBasic() {
        let text = "Hello, world! How are you?"
        let tokens = TextNormalizer.extractTokens(from: text)

        XCTAssertEqual(tokens.count, 5)
        XCTAssertEqual(tokens, ["hello", "world", "how", "are", "you"])
    }

    func testExtractTokensWithPunctuation() {
        let text = "Hello... world!!! Test???"
        let tokens = TextNormalizer.extractTokens(from: text)

        XCTAssertEqual(tokens, ["hello", "world", "test"])
    }

    func testExtractTokensWithNumbers() {
        let text = "Test 123 hello 456 world"
        let tokens = TextNormalizer.extractTokens(from: text)

        XCTAssertEqual(tokens.count, 5)
        XCTAssertTrue(tokens.contains("123"))
        XCTAssertTrue(tokens.contains("456"))
    }

    func testExtractTokensEmptyString() {
        let tokens = TextNormalizer.extractTokens(from: "")
        XCTAssertTrue(tokens.isEmpty)
    }

    func testExtractTokensOnlyPunctuation() {
        let tokens = TextNormalizer.extractTokens(from: "... !!! ???")
        XCTAssertTrue(tokens.isEmpty)
    }

    func testExtractUniqueTokens() {
        let text = "hello world hello test world"
        let uniqueTokens = TextNormalizer.extractUniqueTokens(from: text)

        XCTAssertEqual(uniqueTokens.count, 3)
        XCTAssertTrue(uniqueTokens.contains("hello"))
        XCTAssertTrue(uniqueTokens.contains("world"))
        XCTAssertTrue(uniqueTokens.contains("test"))
    }

    func testExtractUniqueTokensCaseSensitivity() {
        let text = "Hello HELLO hello HeLLo"
        let uniqueTokens = TextNormalizer.extractUniqueTokens(from: text)

        // All should normalize to "hello"
        XCTAssertEqual(uniqueTokens.count, 1)
        XCTAssertTrue(uniqueTokens.contains("hello"))
    }

    func testCleanText() {
        let input = "Hello\r\nWorld\rTest\nEnd"
        let cleaned = TextNormalizer.clean(input)

        // Should normalize all line breaks to \n and collapse spaces
        XCTAssertFalse(cleaned.contains("\r\n"))
        XCTAssertFalse(cleaned.contains("\r"))
    }

    func testCleanTextMultipleSpaces() {
        let input = "Hello    world     test"
        let cleaned = TextNormalizer.clean(input)

        XCTAssertEqual(cleaned, "Hello world test")
    }

    func testCleanTextEmptyString() {
        let cleaned = TextNormalizer.clean("")
        XCTAssertEqual(cleaned, "")
    }

    func testPrepareForIndexing() {
        let input = "  Café   naïve   RÉSUMÉ  "
        let prepared = TextNormalizer.prepareForIndexing(input)

        XCTAssertEqual(prepared, "cafe naive resume")
    }

    func testPrepareForIndexingWithPunctuation() {
        let input = "Hello, world! How are you?"
        let prepared = TextNormalizer.prepareForIndexing(input)

        // Should preserve punctuation but normalize text
        XCTAssertTrue(prepared.contains("hello"))
        XCTAssertTrue(prepared.contains("world"))
    }

    func testNormalizePreservingCase() {
        let input = "Café NAÏVE"
        let normalized = TextNormalizer.normalizePreservingCase(input)

        // Should remove diacritics but preserve case
        XCTAssertTrue(normalized.contains("Cafe"))
        XCTAssertTrue(normalized.contains("NAIVE"))
    }

    // MARK: - Edge Cases and Performance

    func testNormalizeEmptyString() {
        let result = TextNormalizer.normalize("")
        XCTAssertEqual(result, "")
    }

    func testNormalizeOnlyWhitespace() {
        let result = TextNormalizer.normalize("   \n\t   ")
        XCTAssertEqual(result, "")
    }

    func testNormalizeUnicodeCharacters() {
        let input = "Hello 世界"
        let result = TextNormalizer.normalize(input)

        // Should handle Unicode gracefully
        XCTAssertNotNil(result)
        XCTAssertTrue(result.contains("hello"))
    }

    func testNormalizeVeryLongString() {
        let input = String(repeating: "café ", count: 10000)
        let result = TextNormalizer.normalize(input)

        // Should handle large strings without crashing
        XCTAssertNotNil(result)
        XCTAssertTrue(result.contains("cafe"))
    }

    func testNormalizeSpecialCharacters() {
        let input = "@#$%^&*()_+-=[]{}|;':\",./<>?"
        let result = TextNormalizer.normalize(input)

        // Should handle special characters
        XCTAssertNotNil(result)
    }

    func testNormalizePhilosophicalQuote() {
        let quote = "The unexamined life is not worth living."
        let normalized = TextNormalizer.normalize(quote)

        XCTAssertEqual(normalized, "the unexamined life is not worth living.")
    }

    func testNormalizeQuoteWithDiacritics() {
        let quote = "Je pense, donc je suis. (René Descartes)"
        let normalized = TextNormalizer.normalize(quote)

        XCTAssertTrue(normalized.contains("je pense"))
        XCTAssertTrue(normalized.contains("rene descartes"))
        XCTAssertFalse(normalized.contains("é"))
    }

    func testNormalizeLatinQuote() {
        let quote = "Cogito, ergo sum."
        let normalized = TextNormalizer.normalize(quote)

        XCTAssertEqual(normalized, "cogito, ergo sum.")
    }

    func testNormalizationPerformance() {
        let text = String(repeating: "Café naïve résumé ", count: 1000)

        measure {
            _ = TextNormalizer.normalize(text)
        }
    }

    func testTokenExtractionPerformance() {
        let text = String(repeating: "Hello world test ", count: 1000)

        measure {
            _ = TextNormalizer.extractTokens(from: text)
        }
    }

    func testNormalizeGermanText() {
        let input = "Übung macht den Meister"
        let result = TextNormalizer.normalize(input)

        XCTAssertEqual(result, "ubung macht den meister")
    }

    func testNormalizeSpanishText() {
        let input = "¿Cómo estás?"
        let result = TextNormalizer.normalize(input)

        XCTAssertTrue(result.contains("como estas"))
    }

    func testNormalizeFrenchText() {
        let input = "C'est très français"
        let result = TextNormalizer.normalize(input)

        XCTAssertTrue(result.contains("tres francais"))
    }

    func testNormalizationIsIdempotent() {
        let input = "Café naïve"
        let normalized1 = TextNormalizer.normalize(input)
        let normalized2 = TextNormalizer.normalize(normalized1)

        // Normalizing twice should give same result
        XCTAssertEqual(normalized1, normalized2)
    }

    func testNormalizationIsDeterministic() {
        let input = "Café naïve résumé"

        let result1 = TextNormalizer.normalize(input)
        let result2 = TextNormalizer.normalize(input)
        let result3 = TextNormalizer.normalize(input)

        // Should always produce same output for same input
        XCTAssertEqual(result1, result2)
        XCTAssertEqual(result2, result3)
    }
}
