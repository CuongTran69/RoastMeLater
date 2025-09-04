import Foundation
import UserNotifications

class NotificationScheduler {
    static let shared = NotificationScheduler()
    
    private init() {}
    
    func scheduleWorkdayNotifications(frequency: NotificationFrequency) {
        guard frequency != .disabled else { return }
        
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        let workHours = getWorkHours()
        let interval = frequency.intervalInSeconds
        
        // Schedule notifications for the next 7 days
        for day in 0..<7 {
            scheduleNotificationsForDay(day: day, workHours: workHours, interval: interval)
        }
    }
    
    private func getWorkHours() -> (start: Int, end: Int) {
        // Default work hours: 9 AM to 6 PM
        return (start: 9, end: 18)
    }
    
    private func scheduleNotificationsForDay(day: Int, workHours: (start: Int, end: Int), interval: TimeInterval) {
        let calendar = Calendar.current
        let now = Date()
        
        guard let startOfDay = calendar.date(byAdding: .day, value: day, to: calendar.startOfDay(for: now)) else { return }
        
        // Skip weekends
        let weekday = calendar.component(.weekday, from: startOfDay)
        if weekday == 1 || weekday == 7 { return } // Sunday = 1, Saturday = 7
        
        var currentTime = calendar.date(bySettingHour: workHours.start, minute: 0, second: 0, of: startOfDay)!
        let endTime = calendar.date(bySettingHour: workHours.end, minute: 0, second: 0, of: startOfDay)!
        
        var notificationCount = 0
        
        while currentTime < endTime && currentTime > now {
            let identifier = "workday_roast_\(day)_\(notificationCount)"
            scheduleNotification(at: currentTime, identifier: identifier)
            
            currentTime = currentTime.addingTimeInterval(interval)
            notificationCount += 1
        }
    }
    
    private func scheduleNotification(at date: Date, identifier: String) {
        let content = UNMutableNotificationContent()
        content.title = "🔥 RoastMe Break!"
        content.body = "Đã đến lúc nghỉ giải lao với một câu roast vui vẻ!"
        content.sound = .default
        content.badge = 1
        content.categoryIdentifier = "ROAST_CATEGORY"
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            }
        }
    }
    
    func setupNotificationCategories() {
        let generateAction = UNNotificationAction(
            identifier: "GENERATE_ROAST",
            title: "Tạo Roast Mới",
            options: [.foreground]
        )
        
        let viewHistoryAction = UNNotificationAction(
            identifier: "VIEW_HISTORY",
            title: "Xem Lịch Sử",
            options: [.foreground]
        )
        
        let roastCategory = UNNotificationCategory(
            identifier: "ROAST_CATEGORY",
            actions: [generateAction, viewHistoryAction],
            intentIdentifiers: [],
            options: []
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([roastCategory])
    }
    
    func scheduleTestNotification() {
        let content = UNMutableNotificationContent()
        content.title = "🔥 Test RoastMe"
        content.body = "Đây là thông báo test - ứng dụng đang hoạt động tốt!"
        content.sound = .default
        content.badge = 1
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(identifier: "test_notification", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling test notification: \(error.localizedDescription)")
            } else {
                print("Test notification scheduled successfully")
            }
        }
    }
    
    func getScheduledNotificationsInfo() -> [String] {
        var info: [String] = []
        
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            for request in requests {
                if let trigger = request.trigger as? UNCalendarNotificationTrigger,
                   let nextTriggerDate = trigger.nextTriggerDate() {
                    let formatter = DateFormatter()
                    formatter.dateStyle = .short
                    formatter.timeStyle = .short
                    info.append("\(request.identifier): \(formatter.string(from: nextTriggerDate))")
                } else if let trigger = request.trigger as? UNTimeIntervalNotificationTrigger {
                    info.append("\(request.identifier): in \(trigger.timeInterval) seconds")
                }
            }
        }
        
        return info
    }
}
