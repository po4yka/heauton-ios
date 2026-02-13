import Foundation

/// Thread safety utilities for detecting cross-thread access in debug builds
///
/// SwiftData models are Sendable, but mutable model access is still concurrency-sensitive.
/// These utilities help detect thread safety violations during development.
enum ThreadSafety {
    /// Asserts that code is running on the main thread
    /// - Parameter message: Custom message for the assertion
    ///
    /// Use this in model setters or critical sections that must run on MainActor:
    /// ```swift
    /// var title: String {
    ///     willSet {
    ///         ThreadSafety.assertMainThread("JournalEntry.title must be modified on main thread")
    ///     }
    /// }
    /// ```
    static func assertMainThread(
        _: String = "Must be called on main thread",
        file _: StaticString = #file,
        line _: UInt = #line
    ) {
        #if DEBUG
        dispatchPrecondition(condition: .onQueue(.main))
        #endif
    }

    /// Asserts that code is NOT running on the main thread
    /// - Parameter message: Custom message for the assertion
    ///
    /// Use this for background operations that should not block the UI:
    /// ```swift
    /// func processLargeData() {
    ///     ThreadSafety.assertBackgroundThread("Heavy processing should not run on main thread")
    ///     // ... expensive operations
    /// }
    /// ```
    static func assertBackgroundThread(
        _: String = "Should not be called on main thread",
        file _: StaticString = #file,
        line _: UInt = #line
    ) {
        #if DEBUG
        dispatchPrecondition(condition: .notOnQueue(.main))
        #endif
    }
}

// MARK: - SwiftData Model Thread Safety Documentation

/*
 SwiftData Thread Safety Notes:

 SwiftData models are Sendable, but safe mutation rules still apply:

 1. Model instances are mutable reference types
 2. Cross-context writes can still produce races if not isolated
 3. Mutation should remain in MainActor-isolated flows or a single owned context

 IMPORTANT RULES:

 - [OK] READ operations can happen on any thread via ModelContext
 - [NO] WRITE operations (mutations) should ONLY happen via MainActor-isolated code
 - [OK] All services that modify models are properly isolated (using @MainActor or actor)
 - [NO] Never pass mutable models between concurrent contexts

 To verify thread safety in development:

 1. Enable Thread Sanitizer in Xcode scheme (Product > Scheme > Edit Scheme > Diagnostics)
 2. Run tests and look for data race warnings
 3. Use ThreadSafety.assertMainThread() in critical model mutations

 Example of proper usage:

 ```swift
 // [OK] SAFE: Mutation in @MainActor context
 @MainActor
 func updateJournalEntry(_ entry: JournalEntry, title: String) {
     entry.title = title  // Safe: on MainActor
 }

 // [NO] UNSAFE: Mutation in background context
 Task.detached {
     entry.title = "New Title"  // Data race!
 }

 // [OK] SAFE: Mutation inside MainActor.run
 Task.detached {
     await MainActor.run {
         entry.title = "New Title"  // Safe: on MainActor
     }
 }
 ```
 */
