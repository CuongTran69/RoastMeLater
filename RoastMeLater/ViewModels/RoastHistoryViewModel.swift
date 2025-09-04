import Foundation
import RxSwift
import RxCocoa

class RoastHistoryViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var roasts: [Roast] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false
    
    // MARK: - Private Properties
    private let storageService: StorageServiceProtocol
    private let disposeBag = DisposeBag()
    
    // MARK: - Reactive Properties
    private let roastsSubject = BehaviorSubject<[Roast]>(value: [])
    private let loadingSubject = BehaviorSubject<Bool>(value: false)
    private let errorSubject = PublishSubject<String>()
    
    var roastsObservable: Observable<[Roast]> {
        return roastsSubject.asObservable()
    }
    
    var loading: Observable<Bool> {
        return loadingSubject.asObservable()
    }
    
    var error: Observable<String> {
        return errorSubject.asObservable()
    }
    
    // MARK: - Computed Properties
    var totalRoasts: Int {
        return roasts.count
    }
    
    var favoriteRoasts: [Roast] {
        return roasts.filter { $0.isFavorite }
    }
    
    var roastsByCategory: [RoastCategory: [Roast]] {
        return Dictionary(grouping: roasts) { $0.category }
    }
    
    var mostUsedCategory: RoastCategory? {
        let categoryCount = roastsByCategory.mapValues { $0.count }
        return categoryCount.max(by: { $0.value < $1.value })?.key
    }
    
    // MARK: - Initialization
    init(storageService: StorageServiceProtocol = StorageService()) {
        self.storageService = storageService
        setupBindings()
        loadRoasts()
    }
    
    // MARK: - Private Methods
    private func setupBindings() {
        // Bind roasts from storage service
        if let storageService = storageService as? StorageService {
            storageService.roastHistory
                .observe(on: MainScheduler.instance)
                .subscribe(onNext: { [weak self] roasts in
                    self?.roasts = roasts
                    self?.roastsSubject.onNext(roasts)
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
            .subscribe(onNext: { [weak self] errorMessage in
                self?.errorMessage = errorMessage
                self?.showError = true
            })
            .disposed(by: disposeBag)
    }
    
    // MARK: - Public Methods
    func loadRoasts() {
        loadingSubject.onNext(true)
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let roasts = self.storageService.getRoastHistory()
            
            DispatchQueue.main.async {
                self.roasts = roasts
                self.roastsSubject.onNext(roasts)
                self.loadingSubject.onNext(false)
            }
        }
    }
    
    func toggleFavorite(roast: Roast) {
        storageService.toggleFavorite(roastId: roast.id)
        
        // Update local array immediately for better UX
        if let index = roasts.firstIndex(where: { $0.id == roast.id }) {
            roasts[index].isFavorite.toggle()
            roastsSubject.onNext(roasts)
        }
    }
    
    func deleteRoast(roast: Roast) {
        storageService.deleteRoast(roastId: roast.id)
        
        // Update local array immediately
        roasts.removeAll { $0.id == roast.id }
        roastsSubject.onNext(roasts)
    }
    
    func clearAllHistory() {
        storageService.clearAllData()
        roasts.removeAll()
        roastsSubject.onNext([])
    }
    
    // MARK: - Filtering Methods
    func filterRoasts(by category: RoastCategory) -> Observable<[Roast]> {
        return roastsObservable
            .map { roasts in
                roasts.filter { $0.category == category }
            }
    }
    
    func filterRoasts(by spiceLevel: Int) -> Observable<[Roast]> {
        return roastsObservable
            .map { roasts in
                roasts.filter { $0.spiceLevel == spiceLevel }
            }
    }
    
    func filterRoasts(containing searchText: String) -> Observable<[Roast]> {
        return roastsObservable
            .map { roasts in
                guard !searchText.isEmpty else { return roasts }
                return roasts.filter { roast in
                    roast.content.localizedCaseInsensitiveContains(searchText) ||
                    roast.category.displayName.localizedCaseInsensitiveContains(searchText)
                }
            }
    }
    
    func filterFavoriteRoasts() -> Observable<[Roast]> {
        return roastsObservable
            .map { roasts in
                roasts.filter { $0.isFavorite }
            }
    }
    
    // MARK: - Sorting Methods
    func sortRoasts(by sortOption: RoastSortOption) -> Observable<[Roast]> {
        return roastsObservable
            .map { roasts in
                switch sortOption {
                case .dateNewest:
                    return roasts.sorted { $0.createdAt > $1.createdAt }
                case .dateOldest:
                    return roasts.sorted { $0.createdAt < $1.createdAt }
                case .spiceLevelHigh:
                    return roasts.sorted { $0.spiceLevel > $1.spiceLevel }
                case .spiceLevelLow:
                    return roasts.sorted { $0.spiceLevel < $1.spiceLevel }
                case .category:
                    return roasts.sorted { $0.category.displayName < $1.category.displayName }
                case .favorites:
                    return roasts.sorted { $0.isFavorite && !$1.isFavorite }
                }
            }
    }
    
    // MARK: - Statistics Methods
    func getRoastStatistics() -> Observable<RoastStatistics> {
        return roastsObservable
            .map { roasts in
                let totalCount = roasts.count
                let favoriteCount = roasts.filter { $0.isFavorite }.count
                let categoryStats = Dictionary(grouping: roasts) { $0.category }
                    .mapValues { $0.count }
                let averageSpiceLevel = roasts.isEmpty ? 0 : 
                    Double(roasts.map { $0.spiceLevel }.reduce(0, +)) / Double(roasts.count)
                
                return RoastStatistics(
                    totalRoasts: totalCount,
                    favoriteRoasts: favoriteCount,
                    categoryBreakdown: categoryStats,
                    averageSpiceLevel: averageSpiceLevel,
                    mostPopularCategory: categoryStats.max(by: { $0.value < $1.value })?.key
                )
            }
    }
    
    // MARK: - Reactive Batch Operations
    func batchToggleFavorites(roastIds: [UUID]) -> Observable<Void> {
        return Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onCompleted()
                return Disposables.create()
            }
            
            for id in roastIds {
                self.storageService.toggleFavorite(roastId: id)
            }
            
            // Reload data
            self.loadRoasts()
            observer.onNext(())
            observer.onCompleted()
            
            return Disposables.create()
        }
    }
    
    func batchDeleteRoasts(roastIds: [UUID]) -> Observable<Void> {
        return Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onCompleted()
                return Disposables.create()
            }
            
            for id in roastIds {
                self.storageService.deleteRoast(roastId: id)
            }
            
            // Update local array
            self.roasts.removeAll { roastIds.contains($0.id) }
            self.roastsSubject.onNext(self.roasts)
            
            observer.onNext(())
            observer.onCompleted()
            
            return Disposables.create()
        }
    }
}

// MARK: - Supporting Types
enum RoastSortOption: String, CaseIterable {
    case dateNewest = "date_newest"
    case dateOldest = "date_oldest"
    case spiceLevelHigh = "spice_high"
    case spiceLevelLow = "spice_low"
    case category = "category"
    case favorites = "favorites"
    
    var displayName: String {
        switch self {
        case .dateNewest: return "Mới nhất"
        case .dateOldest: return "Cũ nhất"
        case .spiceLevelHigh: return "Cay nhất"
        case .spiceLevelLow: return "Nhẹ nhất"
        case .category: return "Theo danh mục"
        case .favorites: return "Yêu thích trước"
        }
    }
}

struct RoastStatistics {
    let totalRoasts: Int
    let favoriteRoasts: Int
    let categoryBreakdown: [RoastCategory: Int]
    let averageSpiceLevel: Double
    let mostPopularCategory: RoastCategory?
}
