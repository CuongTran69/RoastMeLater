import SwiftUI
import UIKit

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @EnvironmentObject var notificationManager: NotificationManager
    @EnvironmentObject var localizationManager: LocalizationManager
    @ObservedObject private var appLifecycleManager = AppLifecycleManager.shared
    @State private var showingAbout = false
    @State private var showingNotificationTest = false
    @State private var showingStreakFreezeAlert = false
    @State private var showingClearHistoryAlert = false
    @State private var showingClearFavoritesAlert = false
    @State private var showingResetSettingsAlert = false

    // MARK: - UserDefaults Keys for Collapse States
    private enum CollapseStateKeys {
        static let notifications = "settings.section.notifications.expanded"
        static let content = "settings.section.content.expanded"
        static let apiConfig = "settings.section.apiConfig.expanded" // -1 = nil/auto, 0 = false, 1 = true
        static let data = "settings.section.data.expanded"
        static let appInfo = "settings.section.appInfo.expanded"
        static let streak = "settings.section.streak.expanded"
        static let statistics = "settings.section.statistics.expanded"
    }

    // MARK: - Collapsible Section States (with UserDefaults persistence)
    @State private var isNotificationsExpanded: Bool = UserDefaults.standard.object(forKey: CollapseStateKeys.notifications) as? Bool ?? true
    @State private var isContentExpanded: Bool = UserDefaults.standard.object(forKey: CollapseStateKeys.content) as? Bool ?? true
    @State private var isAPIConfigExpanded: Bool? = {
        let value = UserDefaults.standard.integer(forKey: CollapseStateKeys.apiConfig)
        if UserDefaults.standard.object(forKey: CollapseStateKeys.apiConfig) == nil { return nil }
        switch value {
        case -1: return nil
        case 0: return false
        case 1: return true
        default: return nil
        }
    }()
    @State private var isDataExpanded: Bool = UserDefaults.standard.object(forKey: CollapseStateKeys.data) as? Bool ?? false
    @State private var isAppInfoExpanded: Bool = UserDefaults.standard.object(forKey: CollapseStateKeys.appInfo) as? Bool ?? false
    @State private var isStreakExpanded: Bool = UserDefaults.standard.object(forKey: CollapseStateKeys.streak) as? Bool ?? false
    @State private var isStatisticsExpanded: Bool = UserDefaults.standard.object(forKey: CollapseStateKeys.statistics) as? Bool ?? false

    // MARK: - Save Collapse State Functions
    private func saveCollapseState(_ key: String, value: Bool) {
        UserDefaults.standard.set(value, forKey: key)
    }

    private func saveAPIConfigCollapseState(_ value: Bool?) {
        let intValue: Int
        switch value {
        case nil: intValue = -1
        case false: intValue = 0
        case true: intValue = 1
        default: intValue = -1
        }
        UserDefaults.standard.set(intValue, forKey: CollapseStateKeys.apiConfig)
    }

    // Computed property to determine if API is configured
    private var isAPIConfigured: Bool {
        !viewModel.apiKey.isEmpty && !viewModel.baseURL.isEmpty
    }

    // Computed property to determine if section should be expanded
    private var shouldExpandAPIConfig: Bool {
        if let manualState = isAPIConfigExpanded {
            return manualState
        }
        // Auto: expand if not configured
        return !isAPIConfigured
    }

    // MARK: - Spice Level Color
    private func spiceLevelColor(_ level: Int) -> Color {
        switch level {
        case 1: return .green
        case 2: return .yellow
        case 3: return .orange
        case 4: return Color(red: 1.0, green: 0.4, blue: 0.2)
        case 5: return .red
        default: return .orange
        }
    }

    private func spiceLevelEmoji(_ level: Int) -> String {
        switch level {
        case 1: return "😊"
        case 2: return "🙂"
        case 3: return "😏"
        case 4: return "🔥"
        case 5: return "💀"
        default: return "😏"
        }
    }

    var body: some View {
        NavigationView {
            List {
                // MARK: - Notification Settings (Collapsible)
                Section {
                    // Collapsible Header
                    Button(action: {
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            isNotificationsExpanded.toggle()
                            saveCollapseState(CollapseStateKeys.notifications, value: isNotificationsExpanded)
                        }
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "bell.badge.fill")
                                .font(.title3)
                                .foregroundColor(.orange)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(localizationManager.notifications)
                                    .font(.body.weight(.semibold))
                                    .foregroundColor(.primary)
                                Text(viewModel.notificationsEnabled
                                    ? (localizationManager.currentLanguage == "en" ? "Enabled" : "Đã bật")
                                    : (localizationManager.currentLanguage == "en" ? "Disabled" : "Đã tắt"))
                                    .font(.caption)
                                    .foregroundColor(viewModel.notificationsEnabled ? .green : .secondary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(.secondary)
                                .rotationEffect(.degrees(isNotificationsExpanded ? 90 : 0))
                        }
                        .padding(.vertical, 2)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .accessibilityLabel("\(localizationManager.notifications), \(viewModel.notificationsEnabled ? (localizationManager.currentLanguage == "en" ? "Enabled" : "Đã bật") : (localizationManager.currentLanguage == "en" ? "Disabled" : "Đã tắt"))")
                    .accessibilityHint(isNotificationsExpanded
                        ? (localizationManager.currentLanguage == "en" ? "Double tap to collapse" : "Nhấn đúp để thu gọn")
                        : (localizationManager.currentLanguage == "en" ? "Double tap to expand" : "Nhấn đúp để mở rộng"))
                    .accessibilityAddTraits(.isButton)

                    // Expandable Content
                    if isNotificationsExpanded {
                        // Enable Notifications Toggle
                        HStack(spacing: 14) {
                            SettingsIconView(icon: "bell.fill", color: .orange)
                            Toggle(Strings.Settings.Notifications.enableNotifications.localized(localizationManager.currentLanguage), isOn: $viewModel.notificationsEnabled)
                                .onChange(of: viewModel.notificationsEnabled) { enabled in
                                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                    impactFeedback.impactOccurred()
                                    viewModel.updateNotificationsEnabled(enabled)
                                    if enabled {
                                        notificationManager.requestNotificationPermission()
                                    } else {
                                        notificationManager.cancelAllNotifications()
                                    }
                                }
                        }
                        .accessibilityElement(children: .combine)

                        if viewModel.notificationsEnabled {
                            // Frequency Picker
                            HStack(spacing: 14) {
                                SettingsIconView(icon: "clock.fill", color: .blue)
                                Picker(Strings.Settings.Notifications.frequency.localized(localizationManager.currentLanguage), selection: $viewModel.notificationFrequency) {
                                    ForEach(NotificationFrequency.allCases, id: \.self) { frequency in
                                        Text(frequency.displayName).tag(frequency)
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                                .onChange(of: viewModel.notificationFrequency) { newValue in
                                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                    impactFeedback.impactOccurred()
                                    viewModel.updateNotificationFrequency(newValue)
                                    notificationManager.scheduleHourlyNotifications()
                                }
                            }
                            .accessibilityElement(children: .combine)

                            // Test Notification Button
                            Button(action: {
                                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                                impactFeedback.impactOccurred()
                                notificationManager.scheduleTestNotification()
                                showingNotificationTest = true
                            }) {
                                HStack(spacing: 14) {
                                    SettingsIconView(icon: "paperplane.fill", color: .green)
                                    Text(Strings.Settings.Notifications.testNotification.localized(localizationManager.currentLanguage))
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .accessibilityLabel(Strings.Settings.Notifications.testNotification.localized(localizationManager.currentLanguage))
                            .accessibilityHint(localizationManager.currentLanguage == "en" ? "Double tap to send a test notification" : "Nhấn đúp để gửi thông báo thử nghiệm")
                        }
                    }
                }
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isNotificationsExpanded)

                // MARK: - Content Settings (Collapsible)
                Section {
                    // Collapsible Header
                    Button(action: {
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            isContentExpanded.toggle()
                            saveCollapseState(CollapseStateKeys.content, value: isContentExpanded)
                        }
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "paintbrush.fill")
                                .font(.title3)
                                .foregroundColor(.purple)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(localizationManager.content)
                                    .font(.body.weight(.semibold))
                                    .foregroundColor(.primary)
                                Text("\(spiceLevelEmoji(viewModel.defaultSpiceLevel)) \(localizationManager.currentLanguage == "en" ? "Spice Level" : "Độ cay"): \(viewModel.defaultSpiceLevel)/5")
                                    .font(.caption)
                                    .foregroundColor(spiceLevelColor(viewModel.defaultSpiceLevel))
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(.secondary)
                                .rotationEffect(.degrees(isContentExpanded ? 90 : 0))
                        }
                        .padding(.vertical, 2)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .accessibilityLabel("\(localizationManager.content), \(localizationManager.currentLanguage == "en" ? "Spice Level" : "Độ cay") \(viewModel.defaultSpiceLevel) \(localizationManager.currentLanguage == "en" ? "of" : "trên") 5")
                    .accessibilityHint(isContentExpanded
                        ? (localizationManager.currentLanguage == "en" ? "Double tap to collapse" : "Nhấn đúp để thu gọn")
                        : (localizationManager.currentLanguage == "en" ? "Double tap to expand" : "Nhấn đúp để mở rộng"))
                    .accessibilityAddTraits(.isButton)

                    // Expandable Content
                    if isContentExpanded {
                        // Spice Level Selector
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 14) {
                                SettingsIconView(icon: "flame.fill", color: spiceLevelColor(viewModel.defaultSpiceLevel))
                                Text(Strings.Settings.Content.defaultSpiceLevel.localized(localizationManager.currentLanguage))
                                Spacer()
                                Text("\(spiceLevelEmoji(viewModel.defaultSpiceLevel)) \(viewModel.defaultSpiceLevel)/5")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(spiceLevelColor(viewModel.defaultSpiceLevel))
                            }

                            HStack(spacing: 10) {
                                ForEach(1...5, id: \.self) { level in
                                    Button(action: {
                                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                        impactFeedback.impactOccurred()
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                            viewModel.updateDefaultSpiceLevel(level)
                                        }
                                    }) {
                                        Image(systemName: level <= viewModel.defaultSpiceLevel ? "flame.fill" : "flame")
                                            .font(.title2)
                                            .foregroundColor(level <= viewModel.defaultSpiceLevel ? spiceLevelColor(level) : .gray.opacity(0.4))
                                            .scaleEffect(level <= viewModel.defaultSpiceLevel ? 1.1 : 1.0)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .accessibilityLabel(localizationManager.currentLanguage == "en" ? "Spice level \(level)" : "Độ cay \(level)")
                                    .accessibilityHint(level == viewModel.defaultSpiceLevel
                                        ? (localizationManager.currentLanguage == "en" ? "Currently selected" : "Đang được chọn")
                                        : (localizationManager.currentLanguage == "en" ? "Double tap to select" : "Nhấn đúp để chọn"))
                                    .accessibilityAddTraits(level == viewModel.defaultSpiceLevel ? .isSelected : [])
                                }
                                Spacer()
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                        .padding(.vertical, 4)
                        .accessibilityElement(children: .contain)
                        .accessibilityLabel(Strings.Settings.Content.defaultSpiceLevel.localized(localizationManager.currentLanguage))

                        // Default Category Picker
                        HStack(spacing: 14) {
                            SettingsIconView(icon: "folder.fill", color: .orange)
                            Picker(localizationManager.currentLanguage == "en" ? "Category" : "Danh mục", selection: Binding(
                                get: { viewModel.defaultCategory },
                                set: { newValue in
                                    // Only update if value actually changed by user interaction
                                    if viewModel.defaultCategory != newValue {
                                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                        impactFeedback.impactOccurred()
                                        viewModel.updateDefaultCategory(newValue)
                                    }
                                }
                            )) {
                                ForEach(RoastCategory.allCases, id: \.self) { category in
                                    HStack {
                                        Image(systemName: category.icon)
                                        Text(localizationManager.categoryName(category))
                                    }.tag(category)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                        }
                        .accessibilityElement(children: .combine)

                        // Safety Filters Toggle
                        HStack(spacing: 14) {
                            SettingsIconView(icon: "shield.fill", color: .green)
                            Toggle(Strings.Settings.Content.safetyFilters.localized(localizationManager.currentLanguage), isOn: $viewModel.safetyFiltersEnabled)
                                .onChange(of: viewModel.safetyFiltersEnabled) { enabled in
                                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                    impactFeedback.impactOccurred()
                                    viewModel.updateSafetyFilters(enabled)
                                }
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isContentExpanded)

                // MARK: - Language Settings
                Section {
                    HStack(spacing: 14) {
                        SettingsIconView(icon: "globe", color: .blue)
                        Picker(localizationManager.language, selection: $viewModel.preferredLanguage) {
                            ForEach(localizationManager.languageOptions, id: \.code) { option in
                                Text(option.name).tag(option.code)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .onChange(of: viewModel.preferredLanguage) { newValue in
                            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                            impactFeedback.impactOccurred()
                            viewModel.updatePreferredLanguage(newValue)
                            localizationManager.setLanguage(newValue)
                        }
                    }
                }

                // MARK: - API Configuration (Collapsible)
                Section {
                    // Collapsible Header
                    Button(action: {
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            isAPIConfigExpanded = !shouldExpandAPIConfig
                            saveAPIConfigCollapseState(isAPIConfigExpanded)
                        }
                    }) {
                        HStack(spacing: 12) {
                            // Status indicator
                            Image(systemName: isAPIConfigured ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                                .font(.title3)
                                .foregroundColor(isAPIConfigured ? .green : .orange)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(Strings.Settings.APIConfig.sectionTitle.localized(localizationManager.currentLanguage))
                                    .font(.body.weight(.semibold))
                                    .foregroundColor(.primary)
                                Text(isAPIConfigured
                                    ? (localizationManager.currentLanguage == "en" ? "Configured ✓" : "Đã cấu hình ✓")
                                    : (localizationManager.currentLanguage == "en" ? "Not configured" : "Chưa cấu hình"))
                                    .font(.caption)
                                    .foregroundColor(isAPIConfigured ? .green : .orange)
                            }

                            Spacer()

                            // Chevron
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(.secondary)
                                .rotationEffect(.degrees(shouldExpandAPIConfig ? 90 : 0))
                        }
                        .padding(.vertical, 2)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .accessibilityLabel("\(Strings.Settings.APIConfig.sectionTitle.localized(localizationManager.currentLanguage)), \(isAPIConfigured ? (localizationManager.currentLanguage == "en" ? "Configured" : "Đã cấu hình") : (localizationManager.currentLanguage == "en" ? "Not configured" : "Chưa cấu hình"))")
                    .accessibilityHint(shouldExpandAPIConfig
                        ? (localizationManager.currentLanguage == "en" ? "Double tap to collapse" : "Nhấn đúp để thu gọn")
                        : (localizationManager.currentLanguage == "en" ? "Double tap to expand" : "Nhấn đúp để mở rộng"))
                    .accessibilityAddTraits(.isButton)

                    // Expandable Content
                    if shouldExpandAPIConfig {
                        VStack(alignment: .leading, spacing: 16) {
                            // Info text
                            HStack(spacing: 10) {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(.blue)
                                Text(Strings.Settings.APIConfig.description.localized(localizationManager.currentLanguage))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(12)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(10)
                            .accessibilityElement(children: .combine)

                            // API Key Field
                            VStack(alignment: .leading, spacing: 6) {
                                HStack(spacing: 8) {
                                    Image(systemName: "key.fill")
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                    Text(Strings.Settings.APIConfig.apiKey.localized(localizationManager.currentLanguage))
                                        .font(.subheadline.weight(.medium))
                                    Text("*")
                                        .foregroundColor(.red)
                                        .accessibilityLabel(localizationManager.currentLanguage == "en" ? "Required" : "Bắt buộc")
                                }
                                SecureField("sk-xxxxxxxxxxxxxxxx", text: $viewModel.apiKey)
                                    .padding(12)
                                    .background(viewModel.apiKeyError != nil ? Color.red.opacity(0.1) : Color(.systemGray6))
                                    .cornerRadius(10)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(viewModel.apiKeyError != nil ? Color.red : Color.clear, lineWidth: 1)
                                    )
                                    .onChange(of: viewModel.apiKey) { _ in
                                        viewModel.apiTestResult = nil
                                        viewModel.validateAPIKey()
                                    }
                                    .accessibilityLabel(Strings.Settings.APIConfig.apiKey.localized(localizationManager.currentLanguage))
                                    .accessibilityHint(localizationManager.currentLanguage == "en" ? "Enter your API key" : "Nhập API key của bạn")

                                if let error = viewModel.apiKeyError {
                                    HStack(spacing: 4) {
                                        Image(systemName: "exclamationmark.circle.fill")
                                            .font(.caption)
                                        Text(error)
                                            .font(.caption)
                                    }
                                    .foregroundColor(.red)
                                    .transition(.opacity.combined(with: .move(edge: .top)))
                                }
                            }

                            // Base URL Field
                            VStack(alignment: .leading, spacing: 6) {
                                HStack(spacing: 8) {
                                    Image(systemName: "link")
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                    Text(Strings.Settings.APIConfig.baseURL.localized(localizationManager.currentLanguage))
                                        .font(.subheadline.weight(.medium))
                                    Text("*")
                                        .foregroundColor(.red)
                                        .accessibilityLabel(localizationManager.currentLanguage == "en" ? "Required" : "Bắt buộc")
                                }
                                TextField("https://api.example.com/v1/chat/completions", text: $viewModel.baseURL)
                                    .padding(12)
                                    .background(viewModel.baseURLError != nil ? Color.red.opacity(0.1) : Color(.systemGray6))
                                    .cornerRadius(10)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(viewModel.baseURLError != nil ? Color.red : Color.clear, lineWidth: 1)
                                    )
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)
                                    .onChange(of: viewModel.baseURL) { _ in
                                        viewModel.apiTestResult = nil
                                        viewModel.validateBaseURL()
                                    }
                                    .accessibilityLabel(Strings.Settings.APIConfig.baseURL.localized(localizationManager.currentLanguage))
                                    .accessibilityHint(localizationManager.currentLanguage == "en" ? "Enter the API base URL" : "Nhập URL cơ sở của API")

                                if let error = viewModel.baseURLError {
                                    HStack(spacing: 4) {
                                        Image(systemName: "exclamationmark.circle.fill")
                                            .font(.caption)
                                        Text(error)
                                            .font(.caption)
                                    }
                                    .foregroundColor(.red)
                                    .transition(.opacity.combined(with: .move(edge: .top)))
                                }
                            }

                            // Model Name Field (Editable)
                            VStack(alignment: .leading, spacing: 6) {
                                HStack(spacing: 8) {
                                    Image(systemName: "cpu")
                                        .font(.caption)
                                        .foregroundColor(.purple)
                                    Text(Strings.Settings.APIConfig.model.localized(localizationManager.currentLanguage))
                                        .font(.subheadline.weight(.medium))
                                }
                                TextField("gemini:gemini-2.5-pro", text: $viewModel.modelName)
                                    .padding(12)
                                    .background(viewModel.modelNameError != nil ? Color.red.opacity(0.1) : Color(.systemGray6))
                                    .cornerRadius(10)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(viewModel.modelNameError != nil ? Color.red : Color.clear, lineWidth: 1)
                                    )
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)
                                    .onChange(of: viewModel.modelName) { _ in
                                        viewModel.apiTestResult = nil
                                        viewModel.validateModelName()
                                    }
                                    .accessibilityLabel(Strings.Settings.APIConfig.model.localized(localizationManager.currentLanguage))
                                    .accessibilityHint(localizationManager.currentLanguage == "en" ? "Enter the model name" : "Nhập tên model")

                                if let error = viewModel.modelNameError {
                                    HStack(spacing: 4) {
                                        Image(systemName: "exclamationmark.circle.fill")
                                            .font(.caption)
                                        Text(error)
                                            .font(.caption)
                                    }
                                    .foregroundColor(.red)
                                    .transition(.opacity.combined(with: .move(edge: .top)))
                                } else {
                                    Text(localizationManager.currentLanguage == "en"
                                        ? "Model name for AI service (e.g., gpt-4, gemini:gemini-2.5-pro)"
                                        : "Tên model của dịch vụ AI (vd: gpt-4, gemini:gemini-2.5-pro)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }

                            // Test Connection Button
                            Button(action: {
                                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                                impactFeedback.impactOccurred()
                                viewModel.testAPIConnection()
                            }) {
                                HStack(spacing: 10) {
                                    if viewModel.isTestingConnection {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .scaleEffect(0.8)
                                    } else {
                                        Image(systemName: "antenna.radiowaves.left.and.right")
                                    }
                                    Text(viewModel.isTestingConnection
                                        ? (localizationManager.currentLanguage == "en" ? "Testing..." : "Đang kiểm tra...")
                                        : Strings.Settings.APIConfig.testConnection.localized(localizationManager.currentLanguage))
                                        .font(.body.weight(.semibold))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    LinearGradient(
                                        colors: !viewModel.isAPIFormValid || viewModel.isTestingConnection
                                            ? [Color.gray.opacity(0.3), Color.gray.opacity(0.2)]
                                            : [.orange, .red],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .foregroundColor(.white)
                                .cornerRadius(12)
                                .shadow(color: !viewModel.isAPIFormValid || viewModel.isTestingConnection ? .clear : .orange.opacity(0.3), radius: 8, x: 0, y: 4)
                            }
                            .buttonStyle(BorderlessButtonStyle())
                            .disabled(!viewModel.isAPIFormValid || viewModel.isTestingConnection)
                            .accessibilityLabel(viewModel.isTestingConnection
                                ? (localizationManager.currentLanguage == "en" ? "Testing connection" : "Đang kiểm tra kết nối")
                                : Strings.Settings.APIConfig.testConnection.localized(localizationManager.currentLanguage))
                            .accessibilityHint(!viewModel.isAPIFormValid
                                ? (localizationManager.currentLanguage == "en" ? "Fill in API key and base URL first" : "Điền API key và URL cơ sở trước")
                                : (localizationManager.currentLanguage == "en" ? "Double tap to test the API connection" : "Nhấn đúp để kiểm tra kết nối API"))

                            // Test Result
                            if let testResult = viewModel.apiTestResult {
                                HStack(spacing: 10) {
                                    Image(systemName: testResult ? "checkmark.circle.fill" : "xmark.circle.fill")
                                        .font(.title3)
                                    Text(testResult
                                        ? (localizationManager.currentLanguage == "en" ? "Connection successful! Config saved." : "Kết nối thành công! Đã lưu cấu hình.")
                                        : Strings.Settings.APIConfig.connectionFailed.localized(localizationManager.currentLanguage))
                                        .font(.subheadline.weight(.medium))
                                    Spacer()
                                }
                                .foregroundColor(testResult ? .green : .red)
                                .padding(12)
                                .background((testResult ? Color.green : Color.red).opacity(0.1))
                                .cornerRadius(10)
                                .transition(.scale.combined(with: .opacity))
                                .accessibilityElement(children: .combine)
                            }
                        }
                        .padding(.top, 8)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: shouldExpandAPIConfig)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: viewModel.apiTestResult)
                .animation(.easeInOut(duration: 0.2), value: viewModel.apiKeyError)
                .animation(.easeInOut(duration: 0.2), value: viewModel.baseURLError)
                .animation(.easeInOut(duration: 0.2), value: viewModel.modelNameError)

                // MARK: - Data Management (Collapsible)
                Section {
                    // Collapsible Header
                    Button(action: {
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            isDataExpanded.toggle()
                            saveCollapseState(CollapseStateKeys.data, value: isDataExpanded)
                        }
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "folder.fill")
                                .font(.title3)
                                .foregroundColor(.blue)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(localizationManager.data)
                                    .font(.body.weight(.semibold))
                                    .foregroundColor(.primary)
                                Text(localizationManager.currentLanguage == "en" ? "Manage your data" : "Quản lý dữ liệu")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(.secondary)
                                .rotationEffect(.degrees(isDataExpanded ? 90 : 0))
                        }
                        .padding(.vertical, 2)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .accessibilityLabel("\(localizationManager.data), \(localizationManager.currentLanguage == "en" ? "Manage your data" : "Quản lý dữ liệu")")
                    .accessibilityHint(isDataExpanded
                        ? (localizationManager.currentLanguage == "en" ? "Double tap to collapse" : "Nhấn đúp để thu gọn")
                        : (localizationManager.currentLanguage == "en" ? "Double tap to expand" : "Nhấn đúp để mở rộng"))
                    .accessibilityAddTraits(.isButton)

                    // Expandable Content
                    if isDataExpanded {
                        // Data Management Navigation
                        NavigationLink(destination: DataManagementView(viewModel: viewModel)) {
                            HStack(spacing: 14) {
                                SettingsIconView(icon: "externaldrive.fill", color: .blue)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(Strings.Settings.Data.dataManagement.localized(localizationManager.currentLanguage))
                                        .font(.body.weight(.medium))
                                        .foregroundColor(.primary)
                                    Text(Strings.Settings.Data.dataManagementDesc.localized(localizationManager.currentLanguage))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                            }
                        }
                        .accessibilityLabel(Strings.Settings.Data.dataManagement.localized(localizationManager.currentLanguage))
                        .accessibilityHint(Strings.Settings.Data.dataManagementDesc.localized(localizationManager.currentLanguage))

                        // Clear History Button
                        Button(action: {
                            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                            impactFeedback.impactOccurred()
                            showingClearHistoryAlert = true
                        }) {
                            HStack(spacing: 14) {
                                SettingsIconView(icon: "clock.arrow.circlepath", color: .red)
                                Text(localizationManager.clearHistory)
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .accessibilityLabel(localizationManager.clearHistory)
                        .accessibilityHint(localizationManager.currentLanguage == "en" ? "Double tap to clear all roast history" : "Nhấn đúp để xóa tất cả lịch sử roast")

                        // Clear Favorites Button
                        Button(action: {
                            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                            impactFeedback.impactOccurred()
                            showingClearFavoritesAlert = true
                        }) {
                            HStack(spacing: 14) {
                                SettingsIconView(icon: "heart.slash.fill", color: .red)
                                Text(localizationManager.clearFavorites)
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .accessibilityLabel(localizationManager.clearFavorites)
                        .accessibilityHint(localizationManager.currentLanguage == "en" ? "Double tap to clear all favorites" : "Nhấn đúp để xóa tất cả yêu thích")

                        // Reset Settings Button
                        Button(action: {
                            let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
                            impactFeedback.impactOccurred()
                            showingResetSettingsAlert = true
                        }) {
                            HStack(spacing: 14) {
                                SettingsIconView(icon: "arrow.counterclockwise", color: .red)
                                Text(localizationManager.resetSettings)
                                    .foregroundColor(.red)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .accessibilityLabel(localizationManager.resetSettings)
                        .accessibilityHint(localizationManager.currentLanguage == "en" ? "Double tap to reset all settings to default" : "Nhấn đúp để đặt lại tất cả cài đặt về mặc định")
                    }
                }
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isDataExpanded)

                // MARK: - App Info (Collapsible)
                Section {
                    // Collapsible Header
                    Button(action: {
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            isAppInfoExpanded.toggle()
                            saveCollapseState(CollapseStateKeys.appInfo, value: isAppInfoExpanded)
                        }
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "app.fill")
                                .font(.title3)
                                .foregroundColor(.orange)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(Strings.Settings.AppInfo.sectionTitle.localized(localizationManager.currentLanguage))
                                    .font(.body.weight(.semibold))
                                    .foregroundColor(.primary)
                                Text(localizationManager.currentLanguage == "en" ? "About, Rate & Support" : "Giới thiệu, Đánh giá & Hỗ trợ")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(.secondary)
                                .rotationEffect(.degrees(isAppInfoExpanded ? 90 : 0))
                        }
                        .padding(.vertical, 2)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .accessibilityLabel("\(Strings.Settings.AppInfo.sectionTitle.localized(localizationManager.currentLanguage)), \(localizationManager.currentLanguage == "en" ? "About, Rate & Support" : "Giới thiệu, Đánh giá & Hỗ trợ")")
                    .accessibilityHint(isAppInfoExpanded
                        ? (localizationManager.currentLanguage == "en" ? "Double tap to collapse" : "Nhấn đúp để thu gọn")
                        : (localizationManager.currentLanguage == "en" ? "Double tap to expand" : "Nhấn đúp để mở rộng"))
                    .accessibilityAddTraits(.isButton)

                    // Expandable Content
                    if isAppInfoExpanded {
                        // About Button
                        Button(action: {
                            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                            impactFeedback.impactOccurred()
                            showingAbout = true
                        }) {
                            HStack(spacing: 14) {
                                SettingsIconView(icon: "info.circle.fill", color: .orange)
                                Text(Strings.Settings.AppInfo.about.localized(localizationManager.currentLanguage))
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .accessibilityLabel(Strings.Settings.AppInfo.about.localized(localizationManager.currentLanguage))
                        .accessibilityHint(localizationManager.currentLanguage == "en" ? "Double tap to view app information" : "Nhấn đúp để xem thông tin ứng dụng")

                        // Rate App Link
                        Link(destination: URL(string: "https://apps.apple.com")!) {
                            HStack(spacing: 14) {
                                SettingsIconView(icon: "star.fill", color: .yellow)
                                Text(Strings.Settings.AppInfo.rateApp.localized(localizationManager.currentLanguage))
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "arrow.up.right.square")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .accessibilityLabel(Strings.Settings.AppInfo.rateApp.localized(localizationManager.currentLanguage))
                        .accessibilityHint(localizationManager.currentLanguage == "en" ? "Double tap to open App Store and rate this app" : "Nhấn đúp để mở App Store và đánh giá ứng dụng")

                        // Contact Support Link
                        Link(destination: URL(string: "mailto:support@roastme.app")!) {
                            HStack(spacing: 14) {
                                SettingsIconView(icon: "envelope.fill", color: .blue)
                                Text(Strings.Settings.AppInfo.contactSupport.localized(localizationManager.currentLanguage))
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "arrow.up.right.square")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .accessibilityLabel(Strings.Settings.AppInfo.contactSupport.localized(localizationManager.currentLanguage))
                        .accessibilityHint(localizationManager.currentLanguage == "en" ? "Double tap to send an email to support" : "Nhấn đúp để gửi email đến bộ phận hỗ trợ")
                    }
                }
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isAppInfoExpanded)

                // MARK: - Streak Statistics Section (Collapsible)
                Section {
                    // Collapsible Header
                    Button(action: {
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            isStreakExpanded.toggle()
                            saveCollapseState(CollapseStateKeys.streak, value: isStreakExpanded)
                        }
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "flame.fill")
                                .font(.title3)
                                .foregroundColor(.orange)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(Strings.Streak.sectionTitle.localized(localizationManager.currentLanguage))
                                    .font(.body.weight(.semibold))
                                    .foregroundColor(.primary)
                                Text("\(appLifecycleManager.currentStreak.currentStreak) \(localizationManager.currentLanguage == "en" ? "days" : "ngày")")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(.secondary)
                                .rotationEffect(.degrees(isStreakExpanded ? 90 : 0))
                        }
                        .padding(.vertical, 2)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .accessibilityLabel("\(Strings.Streak.sectionTitle.localized(localizationManager.currentLanguage)), \(appLifecycleManager.currentStreak.currentStreak) \(localizationManager.currentLanguage == "en" ? "days" : "ngày")")
                    .accessibilityHint(isStreakExpanded
                        ? (localizationManager.currentLanguage == "en" ? "Double tap to collapse" : "Nhấn đúp để thu gọn")
                        : (localizationManager.currentLanguage == "en" ? "Double tap to expand" : "Nhấn đúp để mở rộng"))
                    .accessibilityAddTraits(.isButton)

                    // Expandable Content
                    if isStreakExpanded {
                        StreakBadgeView(
                            streak: appLifecycleManager.currentStreak,
                            status: appLifecycleManager.streakStatus,
                            isCompact: false
                        )
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)

                        // Streak Freeze Button (if available and streak is expired)
                        if case .expired = appLifecycleManager.streakStatus,
                           appLifecycleManager.currentStreak.streakFreezeAvailable,
                           appLifecycleManager.currentStreak.currentStreak >= 7 {
                            Button(action: {
                                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                                impactFeedback.impactOccurred()
                                showingStreakFreezeAlert = true
                            }) {
                                HStack(spacing: 14) {
                                    SettingsIconView(icon: "snowflake", color: .blue)
                                    Text(Strings.Streak.useStreakFreeze.localized(localizationManager.currentLanguage))
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.secondary)
                                        .font(.caption)
                                }
                            }
                            .accessibilityLabel(Strings.Streak.useStreakFreeze.localized(localizationManager.currentLanguage))
                            .accessibilityHint(localizationManager.currentLanguage == "en" ? "Double tap to use streak freeze" : "Nhấn đúp để sử dụng đóng băng streak")
                        }

                        // Milestones
                        NavigationLink(destination: StreakMilestonesView()) {
                            HStack(spacing: 14) {
                                SettingsIconView(icon: "trophy.fill", color: .yellow)
                                Text(Strings.Streak.streakMilestones.localized(localizationManager.currentLanguage))
                                    .foregroundColor(.primary)
                                Spacer()
                            }
                        }
                        .accessibilityLabel(Strings.Streak.streakMilestones.localized(localizationManager.currentLanguage))
                        .accessibilityHint(localizationManager.currentLanguage == "en" ? "Double tap to view streak milestones" : "Nhấn đúp để xem các mốc streak")
                    }
                }
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isStreakExpanded)

                // MARK: - Statistics (Collapsible)
                Section {
                    // Collapsible Header
                    Button(action: {
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            isStatisticsExpanded.toggle()
                            saveCollapseState(CollapseStateKeys.statistics, value: isStatisticsExpanded)
                        }
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "chart.bar.fill")
                                .font(.title3)
                                .foregroundColor(.purple)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(Strings.Settings.Statistics.sectionTitle.localized(localizationManager.currentLanguage))
                                    .font(.body.weight(.semibold))
                                    .foregroundColor(.primary)
                                Text("\(viewModel.totalRoastsGenerated) \(localizationManager.currentLanguage == "en" ? "roasts" : "roast")")
                                    .font(.caption)
                                    .foregroundColor(.purple)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(.secondary)
                                .rotationEffect(.degrees(isStatisticsExpanded ? 90 : 0))
                        }
                        .padding(.vertical, 2)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .accessibilityLabel("\(Strings.Settings.Statistics.sectionTitle.localized(localizationManager.currentLanguage)), \(viewModel.totalRoastsGenerated) \(localizationManager.currentLanguage == "en" ? "roasts" : "roast")")
                    .accessibilityHint(isStatisticsExpanded
                        ? (localizationManager.currentLanguage == "en" ? "Double tap to collapse" : "Nhấn đúp để thu gọn")
                        : (localizationManager.currentLanguage == "en" ? "Double tap to expand" : "Nhấn đúp để mở rộng"))
                    .accessibilityAddTraits(.isButton)

                    // Expandable Content
                    if isStatisticsExpanded {
                        // Total Roasts
                        HStack(spacing: 14) {
                            SettingsIconView(icon: "number.circle.fill", color: .purple)
                            Text(Strings.Settings.Statistics.totalRoastsGenerated.localized(localizationManager.currentLanguage))
                            Spacer()
                            Text("\(viewModel.totalRoastsGenerated)")
                                .font(.headline.weight(.semibold))
                                .foregroundColor(.purple)
                        }
                        .accessibilityElement(children: .combine)

                        // Favorite Roasts
                        HStack(spacing: 14) {
                            SettingsIconView(icon: "heart.fill", color: .red)
                            Text(Strings.Settings.Statistics.favoriteRoasts.localized(localizationManager.currentLanguage))
                            Spacer()
                            Text("\(viewModel.totalFavorites)")
                                .font(.headline.weight(.semibold))
                                .foregroundColor(.red)
                        }
                        .accessibilityElement(children: .combine)

                        // Most Popular Category
                        HStack(spacing: 14) {
                            SettingsIconView(icon: "crown.fill", color: .orange)
                            Text(Strings.Settings.Statistics.mostPopularCategory.localized(localizationManager.currentLanguage))
                            Spacer()
                            if let category = viewModel.mostPopularCategory {
                                Text(localizationManager.categoryName(category))
                                    .font(.subheadline.weight(.medium))
                                    .foregroundColor(.orange)
                            } else {
                                Text(Strings.Settings.Statistics.notAvailable.localized(localizationManager.currentLanguage))
                                    .font(.subheadline.weight(.medium))
                                    .foregroundColor(.orange)
                            }
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isStatisticsExpanded)

                // MARK: - Version Info (Footer)
                Section {
                    HStack {
                        Spacer()
                        VStack(spacing: 4) {
                            Text("RoastMeLater")
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(.secondary)
                            Text("v\(Constants.App.version)")
                                .font(.caption)
                                .foregroundColor(.secondary.opacity(0.7))
                        }
                        Spacer()
                    }
                    .padding(.vertical, 8)
                    .listRowBackground(Color.clear)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("RoastMeLater \(localizationManager.currentLanguage == "en" ? "version" : "phiên bản") \(Constants.App.version)")
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(Strings.Settings.title.localized(localizationManager.currentLanguage))
        }
        .sheet(isPresented: $showingAbout) {
            AboutView()
        }
        .alert(Strings.Settings.Notifications.testNotification.localized(localizationManager.currentLanguage), isPresented: $showingNotificationTest) {
            Button(Strings.Common.ok.localized(localizationManager.currentLanguage)) { }
        } message: {
            Text(Strings.Settings.Notifications.testNotificationMessage.localized(localizationManager.currentLanguage))
        }
        .alert(Strings.Streak.useStreakFreezeConfirm.localized(localizationManager.currentLanguage), isPresented: $showingStreakFreezeAlert) {
            Button(Strings.Common.cancel.localized(localizationManager.currentLanguage), role: .cancel) { }
            Button(Strings.Streak.useFreeze.localized(localizationManager.currentLanguage), role: .destructive) {
                _ = appLifecycleManager.useStreakFreeze()
            }
        } message: {
            Text(Strings.Streak.useStreakFreezeMessage.localized(localizationManager.currentLanguage))
        }
        // Clear History Alert
        .alert(localizationManager.clearHistory, isPresented: $showingClearHistoryAlert) {
            Button(Strings.Common.cancel.localized(localizationManager.currentLanguage), role: .cancel) { }
            Button(Strings.Common.delete.localized(localizationManager.currentLanguage), role: .destructive) {
                viewModel.clearRoastHistory()
            }
        } message: {
            Text(localizationManager.currentLanguage == "en" ? "Are you sure you want to clear all roast history? This action cannot be undone." : "Bạn có chắc muốn xóa toàn bộ lịch sử roast? Hành động này không thể hoàn tác.")
        }
        // Clear Favorites Alert
        .alert(localizationManager.clearFavorites, isPresented: $showingClearFavoritesAlert) {
            Button(Strings.Common.cancel.localized(localizationManager.currentLanguage), role: .cancel) { }
            Button(Strings.Common.delete.localized(localizationManager.currentLanguage), role: .destructive) {
                viewModel.clearFavorites()
            }
        } message: {
            Text(localizationManager.currentLanguage == "en" ? "Are you sure you want to clear all favorites? This action cannot be undone." : "Bạn có chắc muốn xóa toàn bộ yêu thích? Hành động này không thể hoàn tác.")
        }
        // Reset Settings Alert
        .alert(localizationManager.resetSettings, isPresented: $showingResetSettingsAlert) {
            Button(Strings.Common.cancel.localized(localizationManager.currentLanguage), role: .cancel) { }
            Button(Strings.Common.delete.localized(localizationManager.currentLanguage), role: .destructive) {
                viewModel.resetAllSettings()
            }
        } message: {
            Text(localizationManager.currentLanguage == "en" ? "Are you sure you want to reset all settings to default? This action cannot be undone." : "Bạn có chắc muốn đặt lại tất cả cài đặt về mặc định? Hành động này không thể hoàn tác.")
        }
        // Error Alert
        .alert(
            localizationManager.currentLanguage == "en" ? "Error" : "Lỗi",
            isPresented: $viewModel.showError
        ) {
            Button(Strings.Common.ok.localized(localizationManager.currentLanguage), role: .cancel) {
                viewModel.showError = false
            }
        } message: {
            Text(viewModel.errorMessage ?? (localizationManager.currentLanguage == "en" ? "An error occurred" : "Có lỗi xảy ra"))
        }
        .onAppear {
            viewModel.loadSettings()
            appLifecycleManager.refreshStreakData()
        }
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
}

// MARK: - Settings Helper Components

/// Icon view for settings rows
struct SettingsIconView: View {
    let icon: String
    let color: Color

    var body: some View {
        Image(systemName: icon)
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(.white)
            .frame(width: 28, height: 28)
            .background(color)
            .cornerRadius(6)
    }
}

/// Section header with icon
struct SettingsSectionHeader: View {
    let icon: String
    let title: String
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.secondary)
                .textCase(.uppercase)
        }
    }
}

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(colors: [.orange.opacity(0.2), .red.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 120, height: 120)

                            Image(systemName: "flame.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.orange)
                        }

                        VStack(spacing: 8) {
                            Text("RoastMe Generator")
                                .font(.largeTitle.weight(.bold))

                            Text("🎯 Giải tỏa stress với những câu roast hài hước")
                                .font(.headline)
                                .foregroundColor(.orange)
                                .multilineTextAlignment(.center)
                        }
                    }

                    // Mission
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "target")
                                .foregroundColor(.orange)
                            Text("Sứ mệnh")
                                .font(.title2.weight(.bold))
                        }

                        Text("Mang lại tiếng cười và giúp dân văn phòng giải tỏa căng thẳng công việc thông qua những câu roast vui nhộn, phù hợp với văn hóa Việt Nam.")
                            .font(.body)
                            .lineSpacing(4)
                    }
                    .padding(20)
                    .background(Color(.systemGray6))
                    .cornerRadius(16)

                    // Features
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "star.fill")
                                .foregroundColor(.orange)
                            Text("Tính năng nổi bật")
                                .font(.title2.weight(.bold))
                        }

                        VStack(spacing: 12) {
                            FeatureRow(icon: "brain", text: "AI thông minh tạo roast phù hợp")
                            FeatureRow(icon: "tag.fill", text: "8 danh mục công việc đa dạng")
                            FeatureRow(icon: "flame.fill", text: "5 mức độ cay từ nhẹ đến cực")
                            FeatureRow(icon: "bell.fill", text: "Thông báo định kỳ thông minh")
                            FeatureRow(icon: "heart.fill", text: "Lưu và chia sẻ roast yêu thích")
                            FeatureRow(icon: "clock.fill", text: "Lịch sử và tìm kiếm roast")
                            FeatureRow(icon: "shield.fill", text: "Bộ lọc an toàn nội dung")
                            FeatureRow(icon: "globe", text: "Tối ưu cho văn hóa Việt Nam")
                        }
                    }
                    .padding(20)
                    .background(Color(.systemGray6))
                    .cornerRadius(16)

                    // How it works
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "gearshape.fill")
                                .foregroundColor(.orange)
                            Text("Cách hoạt động")
                                .font(.title2.weight(.bold))
                        }

                        VStack(spacing: 12) {
                            HowItWorksStep(number: "1", title: "Chọn danh mục", description: "Deadline, Meeting, KPI, Code Review...")
                            HowItWorksStep(number: "2", title: "Điều chỉnh độ cay", description: "Từ nhẹ nhàng đến cực cay")
                            HowItWorksStep(number: "3", title: "AI tạo roast", description: "Câu roast phù hợp và hài hước")
                            HowItWorksStep(number: "4", title: "Thưởng thức", description: "Copy, chia sẻ, lưu yêu thích")
                        }
                    }
                    .padding(20)
                    .background(Color(.systemGray6))
                    .cornerRadius(16)

                    // Developer info
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "person.fill")
                                .foregroundColor(.orange)
                            Text("Đội ngũ phát triển")
                                .font(.title2.weight(.bold))
                        }

                        Text("Được phát triển bởi đội ngũ RoastMe Team với mong muốn mang lại tiếng cười và giảm stress cho cộng đồng dân văn phòng Việt Nam.")
                            .font(.body)
                            .lineSpacing(4)

                        HStack {
                            Image(systemName: "envelope.fill")
                                .foregroundColor(.orange)
                            Text("Liên hệ: roastme.team@gmail.com")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(20)
                    .background(Color(.systemGray6))
                    .cornerRadius(16)

                    // Version info - moved to bottom
                    VStack(spacing: 8) {
                        Divider()

                        VStack(spacing: 4) {
                            HStack {
                                Text("Phiên bản \(Constants.App.version)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                Spacer()

                                Text("© 2024 RoastMe Team")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            HStack {
                                Text("Yêu cầu iOS \(Constants.App.minimumIOSVersion)+")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)

                                Spacer()

                                Text("Tối ưu cho iOS \(Constants.App.targetIOSVersion)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                    .padding(.top, 20)
                }
                .padding(20)
            }
            .navigationTitle("Giới Thiệu")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Đóng") {
                        dismiss()
                    }
                    .foregroundColor(.orange)
                }
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.orange)
                .frame(width: 20)
            Text(text)
                .font(.subheadline)
            Spacer()
        }
    }
}

struct HowItWorksStep: View {
    let number: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.orange)
                    .frame(width: 28, height: 28)
                Text(number)
                    .font(.caption.weight(.bold))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(NotificationManager())
}
