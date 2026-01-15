import Foundation

// MARK: - Localization Protocol

/// Protocol for all screen-specific localization structs
protocol LocalizationStrings {
    var en: String { get }
    var vi: String { get }
    func localized(_ language: String) -> String
}

extension LocalizationStrings {
    func localized(_ language: String) -> String {
        return language == "en" ? en : vi
    }
}

// MARK: - LocalizedString

/// A simple struct to hold English and Vietnamese translations
struct L: LocalizationStrings {
    let en: String
    let vi: String
    
    init(_ en: String, _ vi: String) {
        self.en = en
        self.vi = vi
    }
    
    func localized(_ language: String) -> String {
        return language == "en" ? en : vi
    }
}

// MARK: - Localization Namespace

/// Main namespace for all localization strings organized by screen
enum Strings {
    // Screen-specific localizations are defined in separate files
    // - CommonStrings.swift
    // - TabBarStrings.swift
    // - RoastGeneratorStrings.swift
    // - SettingsStrings.swift
    // - FavoritesStrings.swift
    // - HistoryStrings.swift
    // - DataManagementStrings.swift
    // - StreakStrings.swift
    // - ComponentStrings.swift
}

