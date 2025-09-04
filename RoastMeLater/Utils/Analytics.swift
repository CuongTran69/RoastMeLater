import Foundation

class Analytics {
    static let shared = Analytics()
    
    private init() {}
    
    func track(event: String, parameters: [String: Any] = [:]) {
        guard Constants.FeatureFlags.debugModeEnabled else { return }
        
        var eventData = parameters
        eventData["timestamp"] = Date().timeIntervalSince1970
        eventData["app_version"] = Constants.App.version
        
        print("📊 Analytics Event: \(event)")
        print("📊 Parameters: \(eventData)")
        
        // In a production app, you would send this to your analytics service
        // like Firebase Analytics, Mixpanel, or Amplitude
    }
    
    // MARK: - App Events
    func trackAppLaunched() {
        track(event: Constants.Analytics.appLaunched)
    }
    
    func trackAppBackgrounded(duration: TimeInterval) {
        track(event: "app_backgrounded", parameters: ["duration": duration])
    }
    
    // MARK: - Roast Events
    func trackRoastGenerated(category: RoastCategory, spiceLevel: Int, language: String) {
        track(event: Constants.Analytics.roastGenerated, parameters: [
            "category": category.rawValue,
            "spice_level": spiceLevel,
            "language": language
        ])
    }
    
    func trackRoastFavorited(roast: Roast, isFavorited: Bool) {
        track(event: Constants.Analytics.roastFavorited, parameters: [
            "roast_id": roast.id.uuidString,
            "category": roast.category.rawValue,
            "spice_level": roast.spiceLevel,
            "is_favorited": isFavorited
        ])
    }
    
    func trackRoastShared(roast: Roast, shareMethod: String) {
        track(event: Constants.Analytics.roastShared, parameters: [
            "roast_id": roast.id.uuidString,
            "category": roast.category.rawValue,
            "spice_level": roast.spiceLevel,
            "share_method": shareMethod
        ])
    }
    
    func trackRoastDeleted(roast: Roast) {
        track(event: "roast_deleted", parameters: [
            "roast_id": roast.id.uuidString,
            "category": roast.category.rawValue,
            "spice_level": roast.spiceLevel,
            "was_favorite": roast.isFavorite
        ])
    }
    
    // MARK: - Category Events
    func trackCategorySelected(category: RoastCategory) {
        track(event: Constants.Analytics.categorySelected, parameters: [
            "category": category.rawValue
        ])
    }
    
    // MARK: - Settings Events
    func trackSpiceLevelChanged(from oldLevel: Int, to newLevel: Int) {
        track(event: Constants.Analytics.spiceLevelChanged, parameters: [
            "old_level": oldLevel,
            "new_level": newLevel
        ])
    }
    
    func trackNotificationSettingsChanged(enabled: Bool, frequency: NotificationFrequency) {
        track(event: Constants.Analytics.settingsChanged, parameters: [
            "setting_type": "notifications",
            "enabled": enabled,
            "frequency": frequency.rawValue
        ])
    }
    
    func trackSafetyFiltersChanged(enabled: Bool) {
        track(event: Constants.Analytics.settingsChanged, parameters: [
            "setting_type": "safety_filters",
            "enabled": enabled
        ])
    }
    
    func trackLanguageChanged(to language: String) {
        track(event: Constants.Analytics.settingsChanged, parameters: [
            "setting_type": "language",
            "language": language
        ])
    }
    
    // MARK: - Notification Events
    func trackNotificationScheduled(count: Int, frequency: NotificationFrequency) {
        track(event: Constants.Analytics.notificationScheduled, parameters: [
            "count": count,
            "frequency": frequency.rawValue
        ])
    }
    
    func trackNotificationReceived(identifier: String) {
        track(event: "notification_received", parameters: [
            "identifier": identifier
        ])
    }
    
    func trackNotificationTapped(identifier: String) {
        track(event: "notification_tapped", parameters: [
            "identifier": identifier
        ])
    }
    
    // MARK: - Error Events
    func trackError(error: Error, context: String) {
        track(event: "error_occurred", parameters: [
            "error_type": String(describing: type(of: error)),
            "error_description": error.localizedDescription,
            "context": context
        ])
    }
    
    func trackAIServiceError(error: AIServiceError, category: RoastCategory, spiceLevel: Int) {
        track(event: "ai_service_error", parameters: [
            "error_type": error.localizedDescription,
            "category": category.rawValue,
            "spice_level": spiceLevel
        ])
    }
    
    // MARK: - User Journey Events
    func trackUserJourney(step: String, metadata: [String: Any] = [:]) {
        var parameters = metadata
        parameters["journey_step"] = step
        
        track(event: "user_journey", parameters: parameters)
    }
    
    func trackFeatureUsage(feature: String, duration: TimeInterval? = nil) {
        var parameters: [String: Any] = ["feature": feature]
        
        if let duration = duration {
            parameters["duration"] = duration
        }
        
        track(event: "feature_usage", parameters: parameters)
    }
    
    // MARK: - Performance Events
    func trackPerformance(operation: String, duration: TimeInterval, success: Bool) {
        track(event: "performance", parameters: [
            "operation": operation,
            "duration": duration,
            "success": success
        ])
    }
    
    func trackRoastGenerationTime(duration: TimeInterval, category: RoastCategory, success: Bool) {
        track(event: "roast_generation_performance", parameters: [
            "duration": duration,
            "category": category.rawValue,
            "success": success
        ])
    }
}

// MARK: - Analytics Extensions
extension Analytics {
    func startTimer(for operation: String) -> AnalyticsTimer {
        return AnalyticsTimer(operation: operation, analytics: self)
    }
}

class AnalyticsTimer {
    private let operation: String
    private let startTime: Date
    private let analytics: Analytics
    
    init(operation: String, analytics: Analytics) {
        self.operation = operation
        self.startTime = Date()
        self.analytics = analytics
    }
    
    func stop(success: Bool = true, metadata: [String: Any] = [:]) {
        let duration = Date().timeIntervalSince(startTime)
        var parameters = metadata
        parameters["success"] = success
        
        analytics.trackPerformance(operation: operation, duration: duration, success: success)
    }
}
