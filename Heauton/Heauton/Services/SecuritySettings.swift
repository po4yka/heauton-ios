import Foundation
import Observation
import OSLog
import Security

/// Security and privacy settings with critical flags stored in Keychain
@Observable
final class SecuritySettings {
    static let shared = SecuritySettings()

    private let logger = Logger(subsystem: AppConstants.Logging.subsystem, category: "SecuritySettings")
    private let keychainManager = KeychainSecurityManager()

    // MARK: - Settings

    /// Enable app lock with biometrics (stored in Keychain)
    var isAppLockEnabled: Bool {
        get { keychainManager.isAppLockEnabled }
        set { keychainManager.isAppLockEnabled = newValue }
    }

    /// Lock app when entering background (stored in Keychain)
    var lockOnBackground: Bool {
        get { keychainManager.lockOnBackground }
        set { keychainManager.lockOnBackground = newValue }
    }

    /// Require authentication for journal access (stored in Keychain)
    var requireAuthForJournal: Bool {
        get { keychainManager.requireAuthForJournal }
        set { keychainManager.requireAuthForJournal = newValue }
    }

    /// Hide sensitive content in app switcher (stored in Keychain)
    var hideInAppSwitcher: Bool {
        get { keychainManager.hideInAppSwitcher }
        set { keychainManager.hideInAppSwitcher = newValue }
    }

    /// Disable screenshots in sensitive views (stored in Keychain)
    var disableScreenshots: Bool {
        get { keychainManager.disableScreenshots }
        set { keychainManager.disableScreenshots = newValue }
    }

    private init() {
        logger.info("SecuritySettings initialized with Keychain storage")
    }

    // MARK: - Methods

    func resetToDefaults() {
        logger.info("Resetting security settings to defaults")
        isAppLockEnabled = false
        lockOnBackground = true
        requireAuthForJournal = true
        hideInAppSwitcher = true
        disableScreenshots = false
    }
}

// MARK: - Keychain Security Manager

/// Manages security settings in Keychain with UserDefaults migration
private final class KeychainSecurityManager {
    private let logger = Logger(subsystem: AppConstants.Logging.subsystem, category: "KeychainSecurityManager")
    private let defaults = UserDefaults(suiteName: SharedModelContainer.appGroupIdentifier)

    // Keychain keys for security settings
    private let keychainPrefix = "com.heauton.security."
    private let migrationKey = "com.heauton.security.migrated"

    // Setting keys
    private enum SettingKey: String, CaseIterable {
        case isAppLockEnabled
        case lockOnBackground
        case requireAuthForJournal
        case hideInAppSwitcher
        case disableScreenshots

        var keychainKey: String {
            "com.heauton.security.\(rawValue)"
        }

        var userDefaultsKey: String {
            rawValue
        }

        var defaultValue: Bool {
            switch self {
            case .isAppLockEnabled: false
            case .lockOnBackground: true
            case .requireAuthForJournal: true
            case .hideInAppSwitcher: true
            case .disableScreenshots: false
            }
        }
    }

    init() {
        // Migrate from UserDefaults to Keychain on first launch
        migrateFromUserDefaults()
    }

    // MARK: - Properties

    var isAppLockEnabled: Bool {
        get { getBool(for: .isAppLockEnabled) }
        set { setBool(newValue, for: .isAppLockEnabled) }
    }

    var lockOnBackground: Bool {
        get { getBool(for: .lockOnBackground) }
        set { setBool(newValue, for: .lockOnBackground) }
    }

    var requireAuthForJournal: Bool {
        get { getBool(for: .requireAuthForJournal) }
        set { setBool(newValue, for: .requireAuthForJournal) }
    }

    var hideInAppSwitcher: Bool {
        get { getBool(for: .hideInAppSwitcher) }
        set { setBool(newValue, for: .hideInAppSwitcher) }
    }

    var disableScreenshots: Bool {
        get { getBool(for: .disableScreenshots) }
        set { setBool(newValue, for: .disableScreenshots) }
    }

    // MARK: - Keychain Operations

    private func getBool(for key: SettingKey) -> Bool {
        guard let data = loadFromKeychain(key: key.keychainKey) else {
            return key.defaultValue
        }

        // Convert data to bool
        guard data.count == 1 else {
            logger.error("Invalid data size for \(key.rawValue)")
            return key.defaultValue
        }

        return data[0] != 0
    }

    private func setBool(_ value: Bool, for key: SettingKey) {
        let data = Data([value ? 1 : 0])

        do {
            try saveToKeychain(data: data, key: key.keychainKey)
            logger.debug("Saved \(key.rawValue) = \(value) to Keychain")
        } catch {
            logger.error("Failed to save \(key.rawValue) to Keychain: \(error.localizedDescription)")
        }
    }

    private func saveToKeychain(data: Data, key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            kSecValueData as String: data,
        ]

        // Delete any existing item first
        SecItemDelete(query as CFDictionary)

        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)

        guard status == errSecSuccess else {
            logger.error("Failed to save to Keychain: \(status)")
            throw KeychainError.saveFailed(status)
        }
    }

    private func loadFromKeychain(key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess, let data = result as? Data else {
            if status != errSecItemNotFound {
                logger.error("Failed to load from Keychain: \(status)")
            }
            return nil
        }

        return data
    }

    // MARK: - Migration

    private func migrateFromUserDefaults() {
        // Check if migration already completed
        if loadFromKeychain(key: migrationKey) != nil {
            logger.debug("Security settings already migrated to Keychain")
            return
        }

        logger.info("Migrating security settings from UserDefaults to Keychain")

        // Migrate each setting
        for settingKey in SettingKey.allCases {
            if let userDefaultsValue = defaults?.object(forKey: settingKey.userDefaultsKey) as? Bool {
                logger.debug("Migrating \(settingKey.rawValue): \(userDefaultsValue)")
                setBool(userDefaultsValue, for: settingKey)

                // Remove from UserDefaults after successful migration
                defaults?.removeObject(forKey: settingKey.userDefaultsKey)
            } else {
                // No existing value, use default
                logger.debug("No existing value for \(settingKey.rawValue), using default: \(settingKey.defaultValue)")
                setBool(settingKey.defaultValue, for: settingKey)
            }
        }

        // Mark migration as complete
        let migrationData = Data([1])
        do {
            try saveToKeychain(data: migrationData, key: migrationKey)
            logger.info("Security settings migration completed successfully")
        } catch {
            logger.error("Failed to mark migration as complete: \(error.localizedDescription)")
        }
    }
}

// MARK: - Keychain Error

private enum KeychainError: Error, LocalizedError {
    case saveFailed(OSStatus)
    case loadFailed(OSStatus)
    case invalidData

    var errorDescription: String? {
        switch self {
        case .saveFailed(let status):
            "Failed to save to Keychain (status: \(status))"
        case .loadFailed(let status):
            "Failed to load from Keychain (status: \(status))"
        case .invalidData:
            "Invalid data format in Keychain"
        }
    }
}
