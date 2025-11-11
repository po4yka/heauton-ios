import Foundation
import SwiftData

/// Sort options for quotes
enum QuoteSortOption: String, Codable, CaseIterable {
    case newest
    case oldest
    case author
    case mostRead
    case random

    var displayName: String {
        switch self {
        case .newest: "Newest First"
        case .oldest: "Oldest First"
        case .author: "Author A-Z"
        case .mostRead: "Most Read"
        case .random: "Random"
        }
    }
}

/// Date range for filtering
struct DateRange: Codable, Equatable {
    var start: Date
    var end: Date
}

/// Model for filtering and sorting quotes
struct QuoteFilter: Codable, Equatable {
    var searchText: String?
    var authors: Set<String>
    var categories: Set<String>
    var tags: Set<String>
    var moods: Set<String>
    var isFavoriteOnly: Bool
    var dateRange: DateRange?
    var sortBy: QuoteSortOption

    init(
        searchText: String? = nil,
        authors: Set<String> = [],
        categories: Set<String> = [],
        tags: Set<String> = [],
        moods: Set<String> = [],
        isFavoriteOnly: Bool = false,
        dateRange: DateRange? = nil,
        sortBy: QuoteSortOption = .newest
    ) {
        self.searchText = searchText
        self.authors = authors
        self.categories = categories
        self.tags = tags
        self.moods = moods
        self.isFavoriteOnly = isFavoriteOnly
        self.dateRange = dateRange
        self.sortBy = sortBy
    }

    /// Default empty filter
    static var `default`: QuoteFilter {
        QuoteFilter()
    }

    /// Check if any filters are active
    var isActive: Bool {
        !(searchText?.isEmpty ?? true) ||
            !authors.isEmpty ||
            !categories.isEmpty ||
            !tags.isEmpty ||
            !moods.isEmpty ||
            isFavoriteOnly ||
            dateRange != nil
    }

    /// Count of active filters
    var activeFilterCount: Int {
        var count = 0
        if !(searchText?.isEmpty ?? true) { count += 1 }
        count += authors.count
        count += categories.count
        count += tags.count
        count += moods.count
        if isFavoriteOnly { count += 1 }
        if dateRange != nil { count += 1 }
        return count
    }

    /// Generate SwiftData predicate from filter
    func makePredicate() -> Predicate<Quote>? {
        var predicates: [Predicate<Quote>] = []

        // Search text filter
        if let searchText, !searchText.isEmpty {
            let search = searchText
            predicates.append(#Predicate<Quote> { quote in
                quote.text.localizedStandardContains(search) ||
                    quote.author.localizedStandardContains(search) ||
                    (quote.source?.localizedStandardContains(search) ?? false)
            })
        }

        // Favorite filter
        if isFavoriteOnly {
            predicates.append(#Predicate<Quote> { quote in
                quote.isFavorite == true
            })
        }

        // Date range filter
        if let dateRange {
            let start = dateRange.start
            let end = dateRange.end
            predicates.append(#Predicate<Quote> { quote in
                quote.createdAt >= start && quote.createdAt <= end
            })
        }

        // Author filter
        if !authors.isEmpty {
            let authorList = Array(authors)
            predicates.append(#Predicate<Quote> { quote in
                authorList.contains(quote.author)
            })
        }

        // Mood filter
        if !moods.isEmpty {
            let moodList = Array(moods)
            predicates.append(#Predicate<Quote> { quote in
                quote.mood != nil && moodList.contains(quote.mood!)
            })
        }

        // Combine all predicates with AND
        guard !predicates.isEmpty else { return nil }

        return predicates.reduce(predicates[0]) { result, predicate in
            #Predicate<Quote> { quote in
                result.evaluate(quote) && predicate.evaluate(quote)
            }
        }
    }

    /// Generate FetchDescriptor from filter
    func makeFetchDescriptor() -> FetchDescriptor<Quote> {
        var descriptor = FetchDescriptor<Quote>(
            predicate: makePredicate()
        )

        // Apply sorting
        switch sortBy {
        case .newest:
            descriptor.sortBy = [SortDescriptor(\.createdAt, order: .reverse)]
        case .oldest:
            descriptor.sortBy = [SortDescriptor(\.createdAt, order: .forward)]
        case .author:
            descriptor.sortBy = [SortDescriptor(\.author, order: .forward)]
        case .mostRead:
            descriptor.sortBy = [SortDescriptor(\.readCount, order: .reverse)]
        case .random:
            // Random sorting can be handled in the view layer
            descriptor.sortBy = []
        }

        return descriptor
    }
}
