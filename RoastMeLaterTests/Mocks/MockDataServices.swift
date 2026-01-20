import Foundation
import RxSwift
@testable import RoastMeLater

// MARK: - Mock Storage Service

class MockStorageService: StorageServiceProtocol {
    
    // Test data to return
    var roastsToReturn: [Roast] = []
    var preferencesToReturn = UserPreferences()
    var favoritesToReturn: [UUID] = []
    
    // Test flags
    var shouldFailGetRoasts = false
    var shouldFailSaveRoasts = false
    var shouldFailGetPreferences = false
    var shouldFailSavePreferences = false
    
    // Call tracking
    var getAllRoastsCalled = false
    var saveRoastCalled = false
    var bulkSaveRoastsCalled = false
    var getUserPreferencesCalled = false
    var saveUserPreferencesCalled = false
    var bulkUpdateFavoritesCalled = false
    var validateDataIntegrityCalled = false
    
    // MARK: - Roast Methods
    
    func getRoastHistory() -> [Roast] {
        getAllRoastsCalled = true
        return roastsToReturn
    }

    func getFavoriteRoasts() -> [Roast] {
        return roastsToReturn.filter { $0.isFavorite }
    }
    
    func saveRoast(_ roast: Roast) {
        saveRoastCalled = true
        roastsToReturn.append(roast)
    }

    func toggleFavorite(roastId: UUID) {
        if let index = roastsToReturn.firstIndex(where: { $0.id == roastId }) {
            roastsToReturn[index] = Roast(
                id: roastsToReturn[index].id,
                content: roastsToReturn[index].content,
                category: roastsToReturn[index].category,
                spiceLevel: roastsToReturn[index].spiceLevel,
                language: roastsToReturn[index].language,
                createdAt: roastsToReturn[index].createdAt,
                isFavorite: !roastsToReturn[index].isFavorite
            )
        }
    }

    func deleteRoast(roastId: UUID) {
        roastsToReturn.removeAll { $0.id == roastId }
    }
    
