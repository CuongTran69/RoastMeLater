import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @EnvironmentObject var notificationManager: NotificationManager
    @State private var showingAbout = false
    @State private var showingNotificationTest = false
    
    var body: some View {
        NavigationView {
            Form {
                // Notification Settings
                Section("Thông Báo") {
                    Toggle("Bật thông báo", isOn: $viewModel.notificationsEnabled)
                        .onChange(of: viewModel.notificationsEnabled) { enabled in
                            if enabled {
                                notificationManager.requestNotificationPermission()
                            } else {
                                notificationManager.cancelAllNotifications()
                            }
                        }
                    
                    if viewModel.notificationsEnabled {
                        Picker("Tần suất", selection: $viewModel.notificationFrequency) {
                            ForEach(NotificationFrequency.allCases, id: \.self) { frequency in
                                Text(frequency.displayName).tag(frequency)
                            }
                        }
                        .onChange(of: viewModel.notificationFrequency) { _ in
                            notificationManager.scheduleHourlyNotifications()
                        }
                        
                        Button("Test thông báo") {
                            NotificationScheduler.shared.scheduleTestNotification()
                            showingNotificationTest = true
                        }
                        .foregroundColor(.orange)
                    }
                }
                
                // Content Settings
                Section("Nội Dung") {
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
                                        viewModel.defaultSpiceLevel = level
                                    }
                            }
                        }
                    }
                    .padding(.vertical, 4)
                    
                    Toggle("Bộ lọc an toàn", isOn: $viewModel.safetyFiltersEnabled)
                    
                    Picker("Ngôn ngữ", selection: $viewModel.preferredLanguage) {
                        Text("Tiếng Việt").tag("vi")
                        Text("English").tag("en")
                    }
                }
                
                // Category Preferences
                Section("Danh Mục Ưa Thích") {
                    ForEach(RoastCategory.allCases, id: \.self) { category in
                        HStack {
                            Image(systemName: category.icon)
                                .foregroundColor(.orange)
                                .frame(width: 20)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(category.displayName)
                                    .font(.body)
                                
                                Text(category.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                            
                            Spacer()
                            
                            Toggle("", isOn: Binding(
                                get: { viewModel.preferredCategories.contains(category) },
                                set: { isSelected in
                                    if isSelected {
                                        viewModel.addPreferredCategory(category)
                                    } else {
                                        viewModel.removePreferredCategory(category)
                                    }
                                }
                            ))
                            .labelsHidden()
                        }
                        .padding(.vertical, 2)
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
                            Text("anthropic:3.7-sonnet")
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

                // Data Management
                Section("Dữ Liệu") {
                    Button("Xóa lịch sử roast") {
                        viewModel.clearRoastHistory()
                    }
                    .foregroundColor(.red)
                    
                    Button("Xóa danh sách yêu thích") {
                        viewModel.clearFavorites()
                    }
                    .foregroundColor(.red)
                    
                    Button("Đặt lại tất cả cài đặt") {
                        viewModel.resetAllSettings()
                    }
                    .foregroundColor(.red)
                }
                
                // App Info
                Section("Thông Tin Ứng Dụng") {
                    HStack {
                        Text("Phiên bản")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
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
        .alert("Thông báo test", isPresented: $showingNotificationTest) {
            Button("OK") { }
        } message: {
            Text("Thông báo test sẽ xuất hiện sau 5 giây!")
        }
        .onAppear {
            viewModel.loadSettings()
        }
        .dismissKeyboardOnScroll()
    }
}

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.orange)
                    
                    Text("RoastMe")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Phiên bản 1.0.0")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Giới thiệu")
                            .font(.headline)
                        
                        Text("RoastMe là ứng dụng giúp các nhân viên văn phòng giải tỏa stress thông qua những câu roast hài hước và phù hợp với môi trường làm việc.")
                        
                        Text("Tính năng chính:")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            FeatureRow(icon: "sparkles", text: "Tạo roast tự động với AI")
                            FeatureRow(icon: "bell", text: "Thông báo định kỳ")
                            FeatureRow(icon: "heart", text: "Lưu roast yêu thích")
                            FeatureRow(icon: "clock", text: "Lịch sử roast")
                            FeatureRow(icon: "slider.horizontal.3", text: "Tùy chỉnh mức độ cay")
                            FeatureRow(icon: "shield", text: "Bộ lọc an toàn")
                        }
                        
                        Text("Phát triển bởi")
                            .font(.headline)
                        
                        Text("RoastMe Team - Mang tiếng cười đến môi trường làm việc!")
                            .foregroundColor(.secondary)
                    }
                    .padding()
                }
                .padding()
            }
            .navigationTitle("Giới Thiệu")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Đóng") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.orange)
                .frame(width: 20)
            Text(text)
            Spacer()
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(NotificationManager())
}
