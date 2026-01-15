import SwiftUI

// MARK: - StreakBadgeView

struct StreakBadgeView: View {
    @EnvironmentObject var localizationManager: LocalizationManager
    let streak: UserStreak
    let status: StreakStatus
    var isCompact: Bool = false
    
    var body: some View {
        if isCompact {
            compactView
        } else {
            fullView
        }
    }
    
    // MARK: - Compact View (for header)
    private var compactView: some View {
        HStack(spacing: 6) {
            streakIcon
                .font(.system(size: 16))
            
            Text("\(streak.currentStreak)")
                .font(.subheadline.weight(.bold))
                .foregroundColor(streakColor)
            
            if case .expiringSoon(let hours) = status {
                Text("(\(hours)h)")
                    .font(.caption2)
                    .foregroundColor(.orange)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(streakBackgroundColor.opacity(0.15))
        .cornerRadius(12)
    }
    
    // MARK: - Full View (for settings/detail)
    private var fullView: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                // Streak Icon with Animation
                ZStack {
                    Circle()
                        .fill(streakBackgroundColor.opacity(0.2))
                        .frame(width: 60, height: 60)

                    streakIcon
                        .font(.system(size: 28))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(Strings.Streak.currentStreak.localized(localizationManager.currentLanguage))
                        .font(.caption)
                        .foregroundColor(.secondary)

                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(streak.currentStreak)")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(streakColor)

                        Text(Strings.Common.days.localized(localizationManager.currentLanguage))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    statusLabel
                }

                Spacer()
            }

            // Stats Row
            HStack(spacing: 0) {
                statItem(
                    title: Strings.Streak.longestStreak.localized(localizationManager.currentLanguage),
                    value: "\(streak.longestStreak)",
                    icon: "trophy.fill"
                )

                Divider()
                    .frame(height: 40)

                statItem(
                    title: Strings.Streak.totalDays.localized(localizationManager.currentLanguage),
                    value: "\(streak.totalDaysActive)",
                    icon: "calendar"
                )

                Divider()
                    .frame(height: 40)

                statItem(
                    title: Strings.Streak.freeze.localized(localizationManager.currentLanguage),
                    value: streak.streakFreezeAvailable ? "✓" : "✗",
                    icon: "snowflake"
                )
            }
            .padding(.vertical, 8)
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }

    // MARK: - Helper Views
    private var streakIcon: some View {
        Image(systemName: streakIconName)
            .foregroundColor(streakColor)
    }

    private var statusLabel: some View {
        Group {
            switch status {
            case .active:
                Label(
                    Strings.Streak.active.localized(localizationManager.currentLanguage),
                    systemImage: "checkmark.circle.fill"
                )
                .foregroundColor(.green)
            case .expiringSoon(let hours):
                Label(
                    Strings.Streak.expiringIn(hours).localized(localizationManager.currentLanguage),
                    systemImage: "exclamationmark.triangle.fill"
                )
                .foregroundColor(.orange)
            case .expired:
                Label(
                    Strings.Streak.expired.localized(localizationManager.currentLanguage),
                    systemImage: "xmark.circle.fill"
                )
                .foregroundColor(.red)
            case .frozen:
                Label(
                    Strings.Streak.frozen.localized(localizationManager.currentLanguage),
                    systemImage: "snowflake"
                )
                .foregroundColor(.blue)
            case .newUser:
                Label(
                    Strings.Streak.welcome.localized(localizationManager.currentLanguage),
                    systemImage: "star.fill"
                )
                .foregroundColor(.yellow)
            }
        }
        .font(.caption)
    }

    private func statItem(title: String, value: String, icon: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.secondary)

            Text(value)
                .font(.headline.weight(.semibold))

            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Computed Properties
    private var streakIconName: String {
        switch status {
        case .frozen:
            return "snowflake"
        case .expired:
            return "flame"
        case .expiringSoon:
            return "flame.fill"
        default:
            if streak.currentStreak >= 30 {
                return "flame.circle.fill"
            } else if streak.currentStreak >= 7 {
                return "flame.fill"
            } else {
                return "flame"
            }
        }
    }

    private var streakColor: Color {
        switch status {
        case .frozen:
            return .blue
        case .expired:
            return .gray
        case .expiringSoon:
            return .orange
        default:
            if streak.currentStreak >= 30 {
                return .red
            } else if streak.currentStreak >= 7 {
                return .orange
            } else {
                return .orange.opacity(0.8)
            }
        }
    }

    private var streakBackgroundColor: Color {
        switch status {
        case .frozen:
            return .blue
        case .expired:
            return .gray
        default:
            return .orange
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        StreakBadgeView(
            streak: UserStreak(currentStreak: 7, longestStreak: 14, totalDaysActive: 30),
            status: .active,
            isCompact: true
        )

        StreakBadgeView(
            streak: UserStreak(currentStreak: 7, longestStreak: 14, totalDaysActive: 30),
            status: .active
        )

        StreakBadgeView(
            streak: UserStreak(currentStreak: 5, longestStreak: 10, totalDaysActive: 20),
            status: .expiringSoon(hoursRemaining: 2)
        )
    }
    .padding()
    .environmentObject(LocalizationManager.shared)
}

