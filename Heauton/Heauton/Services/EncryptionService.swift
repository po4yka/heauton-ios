import CryptoKit
import Foundation
import OSLog
import Security

/// Service for encrypting and decrypting sensitive data using AES-GCM
actor EncryptionService: EncryptionServiceProtocol {
    private let logger = Logger(subsystem: AppConstants.Logging.subsystem, category: "Encryption")
    private let keychainKey = "com.heauton.encryption.key"

    // Key caching with expiration
    // Reduced from 60 seconds to 30 seconds to minimize security exposure
    private var cachedKey: SymmetricKey?
    private var keyExpirationTime: Date?
    private let keyCacheDuration: TimeInterval = 30 // 30 seconds

    // MARK: - Encryption/Decryption

    func encrypt(_ data: Data) async throws -> Data {
        let key = try await getOrCreateKey()

        do {
            let sealedBox = try AES.GCM.seal(data, using: key)
            guard let combined = sealedBox.combined else {
                throw EncryptionError.encryptionFailed
            }
            return combined
        } catch {
            logger.error("Encryption failed: \(error.localizedDescription)")
            throw EncryptionError.encryptionFailed
        }
    }

    func decrypt(_ encryptedData: Data) async throws -> Data {
        let key = try await getOrCreateKey()

        do {
            let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
            let decryptedData = try AES.GCM.open(sealedBox, using: key)
            return decryptedData
        } catch {
            logger.error("Decryption failed: \(error.localizedDescription)")
            throw EncryptionError.decryptionFailed
        }
    }

    // MARK: - Convenience Methods

    func encryptString(_ string: String) async throws -> Data {
        guard let data = string.data(using: .utf8) else {
            throw EncryptionError.invalidData
        }
        return try await encrypt(data)
    }

    func decryptString(_ encryptedData: Data) async throws -> String {
        let decryptedData = try await decrypt(encryptedData)
        guard let string = String(data: decryptedData, encoding: .utf8) else {
            throw EncryptionError.invalidData
        }
        return string
    }

    // MARK: - Key Management

    private func getOrCreateKey() async throws -> SymmetricKey {
        // Check if cached key is still valid
        if let key = cachedKey,
           let expiration = keyExpirationTime,
           Date.now < expiration {
            return key
        }

        // Clear expired key
        if cachedKey != nil {
            logger.debug("Encryption key cache expired, reloading from keychain")
            cachedKey = nil
            keyExpirationTime = nil
        }

        // Try to load from Keychain
        if let keyData = loadKeyFromKeychain() {
            let key = SymmetricKey(data: keyData)
            cacheKey(key)
            return key
        }

        // Generate new key
        let key = SymmetricKey(size: .bits256)
        try saveKeyToKeychain(key)
        cacheKey(key)

        logger.info("Generated new encryption key")
        return key
    }

    /// Caches the encryption key with expiration
    private func cacheKey(_ key: SymmetricKey) {
        cachedKey = key
        keyExpirationTime = Date.now.addingTimeInterval(keyCacheDuration)
    }

    /// Clears the cached encryption key
    /// Should be called when app goes to background for security
    func clearKeyCache() async {
        cachedKey = nil
        keyExpirationTime = nil
        logger.debug("Encryption key cache cleared")
    }

    private func saveKeyToKeychain(_ key: SymmetricKey) throws {
        let keyData = key.withUnsafeBytes { Data($0) }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: keychainKey,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            kSecValueData as String: keyData,
        ]

        // Delete any existing key first
        _ = SecItemDelete(query as CFDictionary)

        // Add new key
        let status = SecItemAdd(
            query as CFDictionary,
            nil
        )

        guard status == errSecSuccess else {
            logger.error("Failed to save key to Keychain: \(status)")
            throw EncryptionError.keychainError
        }
    }

    private func loadKeyFromKeychain() -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: keychainKey,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(
            query as CFDictionary,
            &result
        )

        guard status == errSecSuccess,
              let keyData = result as? Data else {
            return nil
        }

        return keyData
    }

    func deleteKey() async throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: keychainKey,
        ]

        let status = SecItemDelete(query as CFDictionary)

        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw EncryptionError.keychainError
        }

        cachedKey = nil
        logger.info("Deleted encryption key")
    }
}

// MARK: - Supporting Types

enum EncryptionError: Error, LocalizedError {
    case encryptionFailed
    case decryptionFailed
    case keychainError
    case invalidData

    var errorDescription: String? {
        switch self {
        case .encryptionFailed:
            "Failed to encrypt data"
        case .decryptionFailed:
            "Failed to decrypt data"
        case .keychainError:
            "Keychain operation failed"
        case .invalidData:
            "Invalid data format"
        }
    }
}
