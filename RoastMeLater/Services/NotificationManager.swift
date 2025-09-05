import Foundation
import UserNotifications
import RxSwift

class NotificationManager: ObservableObject {
    private let storageService: StorageServiceProtocol
    private let aiService: AIServiceProtocol
    private let safetyFilter = SafetyFilter()
    private let disposeBag = DisposeBag()

    @Published var notificationPermissionGranted = false
    @Published var pendingNotificationsCount = 0

    init(storageService: StorageServiceProtocol = StorageService(),
         aiService: AIServiceProtocol = AIService()) {
        self.storageService = storageService
        self.aiService = aiService
        checkNotificationPermission()
        setupNotificationDelegate()
    }
    
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { [weak self] granted, error in
            DispatchQueue.main.async {
                self?.notificationPermissionGranted = granted
            }
            
            if granted {
                self?.scheduleHourlyNotifications()
            }
        }
    }
    
    private func checkNotificationPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.notificationPermissionGranted = settings.authorizationStatus == .authorized
            }
        }
    }
    
    func scheduleHourlyNotifications() {
        guard notificationPermissionGranted else { return }
        
        let preferences = storageService.getUserPreferences()
        guard preferences.notificationsEnabled, 
              preferences.notificationFrequency != .disabled else { return }
        
        // Clear existing notifications
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        // Schedule notifications for the next 24 hours
        let interval = preferences.notificationFrequency.intervalInSeconds
        let numberOfNotifications = Int(86400 / interval) // 24 hours worth
        
        for i in 1...numberOfNotifications {
            scheduleNotification(after: interval * Double(i), identifier: "roast_\(i)")
        }
    }
    
    private func scheduleNotification(after timeInterval: TimeInterval, identifier: String) {
        let content = UNMutableNotificationContent()
        content.title = "🔥 RoastMe Time!"
        content.body = "Đã đến lúc nhận một câu roast để giải tỏa stress rồi!"
        content.sound = .default
        content.badge = 1
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            }
        }
    }
    
    func generateAndScheduleRoastNotification() {
        let preferences = storageService.getUserPreferences()
        let randomCategory = preferences.preferredCategories.randomElement() ?? .general
        
        aiService.generateRoast(
            category: randomCategory,
            spiceLevel: preferences.defaultSpiceLevel,
            language: preferences.preferredLanguage
        )
        .subscribe(onNext: { [weak self] roast in
            self?.scheduleImmediateNotification(with: roast)
        }, onError: { error in
            print("Error generating roast for notification: \(error)")
        })
        .disposed(by: disposeBag)
    }
    
    private func scheduleImmediateNotification(with roast: Roast) {
        let content = UNMutableNotificationContent()
        content.title = "🔥 \(roast.category.displayName)"
        content.body = roast.content
        content.sound = .default
        content.badge = 1
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "immediate_roast", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling immediate notification: \(error.localizedDescription)")
            }
        }
        
        // Save the roast to history
        storageService.saveRoast(roast)
    }
    
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        updatePendingNotificationsCount()
    }

    private func setupNotificationDelegate() {
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
    }

    private func updatePendingNotificationsCount() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { [weak self] requests in
            DispatchQueue.main.async {
                self?.pendingNotificationsCount = requests.count
            }
        }
    }

    func getPendingNotifications() -> Observable<[UNNotificationRequest]> {
        return Observable.create { observer in
            UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
                observer.onNext(requests)
                observer.onCompleted()
            }
            return Disposables.create()
        }
    }

    func rescheduleNotificationsIfNeeded() {
        let preferences = storageService.getUserPreferences()

        if preferences.notificationsEnabled && notificationPermissionGranted {
            UNUserNotificationCenter.current().getPendingNotificationRequests { [weak self] requests in
                if requests.isEmpty {
                    DispatchQueue.main.async {
                        self?.scheduleHourlyNotifications()
                    }
                }
            }
        }
    }
}

// MARK: - Notification Delegate
class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()

    private override init() {
        super.init()
    }

    // Handle notification when app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                              willPresent notification: UNNotification,
                              withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge])
    }

    // Handle notification tap
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                              didReceive response: UNNotificationResponse,
                              withCompletionHandler completionHandler: @escaping () -> Void) {

        let identifier = response.notification.request.identifier

        if identifier.hasPrefix("roast_") {
            // Handle roast notification tap
            NotificationCenter.default.post(name: .roastNotificationTapped, object: nil)
        }

        completionHandler()
    }
}

extension Notification.Name {
    static let roastNotificationTapped = Notification.Name("roastNotificationTapped")
}
