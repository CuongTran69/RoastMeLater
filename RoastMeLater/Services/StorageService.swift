import Foundation
import RxSwift
import RxCocoa

protocol StorageServiceProtocol {
    func saveRoast(_ roast: Roast)
    func getRoastHistory() -> [Roast]
    func getFavoriteRoasts() -> [Roast]
    func toggleFavorite(roastId: UUID)
    func deleteRoast(roastId: UUID)
    func saveUserPreferences(_ preferences: UserPreferences)
    func getUserPreferences() -> UserPreferences
    func saveUserStreak(_ streak: UserStreak)
    func getUserStreak() -> UserStreak?
    func clearAllData()

    // Bulk operations for import/export
    func bulkSaveRoasts(_ roasts: [Roast], strategy: BulkSaveStrategy) -> BulkOperationResult
    func bulkUpdateFavorites(_ favoriteIds: [UUID]) -> BulkOperationResult
    func validateDataIntegrity() -> DataIntegrityResult
    func createDataBackup() -> DataBackup?
    func restoreFromBackup(_ backup: DataBackup) -> Bool

    // Widget data management
    func saveWidgetData(_ data: WidgetRoastData)
    func getWidgetData() -> WidgetRoastData?
    func updateWidgetWithLatestRoast(_ roast: Roast, streak: Int)
}

enum BulkSaveStrategy {
    case append     // Add to existing data
    case replace    // Replace all existing data
    case merge      // Merge with existing data, skip duplicates
}

struct BulkOperationResult {
    let success: Bool
    let processedCount: Int
    let skippedCount: Int
    let errors: [BulkOperationError]
}

struct BulkOperationError {
    let itemId: String
    let error: Error
}

struct DataIntegrityResult {
    let isValid: Bool
    let issues: [DataIntegrityIssue]
}

struct DataIntegrityIssue {
    let type: IntegrityIssueType
    let description: String
    let affectedItemId: String?
}

enum IntegrityIssueType {
    case duplicateId
    case invalidData
    case orphanedFavorite
    case corruptedEntry
}

struct DataBackup {
    let roasts: [Roast]
    let preferences: UserPreferences
    let timestamp: Date
}

class StorageService: StorageServiceProtocol {
    // MARK: - Singleton
    static let shared = StorageService()

    private let userDefaults = UserDefaults.standard
    private let roastHistoryKey = "roast_history"
    private let userPreferencesKey = "user_preferences"
    private let userStreakKey = "user_streak"

    // App Group for widget data sharing
    private let appGroupIdentifier = "group.com.roastmelater"
    private let widgetDataKey = "widget_roast_data"

