import Foundation

// MARK: - UserStreak

struct UserStreak: Codable, Equatable {
    var currentStreak: Int
    var longestStreak: Int
    var lastActiveDate: Date
    var streakStartDate: Date?
    var streakFreezeAvailable: Bool
    var streakFreezeUsedDate: Date?
    var totalDaysActive: Int
    
    init(currentStreak: Int = 0,
         longestStreak: Int = 0,
         lastActiveDate: Date = Date(),
         streakStartDate: Date? = nil,
         streakFreezeAvailable: Bool = true,
         streakFreezeUsedDate: Date? = nil,
         totalDaysActive: Int = 0) {
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.lastActiveDate = lastActiveDate
        self.streakStartDate = streakStartDate
        self.streakFreezeAvailable = streakFreezeAvailable
        self.streakFreezeUsedDate = streakFreezeUsedDate
        self.totalDaysActive = totalDaysActive
    }
}

// MARK: - StreakStatus

enum StreakStatus: Equatable {
    case active
    case expiringSoon(hoursRemaining: Int)
    case expired
    case frozen
    case newUser
}

// MARK: - StreakMilestone

struct StreakMilestone: Codable, Identifiable {
    let id: String
    let days: Int
    let title: String
    let description: String
    let iconName: String
    var isUnlocked: Bool
    
    static let milestones: [StreakMilestone] = [
        StreakMilestone(
            id: "streak_3_days",
            days: 3,
            title: "Khởi đầu tốt",
            description: "Duy trì streak 3 ngày liên tiếp",
            iconName: "flame",
            isUnlocked: false
        ),
        StreakMilestone(
            id: "streak_7_days",
            days: 7,
            title: "Tuần lễ rực lửa",
            description: "Duy trì streak 7 ngày liên tiếp",
            iconName: "flame.fill",
            isUnlocked: false
        ),
        StreakMilestone(
            id: "streak_14_days",
            days: 14,
            title: "Hai tuần bền bỉ",
            description: "Duy trì streak 14 ngày liên tiếp",
            iconName: "bolt.fill",
            isUnlocked: false
        ),
        StreakMilestone(
            id: "streak_30_days",
            days: 30,
            title: "Tháng đầu tiên",
            description: "Duy trì streak 30 ngày liên tiếp",
            iconName: "star.fill",
            isUnlocked: false
        ),
        StreakMilestone(
            id: "streak_60_days",
            days: 60,
            title: "Chiến binh kiên cường",
            description: "Duy trì streak 60 ngày liên tiếp",
            iconName: "crown.fill",
            isUnlocked: false
        ),
        StreakMilestone(
            id: "streak_100_days",
            days: 100,
            title: "Huyền thoại",
            description: "Duy trì streak 100 ngày liên tiếp",
            iconName: "trophy.fill",
            isUnlocked: false
        )
    ]
}

