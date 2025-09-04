import Foundation
import SwiftUI

struct Constants {
    
    // MARK: - App Configuration
    struct App {
        static let name = "RoastMe"
        static let version = "1.0.0"
        static let bundleIdentifier = "com.roastme.app"
        static let supportEmail = "support@roastme.app"
        static let appStoreURL = "https://apps.apple.com/app/roastme"
    }
    
    // MARK: - API Configuration
    struct API {
        // Default OpenAI configuration
        static let openAIBaseURL = "https://api.openai.com/v1/chat/completions"
        static let openAIModel = "gpt-3.5-turbo"

        // Custom LLM configuration
        static let defaultBaseURL = ""  // Will be set from user preferences
        static let fixedModel = "anthropic:3.7-sonnet"  // Fixed model - không thay đổi

        // Request configuration
        static let requestTimeout: TimeInterval = 30.0
        static let maxRetries = 3
        static let maxTokens = 150
        static let temperature = 0.8
    }
    
    // MARK: - Storage Keys
    struct StorageKeys {
        static let roastHistory = "roast_history"
        static let userPreferences = "user_preferences"
        static let appStateData = "app_state_data"
        static let firstLaunch = "first_launch"
        static let lastNotificationSchedule = "last_notification_schedule"
        static let apiConfiguration = "api_configuration"
    }
    
    // MARK: - Notification Configuration
    struct Notifications {
        static let categoryIdentifier = "ROAST_CATEGORY"
        static let generateActionIdentifier = "GENERATE_ROAST"
        static let viewHistoryActionIdentifier = "VIEW_HISTORY"
        static let maxPendingNotifications = 64 // iOS limit
        static let defaultScheduleHours = 24
    }
    
    // MARK: - UI Configuration
    struct UI {
        static let cornerRadius: CGFloat = 12
        static let shadowRadius: CGFloat = 8
        static let shadowOpacity: Float = 0.1
        static let animationDuration: Double = 0.3
        static let hapticFeedbackEnabled = true
        
        struct Spacing {
            static let small: CGFloat = 8
            static let medium: CGFloat = 16
            static let large: CGFloat = 24
            static let extraLarge: CGFloat = 32
        }
        
        struct Colors {
            static let primary = Color.orange
            static let secondary = Color.red
            static let accent = Color.orange
            static let background = Color(.systemBackground)
            static let secondaryBackground = Color(.systemGray6)
        }
    }
    
    // MARK: - Content Limits
    struct Content {
        static let maxRoastLength = 280
        static let minRoastLength = 10
        static let maxHistoryItems = 100
        static let maxFavoriteItems = 50
        static let maxSpiceLevel = 5
        static let minSpiceLevel = 1
        static let defaultSpiceLevel = 3
    }
    
    // MARK: - Vietnamese Localization
    struct Vietnamese {
        struct Common {
            static let ok = "OK"
            static let cancel = "Hủy"
            static let done = "Xong"
            static let save = "Lưu"
            static let delete = "Xóa"
            static let edit = "Sửa"
            static let share = "Chia sẻ"
            static let retry = "Thử lại"
            static let loading = "Đang tải..."
            static let error = "Lỗi"
            static let success = "Thành công"
        }
        
        struct Roast {
            static let generate = "Tạo Roast Mới"
            static let generating = "Đang tạo..."
            static let favorite = "Yêu thích"
            static let unfavorite = "Bỏ thích"
            static let spiceLevel = "Mức độ cay"
            static let category = "Danh mục"
            static let content = "Nội dung"
            static let createdAt = "Tạo lúc"
        }
        
        struct Navigation {
            static let roast = "Roast"
            static let history = "Lịch Sử"
            static let favorites = "Yêu Thích"
            static let settings = "Cài Đặt"
        }
        
        struct Settings {
            static let notifications = "Thông Báo"
            static let content = "Nội Dung"
            static let data = "Dữ Liệu"
            static let about = "Giới Thiệu"
            static let frequency = "Tần suất"
            static let safetyFilters = "Bộ lọc an toàn"
            static let language = "Ngôn ngữ"
            static let preferredCategories = "Danh mục ưa thích"
        }
    }
    
    // MARK: - Default Roast Templates
    struct DefaultRoasts {
        static let templates: [RoastCategory: [String]] = [
            .deadlines: [
                "Deadline của bạn như lời hứa của chính trị gia - nghe hay nhưng khó tin!",
                "Bạn làm việc với deadline như rùa đua với thỏ, nhưng không có kết thúc có hậu!",
                "Deadline trong mắt bạn chỉ là... gợi ý, phải không?"
            ],
            .meetings: [
                "Meeting của bạn dài hơn cả phim Titanic, nhưng ít drama hơn!",
                "Cuộc họp của bạn như WiFi công ty - luôn chậm và hay bị gián đoạn!",
                "Bạn họp nhiều đến nỗi có thể mở công ty tư vấn về... cách họp!"
            ],
            .kpis: [
                "KPI của bạn như WiFi nhà hàng xóm - luôn yếu và không ổn định!",
                "Chỉ số của bạn tăng chậm như giá xăng... à không, giá xăng tăng nhanh hơn!",
                "KPI của bạn như thời tiết Sài Gòn - khó đoán và hay thay đổi!"
            ],
            .codeReviews: [
                "Code review của bạn như đi khám bệnh - ai cũng sợ nhưng cần thiết!",
                "Code của bạn như món phở - càng review càng thấy thiếu gia vị!",
                "Review code của bạn như giải mã hieroglyph Ai Cập!"
            ],
            .general: [
                "Bạn làm việc chăm chỉ như một con ốc sên đang thi chạy marathon!",
                "Hiệu suất làm việc của bạn như internet Việt Nam - có lúc nhanh, có lúc... chậm!",
                "Bạn multitask như Windows 95 - cố gắng nhưng hay bị treo!"
            ]
        ]
    }
    
    // MARK: - Feature Flags
    struct FeatureFlags {
        static let aiIntegrationEnabled = true
        static let notificationsEnabled = true
        static let shareFeatureEnabled = true
        static let statisticsEnabled = true
        static let exportImportEnabled = true
        static let debugModeEnabled = false
    }
    
    // MARK: - Analytics Events
    struct Analytics {
        static let roastGenerated = "roast_generated"
        static let roastFavorited = "roast_favorited"
        static let roastShared = "roast_shared"
        static let notificationScheduled = "notification_scheduled"
        static let settingsChanged = "settings_changed"
        static let appLaunched = "app_launched"
        static let categorySelected = "category_selected"
        static let spiceLevelChanged = "spice_level_changed"
    }
}

// MARK: - Environment Configuration
extension Constants {
    static var isDebug: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
    
    static var isSimulator: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }
}
