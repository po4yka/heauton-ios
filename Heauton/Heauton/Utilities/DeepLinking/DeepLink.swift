import Foundation

/// Represents a deep link destination within the app
///
/// # Deep Link Architecture
///
/// Deep links use a custom URL scheme to navigate to specific content:
/// - `heauton://quote/{uuid}` - Navigate to specific quote
/// - `heauton://journal/{uuid}` - Navigate to journal entry
/// - `heauton://exercise/{uuid}` - Navigate to exercise
/// - `heauton://tab/{name}` - Navigate to specific tab
///
/// ## URL Format
/// ```
/// heauton://[destination]/[identifier]?[parameters]
/// ```
///
/// ## Examples
/// ```swift
/// // Navigate to quote detail
/// heauton://quote/550e8400-e29b-41d4-a716-446655440000
///
/// // Navigate to journal entry
/// heauton://journal/550e8400-e29b-41d4-a716-446655440000
///
/// // Navigate to tab
/// heauton://tab/home
/// heauton://tab/journal
/// ```
enum DeepLink: Equatable, Hashable {
    /// Navigate to a specific quote detail view
    case quote(UUID)

    /// Navigate to a specific journal entry
    case journal(UUID)

    /// Navigate to a specific exercise
    case exercise(UUID)

    /// Navigate to a specific tab
    case tab(TabDestination)

    /// Navigate to settings
    case settings

    /// Unknown or invalid deep link
    case unknown

    /// Tab destinations
    enum TabDestination: String, CaseIterable {
        case home
        case journal
        case exercises
        case add
        case library
        case progress

        var tabIndex: Int {
            switch self {
            case .home: 0
            case .journal: 1
            case .exercises: 2
            case .add: 3
            case .library: 4
            case .progress: 5
            }
        }
    }

    // MARK: - URL Construction

    /// The URL scheme for the app
    static let scheme = "heauton"

    /// Converts this deep link to a URL
    var url: URL? {
        var components = URLComponents()
        components.scheme = DeepLink.scheme

        switch self {
        case .quote(let id):
            components.host = "quote"
            components.path = "/\(id.uuidString)"

        case .journal(let id):
            components.host = "journal"
            components.path = "/\(id.uuidString)"

        case .exercise(let id):
            components.host = "exercise"
            components.path = "/\(id.uuidString)"

        case .tab(let destination):
            components.host = "tab"
            components.path = "/\(destination.rawValue)"

        case .settings:
            components.host = "settings"

        case .unknown:
            return nil
        }

        return components.url
    }

    // MARK: - URL Parsing

    /// Parses a URL into a deep link
    /// - Parameter url: The URL to parse
    /// - Returns: A DeepLink if the URL is valid, nil otherwise
    static func parse(from url: URL) -> DeepLink? {
        guard url.scheme == scheme else {
            return nil
        }

        guard let host = url.host else {
            return .unknown
        }

        // Extract the path component (remove leading slash)
        let pathComponent = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))

        return parseHost(host, pathComponent: pathComponent)
    }

    /// Parses the URL host and path component into a deep link
    /// - Parameters:
    ///   - host: The URL host (e.g., "quote", "journal")
    ///   - pathComponent: The path component without leading slash
    /// - Returns: The corresponding DeepLink
    private static func parseHost(_ host: String, pathComponent: String) -> DeepLink {
        switch host {
        case "quote":
            parseUUIDDeepLink(pathComponent, constructor: DeepLink.quote)
        case "journal":
            parseUUIDDeepLink(pathComponent, constructor: DeepLink.journal)
        case "exercise":
            parseUUIDDeepLink(pathComponent, constructor: DeepLink.exercise)
        case "tab":
            parseTabDeepLink(pathComponent)
        case "settings":
            .settings
        default:
            .unknown
        }
    }

    /// Parses a UUID-based deep link (quote, journal, exercise)
    /// - Parameters:
    ///   - pathComponent: The path component containing the UUID
    ///   - constructor: The DeepLink case constructor
    /// - Returns: DeepLink with UUID or .unknown if invalid
    private static func parseUUIDDeepLink(
        _ pathComponent: String,
        constructor: (UUID) -> DeepLink
    ) -> DeepLink {
        guard let uuid = UUID(uuidString: pathComponent) else {
            return .unknown
        }
        return constructor(uuid)
    }

    /// Parses a tab deep link
    /// - Parameter pathComponent: The path component containing the tab name
    /// - Returns: DeepLink.tab or .unknown if invalid
    private static func parseTabDeepLink(_ pathComponent: String) -> DeepLink {
        guard let destination = TabDestination(rawValue: pathComponent) else {
            return .unknown
        }
        return .tab(destination)
    }

    // MARK: - Notification UserInfo

    /// Creates a deep link from notification userInfo dictionary
    /// - Parameter userInfo: The notification userInfo dictionary
    /// - Returns: A DeepLink if valid quote ID found, nil otherwise
    static func fromNotification(userInfo: [AnyHashable: Any]) -> DeepLink? {
        // Check for quoteID in userInfo
        if let quoteIDString = userInfo["quoteID"] as? String,
           let quoteID = UUID(uuidString: quoteIDString) {
            return .quote(quoteID)
        }

        // Check for journalID
        if let journalIDString = userInfo["journalID"] as? String,
           let journalID = UUID(uuidString: journalIDString) {
            return .journal(journalID)
        }

        // Check for exerciseID
        if let exerciseIDString = userInfo["exerciseID"] as? String,
           let exerciseID = UUID(uuidString: exerciseIDString) {
            return .exercise(exerciseID)
        }

        return nil
    }
}

// MARK: - DeepLink CustomStringConvertible

extension DeepLink: CustomStringConvertible {
    var description: String {
        switch self {
        case .quote(let id):
            "quote(\(id))"
        case .journal(let id):
            "journal(\(id))"
        case .exercise(let id):
            "exercise(\(id))"
        case .tab(let destination):
            "tab(\(destination.rawValue))"
        case .settings:
            "settings"
        case .unknown:
            "unknown"
        }
    }
}
