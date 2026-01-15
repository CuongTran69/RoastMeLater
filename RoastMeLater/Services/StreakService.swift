import Foundation

// MARK: - StreakService Protocol

/// Protocol defining the interface for streak tracking and management.
/// Handles user engagement streaks, streak freezes, and milestone tracking.
protocol StreakServiceProtocol {
    
    /// Current streak data containing all streak-related information
    var currentStreak: UserStreak { get }
    
    /// Checks the current streak status and updates it based on the last active date.
    /// This should be called when the app becomes active to determine if the streak
    /// is still valid, expiring soon, or has expired.
    /// - Returns: The updated streak status after evaluation
    func checkAndUpdateStreak() -> StreakStatus
    
    /// Gets the current streak status without modifying any data.
    /// Use this for display purposes when you don't want to trigger an update.
    /// - Returns: The current streak status
    func getStreakStatus() -> StreakStatus
    
    /// Attempts to use a streak freeze to recover a lost streak.
    /// Streak freeze is a one-time use feature that allows users to restore
    /// a streak that was broken (typically for streaks of 7+ days).
    /// - Returns: `true` if the freeze was successfully applied, `false` if no freeze is available or streak is not expired
    func useStreakFreeze() -> Bool
    
    /// Retrieves all available milestones with their current unlock status.
    /// Milestones are achievements based on streak length (e.g., 3 days, 7 days, 30 days).
    /// - Returns: Array of all streak milestones with their unlock status
    func getMilestones() -> [StreakMilestone]
    
    /// Checks if a specific milestone has been unlocked based on the streak days.
    /// - Parameter days: The number of days for the milestone to check
    /// - Returns: `true` if the milestone for the specified days is unlocked
    func isMilestoneUnlocked(days: Int) -> Bool
    
    /// Calculates the remaining hours until the current streak expires.
    /// The streak typically expires at midnight of the next day after the last active date.
    /// - Returns: Hours remaining until expiry, or `nil` if streak is already expired or not active
    func getHoursUntilExpiry() -> Int?
    
    /// Resets the streak data to initial state.
    /// This can be used for testing purposes or when a user explicitly requests a reset.
    /// Warning: This action is irreversible and will clear all streak progress.
    func resetStreak()
}

// MARK: - StreakService Implementation

class StreakService: StreakServiceProtocol {

    // MARK: - Properties
    private let storageService: StorageServiceProtocol
    private let calendar: Calendar
    private var _currentStreak: UserStreak

    private let streakStorageKey = "user_streak"

    // MARK: - Initialization
    init(storageService: StorageServiceProtocol = StorageService.shared) {
        self.storageService = storageService
        self.calendar = Calendar.current
        self._currentStreak = UserStreak()
        loadStreak()
    }

    // MARK: - Protocol Implementation
    var currentStreak: UserStreak {
        return _currentStreak
    }

    func checkAndUpdateStreak() -> StreakStatus {
        loadStreak()

        let today = Date()
        let lastActiveDate = _currentStreak.lastActiveDate

        if _currentStreak.currentStreak == 0 && _currentStreak.totalDaysActive == 0 {
            _currentStreak.currentStreak = 1
            _currentStreak.totalDaysActive = 1
            _currentStreak.lastActiveDate = today
            _currentStreak.streakStartDate = today
            _currentStreak.longestStreak = max(_currentStreak.longestStreak, 1)
            saveStreak()
            return .newUser
        }

        if isToday(lastActiveDate) {
            return calculateCurrentStatus()
        }

        if isYesterday(lastActiveDate) {
            _currentStreak.currentStreak += 1
            _currentStreak.totalDaysActive += 1
            _currentStreak.lastActiveDate = today
            _currentStreak.longestStreak = max(_currentStreak.longestStreak, _currentStreak.currentStreak)
            saveStreak()
            return .active
        }

        let daysSinceLastActive = calendar.dateComponents([.day], from: lastActiveDate, to: today).day ?? 0

        if daysSinceLastActive > 1 {
            if _currentStreak.streakFreezeAvailable && _currentStreak.currentStreak >= 7 {
                return .expired
            }

            _currentStreak.currentStreak = 1
            _currentStreak.totalDaysActive += 1
            _currentStreak.lastActiveDate = today
            _currentStreak.streakStartDate = today
            saveStreak()
            return .expired
        }

        return calculateCurrentStatus()
    }

