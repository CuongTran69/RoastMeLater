import Foundation
import CryptoKit

// MARK: - Security Configuration

struct SecurityConfiguration {
    let excludeAPIKeys: Bool
    let excludeDeviceInfo: Bool
    let anonymizeContent: Bool
    let encryptSensitiveData: Bool
    let addWatermark: Bool
    
    static let `default` = SecurityConfiguration(
        excludeAPIKeys: true,
        excludeDeviceInfo: false,
        anonymizeContent: false,
        encryptSensitiveData: false,
        addWatermark: false
    )
    
    static let secure = SecurityConfiguration(
        excludeAPIKeys: true,
        excludeDeviceInfo: true,
        anonymizeContent: true,
        encryptSensitiveData: true,
        addWatermark: true
    )
}

// MARK: - Privacy Notice

struct PrivacyNotice {
    let title: String
    let description: String
    let dataTypes: [DataType]
    let recommendations: [String]
}

enum DataType {
    case roastContent
    case userPreferences
    case deviceInfo
    case apiConfiguration
    case usageStatistics
    
    var displayName: String {
        switch self {
        case .roastContent:
            return "Nội dung roast"
        case .userPreferences:
            return "Tùy chọn người dùng"
        case .deviceInfo:
            return "Thông tin thiết bị"
        case .apiConfiguration:
            return "Cấu hình API"
        case .usageStatistics:
            return "Thống kê sử dụng"
        }
    }
    
    var sensitivityLevel: SensitivityLevel {
        switch self {
        case .roastContent:
            return .medium
        case .userPreferences:
            return .low
        case .deviceInfo:
            return .low
        case .apiConfiguration:
            return .high
        case .usageStatistics:
            return .low
        }
    }
}

enum SensitivityLevel {
    case low, medium, high
    
    var color: String {
        switch self {
        case .low: return "green"
        case .medium: return "orange"
        case .high: return "red"
        }
    }
}

// MARK: - Data Sanitization

protocol DataSanitizationProtocol {
    func sanitizeUserPreferences(_ preferences: UserPreferences, config: SecurityConfiguration) -> UserPreferences
    func sanitizeRoasts(_ roasts: [Roast], config: SecurityConfiguration) -> [Roast]
    func sanitizeMetadata(_ metadata: ExportMetadata, config: SecurityConfiguration) -> ExportMetadata
    func generatePrivacyNotice(for config: SecurityConfiguration) -> PrivacyNotice
}

class DataSanitizationService: DataSanitizationProtocol {
    
    func sanitizeUserPreferences(_ preferences: UserPreferences, config: SecurityConfiguration) -> UserPreferences {
        var sanitized = preferences
        
        if config.excludeAPIKeys {
            // Remove API configuration
            sanitized.apiConfiguration = APIConfiguration()
        }
        
        return sanitized
    }
    
    func sanitizeRoasts(_ roasts: [Roast], config: SecurityConfiguration) -> [Roast] {
        if !config.anonymizeContent {
            return roasts
        }
        
        return roasts.map { roast in
            var sanitized = roast
            sanitized.content = anonymizeRoastContent(roast.content)
            return sanitized
        }
    }
    
    func sanitizeMetadata(_ metadata: ExportMetadata, config: SecurityConfiguration) -> ExportMetadata {
        var sanitized = metadata
        
        if config.excludeDeviceInfo {
            sanitized.deviceInfo = DeviceInfo(
                platform: "iOS",
                osVersion: "Hidden",
                appBuild: "Hidden"
            )
        }
        
        if config.addWatermark {
            // Add privacy watermark to version
            sanitized.version = "\(metadata.version)-PRIVACY"
        }
        
        return sanitized
    }
    
    func generatePrivacyNotice(for config: SecurityConfiguration) -> PrivacyNotice {
        var dataTypes: [DataType] = [.roastContent, .userPreferences, .usageStatistics]
        var recommendations: [String] = []
        
        if !config.excludeAPIKeys {
            dataTypes.append(.apiConfiguration)
            recommendations.append("API keys sẽ được bao gồm - chỉ chia sẻ với người tin cậy")
        }
        
        if !config.excludeDeviceInfo {
            dataTypes.append(.deviceInfo)
        }
        
        if config.anonymizeContent {
            recommendations.append("Nội dung roast đã được ẩn danh hóa cơ bản")
        }
        
        if config.encryptSensitiveData {
            recommendations.append("Dữ liệu nhạy cảm đã được mã hóa")
        }
        
        recommendations.append("Xem lại nội dung file trước khi chia sẻ")
        recommendations.append("Không tải lên dịch vụ đám mây công cộng")
        
        return PrivacyNotice(
            title: "Thông Tin Quyền Riêng Tư",
            description: "File xuất này chứa dữ liệu cá nhân của bạn. Vui lòng xem xét cẩn thận trước khi chia sẻ.",
            dataTypes: dataTypes,
            recommendations: recommendations
        )
    }
    
    // MARK: - Private Methods
    
