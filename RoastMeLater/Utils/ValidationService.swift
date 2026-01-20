import Foundation

enum ValidationResult: Equatable {
    case valid
    case invalid(message: String)
    
    var isValid: Bool {
        if case .valid = self { return true }
        return false
    }
    
    var errorMessage: String? {
        if case .invalid(let message) = self { return message }
        return nil
    }
}

struct ValidationService {
    
    // MARK: - Constants
    
    struct Limits {
        static let apiKeyMinLength = 20
        static let apiKeyMaxLength = 200
        static let modelNameMinLength = 3
        static let modelNameMaxLength = 100
        static let spiceLevelMin = 1
        static let spiceLevelMax = 5
        static let maxTextInputLength = 1000
    }
    
    // MARK: - API Key Validation
    
    static func validateAPIKey(_ key: String, language: String = "vi") -> ValidationResult {
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmed.isEmpty {
            return .invalid(message: language == "en" 
                ? "API key is required" 
                : "API key là bắt buộc")
        }
        
        if trimmed.count < Limits.apiKeyMinLength {
            return .invalid(message: language == "en"
                ? "API key must be at least \(Limits.apiKeyMinLength) characters"
                : "API key phải có ít nhất \(Limits.apiKeyMinLength) ký tự")
        }
        
        if trimmed.count > Limits.apiKeyMaxLength {
            return .invalid(message: language == "en"
                ? "API key must not exceed \(Limits.apiKeyMaxLength) characters"
                : "API key không được vượt quá \(Limits.apiKeyMaxLength) ký tự")
        }
        
        let allowedCharacters = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
        if trimmed.unicodeScalars.contains(where: { !allowedCharacters.contains($0) }) {
            return .invalid(message: language == "en"
                ? "API key contains invalid characters"
                : "API key chứa ký tự không hợp lệ")
        }
        
        return .valid
    }
    
    // MARK: - Base URL Validation
    
    static func validateBaseURL(_ urlString: String, requireHTTPS: Bool = true, language: String = "vi") -> ValidationResult {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmed.isEmpty {
            return .invalid(message: language == "en"
                ? "Base URL is required"
                : "URL cơ sở là bắt buộc")
        }
        
        if trimmed.contains(" ") {
            return .invalid(message: language == "en"
                ? "URL must not contain spaces"
                : "URL không được chứa khoảng trắng")
        }
        
        guard let url = URL(string: trimmed) else {
            return .invalid(message: language == "en"
                ? "Invalid URL format"
                : "Định dạng URL không hợp lệ")
        }
        
        guard let scheme = url.scheme?.lowercased() else {
            return .invalid(message: language == "en"
                ? "URL must include protocol (https://)"
                : "URL phải bao gồm giao thức (https://)")
        }
        
        if requireHTTPS && scheme != "https" {
            return .invalid(message: language == "en"
                ? "URL must use HTTPS protocol"
                : "URL phải sử dụng giao thức HTTPS")
        }
        
        if !requireHTTPS && scheme != "http" && scheme != "https" {
            return .invalid(message: language == "en"
                ? "URL must use HTTP or HTTPS protocol"
                : "URL phải sử dụng giao thức HTTP hoặc HTTPS")
        }
        
        guard url.host != nil, !url.host!.isEmpty else {
            return .invalid(message: language == "en"
                ? "URL must include a valid domain"
                : "URL phải bao gồm tên miền hợp lệ")
        }
        
        return .valid
    }
    
    // MARK: - Model Name Validation
    
    static func validateModelName(_ name: String, language: String = "vi") -> ValidationResult {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmed.isEmpty {
            return .valid // Model name is optional
        }
        
        if trimmed.count < Limits.modelNameMinLength {
            return .invalid(message: language == "en"
                ? "Model name must be at least \(Limits.modelNameMinLength) characters"
                : "Tên model phải có ít nhất \(Limits.modelNameMinLength) ký tự")
        }
        
        if trimmed.count > Limits.modelNameMaxLength {
            return .invalid(message: language == "en"
                ? "Model name must not exceed \(Limits.modelNameMaxLength) characters"
                : "Tên model không được vượt quá \(Limits.modelNameMaxLength) ký tự")
        }
        
        let allowedCharacters = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_:."))
        if trimmed.unicodeScalars.contains(where: { !allowedCharacters.contains($0) }) {
            return .invalid(message: language == "en"
                ? "Model name contains invalid characters"
                : "Tên model chứa ký tự không hợp lệ")
        }
        
        return .valid
    }

    // MARK: - Spice Level Validation

    static func validateSpiceLevel(_ level: Int) -> Int {
        return min(max(level, Limits.spiceLevelMin), Limits.spiceLevelMax)
    }

    static func isValidSpiceLevel(_ level: Int) -> Bool {
        return level >= Limits.spiceLevelMin && level <= Limits.spiceLevelMax
    }

    // MARK: - Category Validation

    static func isValidCategory(_ category: RoastCategory) -> Bool {
        return RoastCategory.allCases.contains(category)
    }

    // MARK: - Text Sanitization

    static func sanitizeTextInput(_ text: String, maxLength: Int = Limits.maxTextInputLength) -> String {
        var sanitized = text.trimmingCharacters(in: .whitespacesAndNewlines)

        // Remove null characters and control characters (except newlines and tabs)
        let controlCharacters = CharacterSet.controlCharacters.subtracting(CharacterSet(charactersIn: "\n\t"))
        sanitized = sanitized.unicodeScalars.filter { !controlCharacters.contains($0) }.map { String($0) }.joined()

        // Enforce max length
        if sanitized.count > maxLength {
            sanitized = String(sanitized.prefix(maxLength))
        }

        return sanitized
    }

    // MARK: - Combined API Configuration Validation

    static func validateAPIConfiguration(
        apiKey: String,
        baseURL: String,
        modelName: String,
        language: String = "vi"
    ) -> (apiKeyError: String?, baseURLError: String?, modelNameError: String?, isValid: Bool) {
        let apiKeyResult = validateAPIKey(apiKey, language: language)
        let baseURLResult = validateBaseURL(baseURL, language: language)
        let modelNameResult = validateModelName(modelName, language: language)

        let isValid = apiKeyResult.isValid && baseURLResult.isValid && modelNameResult.isValid

        return (
            apiKeyError: apiKeyResult.errorMessage,
            baseURLError: baseURLResult.errorMessage,
            modelNameError: modelNameResult.errorMessage,
            isValid: isValid
        )
    }
}

