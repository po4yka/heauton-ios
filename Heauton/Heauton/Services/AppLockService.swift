import Foundation
import LocalAuthentication
import OSLog

/// Service for managing app lock and biometric authentication
actor AppLockService: AppLockServiceProtocol {
    private let logger = Logger(subsystem: AppConstants.Logging.subsystem, category: "AppLock")

    private var isUnlocked = false
    private var lastUnlockTime: Date?

    // Lock timeout: 5 minutes
    private let lockTimeout: TimeInterval = 5 * 60

    // MARK: - Authentication

    func authenticate() async throws -> Bool {
        let context = LAContext()
        var error: NSError?

        // Check if biometrics are available
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            // Fall back to device passcode
            return try await authenticateWithPasscode(context: context)
        }

        do {
            let reason = "Unlock Heauton to access your journal"
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )

            if success {
                isUnlocked = true
                lastUnlockTime = Date.now
            }

            return success
        } catch {
            logger.error("Biometric authentication failed: \(error.localizedDescription)")
            // Try passcode as fallback
            return try await authenticateWithPasscode(context: context)
        }
    }

    private func authenticateWithPasscode(context: LAContext) async throws -> Bool {
        let reason = "Unlock Heauton to access your journal"

        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: reason
            )

            if success {
                isUnlocked = true
                lastUnlockTime = Date.now
            }

            return success
        } catch {
            logger.error("Passcode authentication failed: \(error.localizedDescription)")
            throw AppLockError.authenticationFailed
        }
    }

    // MARK: - Lock State

    /// Checks if app is currently unlocked without modifying state
    /// This is a pure query function that doesn't mutate state
    func isAppUnlocked() async -> Bool {
        // Check if app is unlocked and hasn't timed out
        guard isUnlocked, let lastUnlock = lastUnlockTime else {
            return false
        }

        let timeSinceUnlock = Date.now.timeIntervalSince(lastUnlock)
        return timeSinceUnlock <= lockTimeout
    }

    /// Checks if app should be locked and locks it if timeout exceeded
    /// Returns true if app is unlocked, false if locked
    func checkAndLockIfNeeded() async -> Bool {
        guard isUnlocked, let lastUnlock = lastUnlockTime else {
            return false
        }

        let timeSinceUnlock = Date.now.timeIntervalSince(lastUnlock)
        if timeSinceUnlock > self.lockTimeout {
            logger.info("App lock timeout exceeded (\(Int(timeSinceUnlock))s > \(Int(self.lockTimeout))s), locking app")
            await lockApp()
            return false
        }

        return true
    }

    /// Explicitly locks the app
    func lockApp() async {
        isUnlocked = false
        lastUnlockTime = nil
        logger.debug("App locked")
    }

    /// Updates the last activity timestamp to keep the app unlocked
    /// Call this on user interaction to prevent timeout
    func updateLastActivity() async {
        if isUnlocked {
            lastUnlockTime = Date.now
        }
    }

    // MARK: - Biometric Availability

    func biometricType() async -> BiometricType {
        let context = LAContext()
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return .none
        }

        switch context.biometryType {
        case .faceID:
            return .faceID
        case .touchID:
            return .touchID
        case .opticID:
            return .opticID
        case .none:
            return .none
        @unknown default:
            return .none
        }
    }

    func isBiometricAvailable() async -> Bool {
        let context = LAContext()
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }
}

// MARK: - Supporting Types

enum BiometricType {
    case faceID
    case touchID
    case opticID
    case none

    var displayName: String {
        switch self {
        case .faceID: "Face ID"
        case .touchID: "Touch ID"
        case .opticID: "Optic ID"
        case .none: "Passcode"
        }
    }

    var icon: String {
        switch self {
        case .faceID: "faceid"
        case .touchID: "touchid"
        case .opticID: "opticid"
        case .none: "lock"
        }
    }
}

enum AppLockError: Error {
    case authenticationFailed
    case biometricsNotAvailable

    var localizedDescription: String {
        switch self {
        case .authenticationFailed:
            "Authentication failed. Please try again."
        case .biometricsNotAvailable:
            "Biometric authentication is not available on this device."
        }
    }
}
