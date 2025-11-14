import Foundation
import OSLog

/// Retry policy configuration for background tasks
struct RetryPolicy {
    /// Maximum number of retry attempts
    let maxAttempts: Int

    /// Initial delay between retries
    let initialDelay: TimeInterval

    /// Backoff multiplier for exponential backoff
    let backoffMultiplier: Double

    /// Maximum delay between retries
    let maxDelay: TimeInterval

    /// Default retry policy: 3 attempts with exponential backoff
    static let `default` = RetryPolicy(
        maxAttempts: AppConstants.Retry.maxBackgroundTaskRetries,
        initialDelay: AppConstants.Retry.retryDelay,
        backoffMultiplier: AppConstants.Retry.backoffMultiplier,
        maxDelay: 60
    )

    /// Aggressive retry policy for critical operations
    static let aggressive = RetryPolicy(
        maxAttempts: 5,
        initialDelay: 2,
        backoffMultiplier: 1.5,
        maxDelay: 30
    )

    /// Conservative retry policy for non-critical operations
    static let conservative = RetryPolicy(
        maxAttempts: 2,
        initialDelay: 10,
        backoffMultiplier: 2.0,
        maxDelay: 60
    )

    /// Calculates the delay for a given attempt number
    /// Uses exponential backoff: delay = initialDelay * (backoffMultiplier ^ attemptNumber)
    /// - Parameter attemptNumber: The current attempt number (0-based)
    /// - Returns: Delay in seconds, capped at maxDelay
    func delay(for attemptNumber: Int) -> TimeInterval {
        let exponentialDelay = initialDelay * pow(backoffMultiplier, Double(attemptNumber))
        return min(exponentialDelay, maxDelay)
    }
}

/// Retry utility for executing operations with automatic retries
///
/// # Exponential Backoff Algorithm
///
/// This implements exponential backoff with configurable parameters:
///
/// ```
/// delay = min(initialDelay * (multiplier ^ attemptNumber), maxDelay)
/// ```
///
/// ## Example Timeline (default policy)
///
/// - Attempt 1: Execute immediately
/// - Attempt 1 fails → Wait 5s
/// - Attempt 2: Execute after 5s
/// - Attempt 2 fails → Wait 10s (5 * 2^1)
/// - Attempt 3: Execute after 10s
/// - Attempt 3 fails → Give up
///
/// ## Why Exponential Backoff?
///
/// 1. **Reduces load**: Gives systems time to recover
/// 2. **Avoids thundering herd**: Spreads retry attempts over time
/// 3. **Adaptive**: Longer delays for persistent failures
///
/// ## Design Decisions
///
/// - **Max delay cap**: Prevents indefinitely long waits
/// - **Attempt limit**: Prevents infinite retry loops
/// - **Immediate first attempt**: No initial delay
enum RetryUtility {
    private static let logger = Logger(
        subsystem: AppConstants.Logging.subsystem,
        category: "Retry"
    )

    /// Executes an async operation with automatic retries
    ///
    /// - Parameters:
    ///   - policy: Retry policy to use
    ///   - operation: The async operation to execute
    /// - Returns: Result of the operation
    /// - Throws: Last error encountered if all retries fail
    static func execute<T>(
        policy: RetryPolicy = .default,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        var lastError: Error?
        var attemptNumber = 0

        while attemptNumber < policy.maxAttempts {
            do {
                let result = try await operation()
                if attemptNumber > 0 {
                    logger.info("Operation succeeded after \(attemptNumber) retries")
                }
                return result
            } catch {
                lastError = error
                attemptNumber += 1

                if attemptNumber < policy.maxAttempts {
                    let delay = policy.delay(for: attemptNumber - 1)
                    logger.warning("Operation failed (attempt \(attemptNumber)/\(policy.maxAttempts)), retrying in \(Int(delay))s: \(error.localizedDescription)")

                    try? await Task.sleep(for: .seconds(delay))
                } else {
                    logger.error("Operation failed after \(attemptNumber) attempts: \(error.localizedDescription)")
                }
            }
        }

        throw lastError ?? RetryError.maxAttemptsExceeded
    }

    /// Executes an async operation with automatic retries and returns optional result
    ///
    /// - Parameters:
    ///   - policy: Retry policy to use
    ///   - operation: The async operation to execute
    /// - Returns: Result of the operation, or nil if all retries fail
    static func executeOptional<T>(
        policy: RetryPolicy = .default,
        operation: @escaping () async throws -> T
    ) async -> T? {
        try? await execute(policy: policy, operation: operation)
    }

    /// Executes an async operation with retry and returns a Result type
    ///
    /// - Parameters:
    ///   - policy: Retry policy to use
    ///   - operation: The async operation to execute
    /// - Returns: Result containing either the value or error
    static func executeWithResult<T>(
        policy: RetryPolicy = .default,
        operation: @escaping () async throws -> T
    ) async -> Result<T, Error> {
        do {
            let result = try await execute(policy: policy, operation: operation)
            return .success(result)
        } catch {
            return .failure(error)
        }
    }
}

// MARK: - Retry Errors

enum RetryError: LocalizedError {
    case maxAttemptsExceeded
    case operationCancelled

    var errorDescription: String? {
        switch self {
        case .maxAttemptsExceeded:
            "Maximum retry attempts exceeded"
        case .operationCancelled:
            "Operation was cancelled"
        }
    }
}

// MARK: - Retryable Protocol

/// Protocol for errors that can indicate whether retry should be attempted
protocol RetryableError: Error {
    /// Whether this error warrants a retry
    var shouldRetry: Bool { get }
}

// MARK: - Common Error Extensions

extension URLError: RetryableError {
    var shouldRetry: Bool {
        switch code {
        case .timedOut, .cannotConnectToHost, .networkConnectionLost, .notConnectedToInternet:
            true
        case .cancelled, .badURL, .unsupportedURL:
            false
        default:
            true
        }
    }
}

extension RetryUtility {
    /// Executes an async operation with smart retry (respects RetryableError)
    ///
    /// - Parameters:
    ///   - policy: Retry policy to use
    ///   - operation: The async operation to execute
    /// - Returns: Result of the operation
    /// - Throws: Last error encountered
    static func executeWithSmartRetry<T>(
        policy: RetryPolicy = .default,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        var lastError: Error?
        var attemptNumber = 0

        while attemptNumber < policy.maxAttempts {
            do {
                return try await operation()
            } catch let error as RetryableError {
                lastError = error
                attemptNumber += 1

                guard error.shouldRetry else {
                    logger.info("Error is not retryable, failing immediately")
                    throw error
                }

                if attemptNumber < policy.maxAttempts {
                    let delay = policy.delay(for: attemptNumber - 1)
                    logger.warning("Retryable error (attempt \(attemptNumber)/\(policy.maxAttempts)), retrying in \(Int(delay))s")
                    try? await Task.sleep(for: .seconds(delay))
                }
            } catch {
                // Non-retryable error
                logger.error("Non-retryable error encountered: \(error.localizedDescription)")
                throw error
            }
        }

        throw lastError ?? RetryError.maxAttemptsExceeded
    }
}
