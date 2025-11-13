import Foundation
import SwiftUI

/// ViewModel for SecuritySettingsView following MVVM + @Observable pattern
/// Handles security settings and biometric authentication
@Observable
@MainActor
final class SecuritySettingsViewModel {
    // MARK: - Dependencies

    private let appLockService: AppLockServiceProtocol

    // MARK: - Published State

    var biometricType: BiometricType = .none
    var isBiometricAvailable = false

    // MARK: - Computed Properties

    var biometricDisplayName: String {
        biometricType.displayName
    }

    var authenticationFooterText: String {
        if isBiometricAvailable {
            "Protect your journal with \(biometricType.displayName)"
        } else {
            "Set up \(biometricType.displayName) in Settings to enable app lock"
        }
    }

    var showBiometricUnavailableWarning: Bool {
        !isBiometricAvailable
    }

    // MARK: - Initialization

    init(appLockService: AppLockServiceProtocol) {
        self.appLockService = appLockService
    }

    // MARK: - Public Methods

    /// Load biometric capabilities
    func loadBiometricCapabilities() async {
        biometricType = await appLockService.biometricType()
        isBiometricAvailable = await appLockService.isBiometricAvailable()
    }
}