    func clearAllData() {
        roastsToReturn.removeAll()
        preferencesToReturn = UserPreferences()
    }
        }
        return Observable.just(())
    }
    
    func bulkSaveRoasts(_ roasts: [Roast], strategy: BulkSaveStrategy = .append) -> BulkOperationResult {
        bulkSaveRoastsCalled = true

        if shouldFailSaveRoasts {
            return BulkOperationResult(
                success: false,
                processedCount: 0,
                skippedCount: 0,
                errors: [BulkOperationError(itemId: "mock", error: MockError.storageError)]
            )
        }

        roastsToReturn.append(contentsOf: roasts)

        return BulkOperationResult(
            success: true,
            processedCount: roasts.count,
            skippedCount: 0,
            errors: []
        )
    }
    
    // MARK: - Preferences Methods
    
    func getUserPreferences() -> UserPreferences {
        getUserPreferencesCalled = true
        return preferencesToReturn
    }
    
    func saveUserPreferences(_ preferences: UserPreferences) {
        saveUserPreferencesCalled = true
        preferencesToReturn = preferences
    }

    func bulkUpdateFavorites(_ favoriteIds: [UUID]) -> BulkOperationResult {
        bulkUpdateFavoritesCalled = true

        for roastIndex in roastsToReturn.indices {
            let roast = roastsToReturn[roastIndex]
            let shouldBeFavorite = favoriteIds.contains(roast.id)
            if roast.isFavorite != shouldBeFavorite {
                roastsToReturn[roastIndex] = Roast(
                    id: roast.id,
                    content: roast.content,
                    category: roast.category,
                    spiceLevel: roast.spiceLevel,
                    language: roast.language,
                    createdAt: roast.createdAt,
                    isFavorite: shouldBeFavorite
                )
            }
        }

        return BulkOperationResult(
            success: true,
            processedCount: favoriteIds.count,
            skippedCount: 0,
            errors: []
        )
    }

    func validateDataIntegrity() -> DataIntegrityResult {
        validateDataIntegrityCalled = true
        return DataIntegrityResult(isValid: true, issues: [])
    }

    func createDataBackup() -> DataBackup? {
        return DataBackup(
            roasts: roastsToReturn,
            preferences: preferencesToReturn,
            timestamp: Date()
        )
    }

    func restoreFromBackup(_ backup: DataBackup) -> Bool {
        roastsToReturn = backup.roasts
        preferencesToReturn = backup.preferences
        return true
    }

    // MARK: - User Streak Methods

    var userStreakToReturn: UserStreak?
    var saveUserStreakCalled = false

    func saveUserStreak(_ streak: UserStreak) {
        saveUserStreakCalled = true
        userStreakToReturn = streak
    }

    func getUserStreak() -> UserStreak? {
        return userStreakToReturn
    }

    // MARK: - Widget Data Methods

    var widgetDataToReturn: WidgetRoastData?
    var saveWidgetDataCalled = false
    var updateWidgetWithLatestRoastCalled = false

    func saveWidgetData(_ data: WidgetRoastData) {
        saveWidgetDataCalled = true
        widgetDataToReturn = data
    }

    func getWidgetData() -> WidgetRoastData? {
        return widgetDataToReturn
    }

    func updateWidgetWithLatestRoast(_ roast: Roast, streak: Int) {
        updateWidgetWithLatestRoastCalled = true
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

    // MARK: - Favorites Methods
    
    func getFavoriteRoasts() -> Observable<[Roast]> {
        let favorites = roastsToReturn.filter { favoritesToReturn.contains($0.id) }
        return Observable.just(favorites)
    }
    
    func addToFavorites(_ roastId: UUID) -> Observable<Void> {
        if !favoritesToReturn.contains(roastId) {
            favoritesToReturn.append(roastId)
        }
        return Observable.just(())
    }
    
    func removeFromFavorites(_ roastId: UUID) -> Observable<Void> {
        favoritesToReturn.removeAll { $0 == roastId }
        return Observable.just(())
    }
    
    func bulkUpdateFavorites(_ favoriteIds: [UUID]) -> Observable<BulkOperationResult> {
        bulkUpdateFavoritesCalled = true
        
        favoritesToReturn = favoriteIds
        
        return Observable.just(BulkOperationResult(
            successCount: favoriteIds.count,
            failureCount: 0,
            errors: []
        ))
    }
    
    // MARK: - Data Management Methods
    
    func validateDataIntegrity() -> Observable<DataIntegrityResult> {
        validateDataIntegrityCalled = true
        
        return Observable.just(DataIntegrityResult(
            isValid: true,
            issues: [],
            repairedCount: 0
        ))
    }
    
    func createDataBackup() -> Observable<DataBackup> {
        return Observable.just(DataBackup(
            roasts: roastsToReturn,
            preferences: preferencesToReturn,
            favorites: favoritesToReturn,
            timestamp: Date()
        ))
    }
    
    func restoreFromBackup(_ backup: DataBackup) -> Observable<Void> {
        roastsToReturn = backup.roasts
        preferencesToReturn = backup.preferences
        favoritesToReturn = backup.favorites
        return Observable.just(())
    }
    
    // MARK: - Statistics Methods
    
    func getStatistics() -> Observable<AppStatistics> {
        return Observable.just(AppStatistics(
            totalRoasts: roastsToReturn.count,
            totalFavorites: favoritesToReturn.count,
            mostPopularCategory: .general,
            averageSpiceLevel: 3.0,
            categoryBreakdown: [.general: roastsToReturn.count]
        ))
    }
    
    // MARK: - Cleanup Methods
    
    func clearAllData() -> Observable<Void> {
        roastsToReturn.removeAll()
        favoritesToReturn.removeAll()
        preferencesToReturn = UserPreferences()
        return Observable.just(())
    }
}

