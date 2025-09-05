import Foundation
import RxSwift
import RxCocoa

class FavoritesViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var favoriteRoasts: [Roast] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false
    
    // MARK: - Private Properties
    private let storageService: StorageServiceProtocol
    private let disposeBag = DisposeBag()
    
    // MARK: - Reactive Properties
    private let favoritesSubject = BehaviorSubject<[Roast]>(value: [])
    private let loadingSubject = BehaviorSubject<Bool>(value: false)
    private let errorSubject = PublishSubject<String>()
    
    var favorites: Observable<[Roast]> {
        return favoritesSubject.asObservable()
    }
    
    var loading: Observable<Bool> {
        return loadingSubject.asObservable()
    }
    
    var error: Observable<String> {
        return errorSubject.asObservable()
    }
    
    // MARK: - Computed Properties
    var totalFavorites: Int {
        return favoriteRoasts.count
    }
    
    var favoritesByCategory: [RoastCategory: [Roast]] {
        return Dictionary(grouping: favoriteRoasts) { $0.category }
    }
    
    var mostFavoritedCategory: RoastCategory? {
        let categoryCount = favoritesByCategory.mapValues { $0.count }
        return categoryCount.max(by: { $0.value < $1.value })?.key
    }
    
    var averageSpiceLevelOfFavorites: Double {
        guard !favoriteRoasts.isEmpty else { return 0 }
        let totalSpice = favoriteRoasts.map { $0.spiceLevel }.reduce(0, +)
        return Double(totalSpice) / Double(favoriteRoasts.count)
    }
    
    // MARK: - Initialization
    init(storageService: StorageServiceProtocol = StorageService()) {
        self.storageService = storageService
        setupBindings()
        loadFavorites()
    }
    
    // MARK: - Private Methods
    private func setupBindings() {
        // Bind favorites from storage service
        if let storageService = storageService as? StorageService {
            storageService.favorites
                .observe(on: MainScheduler.instance)
                .subscribe(onNext: { [weak self] favorites in
                    self?.favoriteRoasts = favorites
                    self?.favoritesSubject.onNext(favorites)
                })
                .disposed(by: disposeBag)
        }
        
        // Bind loading state
        loading
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] isLoading in
                self?.isLoading = isLoading
            })
            .disposed(by: disposeBag)
        
        // Bind error state
        error
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] message in
                self?.errorMessage = message
                self?.showError = true
            })
            .disposed(by: disposeBag)
    }
    
    // MARK: - Public Methods
    func loadFavorites() {
        loadingSubject.onNext(true)
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let favorites = self.storageService.getFavoriteRoasts()
            
            DispatchQueue.main.async {
                self.favoriteRoasts = favorites
                self.favoritesSubject.onNext(favorites)
                self.loadingSubject.onNext(false)
            }
        }
    }
    
    func toggleFavorite(roast: Roast) {
        print("🔄 FavoritesViewModel.toggleFavorite:")
        print("  roast.id: \(roast.id)")
        print("  roast.isFavorite BEFORE: \(roast.isFavorite)")
        print("  favoriteRoasts count BEFORE: \(favoriteRoasts.count)")

        storageService.toggleFavorite(roastId: roast.id)

        // Update local array immediately for better UX
        // Since we're in favorites view, toggling will always remove from favorites
        favoriteRoasts.removeAll { $0.id == roast.id }
        print("  favoriteRoasts count AFTER: \(favoriteRoasts.count)")
        favoritesSubject.onNext(favoriteRoasts)
    }
    
    func removeFavorite(roast: Roast) {
        storageService.toggleFavorite(roastId: roast.id)
        favoriteRoasts.removeAll { $0.id == roast.id }
        favoritesSubject.onNext(favoriteRoasts)
    }
    
    func clearAllFavorites() {
        let favoriteIds = favoriteRoasts.map { $0.id }
        
        for id in favoriteIds {
            storageService.toggleFavorite(roastId: id)
        }
        
        favoriteRoasts.removeAll()
        favoritesSubject.onNext([])
    }
    
    // MARK: - Filtering Methods
    func filterFavorites(by category: RoastCategory) -> Observable<[Roast]> {
        return favorites
            .map { roasts in
                roasts.filter { $0.category == category }
            }
    }
    
    func filterFavorites(by spiceLevel: Int) -> Observable<[Roast]> {
        return favorites
            .map { roasts in
                roasts.filter { $0.spiceLevel == spiceLevel }
            }
    }
    
    func filterFavorites(containing searchText: String) -> Observable<[Roast]> {
        return favorites
            .map { roasts in
                guard !searchText.isEmpty else { return roasts }
                return roasts.filter { roast in
                    roast.content.localizedCaseInsensitiveContains(searchText) ||
                    roast.category.displayName.localizedCaseInsensitiveContains(searchText)
                }
            }
    }
    
    // MARK: - Sorting Methods
    func sortFavorites(by sortOption: FavoriteSortOption) -> Observable<[Roast]> {
        return favorites
            .map { roasts in
                switch sortOption {
                case .dateAdded:
                    return roasts.sorted { $0.createdAt > $1.createdAt }
                case .spiceLevelHigh:
                    return roasts.sorted { $0.spiceLevel > $1.spiceLevel }
                case .spiceLevelLow:
                    return roasts.sorted { $0.spiceLevel < $1.spiceLevel }
                case .category:
                    return roasts.sorted { $0.category.displayName < $1.category.displayName }
                case .contentLength:
                    return roasts.sorted { $0.content.count > $1.content.count }
                }
            }
    }
    
    // MARK: - Statistics Methods
    func getFavoriteStatistics() -> Observable<FavoriteStatistics> {
        return favorites
            .map { [weak self] roasts in
                guard let self = self else {
                    return FavoriteStatistics(
                        totalFavorites: 0,
                        categoryBreakdown: [:],
                        averageSpiceLevel: 0,
                        mostFavoritedCategory: nil,
                        oldestFavorite: nil,
                        newestFavorite: nil
                    )
                }
                
                let categoryStats = Dictionary(grouping: roasts) { $0.category }
                    .mapValues { $0.count }
                
                let averageSpice = roasts.isEmpty ? 0 :
                    Double(roasts.map { $0.spiceLevel }.reduce(0, +)) / Double(roasts.count)
                
                let sortedByDate = roasts.sorted { $0.createdAt < $1.createdAt }
                
                return FavoriteStatistics(
                    totalFavorites: roasts.count,
                    categoryBreakdown: categoryStats,
                    averageSpiceLevel: averageSpice,
                    mostFavoritedCategory: categoryStats.max(by: { $0.value < $1.value })?.key,
                    oldestFavorite: sortedByDate.first,
                    newestFavorite: sortedByDate.last
                )
            }
    }
    
    // MARK: - Sharing Methods
    func generateShareText(for roasts: [Roast]) -> String {
        let header = "🔥 Bộ sưu tập RoastMe yêu thích của tôi:\n\n"
        
        let roastTexts = roasts.enumerated().map { index, roast in
            let spiceIndicator = String(repeating: "🌶️", count: roast.spiceLevel)
            return "\(index + 1). [\(roast.category.displayName)] \(roast.content) \(spiceIndicator)"
        }.joined(separator: "\n\n")
        
        let footer = "\n\nĐược tạo bởi RoastMe App 🔥"
        
        return header + roastTexts + footer
    }
    
    func generateShareTextForSingle(_ roast: Roast) -> String {
        let spiceIndicator = String(repeating: "🌶️", count: roast.spiceLevel)
        return """
        🔥 RoastMe - \(roast.category.displayName)
        
        \(roast.content)
        
        Mức độ cay: \(spiceIndicator)
        
        Được tạo bởi RoastMe App
        """
    }
    
    // MARK: - Reactive Batch Operations
    func batchRemoveFavorites(roastIds: [UUID]) -> Observable<Void> {
        return Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onCompleted()
                return Disposables.create()
            }
            
            for id in roastIds {
                self.storageService.toggleFavorite(roastId: id)
            }
            
            // Update local array
            self.favoriteRoasts.removeAll { roastIds.contains($0.id) }
            self.favoritesSubject.onNext(self.favoriteRoasts)
            
            observer.onNext(())
            observer.onCompleted()
            
            return Disposables.create()
        }
    }
}

// MARK: - Supporting Types
enum FavoriteSortOption: String, CaseIterable {
    case dateAdded = "date_added"
    case spiceLevelHigh = "spice_high"
    case spiceLevelLow = "spice_low"
    case category = "category"
    case contentLength = "content_length"
    
    var displayName: String {
        switch self {
        case .dateAdded: return "Ngày thêm"
        case .spiceLevelHigh: return "Cay nhất"
        case .spiceLevelLow: return "Nhẹ nhất"
        case .category: return "Theo danh mục"
        case .contentLength: return "Độ dài nội dung"
        }
    }
}

struct FavoriteStatistics {
    let totalFavorites: Int
    let categoryBreakdown: [RoastCategory: Int]
    let averageSpiceLevel: Double
    let mostFavoritedCategory: RoastCategory?
    let oldestFavorite: Roast?
    let newestFavorite: Roast?
}
