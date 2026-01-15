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

    private let roastHistorySubject = BehaviorSubject<[Roast]>(value: [])
    private let favoritesSubject = BehaviorSubject<[Roast]>(value: [])

    // MARK: - In-Memory Cache
    private var cachedRoastHistory: [Roast]?
    private var cachedPreferences: UserPreferences?
    private var cachedUserStreak: UserStreak?
    private let cacheQueue = DispatchQueue(label: "com.roastmelater.storage.cache", attributes: .concurrent)

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
        cacheQueue.async(flags: .barrier) { [weak self] in
            self?.cachedRoastHistory = nil
            self?.cachedPreferences = nil
            self?.cachedUserStreak = nil
        }
    }
    
    func saveRoast(_ roast: Roast) {
        var history = getRoastHistory()
        history.insert(roast, at: 0) // Add to beginning

        // Keep only last N roasts (using constant)
        if history.count > Constants.Content.maxHistoryItems {
            history = Array(history.prefix(Constants.Content.maxHistoryItems))
        }

        saveRoastHistory(history)
        roastHistorySubject.onNext(history)

        // Update favorites if this roast is favorited
        if roast.isFavorite {
            let favorites = getFavoriteRoasts()
            favoritesSubject.onNext(favorites)
        }
    }
    
    func getRoastHistory() -> [Roast] {
        return PerformanceMonitor.shared.measure(operation: "StorageService.getRoastHistory") {
            // Check cache first
            if let cached = cacheQueue.sync(execute: { cachedRoastHistory }) {
                return cached
            }

            // Load from UserDefaults
            guard let data = userDefaults.data(forKey: roastHistoryKey),
                  let roasts = try? JSONDecoder().decode([Roast].self, from: data) else {
                return []
            }

            // Update cache
            cacheQueue.async(flags: .barrier) { [weak self] in
                self?.cachedRoastHistory = roasts
            }

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
            let oldValue = history[index].isFavorite
            history[index].isFavorite.toggle()
            let newValue = history[index].isFavorite

            print("🔄 StorageService.toggleFavorite:")
            print("  roastId: \(roastId)")
            print("  isFavorite: \(oldValue) -> \(newValue)")

            saveRoastHistory(history)
            roastHistorySubject.onNext(history)

            let favorites = getFavoriteRoasts()
            print("  favorites count: \(favorites.count)")
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
            print("❌ StorageService.toggleFavorite: Roast not found with id \(roastId)")
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

            // Update cache
            cacheQueue.async(flags: .barrier) { [weak self] in
                self?.cachedRoastHistory = roasts
            }
        } catch {
            print("❌ CRITICAL: Failed to encode roast history: \(error)")
            print("   This is a data loss event - roasts were not saved!")
            // TODO: Notify user about data save failure
            ErrorHandler.shared.logError(error, context: "saveRoastHistory")
        }
    }

    func saveUserPreferences(_ preferences: UserPreferences) {
        print("💾 StorageService.saveUserPreferences called")
        print("  apiKey: \(preferences.apiConfiguration.apiKey.isEmpty ? "EMPTY" : "HAS_VALUE (\(preferences.apiConfiguration.apiKey.count) chars)")")
        print("  baseURL: \(preferences.apiConfiguration.baseURL.isEmpty ? "EMPTY" : preferences.apiConfiguration.baseURL)")
        print("  modelName: \(preferences.apiConfiguration.modelName.isEmpty ? "EMPTY" : preferences.apiConfiguration.modelName)")

        do {
            let data = try JSONEncoder().encode(preferences)
            userDefaults.set(data, forKey: userPreferencesKey)

            // Force synchronize to ensure data is written immediately
            userDefaults.synchronize()
            print("✅ Preferences saved to UserDefaults and synchronized")

            // Update cache synchronously to ensure immediate availability
            cacheQueue.sync(flags: .barrier) { [weak self] in
                self?.cachedPreferences = preferences
                print("✅ Cache updated synchronously")
            }
        } catch {
            print("❌ CRITICAL: Failed to encode preferences: \(error)")
            print("   User preferences were not saved!")
            ErrorHandler.shared.logError(error, context: "saveUserPreferences")
        }
    }

    func getUserPreferences() -> UserPreferences {
        // Check cache first
        if let cached = cacheQueue.sync(execute: { cachedPreferences }) {
            print("📦 getUserPreferences: Using cached preferences")
            print("  apiKey: \(cached.apiConfiguration.apiKey.isEmpty ? "EMPTY" : "HAS_VALUE (\(cached.apiConfiguration.apiKey.count) chars)")")
            print("  baseURL: \(cached.apiConfiguration.baseURL.isEmpty ? "EMPTY" : cached.apiConfiguration.baseURL)")
            print("  modelName: \(cached.apiConfiguration.modelName.isEmpty ? "EMPTY" : cached.apiConfiguration.modelName)")
            return cached
        }

        print("📂 getUserPreferences: Loading from UserDefaults")

        // Load from UserDefaults
        guard let data = userDefaults.data(forKey: userPreferencesKey),
              let preferences = try? JSONDecoder().decode(UserPreferences.self, from: data) else {
            print("⚠️ No preferences found, using defaults")
            let defaultPrefs = UserPreferences()

            // Cache default preferences synchronously
            cacheQueue.sync(flags: .barrier) { [weak self] in
                self?.cachedPreferences = defaultPrefs
            }

            return defaultPrefs
        }

        print("✅ Loaded preferences from UserDefaults")
        print("  apiKey: \(preferences.apiConfiguration.apiKey.isEmpty ? "EMPTY" : "HAS_VALUE (\(preferences.apiConfiguration.apiKey.count) chars)")")
        print("  baseURL: \(preferences.apiConfiguration.baseURL.isEmpty ? "EMPTY" : preferences.apiConfiguration.baseURL)")
        print("  modelName: \(preferences.apiConfiguration.modelName.isEmpty ? "EMPTY" : preferences.apiConfiguration.modelName)")

        // Update cache synchronously
        cacheQueue.sync(flags: .barrier) { [weak self] in
            self?.cachedPreferences = preferences
        }

        return preferences
    }

    func saveUserStreak(_ streak: UserStreak) {
        do {
            let data = try JSONEncoder().encode(streak)
            userDefaults.set(data, forKey: userStreakKey)
            userDefaults.synchronize()

            // Update cache
            cacheQueue.async(flags: .barrier) { [weak self] in
                self?.cachedUserStreak = streak
            }
        } catch {
            print("❌ CRITICAL: Failed to encode user streak: \(error)")
            ErrorHandler.shared.logError(error, context: "saveUserStreak")
        }
    }

    func getUserStreak() -> UserStreak? {
        // Check cache first
        if let cached = cacheQueue.sync(execute: { cachedUserStreak }) {
            return cached
        }

        // Load from UserDefaults
        guard let data = userDefaults.data(forKey: userStreakKey),
              let streak = try? JSONDecoder().decode(UserStreak.self, from: data) else {
            return nil
        }

        // Update cache
        cacheQueue.async(flags: .barrier) { [weak self] in
            self?.cachedUserStreak = streak
        }

        return streak
    }

    func clearAllData() {
        userDefaults.removeObject(forKey: roastHistoryKey)
        userDefaults.removeObject(forKey: userPreferencesKey)
        userDefaults.removeObject(forKey: userStreakKey)

        // Clear cache
        invalidateCache()

        roastHistorySubject.onNext([])
        favoritesSubject.onNext([])
    }

    // MARK: - Bulk Operations

    func bulkSaveRoasts(_ roasts: [Roast], strategy: BulkSaveStrategy = .append) -> BulkOperationResult {
        var processedCount = 0
        var skippedCount = 0
        var errors: [BulkOperationError] = []

        do {
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

        } catch {
            errors.append(BulkOperationError(itemId: "bulk_operation", error: error))
            return BulkOperationResult(
                success: false,
                processedCount: processedCount,
                skippedCount: skippedCount,
                errors: errors
            )
        }
    }

    func bulkUpdateFavorites(_ favoriteIds: [UUID]) -> BulkOperationResult {
        var processedCount = 0
        var skippedCount = 0
        var errors: [BulkOperationError] = []

        do {
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

        } catch {
            errors.append(BulkOperationError(itemId: "bulk_favorites", error: error))
            return BulkOperationResult(
                success: false,
                processedCount: processedCount,
                skippedCount: skippedCount,
                errors: errors
            )
        }
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
        do {
            let roasts = getRoastHistory()
            let preferences = getUserPreferences()

            return DataBackup(
                roasts: roasts,
                preferences: preferences,
                timestamp: Date()
            )
        } catch {
            print("Failed to create backup: \(error)")
            return nil
        }
    }

    func restoreFromBackup(_ backup: DataBackup) -> Bool {
        do {
            // Clear existing data
            clearAllData()

            // Restore preferences
            saveUserPreferences(backup.preferences)

            // Restore roasts
            let result = bulkSaveRoasts(backup.roasts, strategy: .replace)

            return result.success
        } catch {
            print("Failed to restore from backup: \(error)")
            return false
        }
    }
}
