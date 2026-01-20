import Foundation
import Security

/// Service for securely storing sensitive data in iOS Keychain
/// This replaces insecure UserDefaults storage for API keys and other credentials
final class KeychainService {
    
    // MARK: - Singleton
    static let shared = KeychainService()
    
    private init() {}
    
    // MARK: - Keychain Keys
    private enum KeychainKey: String {
        case apiKey = "com.roastmelater.apiKey"
        case baseURL = "com.roastmelater.baseURL"
        case modelName = "com.roastmelater.modelName"
    }
    
    // MARK: - Error Types
    enum KeychainError: Error {
        case duplicateItem
        case itemNotFound
        case unexpectedStatus(OSStatus)
        case invalidData
        
        var localizedDescription: String {
            switch self {
            case .duplicateItem:
                return "Item already exists in Keychain"
            case .itemNotFound:
                return "Item not found in Keychain"
            case .unexpectedStatus(let status):
                return "Keychain error: \(status)"
            case .invalidData:
                return "Invalid data format"
            }
        }
    }
    
    // MARK: - Generic Keychain Operations
    
    private func save(_ data: Data, forKey key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        // Delete existing item first
        SecItemDelete(query as CFDictionary)
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            throw KeychainError.unexpectedStatus(status)
        }
    }
    
    private func load(forKey key: String) throws -> Data {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                throw KeychainError.itemNotFound
            }
            throw KeychainError.unexpectedStatus(status)
        }
        
        guard let data = result as? Data else {
            throw KeychainError.invalidData
        }
        
        return data
    }
    
    private func delete(forKey key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unexpectedStatus(status)
        }
    }
    
    // MARK: - String Convenience Methods
    
    private func saveString(_ string: String, forKey key: String) throws {
        guard let data = string.data(using: .utf8) else {
            throw KeychainError.invalidData
        }
        try save(data, forKey: key)
    }
    
    private func loadString(forKey key: String) -> String? {
        guard let data = try? load(forKey: key),
              let string = String(data: data, encoding: .utf8) else {
            return nil
        }
        return string
    }
    
    // MARK: - API Configuration Methods
    
    /// Save API key securely to Keychain
    func saveAPIKey(_ apiKey: String) {
        do {
            try saveString(apiKey, forKey: KeychainKey.apiKey.rawValue)
            #if DEBUG
            print("✅ [Keychain] API key saved securely")
            #endif
        } catch {
            #if DEBUG
            print("❌ [Keychain] Failed to save API key: \(error)")
            #endif
        }
    }
    
    /// Retrieve API key from Keychain
    func getAPIKey() -> String {
        return loadString(forKey: KeychainKey.apiKey.rawValue) ?? ""
    }
    
    /// Save base URL to Keychain
    func saveBaseURL(_ baseURL: String) {
        do {
            try saveString(baseURL, forKey: KeychainKey.baseURL.rawValue)
        } catch {
            #if DEBUG
            print("❌ [Keychain] Failed to save base URL: \(error)")
            #endif
        }
    }
    
    /// Retrieve base URL from Keychain
    func getBaseURL() -> String {
        return loadString(forKey: KeychainKey.baseURL.rawValue) ?? ""
    }
    
    /// Save model name to Keychain
    func saveModelName(_ modelName: String) {
        do {
            try saveString(modelName, forKey: KeychainKey.modelName.rawValue)
        } catch {
            #if DEBUG
            print("❌ [Keychain] Failed to save model name: \(error)")
            #endif
        }
    }
    
    /// Retrieve model name from Keychain
    func getModelName() -> String {
        return loadString(forKey: KeychainKey.modelName.rawValue) ?? Constants.API.defaultModel
    }

    /// Save complete API configuration
    func saveAPIConfiguration(_ config: APIConfiguration) {
        saveAPIKey(config.apiKey)
        saveBaseURL(config.baseURL)
        saveModelName(config.modelName)
    }

    /// Retrieve complete API configuration
    func getAPIConfiguration() -> APIConfiguration {
        return APIConfiguration(
            apiKey: getAPIKey(),
            baseURL: getBaseURL(),
            modelName: getModelName()
        )
    }

    /// Check if API configuration exists
    func hasAPIConfiguration() -> Bool {
        let apiKey = getAPIKey()
        let baseURL = getBaseURL()
        return !apiKey.isEmpty && !baseURL.isEmpty
    }

    /// Clear all API configuration from Keychain
    func clearAPIConfiguration() {
        do {
            try delete(forKey: KeychainKey.apiKey.rawValue)
            try delete(forKey: KeychainKey.baseURL.rawValue)
            try delete(forKey: KeychainKey.modelName.rawValue)
            #if DEBUG
            print("✅ [Keychain] API configuration cleared")
            #endif
        } catch {
            #if DEBUG
            print("❌ [Keychain] Failed to clear API configuration: \(error)")
            #endif
        }
    }

    /// Migrate API configuration from UserDefaults to Keychain (one-time migration)
    func migrateFromUserDefaultsIfNeeded(preferences: UserPreferences) {
        // Only migrate if Keychain is empty and UserDefaults has data
        guard !hasAPIConfiguration() else { return }

        let config = preferences.apiConfiguration
        if !config.apiKey.isEmpty || !config.baseURL.isEmpty {
            saveAPIConfiguration(config)
            #if DEBUG
            print("✅ [Keychain] Migrated API configuration from UserDefaults")
            #endif
        }
    }
}

