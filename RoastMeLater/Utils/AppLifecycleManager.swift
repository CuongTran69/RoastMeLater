import Foundation
import UIKit
import UserNotifications
import RxSwift

class AppLifecycleManager: ObservableObject {
    static let shared = AppLifecycleManager()
    
    private let disposeBag = DisposeBag()
    private let notificationManager: NotificationManager
    private let storageService: StorageServiceProtocol
    
    @Published var appState: AppState = .active
    @Published var backgroundTime: Date?
    
    private init() {
        self.notificationManager = NotificationManager()
        self.storageService = StorageService()
        
        setupLifecycleObservers()
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
                "spiceLevel": preferences.spiceLevel
            ]
        )
    }
    
    private func saveAppState() {
        // Save any important app state data
        let appStateData = AppStateData(
            lastActiveDate: Date(),
            appVersion: "1.0.0",
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
}
