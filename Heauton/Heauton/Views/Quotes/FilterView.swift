import SwiftUI

struct FilterView: View {
    @Binding var filter: QuoteFilter
    @Environment(\.dismiss)
    private var dismiss

    @State private var tempFilter: QuoteFilter
    @State private var availableAuthors: [String] = []
    @State private var availableCategories: [String] = []
    @State private var availableMoods: [String] = []

    init(filter: Binding<QuoteFilter>) {
        _filter = filter
        _tempFilter = State(
            initialValue: filter.wrappedValue
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                // Search section
                Section("Search") {
                    TextField("Search text", text: Binding(
                        get: { tempFilter.searchText ?? "" },
                        set: { tempFilter.searchText = $0.isEmpty ? nil : $0 }
                    ))
                }

                // Sort section
                Section("Sort By") {
                    Picker("Sort", selection: $tempFilter.sortBy) {
                        ForEach(QuoteSortOption.allCases, id: \.self) { option in
                            Text(option.displayName).tag(option)
                        }
                    }
                    .pickerStyle(.menu)
                }

                // Favorites filter
                Section {
                    Toggle("Favorites Only", isOn: $tempFilter.isFavoriteOnly)
                }

                // Authors filter
                if !availableAuthors.isEmpty {
                    Section("Authors") {
                        ForEach(availableAuthors, id: \.self) { author in
                            Toggle(author, isOn: Binding(
                                get: { tempFilter.authors.contains(author) },
                                set: { isOn in
                                    if isOn {
                                        tempFilter.authors.insert(author)
                                    } else {
                                        tempFilter.authors.remove(author)
                                    }
                                }
                            ))
                        }
                    }
                }

                // Categories filter
                if !availableCategories.isEmpty {
                    Section("Categories") {
                        ForEach(availableCategories, id: \.self) { category in
                            Toggle(category, isOn: Binding(
                                get: { tempFilter.categories.contains(category) },
                                set: { isOn in
                                    if isOn {
                                        tempFilter.categories.insert(category)
                                    } else {
                                        tempFilter.categories.remove(category)
                                    }
                                }
                            ))
                        }
                    }
                }

                // Moods filter
                if !availableMoods.isEmpty {
                    Section("Moods") {
                        ForEach(availableMoods, id: \.self) { mood in
                            Toggle(mood, isOn: Binding(
                                get: { tempFilter.moods.contains(mood) },
                                set: { isOn in
                                    if isOn {
                                        tempFilter.moods.insert(mood)
                                    } else {
                                        tempFilter.moods.remove(mood)
                                    }
                                }
                            ))
                        }
                    }
                }

                // Clear filters
                Section {
                    Button("Clear All Filters", role: .destructive) {
                        tempFilter = .default
                    }
                    .foregroundStyle(.accentDanger)
                }
            }
            .navigationTitle("Filter Quotes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        filter = tempFilter
                        dismiss()
                    }
                }
            }
            .task {
                availableAuthors = ["Marcus Aurelius", "Epictetus", "Seneca"]
                availableCategories = ["Stoicism", "Ethics", "Philosophy"]
                availableMoods = ["Inspiring", "Reflective", "Challenging"]
            }
        }
    }
}

#Preview {
    FilterView(filter: .constant(.default))
}
