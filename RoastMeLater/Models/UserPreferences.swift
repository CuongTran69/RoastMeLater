import Foundation

struct UserPreferences: Codable {
    var preferredLanguage: String
    var notificationsEnabled: Bool
    var notificationFrequency: NotificationFrequency
    var preferredCategories: [RoastCategory]
    var safetyFiltersEnabled: Bool
    var defaultCategory: RoastCategory
    var defaultSpiceLevel: Int

    // API Configuration
    var apiConfiguration: APIConfiguration

    init() {
        self.preferredLanguage = "vi"
        self.notificationsEnabled = true
        self.notificationFrequency = .hourly
        self.preferredCategories = RoastCategory.allCases
        self.safetyFiltersEnabled = true
        self.defaultCategory = .general
        self.defaultSpiceLevel = 3
        self.apiConfiguration = APIConfiguration()
    }
}

struct APIConfiguration: Codable {
    var apiKey: String
    var baseURL: String

    // Model cố định - không cần lưu trong preferences
    var modelName: String {
        return Constants.API.fixedModel
    }

    init() {
        self.apiKey = ""
        self.baseURL = ""
    }

    init(apiKey: String, baseURL: String) {
        self.apiKey = apiKey
        self.baseURL = baseURL
    }
}

enum NotificationFrequency: String, CaseIterable, Codable {
    case disabled = "disabled"
    case hourly = "hourly"
    case every2Hours = "every_2_hours"
    case every4Hours = "every_4_hours"
    case daily = "daily"
    
    var displayName: String {
        switch self {
        case .disabled:
            return "Tắt thông báo"
        case .hourly:
            return "Mỗi giờ"
        case .every2Hours:
            return "Mỗi 2 giờ"
        case .every4Hours:
            return "Mỗi 4 giờ"
        case .daily:
            return "Mỗi ngày"
        }
    }
    
    var intervalInSeconds: TimeInterval {
        switch self {
        case .disabled:
            return 0
        case .hourly:
            return 3600 // 1 hour
        case .every2Hours:
            return 7200 // 2 hours
        case .every4Hours:
            return 14400 // 4 hours
        case .daily:
            return 86400 // 24 hours
        }
    }
}
