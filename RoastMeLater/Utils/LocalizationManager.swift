import Foundation
import SwiftUI

// MARK: - LocalizationManager

/// Manages the current language state and provides localized strings
/// Uses the new screen-specific localization files in /Localization folder
class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()

    @Published var currentLanguage: String = "vi" {
        didSet {
            if oldValue != currentLanguage {
                UserDefaults.standard.set(currentLanguage, forKey: "app_language")
                // Post notification for any observers that need to know about language change
                NotificationCenter.default.post(name: .languageDidChange, object: nil)
            }
        }
    }

    private init() {
        self.currentLanguage = UserDefaults.standard.string(forKey: "app_language") ?? "vi"
    }

    func setLanguage(_ language: String) {
        currentLanguage = language
    }

    /// Convenience method to get localized string from L struct
    func localized(_ l: L) -> String {
        return l.localized(currentLanguage)
    }

    // MARK: - Language Options
    var languageOptions: [(code: String, name: String)] {
        [
            ("vi", currentLanguage == "en" ? "Vietnamese" : "Tiếng Việt"),
            ("en", currentLanguage == "en" ? "English" : "Tiếng Anh")
        ]
    }

    // MARK: - Tab Bar (backward compatibility)
    var tabRoast: String { Strings.TabBar.roast.localized(currentLanguage) }
    var tabHistory: String { Strings.TabBar.history.localized(currentLanguage) }
    var tabFavorites: String { Strings.TabBar.favorites.localized(currentLanguage) }
    var tabSettings: String { Strings.TabBar.settings.localized(currentLanguage) }
    var tabLibrary: String { Strings.Library.tabName.localized(currentLanguage) }

    // MARK: - Library Tab
    var librarySegmentAll: String { Strings.Library.segmentAll.localized(currentLanguage) }
    var librarySegmentFavorites: String { Strings.Library.segmentFavorites.localized(currentLanguage) }
    var librarySearchPlaceholder: String { Strings.Library.searchPlaceholder.localized(currentLanguage) }
    var libraryEmptyAllTitle: String { Strings.Library.emptyAllTitle.localized(currentLanguage) }
    var libraryEmptyAllMessage: String { Strings.Library.emptyAllMessage.localized(currentLanguage) }
    var libraryEmptyFavoritesTitle: String { Strings.Library.emptyFavoritesTitle.localized(currentLanguage) }
    var libraryEmptyFavoritesMessage: String { Strings.Library.emptyFavoritesMessage.localized(currentLanguage) }
    var libraryClearAll: String { Strings.Library.clearAll.localized(currentLanguage) }
    var libraryClearAllConfirmTitle: String { Strings.Library.clearAllConfirmTitle.localized(currentLanguage) }
    var libraryClearAllConfirmMessage: String { Strings.Library.clearAllConfirmMessage.localized(currentLanguage) }

    // MARK: - Common (backward compatibility)
    var ok: String { Strings.Common.ok.localized(currentLanguage) }
    var cancel: String { Strings.Common.cancel.localized(currentLanguage) }
    var done: String { Strings.Common.done.localized(currentLanguage) }
    var save: String { Strings.Common.save.localized(currentLanguage) }
    var delete: String { Strings.Common.delete.localized(currentLanguage) }
    var share: String { Strings.Common.share.localized(currentLanguage) }
    var loading: String { Strings.Common.loading.localized(currentLanguage) }
    var error: String { Strings.Common.error.localized(currentLanguage) }
    var retry: String { Strings.Common.retry.localized(currentLanguage) }
    var skip: String { Strings.Common.skip.localized(currentLanguage) }
    var abort: String { Strings.Common.abort.localized(currentLanguage) }

    // MARK: - Roast Generator (backward compatibility)
    var generateRoast: String { Strings.RoastGenerator.generateRoast.localized(currentLanguage) }
    var generating: String { Strings.RoastGenerator.generating.localized(currentLanguage) }
    var category: String { Strings.RoastGenerator.category.localized(currentLanguage) }
    var spiceLevel: String { Strings.RoastGenerator.spiceLevel.localized(currentLanguage) }
    var selectCategory: String { Strings.RoastGenerator.selectCategory.localized(currentLanguage) }

    // MARK: - Settings (backward compatibility)
    var notifications: String { Strings.Settings.Notifications.sectionTitle.localized(currentLanguage) }
    var content: String { Strings.Settings.Content.sectionTitle.localized(currentLanguage) }
    var data: String { Strings.Settings.Data.sectionTitle.localized(currentLanguage) }
    var version: String { Strings.Settings.Version.sectionTitle.localized(currentLanguage) }
    var about: String { Strings.Settings.AppInfo.about.localized(currentLanguage) }
    var language: String { Strings.Settings.Content.language.localized(currentLanguage) }
    var safetyFilters: String { Strings.Settings.Content.safetyFilters.localized(currentLanguage) }
    var clearHistory: String { Strings.Settings.Data.clearHistory.localized(currentLanguage) }
    var clearFavorites: String { Strings.Settings.Data.clearFavorites.localized(currentLanguage) }
    var resetSettings: String { Strings.Settings.Data.resetSettings.localized(currentLanguage) }

    // MARK: - Data Management (backward compatibility)
    var dataManagement: String { Strings.DataManagement.title.localized(currentLanguage) }
    var exportData: String { Strings.DataManagement.Export.title.localized(currentLanguage) }
    var importData: String { Strings.DataManagement.Import.title.localized(currentLanguage) }
    var exportAllData: String { Strings.DataManagement.Export.exportAll.localized(currentLanguage) }
    var exportOptions: String { Strings.DataManagement.Export.options.localized(currentLanguage) }
    var importPreview: String { Strings.DataManagement.Import.preview.localized(currentLanguage) }
    var dataOverview: String { Strings.DataManagement.dataOverview.localized(currentLanguage) }
    var totalRoasts: String { Strings.DataManagement.totalRoasts.localized(currentLanguage) }
    var favorites: String { Strings.DataManagement.favorites.localized(currentLanguage) }
    var mostPopular: String { Strings.DataManagement.mostPopular.localized(currentLanguage) }

    // Progress
    var preparing: String { Strings.DataManagement.Progress.preparing.localized(currentLanguage) }
    var collectingData: String { Strings.DataManagement.Progress.collectingData.localized(currentLanguage) }
    var processingRoasts: String { Strings.DataManagement.Progress.processingRoasts.localized(currentLanguage) }
    var processingFavorites: String { Strings.DataManagement.Progress.processingFavorites.localized(currentLanguage) }
    var generatingMetadata: String { Strings.DataManagement.Progress.generatingMetadata.localized(currentLanguage) }
    var serializing: String { Strings.DataManagement.Progress.serializing.localized(currentLanguage) }
    var writing: String { Strings.DataManagement.Progress.writing.localized(currentLanguage) }
    var validating: String { Strings.DataManagement.Progress.validating.localized(currentLanguage) }
    var parsing: String { Strings.DataManagement.Progress.parsing.localized(currentLanguage) }
    var processingPreferences: String { Strings.DataManagement.Progress.processingPreferences.localized(currentLanguage) }
    var saving: String { Strings.DataManagement.Progress.saving.localized(currentLanguage) }
    var completed: String { Strings.DataManagement.Progress.completed.localized(currentLanguage) }
    var exportSuccess: String { Strings.DataManagement.Export.success.localized(currentLanguage) }
    var importSuccess: String { Strings.DataManagement.Import.success.localized(currentLanguage) }

    // Export Options
    var apiConfiguration: String { Strings.DataManagement.Export.apiConfiguration.localized(currentLanguage) }
    var deviceInformation: String { Strings.DataManagement.Export.deviceInformation.localized(currentLanguage) }
    var usageStatistics: String { Strings.DataManagement.Export.usageStatistics.localized(currentLanguage) }
    var anonymizeData: String { Strings.DataManagement.Export.anonymizeData.localized(currentLanguage) }
    var includeAPIKeys: String { Strings.DataManagement.Export.includeAPIKeys.localized(currentLanguage) }
    var includeDeviceInfo: String { Strings.DataManagement.Export.includeDeviceInfo.localized(currentLanguage) }
    var includeStats: String { Strings.DataManagement.Export.includeStats.localized(currentLanguage) }
    var anonymizeDescription: String { Strings.DataManagement.Export.anonymizeDescription.localized(currentLanguage) }
    var whatsAlwaysIncluded: String { Strings.DataManagement.Export.whatsIncluded.localized(currentLanguage) }
    var exportDetails: String { Strings.DataManagement.Export.details.localized(currentLanguage) }
    var securityWarning: String { Strings.DataManagement.Export.securityWarning.localized(currentLanguage) }
    var apiKeyWarning: String { Strings.DataManagement.Export.apiKeyWarning.localized(currentLanguage) }
    var anonymizationNote: String { Strings.DataManagement.Export.anonymizationNote.localized(currentLanguage) }
    var allRoastHistory: String { Strings.DataManagement.Export.allRoastHistory.localized(currentLanguage) }
    var favoriteRoastsList: String { Strings.DataManagement.Export.favoritesList.localized(currentLanguage) }
    var userPreferencesAndSettings: String { Strings.DataManagement.Export.userPreferences.localized(currentLanguage) }
    var exportMetadataAndTimestamp: String { Strings.DataManagement.Export.exportMetadata.localized(currentLanguage) }

    // Import
    var fileInformation: String { Strings.DataManagement.Import.fileInformation.localized(currentLanguage) }
    var appVersion: String { Strings.DataManagement.Import.appVersion.localized(currentLanguage) }
    var exportDate: String { Strings.DataManagement.Import.exportDate.localized(currentLanguage) }
    var dataVersion: String { Strings.DataManagement.Import.dataVersion.localized(currentLanguage) }
    var device: String { Strings.DataManagement.Import.device.localized(currentLanguage) }
    var dataSummary: String { Strings.DataManagement.Import.dataSummary.localized(currentLanguage) }
    var importOptions: String { Strings.DataManagement.Import.options.localized(currentLanguage) }
    var importStrategy: String { Strings.DataManagement.Import.strategy.localized(currentLanguage) }
    var mergeWithExisting: String { Strings.DataManagement.Import.mergeWithExisting.localized(currentLanguage) }
    var replaceAllData: String { Strings.DataManagement.Import.replaceAll.localized(currentLanguage) }
    var skipDuplicates: String { Strings.DataManagement.Import.skipDuplicates.localized(currentLanguage) }
    var keepExistingFavorites: String { Strings.DataManagement.Import.keepExistingFavorites.localized(currentLanguage) }
    var warnings: String { Strings.DataManagement.Import.warnings.localized(currentLanguage) }
    var settingsChanges: String { Strings.DataManagement.Import.settingsChanges.localized(currentLanguage) }
    var incompatibleDataWarning: String { Strings.DataManagement.Import.incompatibleWarning.localized(currentLanguage) }
    var whatWouldYouLikeToDo: String { currentLanguage == "en" ? "What would you like to do?" : "Bạn muốn làm gì?" }
    var exportDescription: String { Strings.DataManagement.Export.description.localized(currentLanguage) }
    var importDescription: String { Strings.DataManagement.Import.description.localized(currentLanguage) }
    var dataManagementDescription: String { Strings.Settings.Data.dataManagementDesc.localized(currentLanguage) }

    // MARK: - Errors (backward compatibility)
    var operationFailed: String { Strings.Errors.operationFailed.localized(currentLanguage) }
    var errorDetails: String { Strings.Errors.errorDetails.localized(currentLanguage) }
    var operation: String { Strings.Errors.operation.localized(currentLanguage) }
    var phase: String { Strings.Errors.phase.localized(currentLanguage) }
    var progress: String { Strings.Errors.progress.localized(currentLanguage) }
    var time: String { Strings.Errors.time.localized(currentLanguage) }
    var suggestion: String { Strings.Errors.suggestion.localized(currentLanguage) }
    var recommended: String { Strings.Errors.recommended.localized(currentLanguage) }
    var freeUpStorage: String { Strings.Errors.freeUpStorage.localized(currentLanguage) }
    var skipCorruptedData: String { Strings.Errors.skipCorruptedData.localized(currentLanguage) }
    var stopOperation: String { Strings.Errors.stopOperation.localized(currentLanguage) }
    var checkConnection: String { Strings.Errors.checkConnection.localized(currentLanguage) }

    // MARK: - Search (backward compatibility)
    var searchRoasts: String { Strings.History.searchPlaceholder.localized(currentLanguage) }
    var searchFavorites: String { Strings.Favorites.searchPlaceholder.localized(currentLanguage) }

    // MARK: - Empty States (backward compatibility)
    var noHistory: String { Strings.History.emptyTitle.localized(currentLanguage) }
    var noFavorites: String { Strings.Favorites.emptyTitle.localized(currentLanguage) }
    var startGenerating: String { Strings.History.emptyMessage.localized(currentLanguage) }
    var addFavorites: String { Strings.Favorites.emptyMessage.localized(currentLanguage) }

    // MARK: - Dynamic Functions (backward compatibility)

    func newItems(_ count: Int) -> String {
        Strings.Common.newItems(count).localized(currentLanguage)
    }

    func duplicateRoastsFound(_ count: Int) -> String {
        Strings.DataManagement.Import.duplicatesFound(count).localized(currentLanguage)
    }

    func moreWarnings(_ count: Int) -> String {
        Strings.DataManagement.Import.moreWarnings(count).localized(currentLanguage)
    }

    func languageChange(from: String, to: String) -> String {
        currentLanguage == "en" ? "Language: \(from) → \(to)" : "Ngôn ngữ: \(from) → \(to)"
    }

    func spiceLevelChange(from: Int, to: Int) -> String {
        currentLanguage == "en" ? "Default spice level: \(from) → \(to)" : "Mức độ cay mặc định: \(from) → \(to)"
    }

    func notificationChange(from: Bool, to: Bool) -> String {
        let fromText = from ? (currentLanguage == "en" ? "On" : "Bật") : (currentLanguage == "en" ? "Off" : "Tắt")
        let toText = to ? (currentLanguage == "en" ? "On" : "Bật") : (currentLanguage == "en" ? "Off" : "Tắt")
        return currentLanguage == "en" ? "Notifications: \(fromText) → \(toText)" : "Thông báo: \(fromText) → \(toText)"
    }

    func safetyFilterChange(from: Bool, to: Bool) -> String {
        let fromText = from ? (currentLanguage == "en" ? "On" : "Bật") : (currentLanguage == "en" ? "Off" : "Tắt")
        let toText = to ? (currentLanguage == "en" ? "On" : "Bật") : (currentLanguage == "en" ? "Off" : "Tắt")
        return currentLanguage == "en" ? "Safety filters: \(fromText) → \(toText)" : "Bộ lọc an toàn: \(fromText) → \(toText)"
    }

    // MARK: - Category Names (backward compatibility)
    func categoryName(_ category: RoastCategory) -> String {
        switch category {
        case .general:
            return Strings.RoastGenerator.Categories.general.localized(currentLanguage)
        case .deadlines:
            return Strings.RoastGenerator.Categories.deadlines.localized(currentLanguage)
        case .meetings:
            return Strings.RoastGenerator.Categories.meetings.localized(currentLanguage)
        case .kpis:
            return Strings.RoastGenerator.Categories.kpis.localized(currentLanguage)
        case .codeReviews:
            return Strings.RoastGenerator.Categories.codeReviews.localized(currentLanguage)
        case .workload:
            return Strings.RoastGenerator.Categories.workload.localized(currentLanguage)
        case .colleagues:
            return Strings.RoastGenerator.Categories.colleagues.localized(currentLanguage)
        case .management:
            return Strings.RoastGenerator.Categories.management.localized(currentLanguage)
        }
    }

    func categoryDescription(_ category: RoastCategory) -> String {
        switch category {
        case .general:
            return Strings.RoastGenerator.Categories.generalDesc.localized(currentLanguage)
        case .deadlines:
            return Strings.RoastGenerator.Categories.deadlinesDesc.localized(currentLanguage)
        case .meetings:
            return Strings.RoastGenerator.Categories.meetingsDesc.localized(currentLanguage)
        case .kpis:
            return Strings.RoastGenerator.Categories.kpisDesc.localized(currentLanguage)
        case .codeReviews:
            return Strings.RoastGenerator.Categories.codeReviewsDesc.localized(currentLanguage)
        case .workload:
            return Strings.RoastGenerator.Categories.workloadDesc.localized(currentLanguage)
        case .colleagues:
            return Strings.RoastGenerator.Categories.colleaguesDesc.localized(currentLanguage)
        case .management:
            return Strings.RoastGenerator.Categories.managementDesc.localized(currentLanguage)
        }
    }

    // MARK: - Notification Frequency (backward compatibility)
    func notificationFrequencyName(_ frequency: NotificationFrequency) -> String {
        switch frequency {
        case .disabled:
            return Strings.Settings.Notifications.disabled.localized(currentLanguage)
        case .hourly:
            return Strings.Settings.Notifications.hourly.localized(currentLanguage)
        case .every2Hours:
            return Strings.Settings.Notifications.every2Hours.localized(currentLanguage)
        case .every4Hours:
            return Strings.Settings.Notifications.every4Hours.localized(currentLanguage)
        case .daily:
            return Strings.Settings.Notifications.daily.localized(currentLanguage)
        }
    }

    // MARK: - Spice Level Names (backward compatibility)
    func spiceLevelName(_ level: Int) -> String {
        Strings.RoastGenerator.spiceLevelName(level).localized(currentLanguage)
    }

    // MARK: - Data Operation Helper
    func operationName(_ operation: DataOperation) -> String {
        switch operation {
        case .export:
            return exportData
        case .dataImport:
            return importData
        case .validation:
            return currentLanguage == "en" ? "Data Validation" : "Xác Thực Dữ Liệu"
        }
    }
}

// MARK: - SwiftUI Environment
struct LocalizationEnvironmentKey: EnvironmentKey {
    static let defaultValue = LocalizationManager.shared
}

extension EnvironmentValues {
    var localization: LocalizationManager {
        get { self[LocalizationEnvironmentKey.self] }
        set { self[LocalizationEnvironmentKey.self] = newValue }
    }
}
