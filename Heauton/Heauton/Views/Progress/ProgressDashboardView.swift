import SwiftData
import SwiftUI

struct ProgressDashboardView: View {
    @Environment(\.appDependencies)
    private var dependencies
    @Query private var achievements: [Achievement]

    @State private var viewModel: ProgressDashboardViewModel?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    if let vm = viewModel, let stats = vm.stats {
                        // Hero Stats
                        VStack(spacing: 16) {
                            // Current Streak
                            StreakCard(streak: stats.currentStreak)

                            // Activity Grid
                            LazyVGrid(
                                columns: [
                                    GridItem(.flexible()),
                                    GridItem(.flexible()),
                                ],
                                spacing: 16
                            ) {
                                StatCard(
                                    title: "Quotes",
                                    value: "\(stats.totalQuotes)",
                                    icon: "quote.bubble",
                                    color: .appPrimary
                                )

                                StatCard(
                                    title: "Journal",
                                    value: "\(stats.totalJournalEntries)",
                                    icon: "book.closed",
                                    color: .appSecondary
                                )

                                StatCard(
                                    title: "Meditation",
                                    value: "\(stats.totalMeditationMinutes)m",
                                    icon: "brain.head.profile",
                                    color: .lsGunmetal
                                )

                                StatCard(
                                    title: "Breathing",
                                    value: "\(stats.totalBreathingSessions)",
                                    icon: "wind",
                                    color: .lsIronGrey
                                )
                            }
                        }
                        .padding(.horizontal)

                        // Recent Achievements
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Recent Achievements")
                                    .font(.firaCodeHeadline())

                                Spacer()

                                NavigationLink {
                                    AchievementsView()
                                } label: {
                                    Text("View All")
                                        .font(.firaCodeCaption())
                                        .foregroundStyle(.appPrimary)
                                }
                            }
                            .padding(.horizontal)

                            let unlocked = vm.unlockedAchievements(from: achievements)

                            if unlocked.isEmpty {
                                ContentUnavailableView(
                                    "No Achievements Yet",
                                    systemImage: "trophy",
                                    description: Text("Complete activities to unlock achievements!")
                                )
                                .frame(height: 200)
                            } else {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 16) {
                                        ForEach(vm.recentAchievements(from: achievements)) { achievement in
                                            AchievementCardCompact(achievement: achievement)
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }

                        Spacer(minLength: 20)
                    } else if viewModel?.isLoading == true {
                        ProgressView("Loading stats...")
                            .padding()
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Progress")
            .refreshable {
                await viewModel?.refreshStats()
            }
            .task {
                await viewModel?.loadStats()
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = ProgressDashboardViewModel(
                    progressTrackerService: dependencies.progressTrackerService
                )
            }
        }
    }
}

struct StreakCard: View {
    let streak: Int

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "flame.fill")
                .font(.system(size: 50))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.lsSlateGrey, .lsGunmetal],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            VStack(spacing: 4) {
                Text("\(streak)")
                    .font(.system(size: 48, weight: .bold, design: .rounded))

                Text(streak == 1 ? "Day Streak" : "Day Streak")
                    .font(.firaCodeHeadline())
                    .foregroundStyle(.secondary)
            }

            if streak > 0 {
                Text("Keep it going!")
                    .font(.firaCodeSubheadline())
                    .foregroundStyle(.appPrimary)
            } else {
                Text("Start your journey today!")
                    .font(.firaCodeSubheadline())
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 10, y: 4)
        )
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)

            Text(value)
                .font(.firaCodeTitle())
                .fontWeight(.bold)

            Text(title)
                .font(.firaCodeCaption())
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 120)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
        )
    }
}

struct AchievementCardCompact: View {
    let achievement: Achievement

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: achievement.icon)
                .font(.title)
                .foregroundStyle(.lsSlateGrey)
                .frame(width: 60, height: 60)
                .background(Circle().fill(.lsPaleSlate.opacity(0.4)))

            Text(achievement.title)
                .font(.firaCodeCaption(.semiBold))
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(width: 100)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 5)
        )
    }
}

#Preview {
    ProgressDashboardView()
        // swiftlint:disable:next force_try
        .modelContainer(try! SharedModelContainer.create())
        .environment(\.appDependencies, AppDependencyContainer.shared)
}
