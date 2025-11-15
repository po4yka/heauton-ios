import Combine
import Foundation

/// Manages app settings with shared storage for widget access
@Observable
final class SettingsManager: SettingsManagerProtocol {
    /// Shared instance for easy access throughout the app
    /// Note: Prefer using AppDependencyContainer for dependency injection
    static let shared = SettingsManager()

    /// Widget refresh interval in minutes
    var widgetRefreshInterval: Int {
        didSet {
            UserDefaults.appGroup.set(
                widgetRefreshInterval,
                forKey: Keys.widgetRefreshInterval
            )
        }
    }

    private enum Keys {
        static let widgetRefreshInterval = "widgetRefreshInterval"
    }

    init() {
        // Load settings from UserDefaults, default to 30 minutes
        widgetRefreshInterval = UserDefaults.appGroup.integer(
            forKey: Keys.widgetRefreshInterval
        )

        // If no value set yet (returns 0), set default
        if widgetRefreshInterval == 0 {
            widgetRefreshInterval = 30
            UserDefaults.appGroup.set(
                30,
                forKey: Keys.widgetRefreshInterval
            )
        }
    }

    /// Available refresh interval options (in minutes)
    static let availableIntervals = [5, 10, 15, 30, 60, 120, 180, 360]

    /// Get the refresh interval in seconds (for Date calculations)
    var refreshIntervalInSeconds: TimeInterval {
        TimeInterval(widgetRefreshInterval * 60)
    }

    /// Human-readable description of the interval
    func intervalDescription(_ minutes: Int) -> String {
        if minutes < 60 {
            return "\(minutes) minutes"
        } else {
            let hours = minutes / 60
            return hours == 1 ? "1 hour" : "\(hours) hours"
        }
    }
}
