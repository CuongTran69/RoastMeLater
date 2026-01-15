import Foundation
import RxSwift
import RxCocoa
import Combine

enum LibraryFilterMode: String, CaseIterable {
    case all = "all"
    case favoritesOnly = "favorites_only"
    
    var displayName: String {
        switch self {
        case .all: return "Tất cả"
        case .favoritesOnly: return "Yêu thích"
        }
    }
}

class LibraryViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var allRoasts: [Roast] = []
    @Published var displayedRoasts: [Roast] = []
    @Published var isLoading = false
    @Published var isLoadingMore = false
    @Published var errorMessage: String?
    @Published var showError = false
    @Published var filterMode: LibraryFilterMode = .all
    @Published var searchText: String = ""
    @Published var selectedCategory: RoastCategory?
    @Published var hasMoreData = true
    
    // MARK: - Private Properties
    private let storageService: StorageServiceProtocol
    private let disposeBag = DisposeBag()
    private var cancellables = Set<AnyCancellable>()
    
    private let pageSize = 20
    private var currentPage = 0
    private var filteredRoasts: [Roast] = []
    
    // MARK: - Reactive Properties
    private let roastsSubject = BehaviorSubject<[Roast]>(value: [])
    private let displayedRoastsSubject = BehaviorSubject<[Roast]>(value: [])
    private let loadingSubject = BehaviorSubject<Bool>(value: false)
    private let errorSubject = PublishSubject<String>()
    private let searchTextSubject = BehaviorSubject<String>(value: "")
    
    var roastsObservable: Observable<[Roast]> {
        return roastsSubject.asObservable()
    }
    
    var displayedRoastsObservable: Observable<[Roast]> {
        return displayedRoastsSubject.asObservable()
    }
    
    var loading: Observable<Bool> {
        return loadingSubject.asObservable()
    }
    
    var error: Observable<String> {
        return errorSubject.asObservable()
    }
    
    // MARK: - Computed Properties
    var totalRoasts: Int {
        return allRoasts.count
    }
    
    var totalFavorites: Int {
        return allRoasts.filter { $0.isFavorite }.count
    }
    
    var roastsByCategory: [RoastCategory: [Roast]] {
        return Dictionary(grouping: currentFilteredRoasts) { $0.category }
    }
    
    var currentFilteredRoasts: [Roast] {
        var roasts = filterMode == .favoritesOnly ? allRoasts.filter { $0.isFavorite } : allRoasts
        
        if let category = selectedCategory {
            roasts = roasts.filter { $0.category == category }
        }
        
        if !searchText.isEmpty {
            roasts = roasts.filter { roast in
                roast.content.localizedCaseInsensitiveContains(searchText) ||
                roast.category.displayName.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return roasts
    }
    
    // MARK: - Initialization
    init(storageService: StorageServiceProtocol = StorageService.shared) {
        self.storageService = storageService
        setupBindings()
        setupSearchDebounce()
        loadRoasts()
    }
    
    // MARK: - Private Methods
    private func setupBindings() {
        if let storageService = storageService as? StorageService {
            storageService.roastHistory
                .observe(on: MainScheduler.instance)
                .subscribe(onNext: { [weak self] roasts in
                    self?.allRoasts = roasts
                    self?.roastsSubject.onNext(roasts)
                    self?.applyFiltersAndPagination()
                })
                .disposed(by: disposeBag)
        }
        
        loading
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] isLoading in
                self?.isLoading = isLoading
            })
            .disposed(by: disposeBag)
        
        error
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] message in
                self?.errorMessage = message
                self?.showError = true
            })
            .disposed(by: disposeBag)
        
        NotificationCenter.default.publisher(for: .favoriteDidChange)
            .sink { [weak self] notification in
                self?.handleFavoriteChange(notification)
            }
            .store(in: &cancellables)
    }
    
    private func setupSearchDebounce() {
        $searchText
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.resetPaginationAndApplyFilters()
            }
            .store(in: &cancellables)
        
        $filterMode
            .dropFirst()
            .sink { [weak self] _ in
                self?.resetPaginationAndApplyFilters()
            }
            .store(in: &cancellables)
        
        $selectedCategory
            .dropFirst()
            .sink { [weak self] _ in
                self?.resetPaginationAndApplyFilters()
            }
            .store(in: &cancellables)
    }

    private func resetPaginationAndApplyFilters() {
        currentPage = 0
        hasMoreData = true
        applyFiltersAndPagination()
    }

    private func applyFiltersAndPagination() {
        filteredRoasts = currentFilteredRoasts
        let endIndex = min((currentPage + 1) * pageSize, filteredRoasts.count)
        displayedRoasts = Array(filteredRoasts.prefix(endIndex))
        displayedRoastsSubject.onNext(displayedRoasts)
        hasMoreData = endIndex < filteredRoasts.count
    }

    private func handleFavoriteChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let roastId = userInfo["roastId"] as? UUID,
              let isFavorite = userInfo["isFavorite"] as? Bool else { return }

        if let index = allRoasts.firstIndex(where: { $0.id == roastId }) {
            allRoasts[index].isFavorite = isFavorite
            roastsSubject.onNext(allRoasts)
            applyFiltersAndPagination()
        }
    }

    // MARK: - Public Methods
    func loadRoasts() {
        loadingSubject.onNext(true)

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            let roasts = self.storageService.getRoastHistory()

            DispatchQueue.main.async {
                self.allRoasts = roasts
                self.roastsSubject.onNext(roasts)
                self.applyFiltersAndPagination()
                self.loadingSubject.onNext(false)
            }
        }
    }

    func loadMore() {
        guard hasMoreData, !isLoadingMore else { return }

        isLoadingMore = true
        currentPage += 1

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.applyFiltersAndPagination()
            self?.isLoadingMore = false
        }
    }

    func toggleFavorite(roast: Roast) {
        storageService.toggleFavorite(roastId: roast.id)
    }

    func deleteRoast(roast: Roast) {
        storageService.deleteRoast(roastId: roast.id)
        allRoasts.removeAll { $0.id == roast.id }
        roastsSubject.onNext(allRoasts)
        applyFiltersAndPagination()
    }

    func setFilterMode(_ mode: LibraryFilterMode) {
        filterMode = mode
    }

    func setSearchText(_ text: String) {
        searchText = text
        searchTextSubject.onNext(text)
    }

    func setSelectedCategory(_ category: RoastCategory?) {
        selectedCategory = category
    }

    func clearFilters() {
        searchText = ""
        selectedCategory = nil
        filterMode = .all
        resetPaginationAndApplyFilters()
    }

    // MARK: - Filtering Methods
    func filterRoasts(by category: RoastCategory) -> Observable<[Roast]> {
        return displayedRoastsObservable
            .map { roasts in
                roasts.filter { $0.category == category }
            }
    }

    func filterRoasts(by spiceLevel: Int) -> Observable<[Roast]> {
        return displayedRoastsObservable
            .map { roasts in
                roasts.filter { $0.spiceLevel == spiceLevel }
            }
    }

    func filterRoasts(containing searchText: String) -> Observable<[Roast]> {
        return displayedRoastsObservable
            .map { roasts in
                guard !searchText.isEmpty else { return roasts }
                return roasts.filter { roast in
                    roast.content.localizedCaseInsensitiveContains(searchText) ||
                    roast.category.displayName.localizedCaseInsensitiveContains(searchText)
                }
            }
    }
}
