import Foundation
import RxSwift
import RxCocoa
import UIKit
import Combine

class RoastGeneratorViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var currentRoast: Roast?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false
    @Published var showAPISetup = false
    @Published var selectedCategory: RoastCategory = .general
    @Published var spiceLevel: Int = 3
    
    // MARK: - Private Properties
    private let aiService: AIServiceProtocol
    private let storageService: StorageServiceProtocol
    private let safetyFilter = SafetyFilter()
    private let disposeBag = DisposeBag()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Reactive Properties
    private let loadingSubject = BehaviorSubject<Bool>(value: false)
    private let errorSubject = PublishSubject<String>()
    private let roastSubject = BehaviorSubject<Roast?>(value: nil)
    
    var loading: Observable<Bool> {
        return loadingSubject.asObservable()
    }
    
    var error: Observable<String> {
        return errorSubject.asObservable()
    }
    
    var roast: Observable<Roast?> {
        return roastSubject.asObservable()
    }
    
    // MARK: - Initialization
    init(aiService: AIServiceProtocol = AIService(),
         storageService: StorageServiceProtocol = StorageService()) {
        self.aiService = aiService
        self.storageService = storageService

        setupBindings()
        loadUserPreferences()
        loadInitialRoast()
    }
    
    // MARK: - Private Methods
    private func setupBindings() {
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

        // Bind roast state
        roast
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] roast in
                self?.currentRoast = roast
            })
            .disposed(by: disposeBag)

        // Listen for settings changes to sync spice level
        NotificationCenter.default.publisher(for: .settingsDidChange)
            .sink { [weak self] _ in
                self?.loadUserPreferences()
            }
            .store(in: &cancellables)

        // Listen for favorite changes to sync current roast
        NotificationCenter.default.publisher(for: .favoriteDidChange)
            .sink { [weak self] notification in
                self?.handleFavoriteChange(notification)
            }
            .store(in: &cancellables)
    }

    private func loadUserPreferences() {
        let preferences = storageService.getUserPreferences()
        selectedCategory = preferences.defaultCategory
        spiceLevel = preferences.defaultSpiceLevel

        print("🔄 Loaded user preferences:")
        print("  selectedCategory: \(selectedCategory.displayName)")
        print("  spiceLevel: \(spiceLevel)")
    }

    private func handleFavoriteChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let roastId = userInfo["roastId"] as? UUID,
              let isFavorite = userInfo["isFavorite"] as? Bool,
              let updatedRoast = userInfo["roast"] as? Roast,
              let currentRoast = currentRoast,
              currentRoast.id == roastId else { return }

        print("🔄 RoastGeneratorViewModel.handleFavoriteChange:")
        print("  roastId: \(roastId)")
        print("  isFavorite: \(isFavorite)")

        // Update current roast with new favorite status
        var newRoast = currentRoast
        newRoast.isFavorite = isFavorite
        roastSubject.onNext(newRoast)
        self.currentRoast = newRoast
    }

    private func saveUserPreferences() {
        var preferences = storageService.getUserPreferences()
        preferences.defaultCategory = selectedCategory
        preferences.defaultSpiceLevel = spiceLevel
        storageService.saveUserPreferences(preferences)

        print("💾 Saved user preferences:")
        print("  selectedCategory: \(selectedCategory.displayName)")
        print("  spiceLevel: \(spiceLevel)")
    }

    private func loadInitialRoast() {
        // Check if API is configured to show appropriate welcome message
        let preferences = storageService.getUserPreferences()
        let isAPIConfigured = !preferences.apiConfiguration.apiKey.isEmpty && !preferences.apiConfiguration.baseURL.isEmpty

        let welcomeContent = isAPIConfigured
            ? "Chào mừng bạn đến với RoastMe! Sẵn sàng để được 'nướng' một chút chưa? 🔥"
            : "Chào mừng bạn đến với RoastMe! Nhấn 'Tạo Roast Mới' để bắt đầu cấu hình API và tạo roast đầu tiên! 🔥"

        let welcomeRoast = Roast(
            content: welcomeContent,
            category: .general,
            spiceLevel: 1,
            language: "vi"
        )

        // Check if there's a recent roast in storage, otherwise use welcome message
        let recentRoasts = storageService.getRoastHistory()
        if let lastRoast = recentRoasts.first {
            // Use the most recent roast if it was created within the last hour
            let oneHourAgo = Date().addingTimeInterval(-3600)
            if lastRoast.createdAt > oneHourAgo {
                roastSubject.onNext(lastRoast)
                return
            }
        }

        // Use welcome roast if no recent roast found
        roastSubject.onNext(welcomeRoast)
    }

    // MARK: - Public Methods
    func generateRoast(category: RoastCategory, spiceLevel: Int, language: String = "vi") {
        let preferences = storageService.getUserPreferences()

        // Check if API is configured
        if preferences.apiConfiguration.apiKey.isEmpty || preferences.apiConfiguration.baseURL.isEmpty {
            print("❌ API not configured - showing setup")
            showAPISetup = true
            return
        }

        loadingSubject.onNext(true)

        print("🎯 Generate Roast - API Config:")
        print("  apiKey: \(preferences.apiConfiguration.apiKey.isEmpty ? "EMPTY" : "HAS_VALUE")")
        print("  baseURL: \(preferences.apiConfiguration.baseURL)")
        print("  category: \(category.displayName)")
        print("  spiceLevel: \(spiceLevel)")

        let finalSpiceLevel = preferences.safetyFiltersEnabled ?
            min(spiceLevel, 4) : spiceLevel

        aiService.generateRoast(
            category: category,
            spiceLevel: finalSpiceLevel,
            language: language
        )
        .observe(on: MainScheduler.instance)
        .subscribe(
            onNext: { [weak self] roast in
                self?.handleGeneratedRoast(roast, preferences: preferences)
            },
            onError: { [weak self] error in
                self?.handleError(error)
            }
        )
        .disposed(by: disposeBag)
    }
    
    private func handleGeneratedRoast(_ roast: Roast, preferences: UserPreferences) {
        var finalRoast = roast
        
        // Apply safety filters if enabled
        if preferences.safetyFiltersEnabled {
            if !safetyFilter.isContentSafe(roast.content) {
                let safeContent = safetyFilter.filterContent(roast.content)
                finalRoast = Roast(
                    content: safeContent,
                    category: roast.category,
                    spiceLevel: roast.spiceLevel, // Keep original spice level
                    language: roast.language
                )
            }
        }
        
        // Save to storage
        storageService.saveRoast(finalRoast)
        
        // Update UI
        roastSubject.onNext(finalRoast)
        loadingSubject.onNext(false)
    }
    
    private func handleError(_ error: Error) {
        loadingSubject.onNext(false)
        
        let errorMessage: String
        if let aiError = error as? AIServiceError {
            errorMessage = aiError.localizedDescription
        } else {
            errorMessage = "Có lỗi xảy ra khi tạo roast. Vui lòng thử lại!"
        }
        
        errorSubject.onNext(errorMessage)
    }
    
    func toggleFavorite(roast: Roast) {
        print("🔄 RoastGeneratorViewModel.toggleFavorite:")
        print("  roast.id: \(roast.id)")
        print("  roast.isFavorite BEFORE: \(roast.isFavorite)")

        storageService.toggleFavorite(roastId: roast.id)

        // Update current roast if it's the same one
        if let currentRoast = currentRoast, currentRoast.id == roast.id {
            var updatedRoast = currentRoast
            updatedRoast.isFavorite.toggle()
            print("  updatedRoast.isFavorite AFTER: \(updatedRoast.isFavorite)")
            roastSubject.onNext(updatedRoast)
        }
    }
    
    func clearCurrentRoast() {
        roastSubject.onNext(nil)
    }
    
    func retryLastGeneration() {
        guard let lastRoast = currentRoast else { return }
        generateRoast(
            category: lastRoast.category,
            spiceLevel: lastRoast.spiceLevel,
            language: lastRoast.language
        )
    }
    
    func generateRandomRoast() {
        let preferences = storageService.getUserPreferences()
        let randomCategory = preferences.preferredCategories.randomElement() ?? .general

        generateRoast(
            category: randomCategory,
            spiceLevel: spiceLevel, // Use current spice level, not preferences
            language: preferences.preferredLanguage
        )
    }

    func copyRoastToClipboard() {
        guard let roast = currentRoast else { return }
        UIPasteboard.general.string = roast.content

        // You can add haptic feedback here if desired
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    // MARK: - Reactive Methods
    func generateRoastReactive(category: RoastCategory, spiceLevel: Int, language: String = "vi") -> Observable<Roast> {
        let preferences = storageService.getUserPreferences()
        let finalSpiceLevel = preferences.safetyFiltersEnabled ? 
            min(spiceLevel, 4) : spiceLevel
        
        return aiService.generateRoast(
            category: category,
            spiceLevel: finalSpiceLevel,
            language: language
        )
        .map { [weak self] roast -> Roast in
            guard let self = self else { return roast }
            
            var finalRoast = roast
            
            // Apply safety filters if enabled
            if preferences.safetyFiltersEnabled {
                if !self.safetyFilter.isContentSafe(roast.content) {
                    let safeContent = self.safetyFilter.filterContent(roast.content)
                    finalRoast = Roast(
                        content: safeContent,
                        category: roast.category,
                        spiceLevel: min(roast.spiceLevel, 2),
                        language: roast.language
                    )
                }
            }
            
            // Save to storage
            self.storageService.saveRoast(finalRoast)
            
            return finalRoast
        }
        .catch { [weak self] error -> Observable<Roast> in
            self?.handleError(error)
            return Observable.empty()
        }
    }

    // MARK: - Public Methods for Preferences
    func updateSelectedCategory(_ category: RoastCategory) {
        selectedCategory = category
        saveUserPreferences()
    }

    func updateSpiceLevel(_ level: Int) {
        spiceLevel = level
        saveUserPreferences()
    }

    func shareRoast(_ roast: Roast) {
        let shareText = """
        🔥 RoastMe - \(roast.category.displayName)

        \(roast.content)

        Mức độ cay: \(String(repeating: "🔥", count: roast.spiceLevel))

        Tạo roast của bạn với RoastMe!
        """

        let activityViewController = UIActivityViewController(
            activityItems: [shareText],
            applicationActivities: nil
        )

        // Get the root view controller
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootViewController = window.rootViewController {

            // For iPad
            if let popover = activityViewController.popoverPresentationController {
                popover.sourceView = rootViewController.view
                popover.sourceRect = CGRect(x: rootViewController.view.bounds.midX, y: rootViewController.view.bounds.midY, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }

            rootViewController.present(activityViewController, animated: true)
        }
    }
}
