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
    private let userDefaults = UserDefaults.standard
    private let roastHistoryKey = "roast_history"
    private let userPreferencesKey = "user_preferences"
    
    private let roastHistorySubject = BehaviorSubject<[Roast]>(value: [])
    private let favoritesSubject = BehaviorSubject<[Roast]>(value: [])
    
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
    
    func saveRoast(_ roast: Roast) {
        var history = getRoastHistory()
        history.insert(roast, at: 0) // Add to beginning
        
        // Keep only last 100 roasts
        if history.count > 100 {
            history = Array(history.prefix(100))
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
        guard let data = userDefaults.data(forKey: roastHistoryKey),
              let roasts = try? JSONDecoder().decode([Roast].self, from: data) else {
            return []
        }
        return roasts
    }
    
    func getFavoriteRoasts() -> [Roast] {
        return getRoastHistory().filter { $0.isFavorite }
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
        if let data = try? JSONEncoder().encode(roasts) {
            userDefaults.set(data, forKey: roastHistoryKey)
        }
    }
    
    func saveUserPreferences(_ preferences: UserPreferences) {
        if let data = try? JSONEncoder().encode(preferences) {
            userDefaults.set(data, forKey: userPreferencesKey)
        }
    }
    
    func getUserPreferences() -> UserPreferences {
        guard let data = userDefaults.data(forKey: userPreferencesKey),
              let preferences = try? JSONDecoder().decode(UserPreferences.self, from: data) else {
            return UserPreferences()
        }
        return preferences
    }
    
    func clearAllData() {
        userDefaults.removeObject(forKey: roastHistoryKey)
        userDefaults.removeObject(forKey: userPreferencesKey)

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

            // Maintain size limit
            if currentHistory.count > 1000 { // Increased limit for bulk operations
                currentHistory = Array(currentHistory.prefix(1000))
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

        // Check for duplicate IDs
        if roastIds.count != uniqueIds.count {
            issues.append(DataIntegrityIssue(
                type: .duplicateId,
                description: "Tìm thấy ID trùng lặp trong lịch sử roast",
                affectedItemId: nil
            ))
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
