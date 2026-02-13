import Foundation
import OSLog

extension UserDefaults {
    private static let logger = Logger(subsystem: AppConstants.Logging.subsystem, category: "UserDefaults")

    /// Shared UserDefaults instance for the App Group
    /// This allows both the main app and widget to access the same settings
    /// Falls back to standard UserDefaults if App Group is not available
    static var appGroup: UserDefaults {
        guard let defaults = UserDefaults(
            suiteName: SharedModelContainer.appGroupIdentifier
        ) else {
            logger.warning("Failed to create UserDefaults for App Group, using standard defaults")
            return UserDefaults.standard
        }
        return defaults
    }

    /// Attempts to get App Group UserDefaults, returns nil if not available
    /// Use this when you need to explicitly handle the failure case
    static var appGroupOrNil: UserDefaults? {
        guard let defaults = UserDefaults(
            suiteName: SharedModelContainer.appGroupIdentifier
        ) else {
            logger.error("App Group UserDefaults not available")
            return nil
        }
        return defaults
    }
}
