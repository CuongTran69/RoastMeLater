import SwiftUI

// MARK: - StreakMilestonesView

struct StreakMilestonesView: View {
    @EnvironmentObject var localizationManager: LocalizationManager
    @ObservedObject private var appLifecycleManager = AppLifecycleManager.shared

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Current Streak Summary
                currentStreakCard

                // Milestones Grid
                milestonesSection
            }
            .padding()
        }
        .navigationTitle(Strings.Streak.milestones.localized(localizationManager.currentLanguage))
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Current Streak Card
    private var currentStreakCard: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "flame.fill")
                    .font(.title2)
                    .foregroundColor(.orange)

                Text(Strings.Streak.yourProgress.localized(localizationManager.currentLanguage))
                    .font(.headline)

                Spacer()
            }

            HStack(spacing: 24) {
                VStack {
                    Text("\(appLifecycleManager.currentStreak.currentStreak)")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.orange)
                    Text(Strings.Streak.current.localized(localizationManager.currentLanguage))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Divider()
                    .frame(height: 50)

                VStack {
                    Text("\(appLifecycleManager.currentStreak.longestStreak)")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.yellow)
                    Text(Strings.Streak.best.localized(localizationManager.currentLanguage))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Divider()
                    .frame(height: 50)

                VStack {
                    Text("\(appLifecycleManager.currentStreak.totalDaysActive)")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.green)
                    Text(Strings.Streak.total.localized(localizationManager.currentLanguage))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }

    // MARK: - Milestones Section
    private var milestonesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "trophy.fill")
                    .foregroundColor(.yellow)
                Text(Strings.Streak.milestones.localized(localizationManager.currentLanguage))
                    .font(.headline)
                Spacer()
            }
            .padding(.horizontal, 4)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(appLifecycleManager.getStreakMilestones()) { milestone in
                    MilestoneCard(milestone: milestone)
                }
            }
        }
    }
}

// MARK: - MilestoneCard

struct MilestoneCard: View {
    @EnvironmentObject var localizationManager: LocalizationManager
    let milestone: StreakMilestone

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(milestone.isUnlocked ? Color.yellow.opacity(0.2) : Color.gray.opacity(0.1))
                    .frame(width: 50, height: 50)

                Image(systemName: milestone.iconName)
                    .font(.title2)
                    .foregroundColor(milestone.isUnlocked ? .yellow : .gray)
            }

            Text(milestone.title)
                .font(.subheadline.weight(.semibold))
                .multilineTextAlignment(.center)
                .foregroundColor(milestone.isUnlocked ? .primary : .secondary)

            Text(Strings.Streak.daysCount(milestone.days).localized(localizationManager.currentLanguage))
                .font(.caption)
                .foregroundColor(.secondary)

            if milestone.isUnlocked {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.caption)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(milestone.isUnlocked ? Color.yellow.opacity(0.5) : Color.clear, lineWidth: 2)
        )
        .shadow(color: .black.opacity(0.03), radius: 3, x: 0, y: 1)
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        StreakMilestonesView()
    }
    .environmentObject(LocalizationManager.shared)
}