    private var appGroupDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupIdentifier)
    }

    private let roastHistorySubject = BehaviorSubject<[Roast]>(value: [])
    private let favoritesSubject = BehaviorSubject<[Roast]>(value: [])

    // MARK: - In-Memory Cache with Thread Safety
    private var _cachedRoastHistory: [Roast]?
    private var _cachedPreferences: UserPreferences?
    private var _cachedUserStreak: UserStreak?
    private let cacheQueue = DispatchQueue(label: "com.roastmelater.storage.cache", attributes: .concurrent)

    // Thread-safe cache accessors
    private var cachedRoastHistory: [Roast]? {
        get { cacheQueue.sync { _cachedRoastHistory } }
        set { cacheQueue.async(flags: .barrier) { [weak self] in self?._cachedRoastHistory = newValue } }
    }

    private var cachedPreferences: UserPreferences? {
        get { cacheQueue.sync { _cachedPreferences } }
        set { cacheQueue.async(flags: .barrier) { [weak self] in self?._cachedPreferences = newValue } }
    }

    private var cachedUserStreak: UserStreak? {
        get { cacheQueue.sync { _cachedUserStreak } }
        set { cacheQueue.async(flags: .barrier) { [weak self] in self?._cachedUserStreak = newValue } }
    }

    // Synchronous cache setter for cases where immediate availability is required
    private func setCachedPreferencesSync(_ preferences: UserPreferences?) {
        cacheQueue.sync(flags: .barrier) { [weak self] in self?._cachedPreferences = preferences }
    }

    var roastHistory: Observable<[Roast]> {
        return roastHistorySubject.asObservable()
    }

    var favorites: Observable<[Roast]> {
        return favoritesSubject.asObservable()
    }

    init() {
        loadInitialData()
    }

    private func loadInitialData() {
        let history = getRoastHistory()
        roastHistorySubject.onNext(history)

        let favorites = getFavoriteRoasts()
        favoritesSubject.onNext(favorites)
    }

    private func invalidateCache() {
        cachedRoastHistory = nil
        cachedPreferences = nil
        cachedUserStreak = nil
    }
    
    func saveRoast(_ roast: Roast) {
        var history = getRoastHistory()
        history.insert(roast, at: 0) // Add to beginning

        // Keep only last N roasts (using constant)
        if history.count > Constants.Content.maxHistoryItems {
            history = Array(history.prefix(Constants.Content.maxHistoryItems))
        }

        saveRoastHistory(history)

        // Update widget data with latest roast
        let streak = getUserStreak()?.currentStreak ?? 0
        updateWidgetWithLatestRoast(roast, streak: streak)

        roastHistorySubject.onNext(history)

        // Update favorites if this roast is favorited
        if roast.isFavorite {
            let favorites = getFavoriteRoasts()
            favoritesSubject.onNext(favorites)
        }
    }
    
    func getRoastHistory() -> [Roast] {
        return PerformanceMonitor.shared.measure(operation: "StorageService.getRoastHistory") {
            // Check cache first (thread-safe via property accessor)
            if let cached = cachedRoastHistory {
                return cached
            }

            // Load from UserDefaults
            guard let data = userDefaults.data(forKey: roastHistoryKey),
                  let roasts = try? JSONDecoder().decode([Roast].self, from: data) else {
                return []
            }

            // Update cache (thread-safe via property accessor)
            cachedRoastHistory = roasts

            return roasts
        }
    }

    func getFavoriteRoasts() -> [Roast] {
        return PerformanceMonitor.shared.measure(operation: "StorageService.getFavoriteRoasts") {
            // NOTE: This filters the entire history on every call.
            // For better performance with large datasets, consider:
            // 1. Caching favorites separately
            // 2. Using a more efficient data structure (e.g., Dictionary)
            // 3. Only invalidating cache when favorites change
            return getRoastHistory().filter { $0.isFavorite }
        }
    }
    
    func toggleFavorite(roastId: UUID) {
        var history = getRoastHistory()

        if let index = history.firstIndex(where: { $0.id == roastId }) {
            history[index].isFavorite.toggle()
            let newValue = history[index].isFavorite

            saveRoastHistory(history)
            roastHistorySubject.onNext(history)

            let favorites = getFavoriteRoasts()
            favoritesSubject.onNext(favorites)

            // ✅ Notify all ViewModels about favorite change
            NotificationCenter.default.post(
                name: .favoriteDidChange,
                object: nil,
                userInfo: [
                    "roastId": roastId,
                    "isFavorite": newValue,
                    "roast": history[index]
                ]
            )
        } else {
            #if DEBUG
            print("❌ StorageService.toggleFavorite: Roast not found with id \(roastId)")
            #endif
        }
    }
    
    func deleteRoast(roastId: UUID) {
        var history = getRoastHistory()
        history.removeAll { $0.id == roastId }
        
        saveRoastHistory(history)
        roastHistorySubject.onNext(history)
        
        let favorites = getFavoriteRoasts()
        favoritesSubject.onNext(favorites)
    }
    
    private func saveRoastHistory(_ roasts: [Roast]) {
        do {
            let data = try JSONEncoder().encode(roasts)
            userDefaults.set(data, forKey: roastHistoryKey)

            // Update cache (thread-safe via property accessor)
            cachedRoastHistory = roasts
        } catch {
            #if DEBUG
            print("❌ CRITICAL: Failed to encode roast history: \(error)")
            #endif
            // Notify user about data save failure
            NotificationCenter.default.post(
                name: .dataSaveFailure,
                object: nil,
                userInfo: ["error": error, "context": "saveRoastHistory"]
            )
            ErrorHandler.shared.logError(error, context: "saveRoastHistory")
        }
    }

    func saveUserPreferences(_ preferences: UserPreferences) {
        #if DEBUG
        print("💾 StorageService.saveUserPreferences called")
        #endif

        // Save API key to Keychain (secure storage)
        if !preferences.apiConfiguration.apiKey.isEmpty {
            KeychainService.shared.saveAPIKey(preferences.apiConfiguration.apiKey)
        }
        if !preferences.apiConfiguration.baseURL.isEmpty {
            KeychainService.shared.saveBaseURL(preferences.apiConfiguration.baseURL)
        }
        if !preferences.apiConfiguration.modelName.isEmpty {
            KeychainService.shared.saveModelName(preferences.apiConfiguration.modelName)
        }

        do {
            let data = try JSONEncoder().encode(preferences)
            userDefaults.set(data, forKey: userPreferencesKey)

            // Force synchronize to ensure data is written immediately
            userDefaults.synchronize()
            #if DEBUG
            print("✅ Preferences saved to UserDefaults and synchronized")
            #endif

            // Update cache synchronously to ensure immediate availability
            setCachedPreferencesSync(preferences)
        } catch {
            #if DEBUG
            print("❌ CRITICAL: Failed to encode preferences: \(error)")
            #endif
            ErrorHandler.shared.logError(error, context: "saveUserPreferences")
        }
    }

    func getUserPreferences() -> UserPreferences {
        // Check cache first (thread-safe via property accessor)
        if let cached = cachedPreferences {
            return cached
        }

        #if DEBUG
        print("📂 getUserPreferences: Loading from UserDefaults")
        #endif

        // Load from UserDefaults
        guard let data = userDefaults.data(forKey: userPreferencesKey),
              var preferences = try? JSONDecoder().decode(UserPreferences.self, from: data) else {
            #if DEBUG
            print("⚠️ No preferences found, using defaults")
            #endif
            let defaultPrefs = UserPreferences()

            // Cache default preferences synchronously
            setCachedPreferencesSync(defaultPrefs)

            return defaultPrefs
        }

        // Load API key from Keychain (secure storage)
        preferences.apiConfiguration.apiKey = KeychainService.shared.getAPIKey()
        preferences.apiConfiguration.baseURL = KeychainService.shared.getBaseURL()
        let keychainModel = KeychainService.shared.getModelName()
        if !keychainModel.isEmpty {
            preferences.apiConfiguration.modelName = keychainModel
        }

        // Update cache synchronously
        setCachedPreferencesSync(preferences)

        return preferences
    }

    func saveUserStreak(_ streak: UserStreak) {
        do {
            let data = try JSONEncoder().encode(streak)
            userDefaults.set(data, forKey: userStreakKey)
            userDefaults.synchronize()

            // Update cache (thread-safe via property accessor)
            cachedUserStreak = streak
        } catch {
            #if DEBUG
            print("❌ CRITICAL: Failed to encode user streak: \(error)")
            #endif
            ErrorHandler.shared.logError(error, context: "saveUserStreak")
        }
    }

    func getUserStreak() -> UserStreak? {
        // Check cache first (thread-safe via property accessor)
        if let cached = cachedUserStreak {
            return cached
        }

        // Load from UserDefaults
        guard let data = userDefaults.data(forKey: userStreakKey),
              let streak = try? JSONDecoder().decode(UserStreak.self, from: data) else {
            return nil
        }

        // Update cache (thread-safe via property accessor)
        cachedUserStreak = streak

        return streak
    }

    func clearAllData() {
        userDefaults.removeObject(forKey: roastHistoryKey)
        userDefaults.removeObject(forKey: userPreferencesKey)
        userDefaults.removeObject(forKey: userStreakKey)

        // Clear API configuration from Keychain
        KeychainService.shared.clearAPIConfiguration()

        // Clear widget data from App Group
        if let defaults = appGroupDefaults {
            defaults.removeObject(forKey: widgetDataKey)
            defaults.synchronize()
        }

        // Clear cache
        invalidateCache()

        roastHistorySubject.onNext([])
        favoritesSubject.onNext([])
    }

    // MARK: - Bulk Operations

    func bulkSaveRoasts(_ roasts: [Roast], strategy: BulkSaveStrategy = .append) -> BulkOperationResult {
        var processedCount = 0
        var skippedCount = 0
        let errors: [BulkOperationError] = []

        var currentHistory = getRoastHistory()
        let existingIds = Set(currentHistory.map { $0.id })

        switch strategy {
        case .replace:
            currentHistory = roasts
            processedCount = roasts.count

        case .append:
            for roast in roasts {
                currentHistory.insert(roast, at: 0)
                processedCount += 1
            }

        case .merge:
            for roast in roasts {
                if existingIds.contains(roast.id) {
                    skippedCount += 1
                } else {
                    currentHistory.insert(roast, at: 0)
                    processedCount += 1
                }
            }
        }

        // Maintain size limit (using constant)
        if currentHistory.count > Constants.Content.maxHistoryItemsBulk {
            currentHistory = Array(currentHistory.prefix(Constants.Content.maxHistoryItemsBulk))
        }

        saveRoastHistory(currentHistory)
        roastHistorySubject.onNext(currentHistory)

        // Update favorites
        let favorites = getFavoriteRoasts()
        favoritesSubject.onNext(favorites)

        return BulkOperationResult(
            success: true,
            processedCount: processedCount,
            skippedCount: skippedCount,
            errors: errors
        )
    }

    func bulkUpdateFavorites(_ favoriteIds: [UUID]) -> BulkOperationResult {
        var processedCount = 0
        var skippedCount = 0
        let errors: [BulkOperationError] = []

        var history = getRoastHistory()
        let roastIdMap = Dictionary(uniqueKeysWithValues: history.enumerated().map { ($1.id, $0) })

        for favoriteId in favoriteIds {
            if let index = roastIdMap[favoriteId] {
                history[index].isFavorite = true
                processedCount += 1
            } else {
                skippedCount += 1
            }
        }

        saveRoastHistory(history)
        roastHistorySubject.onNext(history)

        let favorites = getFavoriteRoasts()
        favoritesSubject.onNext(favorites)

        return BulkOperationResult(
            success: true,
            processedCount: processedCount,
            skippedCount: skippedCount,
            errors: errors
        )
    }

    func validateDataIntegrity() -> DataIntegrityResult {
        var issues: [DataIntegrityIssue] = []

        let roasts = getRoastHistory()
        let roastIds = roasts.map { $0.id }
        let uniqueIds = Set(roastIds)

        // Check for duplicate IDs and identify them
        if roastIds.count != uniqueIds.count {
            // Find which IDs are duplicated
            var seenIds = Set<UUID>()
            var duplicateIds = Set<UUID>()

            for id in roastIds {
                if seenIds.contains(id) {
                    duplicateIds.insert(id)
                } else {
                    seenIds.insert(id)
                }
            }

            for duplicateId in duplicateIds {
                issues.append(DataIntegrityIssue(
                    type: .duplicateId,
                    description: "ID trùng lặp được tìm thấy",
                    affectedItemId: duplicateId.uuidString
                ))
            }
        }

        // Check for invalid data
        for roast in roasts {
            if roast.content.isEmpty {
                issues.append(DataIntegrityIssue(
                    type: .invalidData,
                    description: "Roast có nội dung trống",
                    affectedItemId: roast.id.uuidString
                ))
            }

            if roast.spiceLevel < 1 || roast.spiceLevel > 5 {
                issues.append(DataIntegrityIssue(
                    type: .invalidData,
                    description: "Mức độ cay không hợp lệ: \(roast.spiceLevel)",
                    affectedItemId: roast.id.uuidString
                ))
            }
        }

        return DataIntegrityResult(
            isValid: issues.isEmpty,
            issues: issues
        )
    }

    func createDataBackup() -> DataBackup? {
        let roasts = getRoastHistory()
        let preferences = getUserPreferences()

        return DataBackup(
            roasts: roasts,
            preferences: preferences,
            timestamp: Date()
        )
    }

    func restoreFromBackup(_ backup: DataBackup) -> Bool {
        // Clear existing data
        clearAllData()

        // Restore preferences
        saveUserPreferences(backup.preferences)

        // Restore roasts
        let result = bulkSaveRoasts(backup.roasts, strategy: .replace)

        return result.success
    }

    // MARK: - Widget Data Management

    func saveWidgetData(_ data: WidgetRoastData) {
        guard let defaults = appGroupDefaults else {
            #if DEBUG
            print("❌ Failed to access App Group UserDefaults")
            #endif
            return
        }

        do {
            let encodedData = try JSONEncoder().encode(data)
            defaults.set(encodedData, forKey: widgetDataKey)
            defaults.synchronize()
        } catch {
            #if DEBUG
            print("❌ Failed to encode widget data: \(error)")
            #endif
            ErrorHandler.shared.logError(error, context: "saveWidgetData")
        }
    }

    func getWidgetData() -> WidgetRoastData? {
        guard let defaults = appGroupDefaults,
              let data = defaults.data(forKey: widgetDataKey) else {
            return nil
        }

        do {
            return try JSONDecoder().decode(WidgetRoastData.self, from: data)
        } catch {
            #if DEBUG
            print("❌ Failed to decode widget data: \(error)")
            #endif
            // Clean up corrupted data
            defaults.removeObject(forKey: widgetDataKey)
            return nil
        }
    }

    func updateWidgetWithLatestRoast(_ roast: Roast, streak: Int) {
        let widgetData = WidgetRoastData(
            roastOfTheDay: roast.content,
            category: roast.category.rawValue,
            categoryIcon: roast.category.icon,
            spiceLevel: roast.spiceLevel,
            generatedDate: roast.createdAt,
            currentStreak: streak
        )
        saveWidgetData(widgetData)
    }
}
