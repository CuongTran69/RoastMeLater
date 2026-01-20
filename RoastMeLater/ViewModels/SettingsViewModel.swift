import Foundation
import RxSwift
import RxCocoa
import UIKit
import UniformTypeIdentifiers
import Combine

class SettingsViewModel: NSObject, ObservableObject, UIDocumentPickerDelegate {
    // MARK: - Published Properties
    @Published var notificationsEnabled = true
    @Published var notificationFrequency: NotificationFrequency = .hourly
    @Published var defaultSpiceLevel = 3
    @Published var defaultCategory: RoastCategory = .general
    @Published var safetyFiltersEnabled = true
    @Published var preferredLanguage = "vi"
    @Published var preferredCategories: [RoastCategory] = RoastCategory.allCases

    // API Configuration
    @Published var apiKey = ""
    @Published var baseURL = ""
    @Published var modelName = ""
    @Published var apiTestResult: Bool?
    @Published var isTestingConnection = false

    // Validation Errors
    @Published var apiKeyError: String?
    @Published var baseURLError: String?
    @Published var modelNameError: String?

    // Export/Import State
    @Published var isExporting = false
    @Published var isImporting = false
    @Published var exportProgress: ExportProgress?
    @Published var importProgress: ImportProgress?
    @Published var importPreview: ImportPreview?
    @Published var showingImportPreview = false
    @Published var showingExportOptions = false
    @Published var showingPrivacyNotice = false
    @Published var showExportSuccess = false
    @Published var exportOptions = ExportOptions.default
    @Published var importOptions = ImportOptions.merge
    @Published var privacyNotice: PrivacyNotice?
    @Published var complianceIssues: [ComplianceIssue] = []
    @Published var currentExportOptions: ExportOptions?

    // Export file URL tracking
    private var pendingExportURL: URL?

    // Statistics
    @Published var totalRoastsGenerated = 0
    @Published var totalFavorites = 0
    @Published var mostPopularCategory: RoastCategory?

    // Error State
    @Published var errorMessage: String?
    @Published var showError = false
    
