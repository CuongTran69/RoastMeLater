import Foundation
import SwiftUI

class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()
    
    @Published var currentLanguage: String = "vi" {
        didSet {
            UserDefaults.standard.set(currentLanguage, forKey: "app_language")
        }
    }
    
    private init() {
        self.currentLanguage = UserDefaults.standard.string(forKey: "app_language") ?? "vi"
    }
    
    func setLanguage(_ language: String) {
        currentLanguage = language
    }
    
    // MARK: - Localized Strings
    
    // Tab Bar
    var tabRoast: String {
        currentLanguage == "en" ? "Roast" : "Roast"
    }
    
    var tabHistory: String {
        currentLanguage == "en" ? "History" : "Lịch sử"
    }
    
    var tabFavorites: String {
        currentLanguage == "en" ? "Favorites" : "Yêu thích"
    }
    
    var tabSettings: String {
        currentLanguage == "en" ? "Settings" : "Cài đặt"
    }
    
    // Common
    var ok: String {
        currentLanguage == "en" ? "OK" : "OK"
    }
    
    var cancel: String {
        currentLanguage == "en" ? "Cancel" : "Hủy"
    }
    
    var done: String {
        currentLanguage == "en" ? "Done" : "Xong"
    }
    
    var save: String {
        currentLanguage == "en" ? "Save" : "Lưu"
    }
    
    var delete: String {
        currentLanguage == "en" ? "Delete" : "Xóa"
    }
    
    var share: String {
        currentLanguage == "en" ? "Share" : "Chia sẻ"
    }
    
    var loading: String {
        currentLanguage == "en" ? "Loading..." : "Đang tải..."
    }
    
    var error: String {
        currentLanguage == "en" ? "Error" : "Lỗi"
    }
    
    // Roast Generator
    var generateRoast: String {
        currentLanguage == "en" ? "Generate New Roast" : "Tạo Roast Mới"
    }
    
    var generating: String {
        currentLanguage == "en" ? "Generating..." : "Đang tạo..."
    }
    
    var category: String {
        currentLanguage == "en" ? "Category" : "Danh mục"
    }
    
    var spiceLevel: String {
        currentLanguage == "en" ? "Spice Level" : "Mức độ cay"
    }
    
    var selectCategory: String {
        currentLanguage == "en" ? "Select Category" : "Chọn Danh Mục"
    }
    
    // Settings
    var notifications: String {
        currentLanguage == "en" ? "Notifications" : "Thông Báo"
    }
    
    var content: String {
        currentLanguage == "en" ? "Content" : "Nội Dung"
    }
    
    var data: String {
        currentLanguage == "en" ? "Data" : "Dữ Liệu"
    }
    
    var version: String {
        currentLanguage == "en" ? "Version" : "Phiên Bản"
    }
    
    var about: String {
        currentLanguage == "en" ? "About" : "Giới Thiệu"
    }
    
    var language: String {
        currentLanguage == "en" ? "Language" : "Ngôn ngữ"
    }
    
    var safetyFilters: String {
        currentLanguage == "en" ? "Safety Filters" : "Bộ lọc an toàn"
    }
    
    var exportSettings: String {
        currentLanguage == "en" ? "Export Settings" : "Xuất cài đặt"
    }
    
    var importSettings: String {
        currentLanguage == "en" ? "Import Settings" : "Nhập cài đặt"
    }
    
    var clearHistory: String {
        currentLanguage == "en" ? "Clear History" : "Xóa lịch sử roast"
    }
    
    var clearFavorites: String {
        currentLanguage == "en" ? "Clear Favorites" : "Xóa danh sách yêu thích"
    }
    
    var resetSettings: String {
        currentLanguage == "en" ? "Reset All Settings" : "Đặt lại tất cả cài đặt"
    }
    
    // Search
    var searchRoasts: String {
        currentLanguage == "en" ? "Search roasts..." : "Tìm kiếm roast..."
    }
    
    var searchFavorites: String {
        currentLanguage == "en" ? "Search favorites..." : "Tìm kiếm roast yêu thích..."
    }
    
    // Empty States
    var noHistory: String {
        currentLanguage == "en" ? "No History Yet" : "Chưa Có Lịch Sử"
    }
    
    var noFavorites: String {
        currentLanguage == "en" ? "No Favorites Yet" : "Chưa Có Yêu Thích"
    }
    
    var startGenerating: String {
        currentLanguage == "en" ? "Start generating roasts to see them here!" : "Bắt đầu tạo roast để xem chúng ở đây!"
    }
    
    var addFavorites: String {
        currentLanguage == "en" ? "Add some roasts to favorites to see them here!" : "Thêm một số roast vào yêu thích để xem chúng ở đây!"
    }
    
    // Categories
    func categoryName(_ category: RoastCategory) -> String {
        switch category {
        case .general:
            return currentLanguage == "en" ? "General" : "Chung"
        case .deadlines:
            return currentLanguage == "en" ? "Deadlines" : "Deadline"
        case .meetings:
            return currentLanguage == "en" ? "Meetings" : "Họp hành"
        case .kpis:
            return currentLanguage == "en" ? "KPIs" : "KPI"
        case .codeReviews:
            return currentLanguage == "en" ? "Code Reviews" : "Code Review"
        @unknown default:
            return currentLanguage == "en" ? "General" : "Chung"
        }
    }
    
    func categoryDescription(_ category: RoastCategory) -> String {
        switch category {
        case .general:
            return currentLanguage == "en" ? "General workplace humor" : "Hài hước chung về công việc"
        case .deadlines:
            return currentLanguage == "en" ? "About missing deadlines" : "Về việc trễ deadline"
        case .meetings:
            return currentLanguage == "en" ? "Meeting and discussion humor" : "Hài hước về họp hành"
        case .kpis:
            return currentLanguage == "en" ? "Performance metrics jokes" : "Đùa về chỉ số hiệu suất"
        case .codeReviews:
            return currentLanguage == "en" ? "Code review and programming" : "Code review và lập trình"
        @unknown default:
            return currentLanguage == "en" ? "General workplace humor" : "Hài hước chung về công việc"
        }
    }
    
    // Notification Frequency
    func notificationFrequencyName(_ frequency: NotificationFrequency) -> String {
        switch frequency {
        case .disabled:
            return currentLanguage == "en" ? "Disabled" : "Tắt"
        case .hourly:
            return currentLanguage == "en" ? "Every Hour" : "Mỗi giờ"
        case .every2Hours:
            return currentLanguage == "en" ? "Every 2 Hours" : "Mỗi 2 giờ"
        case .every4Hours:
            return currentLanguage == "en" ? "Every 4 Hours" : "Mỗi 4 giờ"
        case .daily:
            return currentLanguage == "en" ? "Daily" : "Hàng ngày"
        }
    }
    
    // Spice Level Names
    func spiceLevelName(_ level: Int) -> String {
        switch level {
        case 1:
            return currentLanguage == "en" ? "Mild" : "Nhẹ nhàng"
        case 2:
            return currentLanguage == "en" ? "Light" : "Nhẹ"
        case 3:
            return currentLanguage == "en" ? "Medium" : "Trung bình"
        case 4:
            return currentLanguage == "en" ? "Spicy" : "Cay nồng"
        case 5:
            return currentLanguage == "en" ? "Extra Hot" : "Cực cay"
        default:
            return currentLanguage == "en" ? "Medium" : "Trung bình"
        }
    }

    // Language Options
    var languageOptions: [(code: String, name: String)] {
        [
            ("vi", currentLanguage == "en" ? "Vietnamese" : "Tiếng Việt"),
            ("en", currentLanguage == "en" ? "English" : "Tiếng Anh")
        ]
    }
}

// MARK: - SwiftUI Environment
struct LocalizationEnvironmentKey: EnvironmentKey {
    static let defaultValue = LocalizationManager.shared
}

extension EnvironmentValues {
    var localization: LocalizationManager {
        get { self[LocalizationEnvironmentKey.self] }
        set { self[LocalizationEnvironmentKey.self] = newValue }
    }
}
