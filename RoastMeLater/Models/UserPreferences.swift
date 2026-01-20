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
        self.safetyFiltersEnabled = false  // Allow full spice level range
        self.defaultCategory = .general
        self.defaultSpiceLevel = 3
        self.apiConfiguration = APIConfiguration()
    }
}

/// API Configuration - Note: API key is stored securely in Keychain, not in UserDefaults
/// The apiKey property here is only used for in-memory operations and migration
struct APIConfiguration: Codable {
    var apiKey: String
    var baseURL: String
    var modelName: String

    // Custom coding keys to exclude apiKey from persistence
    private enum CodingKeys: String, CodingKey {
        case baseURL
        case modelName
        // apiKey is intentionally excluded - stored in Keychain
    }

    init() {
        self.apiKey = ""
        self.baseURL = ""
        self.modelName = Constants.API.defaultModel
    }

    init(apiKey: String, baseURL: String, modelName: String = Constants.API.defaultModel) {
        self.apiKey = apiKey
        self.baseURL = baseURL
        self.modelName = modelName
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.baseURL = try container.decodeIfPresent(String.self, forKey: .baseURL) ?? ""
        self.modelName = try container.decodeIfPresent(String.self, forKey: .modelName) ?? Constants.API.defaultModel
        // Load API key from Keychain instead of UserDefaults
        self.apiKey = KeychainService.shared.getAPIKey()
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(baseURL, forKey: .baseURL)
        try container.encode(modelName, forKey: .modelName)
        // API key is NOT encoded - it's stored in Keychain separately
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