    // MARK: - Private Properties
    private let storageService: StorageServiceProtocol
    private let aiService: AIServiceProtocol
    private let dataExportService: DataExportServiceProtocol
    private let dataImportService: DataImportServiceProtocol
    private let disposeBag = DisposeBag()
    private var cancellables = Set<AnyCancellable>()

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
    init(storageService: StorageServiceProtocol = StorageService.shared,
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
        setupNotificationObservers()

        // Force update API configuration on init
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.updateAPIConfiguration()
        }
    }

    // Flag to prevent infinite loop when reloading from storage
    private var isReloadingFromStorage = false

    private func setupNotificationObservers() {
        // Listen for settings changes from RoastGeneratorView to sync spice level and category
        NotificationCenter.default.publisher(for: .settingsDidChange)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                // Only reload if notification came from RoastGeneratorViewModel (not from self)
                guard notification.object as? SettingsViewModel !== self else { return }
                self?.reloadFromStorage()
            }
            .store(in: &cancellables)
    }

    private func reloadFromStorage() {
        // Ensure we're on main thread for UI updates
        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self] in
                self?.reloadFromStorage()
            }
            return
        }

        isReloadingFromStorage = true

        let preferences = storageService.getUserPreferences()

        // Update preferencesSubject to trigger updatePublishedProperties
        // This ensures all @Published properties are updated correctly
        preferencesSubject.onNext(preferences)

        #if DEBUG
        print("🔄 SettingsViewModel reloadFromStorage:")
        print("  defaultSpiceLevel: \(preferences.defaultSpiceLevel)")
        print("  defaultCategory: \(preferences.defaultCategory.displayName)")
        #endif

        // Reset flag after a short delay to allow UI to update
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.isReloadingFromStorage = false
        }
    }
    
    // MARK: - Private Methods
    private func setupBindings() {
        // Observe preferences changes and save automatically
        // Skip saving when reloading from storage to prevent unnecessary writes
        preferences
            .skip(1) // Skip initial value
            .debounce(.milliseconds(500), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] preferences in
                guard let self = self, !self.isReloadingFromStorage else { return }
                self.storageService.saveUserPreferences(preferences)
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
        defaultCategory = preferences.defaultCategory
        safetyFiltersEnabled = preferences.safetyFiltersEnabled
        preferredLanguage = preferences.preferredLanguage
        preferredCategories = preferences.preferredCategories

        // API Configuration
        apiKey = preferences.apiConfiguration.apiKey
        baseURL = preferences.apiConfiguration.baseURL
        modelName = preferences.apiConfiguration.modelName
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
        // Skip if this is triggered by reloadFromStorage to prevent loop
        guard !isReloadingFromStorage else { return }

        // Validate and clamp spice level to valid range
        let validatedLevel = ValidationService.validateSpiceLevel(level)

        #if DEBUG
        if level != validatedLevel {
            print("⚠️ Spice level \(level) was clamped to \(validatedLevel)")
        }
        #endif

        // Skip if value hasn't changed
        guard defaultSpiceLevel != validatedLevel else { return }

        defaultSpiceLevel = validatedLevel
        updatePreferences { preferences in
            preferences.defaultSpiceLevel = validatedLevel
        }

        // Save immediately to storage for sync (bypass debounce)
        saveCurrentPreferencesImmediately()

        // Notify other ViewModels about settings change (pass self to identify source)
        NotificationCenter.default.post(name: .settingsDidChange, object: self)
    }

    func updateDefaultCategory(_ category: RoastCategory) {
        // Skip if this is triggered by reloadFromStorage to prevent loop
        guard !isReloadingFromStorage else { return }

        // Validate category
        guard ValidationService.isValidCategory(category) else {
            #if DEBUG
            print("⚠️ Invalid category attempted: \(category)")
            #endif
            return
        }

        // Skip if value hasn't changed
        guard defaultCategory != category else { return }

        defaultCategory = category
        updatePreferences { preferences in
            preferences.defaultCategory = category
        }

        // Save immediately to storage for sync (bypass debounce)
        saveCurrentPreferencesImmediately()

        // Notify other ViewModels about settings change (pass self to identify source)
        NotificationCenter.default.post(name: .settingsDidChange, object: self)
    }

    private func saveCurrentPreferencesImmediately() {
        do {
            let currentPreferences = try preferencesSubject.value()
            storageService.saveUserPreferences(currentPreferences)
        } catch {
            #if DEBUG
            print("Error saving preferences immediately: \(error)")
            #endif
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
            #if DEBUG
            print("Error updating preferences: \(error)")
            #endif
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
                    #if DEBUG
                    print("Export failed: \(error)")
                    #endif
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
                pendingExportURL = latestFile
                showExportLocationPicker()
            }
        } catch {
            #if DEBUG
            print("Failed to find export file: \(error)")
            #endif
        }
    }

    private func showExportLocationPicker() {
        guard let exportURL = pendingExportURL else { return }

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let documentPicker = UIDocumentPickerViewController(forExporting: [exportURL], asCopy: true)
            documentPicker.delegate = self

            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                window.rootViewController?.present(documentPicker, animated: true)
            }
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
                        #if DEBUG
                        print("Preview failed: \(error)")
                        #endif
                    }
                )
                .disposed(by: disposeBag)
        } catch {
            #if DEBUG
            print("Failed to read file: \(error)")
            #endif
        }
    }

    // Store the import data temporarily
    private var pendingImportData: Data?

    func confirmImport(with options: ImportOptions = .merge) {
        guard let importData = pendingImportData else {
            #if DEBUG
            print("No import data available")
            #endif
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
                        warnings: [],
                        errors: [],
                        successCount: 0,
                        errorCount: 0
                    )
                    #if DEBUG
                    print("Import failed: \(error)")
                    #endif
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

        // Check if this is an export operation (user selected save location)
        if pendingExportURL != nil {
            // Export completed successfully
            pendingExportURL = nil
            showExportSuccess = true
            return
        }

        // Otherwise, this is an import operation
        // Start security-scoped resource access
        guard url.startAccessingSecurityScopedResource() else {
            #if DEBUG
            print("Failed to access security-scoped resource")
            #endif
            return
        }

        defer {
            url.stopAccessingSecurityScopedResource()
        }

        // Preview the import data first
        previewImportData(from: url)
    }

    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        // Clean up if export was cancelled
        if let exportURL = pendingExportURL {
            // Optionally delete the temporary export file
            try? FileManager.default.removeItem(at: exportURL)
            pendingExportURL = nil
        }
    }

    // MARK: - API Configuration Methods
    func updateAPIConfiguration() {
        // Sanitize inputs before saving
        let sanitizedAPIKey = ValidationService.sanitizeTextInput(apiKey)
        let sanitizedBaseURL = ValidationService.sanitizeTextInput(baseURL)
        let sanitizedModelName = ValidationService.sanitizeTextInput(modelName)

        #if DEBUG
        print("🔧 Updating API Configuration:")
        print("  apiKey: \(sanitizedAPIKey.isEmpty ? "EMPTY" : "SET")")
        print("  baseURL: \(sanitizedBaseURL.isEmpty ? "EMPTY" : "SET")")
        print("  modelName: \(sanitizedModelName.isEmpty ? "EMPTY" : sanitizedModelName)")
        #endif

        updatePreferences { preferences in
            preferences.apiConfiguration = APIConfiguration(
                apiKey: sanitizedAPIKey,
                baseURL: sanitizedBaseURL,
                modelName: sanitizedModelName
            )
        }

        // Force save immediately (don't wait for debounce)
        do {
            let currentPreferences = try preferencesSubject.value()
            storageService.saveUserPreferences(currentPreferences)
            #if DEBUG
            print("✅ API Configuration saved to storage immediately")
            #endif
        } catch {
            #if DEBUG
            print("❌ Failed to save API configuration: \(error)")
            #endif
        }

        #if DEBUG
        print("✅ API Configuration updated")
        #endif
    }

    func clearAPIConfiguration() {
        apiKey = ""
        baseURL = ""
        modelName = ""
        apiTestResult = nil
        clearValidationErrors()
        updateAPIConfiguration()
    }

    // MARK: - Validation Methods

    func validateAPIKey() {
        let language = LocalizationManager.shared.currentLanguage
        let result = ValidationService.validateAPIKey(apiKey, language: language)
        apiKeyError = result.errorMessage
    }

    func validateBaseURL() {
        let language = LocalizationManager.shared.currentLanguage
        let result = ValidationService.validateBaseURL(baseURL, language: language)
        baseURLError = result.errorMessage
    }

    func validateModelName() {
        let language = LocalizationManager.shared.currentLanguage
        let result = ValidationService.validateModelName(modelName, language: language)
        modelNameError = result.errorMessage
    }

    func validateAllAPIFields() -> Bool {
        let language = LocalizationManager.shared.currentLanguage
        let validation = ValidationService.validateAPIConfiguration(
            apiKey: apiKey,
            baseURL: baseURL,
            modelName: modelName,
            language: language
        )

        apiKeyError = validation.apiKeyError
        baseURLError = validation.baseURLError
        modelNameError = validation.modelNameError

        return validation.isValid
    }

    func clearValidationErrors() {
        apiKeyError = nil
        baseURLError = nil
        modelNameError = nil
    }

    var isAPIFormValid: Bool {
        let apiKeyTrimmed = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        let baseURLTrimmed = baseURL.trimmingCharacters(in: .whitespacesAndNewlines)

        return !apiKeyTrimmed.isEmpty &&
               !baseURLTrimmed.isEmpty &&
               apiKeyError == nil &&
               baseURLError == nil &&
               modelNameError == nil
    }

    func testAPIConnection() {
        #if DEBUG
        print("🧪 Testing API Connection...")
        print("  API Key: \(apiKey.isEmpty ? "EMPTY" : "SET")")
        print("  Base URL: \(baseURL.isEmpty ? "EMPTY" : "SET")")
        print("  Model: \(modelName.isEmpty ? "EMPTY" : modelName)")
        #endif

        // Validate all fields first
        guard validateAllAPIFields() else {
            #if DEBUG
            print("❌ Validation failed")
            #endif
            apiTestResult = false
            return
        }

        #if DEBUG
        print("✅ Validation passed, calling AIService...")
        #endif

        // Sanitize inputs before use
        let sanitizedAPIKey = ValidationService.sanitizeTextInput(apiKey)
        let sanitizedBaseURL = ValidationService.sanitizeTextInput(baseURL)
        let sanitizedModelName = ValidationService.sanitizeTextInput(modelName)

        // Reset previous result and show loading
        apiTestResult = nil
        isTestingConnection = true

        aiService.testAPIConnection(apiKey: sanitizedAPIKey, baseURL: sanitizedBaseURL, modelName: sanitizedModelName)
            .observe(on: MainScheduler.instance)
            .subscribe(
                onNext: { [weak self] success in
                    #if DEBUG
                    print("📡 API Test Result: \(success ? "SUCCESS" : "FAILED")")
                    #endif
                    self?.isTestingConnection = false
                    self?.apiTestResult = success
                    if success {
                        #if DEBUG
                        print("💾 Saving API configuration...")
                        #endif
                        self?.updateAPIConfiguration()
                    }
                },
                onError: { [weak self] error in
                    #if DEBUG
                    print("❌ API Test Error: \(error.localizedDescription)")
                    #endif
                    self?.isTestingConnection = false
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

    private func performExport(with options: ExportOptions) {
        isExporting = true
        exportProgress = nil

        dataExportService.exportData(options: options)
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] progress in
                self?.exportProgress = progress
                if case .completed = progress.phase {
                    self?.isExporting = false
                    self?.showExportSuccess = true
                }
            }, onError: { [weak self] error in
                self?.isExporting = false
                self?.handleError(error)
            })
            .disposed(by: disposeBag)
    }

    func cancelPrivacyNotice() {
        showingPrivacyNotice = false
        currentExportOptions = nil
        privacyNotice = nil
        complianceIssues = []
    }

    private func handleError(_ error: Error) {
        let message = ErrorHandler.shared.handle(error)
        ErrorHandler.shared.logError(error, context: "SettingsViewModel")

        DispatchQueue.main.async { [weak self] in
            self?.errorMessage = message
            self?.showError = true
        }
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
