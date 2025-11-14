import CryptoKit
import Foundation
@testable import Heauton
import Testing

@Suite("EncryptionService Tests")
struct EncryptionServiceTests {
    // MARK: - Basic Encryption/Decryption Tests

    @Test("Encrypt and decrypt string successfully", .disabled("Keychain access not available in test environment"))
    func encryptDecryptString() async throws {
        let service = EncryptionService()
        let originalString = "Hello, Heauton! This is a test message."

        let encryptedData = try await service.encryptString(originalString)

        #expect(encryptedData != originalString.data(using: .utf8)!)
        #expect(!encryptedData.isEmpty)

        let decryptedString = try await service.decryptString(encryptedData)

        #expect(decryptedString == originalString)
    }

    @Test("Encrypt and decrypt data successfully", .disabled("Keychain access not available in test environment"))
    func encryptDecryptData() async throws {
        let service = EncryptionService()
        let originalData = Data("Test data for encryption".utf8)

        let encryptedData = try await service.encrypt(originalData)

        #expect(encryptedData != originalData)
        #expect(encryptedData.count > originalData.count)

        let decryptedData = try await service.decrypt(encryptedData)

        #expect(decryptedData == originalData)
    }

    @Test("Encrypt empty string", .disabled("Keychain access not available in test environment"))
    func encryptEmptyString() async throws {
        let service = EncryptionService()
        let emptyString = ""

        let encryptedData = try await service.encryptString(emptyString)
        #expect(!encryptedData.isEmpty)

        let decryptedString = try await service.decryptString(encryptedData)
        #expect(decryptedString == emptyString)
    }

    @Test("Encrypt large text", .disabled("Keychain access not available in test environment"))
    func encryptLargeText() async throws {
        let service = EncryptionService()
        let largeText = String(repeating: "Lorem ipsum dolor sit amet. ", count: 1000)

        let encryptedData = try await service.encryptString(largeText)
        let decryptedString = try await service.decryptString(encryptedData)

        #expect(decryptedString == largeText)
    }

    @Test("Encrypt text with special characters", .disabled("Keychain access not available in test environment"))
    func encryptSpecialCharacters() async throws {
        let service = EncryptionService()
        let specialText = "Hello! Привет! 你好! Special chars: @#$%^&*(){}[]"

        let encryptedData = try await service.encryptString(specialText)
        let decryptedString = try await service.decryptString(encryptedData)

        #expect(decryptedString == specialText)
    }

    // MARK: - Security Tests

    @Test(
        "Encrypted data should be different each time (non-deterministic)",
        .disabled("Keychain access not available in test environment")
    )
    func encryptionNonDeterministic() async throws {
        let service = EncryptionService()
        let originalString = "Same message encrypted twice"

        let encrypted1 = try await service.encryptString(originalString)
        let encrypted2 = try await service.encryptString(originalString)

        #expect(encrypted1 != encrypted2)

        let decrypted1 = try await service.decryptString(encrypted1)
        let decrypted2 = try await service.decryptString(encrypted2)

        #expect(decrypted1 == originalString)
        #expect(decrypted2 == originalString)
    }

    @Test("Decrypting corrupted data should fail", .disabled("Keychain access not available in test environment"))
    func decryptCorruptedData() async throws {
        let service = EncryptionService()
        let corruptedData = Data([1, 2, 3, 4, 5, 6, 7, 8, 9, 10])

        await #expect(throws: EncryptionError.self) {
            try await service.decrypt(corruptedData)
        }
    }

    @Test("Decrypting tampered data should fail", .disabled("Keychain access not available in test environment"))
    func decryptTamperedData() async throws {
        let service = EncryptionService()
        let originalString = "This will be tampered with"

        var encryptedData = try await service.encryptString(originalString)

        // Tamper with the encrypted data
        encryptedData[encryptedData.count / 2] ^= 0xFF

        await #expect(throws: EncryptionError.self) {
            try await service.decryptString(encryptedData)
        }
    }

    // MARK: - Key Management Tests

    @Test("Multiple encryption operations use same key", .disabled("Keychain access not available in test environment"))
    func consistentKeyUsage() async throws {
        let service = EncryptionService()

        let message1 = "First message"
        let message2 = "Second message"

        let encrypted1 = try await service.encryptString(message1)
        let encrypted2 = try await service.encryptString(message2)

        let decrypted1 = try await service.decryptString(encrypted1)
        let decrypted2 = try await service.decryptString(encrypted2)

        #expect(decrypted1 == message1)
        #expect(decrypted2 == message2)
    }

    @Test("Key deletion prevents decryption", .disabled("Keychain access not available in test environment"))
    func keyDeletionPreventsDecryption() async throws {
        let service = EncryptionService()
        let originalString = "This will become unrecoverable"

        let encryptedData = try await service.encryptString(originalString)

        try await service.deleteKey()

        await #expect(throws: EncryptionError.self) {
            try await service.decryptString(encryptedData)
        }
    }

    // MARK: - Edge Cases

    @Test("Encrypt and decrypt journal entry scenario", .disabled("Keychain access not available in test environment"))
    func journalEntryEncryption() async throws {
        let service = EncryptionService()
        let journalEntry = """
        Today I reflected on Marcus Aurelius's wisdom:
        "You have power over your mind - not outside events.
        Realize this, and you will find strength."

        This helped me find peace during a challenging day.
        """

        let encryptedData = try await service.encryptString(journalEntry)
        let decryptedEntry = try await service.decryptString(encryptedData)

        #expect(decryptedEntry == journalEntry)
    }

    @Test(
        "Encrypt multiline text with various formatting",
        .disabled("Keychain access not available in test environment")
    )
    func encryptMultilineText() async throws {
        let service = EncryptionService()
        let multilineText = """
        Line 1

        Line 3 (with blank line above)
        \tTabbed line
        Spaced    line
        """

        let encryptedData = try await service.encryptString(multilineText)
        let decryptedText = try await service.decryptString(encryptedData)

        #expect(decryptedText == multilineText)
    }
}
