import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @EnvironmentObject var notificationManager: NotificationManager
    @EnvironmentObject var localizationManager: LocalizationManager
    @State private var showingAbout = false
    @State private var showingNotificationTest = false
    
    var body: some View {
        NavigationView {
            Form {
                // Notification Settings
                Section(localizationManager.notifications) {
                    Toggle(localizationManager.currentLanguage == "en" ? "Enable Notifications" : "Bật thông báo", isOn: $viewModel.notificationsEnabled)
                        .onChange(of: viewModel.notificationsEnabled) { enabled in
                            viewModel.updateNotificationsEnabled(enabled)
                            if enabled {
                                notificationManager.requestNotificationPermission()
                            } else {
                                notificationManager.cancelAllNotifications()
                            }
                        }
                    
                    if viewModel.notificationsEnabled {
                        Picker(localizationManager.currentLanguage == "en" ? "Frequency" : "Tần suất", selection: $viewModel.notificationFrequency) {
                            ForEach(NotificationFrequency.allCases, id: \.self) { frequency in
                                Text(frequency.displayName).tag(frequency)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .onChange(of: viewModel.notificationFrequency) { newValue in
                            viewModel.updateNotificationFrequency(newValue)
                            notificationManager.scheduleHourlyNotifications()
                        }
                        
                        Button(localizationManager.currentLanguage == "en" ? "Test Notification" : "Test thông báo") {
                            notificationManager.scheduleTestNotification()
                            showingNotificationTest = true
                        }
                        .foregroundColor(.orange)
                    }
                }
                
                // Content Settings
                Section(localizationManager.content) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Mức độ cay mặc định:")
                            Spacer()
                            Text("\(viewModel.defaultSpiceLevel)/5")
                                .fontWeight(.semibold)
                        }
                        
                        HStack(spacing: 8) {
                            ForEach(1...5, id: \.self) { level in
                                Image(systemName: level <= viewModel.defaultSpiceLevel ? "flame.fill" : "flame")
                                    .foregroundColor(level <= viewModel.defaultSpiceLevel ? .orange : .gray)
                                    .onTapGesture {
                                        viewModel.updateDefaultSpiceLevel(level)
                                    }
                            }
                        }
                    }
                    .padding(.vertical, 4)
                    
                    Toggle("Bộ lọc an toàn", isOn: $viewModel.safetyFiltersEnabled)
                        .onChange(of: viewModel.safetyFiltersEnabled) { enabled in
                            viewModel.updateSafetyFilters(enabled)
                        }
                    
                    Picker(localizationManager.language, selection: $viewModel.preferredLanguage) {
                        ForEach(localizationManager.languageOptions, id: \.code) { option in
                            Text(option.name).tag(option.code)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .onChange(of: viewModel.preferredLanguage) { newValue in
                        viewModel.updatePreferredLanguage(newValue)
                        localizationManager.setLanguage(newValue)
                    }
                }

                // API Configuration
                Section(header:
                    HStack {
                        Image(systemName: "key.fill")
                            .foregroundColor(.orange)
                        Text("Cấu Hình API")
                    }
                ) {
                    VStack(alignment: .leading, spacing: 12) {
                        // Info text
                        Text("Để sử dụng tính năng tạo roast, bạn cần cung cấp API key và URL của dịch vụ AI.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.bottom, 8)

                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("API Key")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Text("*")
                                    .foregroundColor(.red)
                            }
                            SecureField("sk-xxxxxxxxxxxxxxxx", text: $viewModel.apiKey)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Base URL")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Text("*")
                                    .foregroundColor(.red)
                            }
                            TextField("https://api.example.com/v1/chat/completions", text: $viewModel.baseURL)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Model")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text("deepseek:deepseek-v3")
                                .font(.body)
                                .foregroundColor(.primary)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                        }

                        // Test button
                        Button(action: {
                            viewModel.testAPIConnection()
                        }) {
                            HStack {
                                Image(systemName: "checkmark.circle")
                                Text("Test Kết Nối")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(viewModel.apiKey.isEmpty || viewModel.baseURL.isEmpty ? Color.gray.opacity(0.3) : Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .disabled(viewModel.apiKey.isEmpty || viewModel.baseURL.isEmpty)

                        // Test result
                        if let testResult = viewModel.apiTestResult {
                            HStack {
                                Image(systemName: testResult ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundColor(testResult ? .green : .red)
                                Text(testResult ? "✅ API hoạt động tốt!" : "❌ Không thể kết nối API")
                                    .font(.subheadline)
                                    .foregroundColor(testResult ? .green : .red)
                                Spacer()
                            }
                            .padding(.top, 8)
                        }

                        // Save status
                        if !viewModel.apiKey.isEmpty && !viewModel.baseURL.isEmpty {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("Cấu hình đã được lưu")
                                    .font(.caption)
                                    .foregroundColor(.green)
                                Spacer()
                            }
                            .padding(.top, 4)
                        }
                    }
                    .padding(.vertical, 8)
                }

                // Data Management - Enhanced Section
                Section {
                    NavigationLink(destination: DataManagementView(viewModel: viewModel)) {
                        HStack {
                            Image(systemName: "externaldrive")
                                .foregroundColor(.blue)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(localizationManager.currentLanguage == "en" ? "Data Management" : "Quản Lý Dữ Liệu")
                                    .fontWeight(.medium)
                                Text(localizationManager.currentLanguage == "en" ? "Export, import, and manage your data" : "Xuất, nhập và quản lý dữ liệu của bạn")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                    }

                    Divider()

                    // Quick Actions
                    Button(localizationManager.clearHistory) {
                        viewModel.clearRoastHistory()
                    }
                    .foregroundColor(.red)

                    Button(localizationManager.clearFavorites) {
                        viewModel.clearFavorites()
                    }
                    .foregroundColor(.red)

                    Button(localizationManager.resetSettings) {
                        viewModel.resetAllSettings()
                    }
                    .foregroundColor(.red)
                } header: {
                    Text(localizationManager.data)
                }
                
                // Version Info
                Section(localizationManager.version) {
                    HStack {
                        Text("Phiên bản")
                        Spacer()
                        Text(Constants.App.version)
                            .foregroundColor(.secondary)
                    }
                }

                // App Info
                Section("Thông Tin Ứng Dụng") {
                    Button("Giới thiệu") {
                        showingAbout = true
                    }
                    .foregroundColor(.orange)

                    Link("Đánh giá ứng dụng", destination: URL(string: "https://apps.apple.com")!)
                        .foregroundColor(.orange)

                    Link("Liên hệ hỗ trợ", destination: URL(string: "mailto:support@roastme.app")!)
                        .foregroundColor(.orange)
                }
                
                // Statistics
                Section("Thống Kê") {
                    HStack {
                        Text("Tổng số roast đã tạo")
                        Spacer()
                        Text("\(viewModel.totalRoastsGenerated)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Roast yêu thích")
                        Spacer()
                        Text("\(viewModel.totalFavorites)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Danh mục phổ biến nhất")
                        Spacer()
                        Text(viewModel.mostPopularCategory?.displayName ?? "Chưa có")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Cài Đặt")
        }
        .sheet(isPresented: $showingAbout) {
            AboutView()
        }
        .alert(localizationManager.currentLanguage == "en" ? "Test Notification" : "Thông báo test", isPresented: $showingNotificationTest) {
            Button("OK") { }
        } message: {
            Text(localizationManager.currentLanguage == "en" ? "Test notification will appear in 5 seconds!" : "Thông báo test sẽ xuất hiện sau 5 giây!")
        }
        .onAppear {
            viewModel.loadSettings()
        }
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
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
                                .font(.largeTitle)
                                .fontWeight(.bold)

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
                                .font(.title2)
                                .fontWeight(.bold)
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
                                .font(.title2)
                                .fontWeight(.bold)
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
                                .font(.title2)
                                .fontWeight(.bold)
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
                                .font(.title2)
                                .fontWeight(.bold)
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
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
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
