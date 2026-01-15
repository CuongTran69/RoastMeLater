import Foundation
import UIKit
import UserNotifications
import RxSwift

class AppLifecycleManager: ObservableObject {
    static let shared = AppLifecycleManager()

    private let disposeBag = DisposeBag()
    private let notificationManager: NotificationManager
    private let storageService: StorageServiceProtocol
    private let streakService: StreakServiceProtocol

    @Published var appState: AppState = .active
    @Published var backgroundTime: Date?
    @Published var currentStreak: UserStreak = UserStreak()
    @Published var streakStatus: StreakStatus = .newUser

    private init() {
        self.notificationManager = NotificationManager()
        self.storageService = StorageService.shared
        self.streakService = StreakService(storageService: StorageService.shared)

        setupLifecycleObservers()

        // Initialize streak data
        updateStreakData()
    }
    
    private func setupLifecycleObservers() {
        // App will enter background
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterBackground),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
        
        // App did become active
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        
        // App will terminate
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillTerminate),
            name: UIApplication.willTerminateNotification,
            object: nil
        )
        
        // Handle roast notification taps
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRoastNotificationTap),
            name: .roastNotificationTapped,
            object: nil
        )
    }
    
    @objc private func appWillEnterBackground() {
        appState = .background
        backgroundTime = Date()
        
        // Schedule notifications if needed
        let preferences = storageService.getUserPreferences()
        if preferences.notificationsEnabled {
            notificationManager.scheduleHourlyNotifications()
        }
        
        // Save any pending data
        saveAppState()
    }
    
    @objc private func appDidBecomeActive() {
        appState = .active

        // Check and update streak when app becomes active
        updateStreakData()

        // Check if we need to reschedule notifications
        notificationManager.rescheduleNotificationsIfNeeded()

        // Handle returning from background
        if let backgroundTime = backgroundTime {
            handleReturnFromBackground(backgroundTime: backgroundTime)
        }

        backgroundTime = nil
    }
    
    @objc private func appWillTerminate() {
        appState = .terminated
        saveAppState()
    }
    
    @objc private func handleRoastNotificationTap() {
        // Post notification to navigate to roast generator
        NotificationCenter.default.post(name: .navigateToRoastGenerator, object: nil)
    }
    
    private func handleReturnFromBackground(backgroundTime: Date) {
        let timeInBackground = Date().timeIntervalSince(backgroundTime)

        // If app was in background for more than 1 hour, generate a welcome back roast
        if timeInBackground > 3600 { // 1 hour
            generateWelcomeBackRoast()
        }

        // Update notification badge
        if #available(iOS 16.0, *) {
            UNUserNotificationCenter.current().setBadgeCount(0)
        } else {
            UIApplication.shared.applicationIconBadgeNumber = 0
        }
    }
    
    private func generateWelcomeBackRoast() {
        let preferences = storageService.getUserPreferences()
        let randomCategory = preferences.preferredCategories.randomElement() ?? .general
        
        // This would trigger a roast generation in the main app
        NotificationCenter.default.post(
            name: .generateWelcomeBackRoast,
            object: nil,
            userInfo: [
                "category": randomCategory,
                "spiceLevel": preferences.defaultSpiceLevel
            ]
        )
    }
    
    private func saveAppState() {
        // Save any important app state data
        let appStateData = AppStateData(
            lastActiveDate: Date(),
            appVersion: Constants.App.version,
            sessionCount: getSessionCount() + 1
        )
        
        if let data = try? JSONEncoder().encode(appStateData) {
            UserDefaults.standard.set(data, forKey: "app_state_data")
        }
    }
    
    private func getSessionCount() -> Int {
        guard let data = UserDefaults.standard.data(forKey: "app_state_data"),
              let appStateData = try? JSONDecoder().decode(AppStateData.self, from: data) else {
            return 0
        }
        return appStateData.sessionCount
    }
    
    func getAppStateData() -> AppStateData? {
        guard let data = UserDefaults.standard.data(forKey: "app_state_data"),
              let appStateData = try? JSONDecoder().decode(AppStateData.self, from: data) else {
            return nil
        }
        return appStateData
    }

    // MARK: - Streak Management

    /// Updates the streak data by checking and updating the streak status
    private func updateStreakData() {
        streakStatus = streakService.checkAndUpdateStreak()
        currentStreak = streakService.currentStreak

        // Post notification if streak status changed significantly
        if case .expiringSoon(let hours) = streakStatus, hours <= 2 {
            postStreakExpiringNotification(hoursRemaining: hours)
        }
    }

    /// Manually refresh streak data (can be called from views)
    func refreshStreakData() {
        streakStatus = streakService.getStreakStatus()
        currentStreak = streakService.currentStreak
    }

    /// Attempts to use a streak freeze
    /// - Returns: true if freeze was successfully used
    func useStreakFreeze() -> Bool {
        let success = streakService.useStreakFreeze()
        if success {
            refreshStreakData()
        }
        return success
    }

    /// Gets all streak milestones with their unlock status
    func getStreakMilestones() -> [StreakMilestone] {
        return streakService.getMilestones()
    }

    /// Gets hours remaining until streak expires
    func getHoursUntilStreakExpiry() -> Int? {
        return streakService.getHoursUntilExpiry()
    }

    private func postStreakExpiringNotification(hoursRemaining: Int) {
        NotificationCenter.default.post(
            name: .streakExpiringSoon,
            object: nil,
            userInfo: ["hoursRemaining": hoursRemaining]
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

enum AppState {
    case active
    case background
    case terminated
}

struct AppStateData: Codable {
    let lastActiveDate: Date
    let appVersion: String
    let sessionCount: Int
}

extension Notification.Name {
    static let navigateToRoastGenerator = Notification.Name("navigateToRoastGenerator")
    static let generateWelcomeBackRoast = Notification.Name("generateWelcomeBackRoast")
    static let streakExpiringSoon = Notification.Name("streakExpiringSoon")
}
