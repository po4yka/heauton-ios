import SwiftData
import SwiftUI

struct AchievementsView: View {
    @Query(sort: \Achievement.unlockedAt, order: .reverse)
    private var achievements: [Achievement]

    var unlockedAchievements: [Achievement] {
        achievements.filter { $0.isUnlocked && !$0.isHidden }
    }

    var lockedAchievements: [Achievement] {
        achievements.filter { !$0.isUnlocked && !$0.isHidden }
    }

    var secretAchievements: [Achievement] {
        achievements.filter(\.isHidden)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Progress Summary
                VStack(spacing: 12) {
                    Text("\(unlockedAchievements.count) / \(achievements.filter { !$0.isHidden }.count)")
                        .font(.system(size: 48, weight: .bold, design: .rounded))

                    Text("Achievements Unlocked")
                        .font(.firaCodeHeadline())
                        .foregroundStyle(.secondary)

                    ProgressView(value: progressPercentage) {
                        Text("\(Int(progressPercentage * 100))%")
                            .font(.firaCodeCaption())
                    }
                    .tint(.blue)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.1), radius: 10, y: 4)
                )
                .padding(.horizontal)

                // Unlocked Achievements
                if !unlockedAchievements.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Unlocked")
                            .font(.firaCodeHeadline())
                            .padding(.horizontal)

                        LazyVStack(spacing: 12) {
                            ForEach(unlockedAchievements) { achievement in
                                AchievementCard(achievement: achievement)
                            }
                        }
                        .padding(.horizontal)
                    }
                }

                // Locked Achievements
                if !lockedAchievements.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Locked")
                            .font(.firaCodeHeadline())
                            .padding(.horizontal)

                        LazyVStack(spacing: 12) {
                            ForEach(lockedAchievements) { achievement in
                                AchievementCard(achievement: achievement)
                            }
                        }
                        .padding(.horizontal)
                    }
                }

                // Secret Achievements
                if !secretAchievements.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Secret")
                            .font(.firaCodeHeadline())
                            .padding(.horizontal)

                        LazyVStack(spacing: 12) {
                            ForEach(secretAchievements) { achievement in
                                AchievementCard(achievement: achievement)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Achievements")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var progressPercentage: Double {
        let total = achievements.filter { !$0.isHidden }.count
        guard total > 0 else { return 0 }
        return Double(unlockedAchievements.count) / Double(total)
    }
}

struct AchievementCard: View {
    let achievement: Achievement

    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(achievement.isUnlocked ? .yellow.opacity(0.2) : .gray.opacity(0.1))
                    .frame(width: 60, height: 60)

                Image(systemName: achievement.icon)
                    .font(.title2)
                    .foregroundStyle(achievement.isUnlocked ? .yellow : .gray)
            }

            // Info
            VStack(alignment: .leading, spacing: 6) {
                Text(achievement.title)
                    .font(.firaCodeSubheadline(.semiBold))
                    .foregroundStyle(achievement.isUnlocked ? .primary : .secondary)

                Text(achievement.achievementDescription)
                    .font(.firaCodeCaption())
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                // Progress bar for locked achievements
                if !achievement.isUnlocked {
                    HStack(spacing: 8) {
                        ProgressView(value: achievement.progressPercentage)
                            .tint(.blue)

                        Text(achievement.progressString)
                            .font(.firaCodeCaption())
                            .foregroundStyle(.secondary)
                            .fixedSize()
                    }
                } else if let unlockedAt = achievement.unlockedAt {
                    Text("Unlocked \(unlockedAt.formatted(date: .abbreviated, time: .omitted))")
                        .font(.firaCodeCaption())
                        .foregroundStyle(.green)
                }
            }

            Spacer()

            if achievement.isUnlocked {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.green)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
        )
    }
}

#Preview {
    NavigationStack {
        AchievementsView()
            // swiftlint:disable:next force_try
            .modelContainer(try! SharedModelContainer.create())
    }
}
