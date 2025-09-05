import Foundation
import RxSwift
import RxCocoa

class SettingsViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var notificationsEnabled = true
    @Published var notificationFrequency: NotificationFrequency = .hourly
    @Published var defaultSpiceLevel = 3
    @Published var safetyFiltersEnabled = true
    @Published var preferredLanguage = "vi"
    @Published var preferredCategories: [RoastCategory] = RoastCategory.allCases

    // API Configuration
    @Published var apiKey = ""
    @Published var baseURL = ""
    @Published var apiTestResult: Bool?

    // Model cố định - không cần @Published
    var modelName: String {
        return Constants.API.fixedModel
    }

    // Statistics
    @Published var totalRoastsGenerated = 0
    @Published var totalFavorites = 0
    @Published var mostPopularCategory: RoastCategory?
    
    // MARK: - Private Properties
    private let storageService: StorageServiceProtocol
    private let aiService: AIServiceProtocol
    private let disposeBag = DisposeBag()
    
    // MARK: - Reactive Properties
    private let preferencesSubject = BehaviorSubject<UserPreferences>(value: UserPreferences())
    private let statisticsSubject = BehaviorSubject<SettingsStatistics>(value: SettingsStatistics())
    
    var preferences: Observable<UserPreferences> {
        return preferencesSubject.asObservable()
    }
    
    var statistics: Observable<SettingsStatistics> {
        return statisticsSubject.asObservable()
    }
    
    // MARK: - Initialization
    init(storageService: StorageServiceProtocol = StorageService(),
         aiService: AIServiceProtocol = AIService()) {
        self.storageService = storageService
        self.aiService = aiService
        setupBindings()
        loadSettings()

        // Force update API configuration on init
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.updateAPIConfiguration()
        }
    }
    
    // MARK: - Private Methods
    private func setupBindings() {
        // Observe preferences changes and save automatically
        preferences
            .skip(1) // Skip initial value
            .debounce(.milliseconds(500), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] preferences in
                self?.storageService.saveUserPreferences(preferences)
            })
            .disposed(by: disposeBag)
        
        // Update published properties when preferences change
        preferences
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] preferences in
                self?.updatePublishedProperties(from: preferences)
            })
            .disposed(by: disposeBag)
        
        // Update statistics when they change
        statistics
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] stats in
                self?.totalRoastsGenerated = stats.totalRoasts
                self?.totalFavorites = stats.totalFavorites
                self?.mostPopularCategory = stats.mostPopularCategory
            })
            .disposed(by: disposeBag)
    }
    
    private func updatePublishedProperties(from preferences: UserPreferences) {
        notificationsEnabled = preferences.notificationsEnabled
        notificationFrequency = preferences.notificationFrequency
        defaultSpiceLevel = preferences.defaultSpiceLevel
        safetyFiltersEnabled = preferences.safetyFiltersEnabled
        preferredLanguage = preferences.preferredLanguage
        preferredCategories = preferences.preferredCategories

        // API Configuration
        apiKey = preferences.apiConfiguration.apiKey
        baseURL = preferences.apiConfiguration.baseURL
    }
    
    // MARK: - Public Methods
    func loadSettings() {
        let preferences = storageService.getUserPreferences()
        preferencesSubject.onNext(preferences)
        
        // Load statistics
        loadStatistics()
    }
    
    private func loadStatistics() {
        let roasts = storageService.getRoastHistory()
        let favorites = storageService.getFavoriteRoasts()
        
        let categoryCount = Dictionary(grouping: roasts) { $0.category }
            .mapValues { $0.count }
        
        let stats = SettingsStatistics(
            totalRoasts: roasts.count,
            totalFavorites: favorites.count,
            mostPopularCategory: categoryCount.max(by: { $0.value < $1.value })?.key,
            averageSpiceLevel: roasts.isEmpty ? 0 : 
                Double(roasts.map { $0.spiceLevel }.reduce(0, +)) / Double(roasts.count),
            categoryBreakdown: categoryCount
        )
        
        statisticsSubject.onNext(stats)
    }
    
    // MARK: - Settings Update Methods
    func updateNotificationsEnabled(_ enabled: Bool) {
        notificationsEnabled = enabled
        updatePreferences { preferences in
            preferences.notificationsEnabled = enabled
        }
    }
    
    func updateNotificationFrequency(_ frequency: NotificationFrequency) {
        notificationFrequency = frequency
        updatePreferences { preferences in
            preferences.notificationFrequency = frequency
        }
    }
    
    func updateDefaultSpiceLevel(_ level: Int) {
        defaultSpiceLevel = level
        updatePreferences { preferences in
            preferences.defaultSpiceLevel = level
        }
    }
    
    func updateSafetyFilters(_ enabled: Bool) {
        safetyFiltersEnabled = enabled
        updatePreferences { preferences in
            preferences.safetyFiltersEnabled = enabled
        }
    }
    
    func updatePreferredLanguage(_ language: String) {
        preferredLanguage = language
        updatePreferences { preferences in
            preferences.preferredLanguage = language
        }
    }
    
    func addPreferredCategory(_ category: RoastCategory) {
        if !preferredCategories.contains(category) {
            preferredCategories.append(category)
            updatePreferences { preferences in
                preferences.preferredCategories = self.preferredCategories
            }
        }
    }
    
    func removePreferredCategory(_ category: RoastCategory) {
        preferredCategories.removeAll { $0 == category }
        
        // Ensure at least one category is selected
        if preferredCategories.isEmpty {
            preferredCategories = [.general]
        }
        
        updatePreferences { preferences in
            preferences.preferredCategories = self.preferredCategories
        }
    }
    
    private func updatePreferences(_ update: (inout UserPreferences) -> Void) {
        do {
            var currentPreferences = try preferencesSubject.value()
            update(&currentPreferences)
            preferencesSubject.onNext(currentPreferences)
        } catch {
            print("Error updating preferences: \(error)")
        }
    }
    
    // MARK: - Data Management Methods
    func clearRoastHistory() {
        storageService.clearAllData()
        loadStatistics()
    }
    
    func clearFavorites() {
        let favorites = storageService.getFavoriteRoasts()
        for favorite in favorites {
            storageService.toggleFavorite(roastId: favorite.id)
        }
        loadStatistics()
    }
    
    func resetAllSettings() {
        let defaultPreferences = UserPreferences()
        preferencesSubject.onNext(defaultPreferences)
        storageService.saveUserPreferences(defaultPreferences)
    }

    // MARK: - API Configuration Methods
    func updateAPIConfiguration() {
        print("🔧 Updating API Configuration:")
        print("  apiKey: \(apiKey.isEmpty ? "EMPTY" : "HAS_VALUE")")
        print("  baseURL: \(baseURL)")

        updatePreferences { preferences in
            preferences.apiConfiguration = APIConfiguration(
                apiKey: apiKey,
                baseURL: baseURL
            )
        }

        print("✅ API Configuration updated")
    }

    func clearAPIConfiguration() {
        apiKey = ""
        baseURL = ""
        apiTestResult = nil
        updateAPIConfiguration()
    }

    func testAPIConnection() {
        guard !apiKey.isEmpty, !baseURL.isEmpty else {
            apiTestResult = false
            return
        }

        aiService.testAPIConnection(apiKey: apiKey, baseURL: baseURL, modelName: modelName)
            .observe(on: MainScheduler.instance)
            .subscribe(
                onNext: { [weak self] success in
                    self?.apiTestResult = success
                    if success {
                        self?.updateAPIConfiguration()
                    }
                },
                onError: { [weak self] _ in
                    self?.apiTestResult = false
                }
            )
            .disposed(by: disposeBag)
    }
    
    // MARK: - Export/Import Methods
    func exportSettings() -> Observable<Data> {
        return Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onError(SettingsError.exportFailed)
                return Disposables.create()
            }
            
            do {
                let preferences = try self.preferencesSubject.value()
                let roasts = self.storageService.getRoastHistory()
                
                let exportData = SettingsExportData(
                    preferences: preferences,
                    roasts: roasts,
                    exportDate: Date(),
                    appVersion: "1.0.0"
                )
                
                let data = try JSONEncoder().encode(exportData)
                observer.onNext(data)
                observer.onCompleted()
            } catch {
                observer.onError(error)
            }
            
            return Disposables.create()
        }
    }
    
    func importSettings(from data: Data) -> Observable<Void> {
        return Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onError(SettingsError.importFailed)
                return Disposables.create()
            }
            
            do {
                let importData = try JSONDecoder().decode(SettingsExportData.self, from: data)
                
                // Import preferences
                self.preferencesSubject.onNext(importData.preferences)
                self.storageService.saveUserPreferences(importData.preferences)
                
                // Import roasts
                for roast in importData.roasts {
                    self.storageService.saveRoast(roast)
                }
                
                // Reload statistics
                self.loadStatistics()
                
                observer.onNext(())
                observer.onCompleted()
            } catch {
                observer.onError(error)
            }
            
            return Disposables.create()
        }
    }
    
    // MARK: - Reactive Getters
    func getPreferencesObservable() -> Observable<UserPreferences> {
        return preferences
    }
    
    func getStatisticsObservable() -> Observable<SettingsStatistics> {
        return statistics
    }
    
    func getNotificationSettingsObservable() -> Observable<(Bool, NotificationFrequency)> {
        return preferences
            .map { ($0.notificationsEnabled, $0.notificationFrequency) }
    }
    
    func getContentSettingsObservable() -> Observable<(Int, Bool, String)> {
        return preferences
            .map { ($0.defaultSpiceLevel, $0.safetyFiltersEnabled, $0.preferredLanguage) }
    }
}

