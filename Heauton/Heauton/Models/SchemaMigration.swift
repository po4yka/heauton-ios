import Foundation
import SwiftData

// MARK: - SwiftData Migration Strategy

//
// This file defines the migration strategy for the Heauton app's SwiftData models.
//
// ## Why Migration Strategy is Critical
//
// Without an explicit migration strategy:
// - Schema changes cause data loss (SwiftData recreates the entire database)
// - Users lose ALL their quotes, journal entries, exercises, and progress
// - No rollback or recovery is possible
// - App updates become risky for users
//
// ## How to Use This Migration Strategy
//
// 1. **Current Version (V1)**: All existing models are defined in HeautonSchemaV1
//    - This represents the current state of the database
//    - All changes must be backward compatible within V1
//
// 2. **Future Versions**: When making breaking schema changes:
//    - Create HeautonSchemaV2, V3, etc.
//    - Add the new version to the `schemas` array in HeautonMigrationPlan
//    - Define migration stages to transform data from old to new schema
//
// 3. **Migration Stages**: Define how to transform data between versions
//    ```swift
//    static var stages: [MigrationStage] {
//        [
//            MigrationStage.custom(
//                fromVersion: HeautonSchemaV1.self,
//                toVersion: HeautonSchemaV2.self,
//                willMigrate: { context in
//                    // Pre-migration logic
//                },
//                didMigrate: { context in
//                    // Post-migration logic: transform data here
//                }
//            )
//        ]
//    }
//    ```
//
// ## Safe Schema Changes
//
// Within the same version, these changes are safe:
// - Adding optional properties with default values
// - Adding computed properties (no storage)
// - Changing property order
// - Adding new methods
//
// ## Breaking Changes Requiring New Version
//
// These changes require creating a new schema version and migration:
// - Removing properties
// - Changing property types
// - Changing property names (unless using @Attribute to maintain storage name)
// - Making optional properties required
// - Changing relationships between models
//
// ## Testing Migrations
//
// Before releasing schema changes:
// 1. Test migration with production-like data
// 2. Verify all data is preserved correctly
// 3. Test rollback scenarios
// 4. Monitor migration performance with large datasets
//
// ## References
//
// - Apple SwiftData Migration Guide: https://developer.apple.com/documentation/swiftdata/migrating-your-models
// - VersionedSchema: https://developer.apple.com/documentation/swiftdata/versionedschema
// - SchemaMigrationPlan: https://developer.apple.com/documentation/swiftdata/schemamigrationplan

// MARK: - Schema Versions

/// Version 1.0.0 - Initial Schema
///
/// This represents the baseline schema for the Heauton app.
/// All models present at the time of implementing the migration strategy.
///
/// Models included:
/// - Quote: Philosophical quotes with categorization and file storage support
/// - JournalEntry: User journal entries with encryption support
/// - Exercise: Wellness exercises (meditation, breathing, etc.)
/// - ExerciseSession: Tracking of completed exercise sessions
/// - JournalPrompt: Prompts for journal reflection
/// - UserEvent: Activity tracking and timeline events
/// - Achievement: User achievement tracking and gamification
/// - ProgressSnapshot: Daily wellness activity snapshots
/// - QuoteSchedule: Scheduling for daily quote delivery
/// - Share: Tracking of shared content
/// - SearchHistory: Search query history and analytics
enum HeautonSchemaV1: VersionedSchema {
    /// Version identifier using semantic versioning
    static var versionIdentifier = Schema.Version(1, 0, 0)

    /// All persistent models in this version
    static var models: [any PersistentModel.Type] {
        [
            Quote.self,
            JournalEntry.self,
            Exercise.self,
            ExerciseSession.self,
            JournalPrompt.self,
            UserEvent.self,
            Achievement.self,
            ProgressSnapshot.self,
            QuoteSchedule.self,
            Share.self,
            SearchHistory.self,
        ]
    }
}

// MARK: - Migration Plan

/// Heauton's complete migration plan
///
/// This defines all schema versions and the migration stages between them.
///
/// ## Current State
/// - Active Version: V1 (1.0.0)
/// - Migration Stages: None (baseline version)
///
/// ## Adding Future Versions
///
/// When creating version 2.0.0:
/// ```swift
/// enum HeautonSchemaV2: VersionedSchema {
///     static var versionIdentifier = Schema.Version(2, 0, 0)
///     static var models: [any PersistentModel.Type] {
///         [/* updated model types */]
///     }
/// }
///
/// // Add to schemas array:
/// static var schemas: [any VersionedSchema.Type] {
///     [HeautonSchemaV1.self, HeautonSchemaV2.self]
/// }
///
/// // Add migration stage:
/// static var stages: [MigrationStage] {
///     [
///         MigrationStage.custom(
///             fromVersion: HeautonSchemaV1.self,
///             toVersion: HeautonSchemaV2.self,
///             willMigrate: nil,
///             didMigrate: { context in
///                 // Transform data here
///             }
///         )
///     ]
/// }
/// ```
///
/// ## Migration Stage Types
///
/// 1. **Lightweight**: SwiftData handles automatically
///    - Use for simple additive changes
///    - Limited control over the process
///
/// 2. **Custom**: Full control over migration
///    - Required for complex transformations
///    - Can access both old and new model contexts
///    - Allows for data validation and cleanup
///
/// ## Best Practices
///
/// - Always test migrations with real user data
/// - Keep migration logic simple and focused
/// - Log migration progress for debugging
/// - Consider migration performance for large datasets
/// - Provide user feedback during long migrations
/// - Have a rollback strategy for failed migrations
enum HeautonMigrationPlan: SchemaMigrationPlan {
    /// All schema versions in chronological order
    ///
    /// IMPORTANT: Never remove versions from this array.
    /// Users may be migrating from any previous version.
    static var schemas: [any VersionedSchema.Type] {
        [
            HeautonSchemaV1.self,
            // Future versions will be added here:
            // HeautonSchemaV2.self,
            // HeautonSchemaV3.self,
        ]
    }

    /// Migration stages between versions
    ///
    /// Currently empty as V1 is the baseline version.
    /// Future migrations will be defined here.
    ///
    /// Example for V1 -> V2 migration:
    /// ```swift
    /// static var stages: [MigrationStage] {
    ///     [
    ///         MigrationStage.custom(
    ///             fromVersion: HeautonSchemaV1.self,
    ///             toVersion: HeautonSchemaV2.self,
    ///             willMigrate: { context in
    ///                 // Optional: Pre-migration setup
    ///                 print("Starting migration from V1 to V2")
    ///             },
    ///             didMigrate: { context in
    ///                 // Required: Transform the data
    ///                 let quotes = try context.fetch(FetchDescriptor<Quote>())
    ///                 for quote in quotes {
    ///                     // Apply transformations
    ///                 }
    ///                 try context.save()
    ///             }
    ///         )
    ///     ]
    /// }
    /// ```
    static var stages: [MigrationStage] {
        // Empty for baseline version V1
        // Migration stages will be added here when moving to V2, V3, etc.
        []
    }
}
