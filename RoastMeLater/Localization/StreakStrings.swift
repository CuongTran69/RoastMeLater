import Foundation

// MARK: - Streak Strings

extension Strings {
    enum Streak {
        // Section Title
        static let sectionTitle = L("Streak", "Chuỗi hoạt động")
        
        // Status
        static let currentStreak = L("Current Streak", "Chuỗi hiện tại")
        static let longestStreak = L("Longest Streak", "Chuỗi dài nhất")
        static let totalDays = L("Total Days", "Tổng ngày")
        static let totalActiveDays = L("Total Active Days", "Tổng ngày hoạt động")
        
        // Status Labels
        static let active = L("Active", "Đang hoạt động")
        static let expiringSoon = L("Expiring Soon!", "Sắp hết hạn!")
        static let expired = L("Expired", "Đã hết hạn")
        static let frozen = L("Frozen", "Đã đóng băng")
        static let welcome = L("Welcome!", "Chào mừng!")
        
        // Freeze
        static let freeze = L("Freeze", "Đóng băng")
        static let freezeAvailable = L("Freeze Available", "Có thể đóng băng")
        static let freezeUsed = L("Freeze Used", "Đã dùng đóng băng")
        static let useStreakFreeze = L("Use Streak Freeze", "Sử dụng đóng băng streak")
        static let useStreakFreezeConfirm = L("Use Streak Freeze?", "Sử dụng đóng băng streak?")
        static let useStreakFreezeMessage = L(
            "This will restore your streak. You can only use this once!",
            "Điều này sẽ khôi phục streak của bạn. Bạn chỉ có thể sử dụng một lần!"
        )
        static let useFreeze = L("Use Freeze", "Sử dụng")
        
        // Milestones
        static let milestones = L("Milestones", "Cột mốc")
        static let streakMilestones = L("Streak Milestones", "Cột mốc streak")
        static let yourProgress = L("Your Progress", "Tiến độ của bạn")
        static let current = L("Current", "Hiện tại")
        static let best = L("Best", "Tốt nhất")
        static let total = L("Total", "Tổng")
        
        // Dynamic
        static func expiringIn(_ hours: Int) -> L {
            return L("Expiring in \(hours)h", "Hết hạn sau \(hours)h")
        }
        
        static func hoursLeft(_ hours: Int) -> L {
            return L("\(hours) hours left", "\(hours) giờ còn lại")
        }
        
        static func daysCount(_ count: Int) -> L {
            return L("\(count) days", "\(count) ngày")
        }
    }
}