// MARK: - Supporting Types
struct SettingsStatistics {
    let totalRoasts: Int
    let totalFavorites: Int
    let mostPopularCategory: RoastCategory?
    let averageSpiceLevel: Double
    let categoryBreakdown: [RoastCategory: Int]
    
    init(totalRoasts: Int = 0,
         totalFavorites: Int = 0,
         mostPopularCategory: RoastCategory? = nil,
         averageSpiceLevel: Double = 0,
         categoryBreakdown: [RoastCategory: Int] = [:]) {
        self.totalRoasts = totalRoasts
        self.totalFavorites = totalFavorites
        self.mostPopularCategory = mostPopularCategory
        self.averageSpiceLevel = averageSpiceLevel
        self.categoryBreakdown = categoryBreakdown
    }
}

struct SettingsExportData: Codable {
    let preferences: UserPreferences
    let roasts: [Roast]
    let exportDate: Date
    let appVersion: String
}

enum SettingsError: Error {
    case exportFailed
    case importFailed
    case invalidData
    
    var localizedDescription: String {
        switch self {
        case .exportFailed:
            return "Không thể xuất cài đặt"
        case .importFailed:
            return "Không thể nhập cài đặt"
        case .invalidData:
            return "Dữ liệu không hợp lệ"
        }
    }
}
