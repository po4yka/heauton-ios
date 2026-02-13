import SwiftData
import SwiftUI

struct ExercisesLibraryView: View {
    @Query(sort: \Exercise.title)
    private var allExercises: [Exercise]
    @Environment(\.appDependencies)
    private var dependencies

    @State private var viewModel = ExercisesLibraryViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Filters
                    VStack(spacing: 12) {
                        // Type filter
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                FilterChip(
                                    title: "All",
                                    isSelected: viewModel.selectedType == nil
                                ) {
                                    viewModel.selectType(nil)
                                }

                                ForEach(ExerciseType.allCases, id: \.self) { type in
                                    FilterChip(
                                        title: type.displayName,
                                        icon: type.icon,
                                        iconColor: type.color,
                                        isSelected: viewModel.selectedType == type
                                    ) {
                                        viewModel.selectType(type)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }

                        // Difficulty filter
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(Difficulty.allCases, id: \.self) { difficulty in
                                    FilterChip(
                                        title: difficulty.displayName,
                                        iconColor: difficulty.swiftUIColor,
                                        isSelected: viewModel.selectedDifficulty == difficulty
                                    ) {
                                        viewModel.toggleDifficulty(difficulty)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.top)

                    // Favorites section
                    let favorites = viewModel.favoriteExercises(from: allExercises)
                    if !favorites.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Favorites")
                                .font(.firaCodeHeadline())
                                .padding(.horizontal)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    ForEach(favorites) { exercise in
                                        NavigationLink {
                                            ExerciseDetailView(exercise: exercise)
                                        } label: {
                                            ExerciseCard(exercise: exercise)
                                                .frame(width: 280)
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }

                    // All exercises
                    let filtered = viewModel.filteredExercises(from: allExercises)
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("All Exercises")
                                .font(.firaCodeHeadline())

                            Spacer()

                            Text("\(filtered.count)")
                                .font(.firaCodeSubheadline())
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal)

                        LazyVStack(spacing: 16) {
                            ForEach(filtered) { exercise in
                                NavigationLink {
                                    ExerciseDetailView(exercise: exercise)
                                } label: {
                                    ExerciseCard(exercise: exercise)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .navigationTitle("Exercises")
            .searchable(text: $viewModel.searchText, prompt: "Search exercises")
        }
    }
}

struct ExerciseCard: View {
    let exercise: Exercise

    var body: some View {
        HStack(spacing: 16) {
            // Icon with type color
            Image(systemName: exercise.type.icon)
                .font(.title2)
                .foregroundStyle(.white)
                .frame(width: 60, height: 60)
                .background(
                    LinearGradient(
                        colors: [
                            exercise.type.color,
                            exercise.type.color.opacity(0.7)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))

            // Info
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(exercise.title)
                        .font(.firaCodeSubheadline(.semiBold))
                        .foregroundStyle(.primary)

                    Spacer()

                    if exercise.isFavorite {
                        Image(systemName: "heart.fill")
                            .font(.caption)
                            .foregroundStyle(Color.lsShadowGrey)
                    }
                }

                HStack(spacing: 8) {
                    Text(exercise.formattedDuration)
                        .font(.firaCodeCaption())
                        .foregroundStyle(.secondary)

                    Text("•")
                        .foregroundStyle(.secondary)

                    // Difficulty badge with color
                    Text(exercise.difficulty.displayName)
                        .font(.system(size: 11, weight: .medium))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(exercise.difficulty.swiftUIColor.opacity(0.15))
                        )
                        .foregroundStyle(exercise.difficulty.swiftUIColor)

                    Text("•")
                        .foregroundStyle(.secondary)

                    Text(exercise.category)
                        .font(.firaCodeCaption())
                        .foregroundStyle(.secondary)
                }
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
        )
    }
}

struct FilterChip: View {
    let title: String
    var icon: String?
    var iconColor: Color?
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                // Color indicator dot
                if let iconColor, !isSelected {
                    Circle()
                        .fill(iconColor)
                        .frame(width: 8, height: 8)
                }

                if let icon {
                    Image(systemName: icon)
                        .font(.caption)
                }

                Text(title)
                    .font(.firaCodeSubheadline())
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected
                        ? (iconColor ?? .appPrimary)
                        : Color.lsPaleSlate.opacity(0.2))
            )
            .foregroundStyle(isSelected ? .white : .primary)
        }
    }
}

#Preview {
    ExercisesLibraryView()
        // swiftlint:disable:next force_try
        .modelContainer(try! SharedModelContainer.create())
        .environment(\.appDependencies, AppDependencyContainer.shared)
}