// MARK: - Mock Error Handler

class MockDataErrorHandler: DataErrorHandlerProtocol {
    
    // Call tracking
    var handleErrorCalled = false
    var getRecoveryOptionsCalled = false
    var logErrorCalled = false
    
    // Test data
    var recoveryOptionsToReturn: [ErrorRecoveryOption] = []
    var errorToReturn: Error?
    
    func handleError(_ error: Error, context: ErrorContext) -> Observable<ErrorRecoveryOption> {
        handleErrorCalled = true
        
        if let errorToReturn = errorToReturn {
            return Observable.error(errorToReturn)
        }
        
        let options = getRecoveryOptions(for: error, context: context)
        let recommendedOption = options.first(where: { $0.isRecommended }) ?? options.first
        
        if let option = recommendedOption {
            return Observable.just(option)
        } else {
            return Observable.just(ErrorRecoveryOption(
                strategy: .abort,
                title: "Abort",
                description: "Stop operation",
                isRecommended: true
            ))
        }
    }
    
    func getRecoveryOptions(for error: Error, context: ErrorContext) -> [ErrorRecoveryOption] {
        getRecoveryOptionsCalled = true
        
        if !recoveryOptionsToReturn.isEmpty {
            return recoveryOptionsToReturn
        }
        
        // Default recovery options based on error type
        if error is DataManagementError {
            return [
                ErrorRecoveryOption(
                    strategy: .retry,
                    title: "Retry",
                    description: "Try the operation again",
                    isRecommended: true
                ),
                ErrorRecoveryOption(
                    strategy: .abort,
                    title: "Cancel",
                    description: "Stop the operation",
                    isRecommended: false
                )
            ]
        }
        
        return [
            ErrorRecoveryOption(
                strategy: .abort,
                title: "Cancel",
                description: "Stop the operation",
                isRecommended: true
            )
        ]
    }
    
    func logError(_ error: Error, context: ErrorContext) {
        logErrorCalled = true
        print("Mock: Logged error - \(error.localizedDescription)")
    }
}

// MARK: - Mock Errors

enum MockError: Error, LocalizedError {
    case storageError
    case networkError
    case validationError
    
    var errorDescription: String? {
        switch self {
        case .storageError:
            return "Mock storage error"
        case .networkError:
            return "Mock network error"
        case .validationError:
            return "Mock validation error"
        }
    }
}

// MARK: - Test Data Factories

extension MockStorageService {
    
    static func withMockData() -> MockStorageService {
        let service = MockStorageService()
        
        // Add some mock roasts
        service.roastsToReturn = [
            Roast(
                id: UUID(),
                content: "You're so basic, you make vanilla look exotic.",
                category: .general,
                spiceLevel: 3,
                createdAt: Date().addingTimeInterval(-3600),
                isFavorite: true
            ),
            Roast(
                id: UUID(),
                content: "Your code is like your personality - full of bugs.",
                category: .work,
                spiceLevel: 4,
                createdAt: Date().addingTimeInterval(-7200),
                isFavorite: false
            ),
            Roast(
                id: UUID(),
                content: "You're the human equivalent of a participation trophy.",
                category: .general,
                spiceLevel: 2,
                createdAt: Date().addingTimeInterval(-10800),
                isFavorite: true
            )
        ]
        
        // Set up favorites
        service.favoritesToReturn = service.roastsToReturn
            .filter { $0.isFavorite }
            .map { $0.id }
        
        // Set up preferences
        service.preferencesToReturn = UserPreferences(
            notificationsEnabled: true,
            notificationFrequency: .daily,
            defaultSpiceLevel: 3,
            safetyFiltersEnabled: true,
            preferredLanguage: "en",
            preferredCategories: [.general, .work],
            apiConfiguration: APIConfiguration(
                apiKey: "test-api-key",
                baseURL: "https://api.test.com"
            )
        )
        
        return service
    }
}
