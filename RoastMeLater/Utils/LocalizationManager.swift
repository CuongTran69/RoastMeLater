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

    // MARK: - Enhanced Data Management

    var dataManagement: String {
        currentLanguage == "en" ? "Data Management" : "Quản Lý Dữ Liệu"
    }

    var exportData: String {
        currentLanguage == "en" ? "Export Data" : "Xuất Dữ Liệu"
    }

    var importData: String {
        currentLanguage == "en" ? "Import Data" : "Nhập Dữ Liệu"
    }

    var exportAllData: String {
        currentLanguage == "en" ? "Export All Data" : "Xuất Tất Cả Dữ Liệu"
    }

    var exportOptions: String {
        currentLanguage == "en" ? "Export Options" : "Tùy Chọn Xuất"
    }

    var importPreview: String {
        currentLanguage == "en" ? "Import Preview" : "Xem Trước Nhập"
    }

    var dataOverview: String {
        currentLanguage == "en" ? "Data Overview" : "Tổng Quan Dữ Liệu"
    }

    var totalRoasts: String {
        currentLanguage == "en" ? "Total Roasts" : "Tổng Roast"
    }

    var favorites: String {
        currentLanguage == "en" ? "Favorites" : "Yêu Thích"
    }

    var mostPopular: String {
        currentLanguage == "en" ? "Most Popular:" : "Phổ biến nhất:"
    }

    // Export/Import Progress
    var preparing: String {
        currentLanguage == "en" ? "Preparing..." : "Chuẩn bị..."
    }

    var collectingData: String {
        currentLanguage == "en" ? "Collecting data..." : "Thu thập dữ liệu..."
    }

    var processingRoasts: String {
        currentLanguage == "en" ? "Processing roasts..." : "Xử lý roast..."
    }

    var processingFavorites: String {
        currentLanguage == "en" ? "Processing favorites..." : "Xử lý yêu thích..."
    }

    var generatingMetadata: String {
        currentLanguage == "en" ? "Generating metadata..." : "Tạo metadata..."
    }

    var serializing: String {
        currentLanguage == "en" ? "Creating JSON file..." : "Tạo file JSON..."
    }

    var writing: String {
        currentLanguage == "en" ? "Saving file..." : "Lưu file..."
    }

    var validating: String {
        currentLanguage == "en" ? "Validating data..." : "Xác thực dữ liệu..."
    }

    var parsing: String {
        currentLanguage == "en" ? "Parsing data..." : "Phân tích dữ liệu..."
    }

    var processingPreferences: String {
        currentLanguage == "en" ? "Processing settings..." : "Xử lý cài đặt..."
    }

    var saving: String {
        currentLanguage == "en" ? "Saving data..." : "Lưu dữ liệu..."
    }

    var completed: String {
        currentLanguage == "en" ? "Completed!" : "Hoàn thành!"
    }

    var exportSuccess: String {
        currentLanguage == "en" ? "Export successful!" : "Xuất dữ liệu thành công!"
    }

    var importSuccess: String {
        currentLanguage == "en" ? "Import successful!" : "Nhập dữ liệu thành công!"
    }

    // Export Options
    var apiConfiguration: String {
        currentLanguage == "en" ? "API Configuration" : "Cấu Hình API"
    }

    var deviceInformation: String {
        currentLanguage == "en" ? "Device Information" : "Thông Tin Thiết Bị"
    }

    var usageStatistics: String {
        currentLanguage == "en" ? "Usage Statistics" : "Thống Kê Sử Dụng"
    }

    var anonymizeData: String {
        currentLanguage == "en" ? "Anonymize Data" : "Ẩn Danh Dữ Liệu"
    }

    var includeAPIKeys: String {
        currentLanguage == "en" ? "Include API keys and endpoints (not recommended for sharing)" : "Bao gồm API key và endpoint (không khuyến nghị khi chia sẻ)"
    }

    var includeDeviceInfo: String {
        currentLanguage == "en" ? "Include device model and iOS version for compatibility" : "Bao gồm model thiết bị và phiên bản iOS để tương thích"
    }

    var includeStats: String {
        currentLanguage == "en" ? "Include category breakdown and usage patterns" : "Bao gồm phân tích danh mục và mẫu sử dụng"
    }

    var anonymizeDescription: String {
        currentLanguage == "en" ? "Remove potentially identifying information from roast content" : "Loại bỏ thông tin có thể nhận dạng khỏi nội dung roast"
    }

    var whatsAlwaysIncluded: String {
        currentLanguage == "en" ? "What's Always Included" : "Luôn Được Bao Gồm"
    }

    var exportDetails: String {
        currentLanguage == "en" ? "Export Details" : "Chi Tiết Xuất"
    }

    var securityWarning: String {
        currentLanguage == "en" ? "Security Warning" : "Cảnh Báo Bảo Mật"
    }

    var apiKeyWarning: String {
        currentLanguage == "en" ? "API keys will be included in plain text. Only share this file with trusted recipients." : "API key sẽ được bao gồm dưới dạng văn bản thuần. Chỉ chia sẻ file này với người tin cậy."
    }

    var anonymizationNote: String {
        currentLanguage == "en" ? "Anonymization Note" : "Lưu Ý Ẩn Danh"
    }

    var anonymizationDescription: String {
        currentLanguage == "en" ? "Basic anonymization will be applied. Review exported content before sharing." : "Ẩn danh cơ bản sẽ được áp dụng. Xem lại nội dung đã xuất trước khi chia sẻ."
    }

    // MARK: - Import Preview

    var fileInformation: String {
        currentLanguage == "en" ? "File Information" : "Thông Tin File"
    }

    var appVersion: String {
        currentLanguage == "en" ? "App Version" : "Phiên bản ứng dụng"
    }

    var exportDate: String {
        currentLanguage == "en" ? "Export Date" : "Ngày xuất"
    }

    var dataVersion: String {
        currentLanguage == "en" ? "Data Version" : "Phiên bản dữ liệu"
    }

    var device: String {
        currentLanguage == "en" ? "Device" : "Thiết bị"
    }

    var dataSummary: String {
        currentLanguage == "en" ? "Data Summary" : "Tổng Quan Dữ Liệu"
    }

    func newItems(_ count: Int) -> String {
        currentLanguage == "en" ? "\(count) new" : "\(count) mới"
    }

    func duplicateRoastsFound(_ count: Int) -> String {
        currentLanguage == "en" ? "\(count) duplicate roasts found" : "Tìm thấy \(count) roast trùng lặp"
    }

    var importOptions: String {
        currentLanguage == "en" ? "Import Options" : "Tùy Chọn Nhập"
    }

    var importStrategy: String {
        currentLanguage == "en" ? "Import Strategy" : "Chiến lược nhập"
    }

    var mergeWithExisting: String {
        currentLanguage == "en" ? "Merge with existing data" : "Gộp với dữ liệu hiện có"
    }

    var replaceAllData: String {
        currentLanguage == "en" ? "Replace all existing data" : "Thay thế toàn bộ dữ liệu"
    }

    var skipDuplicates: String {
        currentLanguage == "en" ? "Skip duplicate roasts" : "Bỏ qua roast trùng lặp"
    }

    var keepExistingFavorites: String {
        currentLanguage == "en" ? "Keep existing favorites" : "Giữ danh sách yêu thích hiện có"
    }

    var warnings: String {
        currentLanguage == "en" ? "Warnings" : "Cảnh Báo"
    }

    func moreWarnings(_ count: Int) -> String {
        currentLanguage == "en" ? "... and \(count) more warnings" : "... và \(count) cảnh báo khác"
    }

    var settingsChanges: String {
        currentLanguage == "en" ? "Settings Changes" : "Thay Đổi Cài Đặt"
    }

    var incompatibleDataWarning: String {
        currentLanguage == "en" ? "This data may not be fully compatible with the current app version." : "Dữ liệu này có thể không hoàn toàn tương thích với phiên bản ứng dụng hiện tại."
    }

    var whatWouldYouLikeToDo: String {
        currentLanguage == "en" ? "What would you like to do?" : "Bạn muốn làm gì?"
    }

    // MARK: - Error Handling

    var operationFailed: String {
        currentLanguage == "en" ? "Operation Failed" : "Thao Tác Thất Bại"
    }

    var errorDetails: String {
        currentLanguage == "en" ? "Error Details" : "Chi Tiết Lỗi"
    }

    var operation: String {
        currentLanguage == "en" ? "Operation" : "Thao tác"
    }

    var phase: String {
        currentLanguage == "en" ? "Phase" : "Giai đoạn"
    }

    var progress: String {
        currentLanguage == "en" ? "Progress" : "Tiến độ"
    }

    var time: String {
        currentLanguage == "en" ? "Time" : "Thời gian"
    }

    var suggestion: String {
        currentLanguage == "en" ? "Suggestion:" : "Gợi ý:"
    }

    var recommended: String {
        currentLanguage == "en" ? "Recommended" : "Khuyến nghị"
    }

    var retry: String {
        currentLanguage == "en" ? "Retry" : "Thử lại"
    }

    var skip: String {
        currentLanguage == "en" ? "Skip" : "Bỏ qua"
    }

    var abort: String {
        currentLanguage == "en" ? "Abort" : "Hủy bỏ"
    }

    var freeUpStorage: String {
        currentLanguage == "en" ? "Free Up Storage" : "Giải phóng dung lượng"
    }

    var skipCorruptedData: String {
        currentLanguage == "en" ? "Skip Corrupted Data" : "Bỏ qua dữ liệu lỗi"
    }

    var stopOperation: String {
        currentLanguage == "en" ? "Stop Operation" : "Dừng thao tác"
    }

    var checkConnection: String {
        currentLanguage == "en" ? "Check Connection" : "Kiểm tra kết nối"
    }

    // MARK: - Data Management Descriptions

    var exportDescription: String {
        currentLanguage == "en" ? "Export your roast history, favorites, and settings to a JSON file for backup or transfer." : "Xuất lịch sử roast, danh sách yêu thích và cài đặt ra file JSON để sao lưu hoặc chuyển đổi."
    }

    var importDescription: String {
        currentLanguage == "en" ? "Import previously exported data from a JSON file. You can choose to merge with existing data or replace it completely." : "Nhập dữ liệu đã xuất trước đó từ file JSON. Bạn có thể chọn gộp với dữ liệu hiện có hoặc thay thế hoàn toàn."
    }

    var dataManagementDescription: String {
        currentLanguage == "en" ? "Export, import, and manage your data" : "Xuất, nhập và quản lý dữ liệu của bạn"
    }

    // MARK: - Helper Methods

    func operationName(_ operation: DataOperation) -> String {
        switch operation {
        case .export:
            return exportData
        case .dataImport:
            return importData
        case .validation:
            return currentLanguage == "en" ? "Data Validation" : "Xác Thực Dữ Liệu"
        }
    }

    // Bullet points for export details
    var allRoastHistory: String {
        currentLanguage == "en" ? "All roast history and content" : "Toàn bộ lịch sử và nội dung roast"
    }

    var favoriteRoastsList: String {
        currentLanguage == "en" ? "Favorite roasts list" : "Danh sách roast yêu thích"
    }

    var userPreferencesAndSettings: String {
        currentLanguage == "en" ? "User preferences and settings" : "Tùy chọn và cài đặt người dùng"
    }

    var exportMetadataAndTimestamp: String {
        currentLanguage == "en" ? "Export metadata and timestamp" : "Metadata và thời gian xuất"
    }

    // Language settings
    func languageChange(from: String, to: String) -> String {
        currentLanguage == "en" ? "Language: \(from) → \(to)" : "Ngôn ngữ: \(from) → \(to)"
    }

    func spiceLevelChange(from: Int, to: Int) -> String {
        currentLanguage == "en" ? "Default spice level: \(from) → \(to)" : "Mức độ cay mặc định: \(from) → \(to)"
    }

    func notificationChange(from: Bool, to: Bool) -> String {
        let fromText = from ? (currentLanguage == "en" ? "On" : "Bật") : (currentLanguage == "en" ? "Off" : "Tắt")
        let toText = to ? (currentLanguage == "en" ? "On" : "Bật") : (currentLanguage == "en" ? "Off" : "Tắt")
        return currentLanguage == "en" ? "Notifications: \(fromText) → \(toText)" : "Thông báo: \(fromText) → \(toText)"
    }

    func safetyFilterChange(from: Bool, to: Bool) -> String {
        let fromText = from ? (currentLanguage == "en" ? "On" : "Bật") : (currentLanguage == "en" ? "Off" : "Tắt")
        let toText = to ? (currentLanguage == "en" ? "On" : "Bật") : (currentLanguage == "en" ? "Off" : "Tắt")
        return currentLanguage == "en" ? "Safety filters: \(fromText) → \(toText)" : "Bộ lọc an toàn: \(fromText) → \(toText)"
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
