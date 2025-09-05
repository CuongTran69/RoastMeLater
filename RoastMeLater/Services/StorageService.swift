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
}