    func getStreakStatus() -> StreakStatus {
        return calculateCurrentStatus()
    }

    func useStreakFreeze() -> Bool {
        guard _currentStreak.streakFreezeAvailable else {
            return false
        }

        guard _currentStreak.currentStreak >= 7 else {
            return false
        }

        let lastActiveDate = _currentStreak.lastActiveDate
        let daysSinceLastActive = calendar.dateComponents([.day], from: lastActiveDate, to: Date()).day ?? 0

        guard daysSinceLastActive > 1 else {
            return false
        }

        _currentStreak.streakFreezeAvailable = false
        _currentStreak.streakFreezeUsedDate = Date()
        _currentStreak.lastActiveDate = Date()
        _currentStreak.totalDaysActive += 1
        saveStreak()

        return true
    }

    func getMilestones() -> [StreakMilestone] {
        return StreakMilestone.milestones.map { milestone in
            var updatedMilestone = milestone
            updatedMilestone.isUnlocked = isMilestoneUnlocked(days: milestone.days)
            return updatedMilestone
        }
    }

    func isMilestoneUnlocked(days: Int) -> Bool {
        return _currentStreak.currentStreak >= days || _currentStreak.longestStreak >= days
    }

    func getHoursUntilExpiry() -> Int? {
        guard _currentStreak.currentStreak > 0 else {
            return nil
        }

        guard let endOfDay = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: Date()) else {
            return nil
        }

        let hoursRemaining = calendar.dateComponents([.hour], from: Date(), to: endOfDay).hour ?? 0
        return max(0, hoursRemaining)
    }

    func resetStreak() {
        _currentStreak = UserStreak()
        saveStreak()
    }

    // MARK: - Private Methods
    private func loadStreak() {
        guard let data = UserDefaults.standard.data(forKey: streakStorageKey),
              let streak = try? JSONDecoder().decode(UserStreak.self, from: data) else {
            _currentStreak = UserStreak()
            return
        }
        _currentStreak = streak
    }

    private func saveStreak() {
        guard let data = try? JSONEncoder().encode(_currentStreak) else {
            return
        }
        UserDefaults.standard.set(data, forKey: streakStorageKey)
        UserDefaults.standard.synchronize()
    }

    private func isToday(_ date: Date) -> Bool {
        calendar.isDateInToday(date)
    }

    private func isYesterday(_ date: Date) -> Bool {
        calendar.isDateInYesterday(date)
    }

    private func calculateCurrentStatus() -> StreakStatus {
        if _currentStreak.currentStreak == 0 {
            return .newUser
        }

        let lastActiveDate = _currentStreak.lastActiveDate
        let daysSinceLastActive = calendar.dateComponents([.day], from: lastActiveDate, to: Date()).day ?? 0

        if daysSinceLastActive > 1 {
            if _currentStreak.streakFreezeAvailable && _currentStreak.currentStreak >= 7 {
                return .frozen
            }
            return .expired
        }

        if let hoursRemaining = getHoursUntilExpiry(), hoursRemaining < 2 && !isToday(lastActiveDate) {
            return .expiringSoon(hoursRemaining: hoursRemaining)
        }

        if !isToday(lastActiveDate) && isYesterday(lastActiveDate) {
            if let hoursRemaining = getHoursUntilExpiry(), hoursRemaining < 2 {
                return .expiringSoon(hoursRemaining: hoursRemaining)
            }
        }

        return .active
    }
}