    private func anonymizeRoastContent(_ content: String) -> String {
        var anonymized = content
        
        // Remove potential personal identifiers
        // This is a basic implementation - could be enhanced with more sophisticated NLP
        
        // Replace common personal references
        let personalPatterns = [
            ("tôi", "người dùng"),
            ("mình", "người dùng"),
            ("em", "người dùng"),
            ("anh", "đồng nghiệp"),
            ("chị", "đồng nghiệp"),
            ("sếp", "quản lý"),
            ("boss", "quản lý")
        ]
        
        for (original, replacement) in personalPatterns {
            anonymized = anonymized.replacingOccurrences(
                of: original,
                with: replacement,
                options: [.caseInsensitive, .diacriticInsensitive]
            )
        }
        
        // Remove potential company/project names (basic pattern matching)
        // Replace sequences of capital letters that might be company names
        let companyPattern = try! NSRegularExpression(pattern: "\\b[A-Z]{2,}\\b", options: [])
        anonymized = companyPattern.stringByReplacingMatches(
            in: anonymized,
            options: [],
            range: NSRange(location: 0, length: anonymized.count),
            withTemplate: "[COMPANY]"
        )
        
        return anonymized
    }
}

// MARK: - File Security

protocol FileSecurityProtocol {
    func setSecureFilePermissions(for url: URL) throws
    func validateFileIntegrity(_ url: URL) throws -> Bool
    func generateFileChecksum(_ url: URL) throws -> String
}

class FileSecurityService: FileSecurityProtocol {
    
    func setSecureFilePermissions(for url: URL) throws {
        // Set file permissions to be readable only by the owner
        let attributes = [FileAttributeKey.posixPermissions: 0o600]
        try FileManager.default.setAttributes(attributes, ofItemAtPath: url.path)
    }
    
    func validateFileIntegrity(_ url: URL) throws -> Bool {
        // Check if file exists and is readable
        guard FileManager.default.fileExists(atPath: url.path) else {
            return false
        }
        
        // Check file size is reasonable (not empty, not too large)
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
        guard let fileSize = attributes[.size] as? Int64 else {
            return false
        }
        
        // File should be between 1KB and 100MB
        return fileSize > 1024 && fileSize < 100 * 1024 * 1024
    }
    
    func generateFileChecksum(_ url: URL) throws -> String {
        let data = try Data(contentsOf: url)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - Privacy Compliance

struct PrivacyCompliance {
    static func validateExportCompliance(_ exportData: AppDataExport, config: SecurityConfiguration) -> [ComplianceIssue] {
        var issues: [ComplianceIssue] = []
        
        // Check for API keys in preferences
        if !config.excludeAPIKeys && !exportData.userPreferences.apiConfiguration.apiKey.isEmpty {
            issues.append(ComplianceIssue(
                type: .sensitiveDataIncluded,
                severity: .high,
                description: "API key được bao gồm trong file xuất",
                recommendation: "Xem xét loại bỏ API key để bảo mật"
            ))
        }
        
        // Check for device information
        if !config.excludeDeviceInfo {
            issues.append(ComplianceIssue(
                type: .deviceInfoIncluded,
                severity: .low,
                description: "Thông tin thiết bị được bao gồm",
                recommendation: "Thông tin này có thể được sử dụng để nhận dạng thiết bị"
            ))
        }
        
        // Check roast content for potential personal information
        let personalContentCount = exportData.roastHistory.filter { roast in
            containsPersonalInformation(roast.content)
        }.count
        
        if personalContentCount > 0 && !config.anonymizeContent {
            issues.append(ComplianceIssue(
                type: .personalContentDetected,
                severity: .medium,
                description: "Phát hiện \(personalContentCount) roast có thể chứa thông tin cá nhân",
                recommendation: "Xem xét bật tính năng ẩn danh hóa"
            ))
        }
        
        return issues
    }
    
    private static func containsPersonalInformation(_ content: String) -> Bool {
        let personalIndicators = ["tôi", "mình", "em", "tên tôi", "công ty tôi", "dự án của"]
        return personalIndicators.contains { indicator in
            content.lowercased().contains(indicator)
        }
    }
}

struct ComplianceIssue {
    let type: ComplianceIssueType
    let severity: ComplianceSeverity
    let description: String
    let recommendation: String
}

enum ComplianceIssueType {
    case sensitiveDataIncluded
    case deviceInfoIncluded
    case personalContentDetected
    case unencryptedData
}

enum ComplianceSeverity {
    case low, medium, high
    
    var color: String {
        switch self {
        case .low: return "yellow"
        case .medium: return "orange"
        case .high: return "red"
        }
    }
}

// MARK: - Secure Export Data

struct SecureExportData: Codable {
    let metadata: ExportMetadata
    let userPreferences: UserPreferences
    let roastHistory: [Roast]
    let favorites: [UUID]
    let statistics: ExportStatistics?
    let privacyNotice: PrivacyNoticeData
    let securityConfiguration: SecurityConfigurationData
    let checksum: String
}

struct PrivacyNoticeData: Codable {
    let title: String
    let description: String
    let dataTypes: [String]
    let recommendations: [String]
    let timestamp: Date
}

struct SecurityConfigurationData: Codable {
    let excludeAPIKeys: Bool
    let excludeDeviceInfo: Bool
    let anonymizeContent: Bool
    let encryptSensitiveData: Bool
    let addWatermark: Bool
}
