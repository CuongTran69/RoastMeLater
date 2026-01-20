import Foundation
import RxSwift
import RxCocoa
import UIKit
import Combine
import WidgetKit

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
    private var isReloadingFromSettings = false
    
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
         storageService: StorageServiceProtocol = StorageService.shared) {
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
            .sink { [weak self] notification in
                // Only reload if notification came from SettingsViewModel (not from self)
                guard notification.object as? RoastGeneratorViewModel !== self else { return }
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
        isReloadingFromSettings = true

        let preferences = storageService.getUserPreferences()
        selectedCategory = preferences.defaultCategory
        spiceLevel = preferences.defaultSpiceLevel

        #if DEBUG
        print("🔄 RoastGeneratorViewModel loadUserPreferences:")
        print("  selectedCategory: \(selectedCategory.displayName)")
        print("  spiceLevel: \(spiceLevel)")
        #endif

        // Reset flag after a short delay to allow UI to update
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.isReloadingFromSettings = false
        }
    }

    private func handleFavoriteChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let roastId = userInfo["roastId"] as? UUID,
              let isFavorite = userInfo["isFavorite"] as? Bool,
              let _ = userInfo["roast"] as? Roast else { return }

        // Ensure UI updates happen on main thread
        DispatchQueue.main.async { [weak self] in
            guard let self = self,
                  let currentRoast = self.currentRoast,
                  currentRoast.id == roastId else { return }

            #if DEBUG
            print("🔄 RoastGeneratorViewModel.handleFavoriteChange:")
            print("  roastId: \(roastId)")
            print("  isFavorite: \(isFavorite)")
            #endif

            // Update current roast with new favorite status
            var newRoast = currentRoast
            newRoast.isFavorite = isFavorite
            self.roastSubject.onNext(newRoast)
            self.currentRoast = newRoast
        }
    }

    private func saveUserPreferences() {
        var preferences = storageService.getUserPreferences()
        preferences.defaultCategory = selectedCategory
        preferences.defaultSpiceLevel = spiceLevel
        storageService.saveUserPreferences(preferences)

        #if DEBUG
        print("💾 Saved user preferences:")
        print("  selectedCategory: \(selectedCategory.displayName)")
        print("  spiceLevel: \(spiceLevel)")
        #endif
    }

    private func loadInitialRoast() {
        #if DEBUG
        print("📱 loadInitialRoast called")
        #endif

        // Check if API is configured to show appropriate welcome message
        let preferences = storageService.getUserPreferences()
        let isAPIConfigured = !preferences.apiConfiguration.apiKey.isEmpty && !preferences.apiConfiguration.baseURL.isEmpty

        #if DEBUG
        print("🔍 Initial Load - API Config Check:")
        print("  apiKey: \(preferences.apiConfiguration.apiKey.isEmpty ? "EMPTY" : "SET")")
        print("  baseURL: \(preferences.apiConfiguration.baseURL.isEmpty ? "EMPTY" : "SET")")
        print("  isAPIConfigured: \(isAPIConfigured)")
        #endif

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
                #if DEBUG
                print("✅ Using recent roast from storage")
                #endif
                roastSubject.onNext(lastRoast)
                return
            }
        }

        // Use welcome roast if no recent roast found
        #if DEBUG
        print("✅ Using welcome roast")
        #endif
        roastSubject.onNext(welcomeRoast)
    }

    // MARK: - Public Methods
    func generateRoast(category: RoastCategory, spiceLevel: Int, language: String? = nil) {
        #if DEBUG
        print("🚀 generateRoast called")
        #endif

        // Validate category
        guard ValidationService.isValidCategory(category) else {
            #if DEBUG
            print("❌ Invalid category: \(category)")
            #endif
            errorSubject.onNext("Invalid category selected")
            return
        }

        // Validate and clamp spice level
        let validatedSpiceLevel = ValidationService.validateSpiceLevel(spiceLevel)
        #if DEBUG
        if spiceLevel != validatedSpiceLevel {
            print("⚠️ Spice level \(spiceLevel) was clamped to \(validatedSpiceLevel)")
        }
        #endif

        let preferences = storageService.getUserPreferences()

        #if DEBUG
        print("🔍 Checking API Configuration:")
        print("  apiKey: \(preferences.apiConfiguration.apiKey.isEmpty ? "EMPTY" : "SET")")
        print("  baseURL: \(preferences.apiConfiguration.baseURL.isEmpty ? "EMPTY" : "SET")")
        print("  modelName: \(preferences.apiConfiguration.modelName.isEmpty ? "EMPTY" : preferences.apiConfiguration.modelName)")
        #endif

        // Check if API is configured
        if preferences.apiConfiguration.apiKey.isEmpty || preferences.apiConfiguration.baseURL.isEmpty {
            #if DEBUG
            print("❌ API not configured - showing setup")
            print("  apiKey isEmpty: \(preferences.apiConfiguration.apiKey.isEmpty)")
            print("  baseURL isEmpty: \(preferences.apiConfiguration.baseURL.isEmpty)")
            #endif
            showAPISetup = true
            return
        }

        #if DEBUG
        print("✅ API is configured, proceeding with generation")
        #endif
        loadingSubject.onNext(true)

        #if DEBUG
        print("🎯 Generate Roast - API Config:")
        print("  apiKey: \(preferences.apiConfiguration.apiKey.isEmpty ? "EMPTY" : "SET")")
        print("  baseURL: \(preferences.apiConfiguration.baseURL.isEmpty ? "EMPTY" : "SET")")
        print("  modelName: \(preferences.apiConfiguration.modelName)")
        print("  category: \(category.displayName)")
        print("  spiceLevel: \(validatedSpiceLevel)")
        print("  language: Auto-detect from LocalizationManager")
        #endif

        let finalSpiceLevel = preferences.safetyFiltersEnabled ?
            min(validatedSpiceLevel, 5) : validatedSpiceLevel  // Allow up to level 5 even with safety filter

        aiService.generateRoast(
            category: category,
            spiceLevel: finalSpiceLevel,
            language: nil  // Use LocalizationManager.shared.currentLanguage
        )
        .timeout(.seconds(30), scheduler: MainScheduler.instance)
        .observe(on: MainScheduler.instance)
        .subscribe(
            onNext: { [weak self] roast in
                self?.handleGeneratedRoast(roast, preferences: preferences)
            },
            onError: { [weak self] error in
                // Handle RxSwift timeout error
                if case RxError.timeout = error {
                    self?.handleError(AIServiceError.networkTimeout)
                } else {
                    self?.handleError(error)
                }
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
                // Keep the original spice level when filtering, don't reduce it
                finalRoast = Roast(
                    content: safeContent,
                    category: roast.category,
                    spiceLevel: roast.spiceLevel,
                    language: roast.language
                )
            }
        }

        // Save to storage
        storageService.saveRoast(finalRoast)

        // Refresh widget to show new roast
        WidgetCenter.shared.reloadAllTimelines()

        // Update UI
        roastSubject.onNext(finalRoast)
        loadingSubject.onNext(false)
    }
    
    private func handleError(_ error: Error) {
        loadingSubject.onNext(false)

        let errorMessage = ErrorHandler.shared.handle(error)
        ErrorHandler.shared.logError(error, context: "RoastGeneratorViewModel.generateRoast")

        errorSubject.onNext(errorMessage)
    }
    
    func toggleFavorite(roast: Roast) {
        #if DEBUG
        print("🔄 RoastGeneratorViewModel.toggleFavorite:")
        print("  roast.id: \(roast.id)")
        print("  roast.isFavorite BEFORE: \(roast.isFavorite)")
        #endif

        storageService.toggleFavorite(roastId: roast.id)

        // Update current roast if it's the same one
        if let currentRoast = currentRoast, currentRoast.id == roast.id {
            var updatedRoast = currentRoast
            updatedRoast.isFavorite.toggle()
            #if DEBUG
            print("  updatedRoast.isFavorite AFTER: \(updatedRoast.isFavorite)")
            #endif
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
    func generateRoastReactive(category: RoastCategory, spiceLevel: Int, language: String? = nil) -> Observable<Roast> {
        // Validate and clamp spice level
        let validatedSpiceLevel = ValidationService.validateSpiceLevel(spiceLevel)

        let preferences = storageService.getUserPreferences()
        let finalSpiceLevel = preferences.safetyFiltersEnabled ?
            min(validatedSpiceLevel, 5) : validatedSpiceLevel  // Allow up to level 5 even with safety filter

        return aiService.generateRoast(
            category: category,
            spiceLevel: finalSpiceLevel,
            language: nil  // Use LocalizationManager.shared.currentLanguage
        )
        .map { [weak self] roast -> Roast in
            guard let self = self else { return roast }

            var finalRoast = roast

            // Apply safety filters if enabled
            if preferences.safetyFiltersEnabled {
                if !self.safetyFilter.isContentSafe(roast.content) {
                    let safeContent = self.safetyFilter.filterContent(roast.content)
                    // Keep the original spice level consistent with handleGeneratedRoast
                    finalRoast = Roast(
                        content: safeContent,
                        category: roast.category,
                        spiceLevel: roast.spiceLevel,
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
        // Skip if this is triggered by loadUserPreferences to prevent loop
        guard !isReloadingFromSettings else { return }

        // Validate category
        guard ValidationService.isValidCategory(category) else {
            #if DEBUG
            print("⚠️ Invalid category attempted: \(category)")
            #endif
            return
        }

        // Skip if value hasn't changed
        guard selectedCategory != category else { return }

        selectedCategory = category
        saveUserPreferences()
        // Notify SettingsView to sync category (pass self to identify source)
        NotificationCenter.default.post(name: .settingsDidChange, object: self)
    }

    func updateSpiceLevel(_ level: Int) {
        // Skip if this is triggered by loadUserPreferences to prevent loop
        guard !isReloadingFromSettings else { return }

        // Validate and clamp spice level to valid range
        let validatedLevel = ValidationService.validateSpiceLevel(level)

        #if DEBUG
        if level != validatedLevel {
            print("⚠️ Spice level \(level) was clamped to \(validatedLevel)")
        }
        #endif

        // Skip if value hasn't changed
        guard spiceLevel != validatedLevel else { return }

        spiceLevel = validatedLevel
        saveUserPreferences()
        // Notify SettingsView to sync spice level (pass self to identify source)
        NotificationCenter.default.post(name: .settingsDidChange, object: self)
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
