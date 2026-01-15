import Foundation

// MARK: - Settings Strings

extension Strings {
    enum Settings {
        // Navigation
        static let title = L("Settings", "Cài Đặt")
        
        // MARK: - Notifications Section
        enum Notifications {
            static let sectionTitle = L("Notifications", "Thông Báo")
            static let enableNotifications = L("Enable Notifications", "Bật thông báo")
            static let frequency = L("Frequency", "Tần suất")
            static let testNotification = L("Test Notification", "Test thông báo")
            static let testNotificationMessage = L(
                "Test notification will appear in 5 seconds!",
                "Thông báo test sẽ xuất hiện sau 5 giây!"
            )
            
            // Frequency Options
            static let disabled = L("Disabled", "Tắt")
            static let hourly = L("Every Hour", "Mỗi giờ")
            static let every2Hours = L("Every 2 Hours", "Mỗi 2 giờ")
            static let every4Hours = L("Every 4 Hours", "Mỗi 4 giờ")
            static let daily = L("Daily", "Hàng ngày")
        }
        
        // MARK: - Content Section
        enum Content {
            static let sectionTitle = L("Content", "Nội Dung")
            static let defaultSpiceLevel = L("Default spice level:", "Mức độ cay mặc định:")
            static let safetyFilters = L("Safety Filters", "Bộ lọc an toàn")
            static let language = L("Language", "Ngôn ngữ")
            static let vietnamese = L("Vietnamese", "Tiếng Việt")
            static let english = L("English", "Tiếng Anh")
        }
        
        // MARK: - API Configuration Section
        enum APIConfig {
            static let sectionTitle = L("API Configuration", "Cấu Hình API")
            static let description = L(
                "To use the roast generation feature, you need to provide an API key and URL of the AI service.",
                "Để sử dụng tính năng tạo roast, bạn cần cung cấp API key và URL của dịch vụ AI."
            )
            static let apiKey = L("API Key", "API Key")
            static let baseURL = L("Base URL", "Base URL")
            static let model = L("Model", "Model")
            static let testConnection = L("Test Connection", "Test Kết Nối")
            static let connectionSuccess = L("✅ API is working!", "✅ API hoạt động tốt!")
            static let connectionFailed = L("❌ Cannot connect to API", "❌ Không thể kết nối API")
            static let configSaved = L("Configuration saved", "Cấu hình đã được lưu")
        }
        
        // MARK: - Data Section
        enum Data {
            static let sectionTitle = L("Data", "Dữ Liệu")
            static let dataManagement = L("Data Management", "Quản Lý Dữ Liệu")
            static let dataManagementDesc = L(
                "Export, import, and manage your data",
                "Xuất, nhập và quản lý dữ liệu của bạn"
            )
            static let clearHistory = L("Clear History", "Xóa lịch sử roast")
            static let clearFavorites = L("Clear Favorites", "Xóa danh sách yêu thích")
            static let resetSettings = L("Reset All Settings", "Đặt lại tất cả cài đặt")
        }
        
        // MARK: - Version Section
        enum Version {
            static let sectionTitle = L("Version", "Phiên Bản")
            static let version = L("Version", "Phiên bản")
        }
        
        // MARK: - App Info Section
        enum AppInfo {
            static let sectionTitle = L("App Information", "Thông Tin Ứng Dụng")
            static let about = L("About", "Giới thiệu")
            static let rateApp = L("Rate App", "Đánh giá ứng dụng")
            static let contactSupport = L("Contact Support", "Liên hệ hỗ trợ")
        }
        
        // MARK: - Statistics Section
        enum Statistics {
            static let sectionTitle = L("Statistics", "Thống Kê")
            static let totalRoastsGenerated = L("Total roasts generated", "Tổng số roast đã tạo")
            static let favoriteRoasts = L("Favorite roasts", "Roast yêu thích")
            static let mostPopularCategory = L("Most popular category", "Danh mục phổ biến nhất")
            static let notAvailable = L("Not available", "Chưa có")
        }
    }
}

