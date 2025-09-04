import Foundation
import RxSwift
import RxCocoa
import UIKit

class RoastGeneratorViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var currentRoast: Roast?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false
    @Published var showAPISetup = false
    
    // MARK: - Private Properties
    private let aiService: AIServiceProtocol
    private let storageService: StorageServiceProtocol
    private let safetyFilter = SafetyFilter()
    private let disposeBag = DisposeBag()
    
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
        print("  useCustomAPI: \(preferences.apiConfiguration.useCustomAPI)")
        print("  apiKey: \(preferences.apiConfiguration.apiKey.isEmpty ? "EMPTY" : "HAS_VALUE")")
        print("  baseURL: \(preferences.apiConfiguration.baseURL)")

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
                    spiceLevel: min(roast.spiceLevel, 2),
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
        storageService.toggleFavorite(roastId: roast.id)
        
        // Update current roast if it's the same one
        if let currentRoast = currentRoast, currentRoast.id == roast.id {
            var updatedRoast = currentRoast
            updatedRoast.isFavorite.toggle()
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
            spiceLevel: preferences.spiceLevel,
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
}
