import SwiftUI

struct ExportOptionsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    @EnvironmentObject var localizationManager: LocalizationManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var includeAPIConfiguration = false
    @State private var includeDeviceInfo = true
    @State private var includeStatistics = true
    @State private var anonymizeData = false
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    Text(localizationManager.currentLanguage == "en"
                         ? "Choose what data to include in your export. Sensitive information like API keys can be excluded for security."
                         : "Chọn dữ liệu nào sẽ được bao gồm trong file xuất. Thông tin nhạy cảm như API key có thể được loại bỏ để bảo mật.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } header: {
                    Text(localizationManager.currentLanguage == "en" ? "Export Options" : "Tùy Chọn Xuất")
                }
                
                Section {
                    Toggle(isOn: $includeAPIConfiguration) {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Image(systemName: "key.fill")
                                    .foregroundColor(.orange)
                                Text(localizationManager.currentLanguage == "en" ? "API Configuration" : "Cấu Hình API")
                                    .fontWeight(.medium)
                            }
                            Text(localizationManager.currentLanguage == "en"
                                 ? "Include API keys and endpoints (not recommended for sharing)"
                                 : "Bao gồm API key và endpoint (không khuyến nghị khi chia sẻ)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Toggle(isOn: $includeDeviceInfo) {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Image(systemName: "iphone")
                                    .foregroundColor(.blue)
                                Text(localizationManager.currentLanguage == "en" ? "Device Information" : "Thông Tin Thiết Bị")
                                    .fontWeight(.medium)
                            }
                            Text(localizationManager.currentLanguage == "en"
                                 ? "Include device model and iOS version for compatibility"
                                 : "Bao gồm model thiết bị và phiên bản iOS để tương thích")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Toggle(isOn: $includeStatistics) {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Image(systemName: "chart.bar")
                                    .foregroundColor(.green)
                                Text(localizationManager.currentLanguage == "en" ? "Usage Statistics" : "Thống Kê Sử Dụng")
                                    .fontWeight(.medium)
                            }
                            Text(localizationManager.currentLanguage == "en"
                                 ? "Include category breakdown and usage patterns"
                                 : "Bao gồm phân tích danh mục và mẫu sử dụng")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Toggle(isOn: $anonymizeData) {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Image(systemName: "eye.slash")
                                    .foregroundColor(.purple)
                                Text(localizationManager.currentLanguage == "en" ? "Anonymize Data" : "Ẩn Danh Dữ Liệu")
                                    .fontWeight(.medium)
                            }
                            Text(localizationManager.currentLanguage == "en"
                                 ? "Remove potentially identifying information from roast content"
                                 : "Loại bỏ thông tin có thể nhận dạng khỏi nội dung roast")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text(localizationManager.currentLanguage == "en" ? "Data to Include" : "Dữ Liệu Bao Gồm")
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundColor(.blue)
                            Text(localizationManager.currentLanguage == "en" ? "What's Always Included" : "Luôn Được Bao Gồm")
                                .fontWeight(.semibold)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            BulletPoint(text: localizationManager.currentLanguage == "en" ? "All roast history and content" : "Toàn bộ lịch sử và nội dung roast")
                            BulletPoint(text: localizationManager.currentLanguage == "en" ? "Favorite roasts list" : "Danh sách roast yêu thích")
                            BulletPoint(text: localizationManager.currentLanguage == "en" ? "User preferences and settings" : "Tùy chọn và cài đặt người dùng")
                            BulletPoint(text: localizationManager.currentLanguage == "en" ? "Export metadata and timestamp" : "Metadata và thời gian xuất")
                        }
                    }
                } header: {
                    Text(localizationManager.currentLanguage == "en" ? "Export Details" : "Chi Tiết Xuất")
                }
                
                Section {
                    if includeAPIConfiguration {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(localizationManager.currentLanguage == "en" ? "Security Warning" : "Cảnh Báo Bảo Mật")
                                    .fontWeight(.semibold)
                                    .foregroundColor(.red)
                                Text(localizationManager.currentLanguage == "en"
                                     ? "API keys will be included in plain text. Only share this file with trusted recipients."
                                     : "API key sẽ được bao gồm dưới dạng văn bản thuần. Chỉ chia sẻ file này với người tin cậy.")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                    }
                    
                    if anonymizeData {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.blue)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(localizationManager.currentLanguage == "en" ? "Anonymization Note" : "Lưu Ý Ẩn Danh")
                                    .fontWeight(.semibold)
                                    .foregroundColor(.blue)
                                Text(localizationManager.currentLanguage == "en"
                                     ? "Basic anonymization will be applied. Review exported content before sharing."
                                     : "Ẩn danh cơ bản sẽ được áp dụng. Xem lại nội dung đã xuất trước khi chia sẻ.")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
            }
            .navigationTitle(localizationManager.currentLanguage == "en" ? "Export Options" : "Tùy Chọn Xuất")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(localizationManager.cancel) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(localizationManager.currentLanguage == "en" ? "Export" : "Xuất") {
                        let options = ExportOptions(
                            includeAPIConfiguration: includeAPIConfiguration,
                            includeDeviceInfo: includeDeviceInfo,
                            includeStatistics: includeStatistics,
                            anonymizeData: anonymizeData
                        )
                        viewModel.generatePrivacyNotice(for: options)
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            // Initialize with current export options
            includeAPIConfiguration = viewModel.exportOptions.includeAPIConfiguration
            includeDeviceInfo = viewModel.exportOptions.includeDeviceInfo
            includeStatistics = viewModel.exportOptions.includeStatistics
            anonymizeData = viewModel.exportOptions.anonymizeData
        }
    }
}

struct BulletPoint: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .foregroundColor(.secondary)
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
        }
    }
}

#Preview {
    ExportOptionsView(viewModel: SettingsViewModel())
        .environmentObject(LocalizationManager.shared)
}
