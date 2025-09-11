import Foundation
import RxSwift
import RxCocoa
import UIKit
import UniformTypeIdentifiers

class SettingsViewModel: NSObject, ObservableObject, UIDocumentPickerDelegate {
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

    // Export/Import State
    @Published var isExporting = false
    @Published var isImporting = false
    @Published var exportProgress: ExportProgress?
    @Published var importProgress: ImportProgress?
    @Published var importPreview: ImportPreview?
    @Published var showingImportPreview = false
    @Published var showingExportOptions = false
    @Published var showingPrivacyNotice = false
    @Published var exportOptions = ExportOptions.default
    @Published var importOptions = ImportOptions.merge
    @Published var privacyNotice: PrivacyNotice?
    @Published var complianceIssues: [ComplianceIssue] = []
    @Published var currentExportOptions: ExportOptions?

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
    private let dataExportService: DataExportServiceProtocol
    private let dataImportService: DataImportServiceProtocol
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
         aiService: AIServiceProtocol = AIService(),
         dataExportService: DataExportServiceProtocol? = nil,
         dataImportService: DataImportServiceProtocol? = nil) {
        self.storageService = storageService
        self.aiService = aiService
        self.dataExportService = dataExportService ?? DataExportService(storageService: storageService)
        self.dataImportService = dataImportService ?? DataImportService(storageService: storageService)
        super.init()
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

        // Sync language with LocalizationManager
        LocalizationManager.shared.setLanguage(preferences.preferredLanguage)

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

        // Notify other ViewModels about settings change
        NotificationCenter.default.post(name: .settingsDidChange, object: nil)
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

        // Sync with LocalizationManager
        LocalizationManager.shared.setLanguage(language)
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

    // MARK: - Enhanced Export/Import Methods

    func showExportOptions() {
        showingExportOptions = true
    }

    // Convenience method for backward compatibility
    func exportSettings() {
        exportData(with: .default)
    }

    // Convenience method for backward compatibility
    func importSettings() {
        importData()
    }

    func exportData(with options: ExportOptions = .default) {
        isExporting = true
        exportProgress = nil

        dataExportService.exportData(options: options)
            .observe(on: MainScheduler.instance)
            .subscribe(
                onNext: { [weak self] progress in
                    self?.exportProgress = progress

                    if case .completed = progress.phase {
                        self?.isExporting = false
                        // Show share sheet for the exported file
                        self?.shareExportedFile()
                    }
                },
                onError: { [weak self] error in
                    self?.isExporting = false
                    self?.exportProgress = ExportProgress(
                        phase: .failed(error),
                        progress: 0.0,
                        message: error.localizedDescription,
                        itemsProcessed: 0,
                        totalItems: 0
                    )
                    print("Export failed: \(error)")
                }
            )
            .disposed(by: disposeBag)
    }

    private func shareExportedFile() {
        // Get the most recent export file
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]

        do {
            let files = try FileManager.default.contentsOfDirectory(at: documentsPath, includingPropertiesForKeys: [.creationDateKey])
            let exportFiles = files.filter { $0.lastPathComponent.hasPrefix("RoastMeLater_Export_") }

            if let latestFile = exportFiles.max(by: { file1, file2 in
                let date1 = (try? file1.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date.distantPast
                let date2 = (try? file2.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date.distantPast
                return date1 < date2
            }) {
                DispatchQueue.main.async {
                    let activityVC = UIActivityViewController(activityItems: [latestFile], applicationActivities: nil)

                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let window = windowScene.windows.first {
                        window.rootViewController?.present(activityVC, animated: true)
                    }
                }
            }
        } catch {
            print("Failed to find export file: \(error)")
        }
    }

    func importData() {
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.json])
        documentPicker.delegate = self

        DispatchQueue.main.async {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                window.rootViewController?.present(documentPicker, animated: true)
            }
        }
    }

    func previewImportData(from url: URL) {
        do {
            let data = try Data(contentsOf: url)
            pendingImportData = data // Cache the data for later import

            dataImportService.previewImport(from: data)
                .observe(on: MainScheduler.instance)
                .subscribe(
                    onNext: { [weak self] preview in
                        self?.importPreview = preview
                        self?.showingImportPreview = true
                    },
                    onError: { [weak self] error in
                        self?.pendingImportData = nil // Clear on error
                        print("Preview failed: \(error)")
                    }
                )
                .disposed(by: disposeBag)
        } catch {
            print("Failed to read file: \(error)")
        }
    }

    // Store the import data temporarily
    private var pendingImportData: Data?

    func confirmImport(with options: ImportOptions = .merge) {
        guard let importData = pendingImportData else {
            print("No import data available")
            return
        }

        isImporting = true
        importProgress = nil
        showingImportPreview = false

        dataImportService.importData(from: importData, options: options)
            .observe(on: MainScheduler.instance)
            .subscribe(
                onNext: { [weak self] progress in
                    self?.importProgress = progress

                    if case .completed = progress.phase {
                        self?.isImporting = false
                        self?.pendingImportData = nil // Clear cached data
                        self?.loadSettings() // Refresh UI
                        self?.loadStatistics() // Refresh statistics
                    }
                },
                onError: { [weak self] error in
                    self?.isImporting = false
                    self?.pendingImportData = nil // Clear cached data
                    self?.importProgress = ImportProgress(
                        phase: .failed(error),
                        progress: 0.0,
                        message: error.localizedDescription,
                        itemsProcessed: 0,
                        totalItems: 0,
                        warnings: []
                    )
                    print("Import failed: \(error)")
                }
            )
            .disposed(by: disposeBag)
    }

    func cancelImport() {
        showingImportPreview = false
        importPreview = nil
        pendingImportData = nil // Clear cached data
    }

    // MARK: - UIDocumentPickerDelegate
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }

        // Start security-scoped resource access
        guard url.startAccessingSecurityScopedResource() else {
            print("Failed to access security-scoped resource")
            return
        }

        defer {
            url.stopAccessingSecurityScopedResource()
        }

        // Preview the import data first
        previewImportData(from: url)
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

    // MARK: - Privacy and Security Methods

    func generatePrivacyNotice(for options: ExportOptions) {
        currentExportOptions = options

        dataExportService.generatePrivacyNotice(for: options)
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] notice, issues in
                self?.privacyNotice = notice
                self?.complianceIssues = issues
                self?.showingPrivacyNotice = true
            }, onError: { [weak self] error in
                self?.handleError(error)
            })
            .disposed(by: disposeBag)
    }

    func acceptPrivacyNoticeAndExport() {
        guard let options = currentExportOptions else { return }
        showingPrivacyNotice = false
        performExport(with: options)
    }

    func cancelPrivacyNotice() {
        showingPrivacyNotice = false
        currentExportOptions = nil
        privacyNotice = nil
        complianceIssues = []
    }

    private func handleError(_ error: Error) {
        // Handle errors appropriately
        print("Error: \(error.localizedDescription)")
        // You could show an alert or update UI state here
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
