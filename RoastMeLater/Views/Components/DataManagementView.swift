import SwiftUI

struct DataManagementView: View {
    @ObservedObject var viewModel: SettingsViewModel
    @EnvironmentObject var localizationManager: LocalizationManager
    
    var body: some View {
        VStack(spacing: 16) {
            // Export Section
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(.blue)
                    Text(localizationManager.currentLanguage == "en" ? "Export Data" : "Xuất Dữ Liệu")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                
                Text(localizationManager.currentLanguage == "en" 
                     ? "Export your roast history, favorites, and settings to a JSON file for backup or transfer."
                     : "Xuất lịch sử roast, danh sách yêu thích và cài đặt ra file JSON để sao lưu hoặc chuyển đổi.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if viewModel.isExporting {
                    ExportProgressView(progress: viewModel.exportProgress)
                } else {
                    Button(action: {
                        viewModel.exportData()
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text(localizationManager.currentLanguage == "en" ? "Export All Data" : "Xuất Tất Cả Dữ Liệu")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    
                    Button(action: {
                        viewModel.showExportOptions()
                    }) {
                        HStack {
                            Image(systemName: "gear")
                            Text(localizationManager.currentLanguage == "en" ? "Export Options" : "Tùy Chọn Xuất")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(10)
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            // Import Section
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "square.and.arrow.down")
                        .foregroundColor(.green)
                    Text(localizationManager.currentLanguage == "en" ? "Import Data" : "Nhập Dữ Liệu")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                
                Text(localizationManager.currentLanguage == "en"
                     ? "Import previously exported data from a JSON file. You can choose to merge with existing data or replace it completely."
                     : "Nhập dữ liệu đã xuất trước đó từ file JSON. Bạn có thể chọn gộp với dữ liệu hiện có hoặc thay thế hoàn toàn.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if viewModel.isImporting {
                    ImportProgressView(progress: viewModel.importProgress)
                } else {
                    Button(action: {
                        viewModel.importData()
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.down")
                            Text(localizationManager.currentLanguage == "en" ? "Import Data" : "Nhập Dữ Liệu")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            // Data Statistics
            DataStatisticsView(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.showingExportOptions) {
            ExportOptionsView(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.showingImportPreview) {
            ImportPreviewView(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.showingPrivacyNotice) {
            if let privacyNotice = viewModel.privacyNotice {
                PrivacyNoticeView(
                    privacyNotice: privacyNotice,
                    complianceIssues: viewModel.complianceIssues,
                    onAccept: {
                        viewModel.acceptPrivacyNoticeAndExport()
                    },
                    onCancel: {
                        viewModel.cancelPrivacyNotice()
                    }
                )
            }
        }
    }
}

struct ExportProgressView: View {
    let progress: ExportProgress?
    @EnvironmentObject var localizationManager: LocalizationManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let progress = progress {
                HStack {
                    Text(progress.message)
                        .font(.subheadline)
                    Spacer()
                    Text("\(Int(progress.progress * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                ProgressView(value: progress.progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                
                if progress.totalItems > 0 {
                    Text("\(progress.itemsProcessed)/\(progress.totalItems) items")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                if case .failed(let error) = progress.phase {
                    Text(error.localizedDescription)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.top, 4)
                }
            }
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(8)
    }
}

struct ImportProgressView: View {
    let progress: ImportProgress?
    @EnvironmentObject var localizationManager: LocalizationManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let progress = progress {
                HStack {
                    Text(progress.message)
                        .font(.subheadline)
                    Spacer()
                    Text("\(Int(progress.progress * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                ProgressView(value: progress.progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: .green))
                
                if progress.totalItems > 0 {
                    Text("\(progress.itemsProcessed)/\(progress.totalItems) items")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                if !progress.warnings.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(localizationManager.currentLanguage == "en" ? "Warnings:" : "Cảnh báo:")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.orange)
                        
                        ForEach(progress.warnings.prefix(3), id: \.message) { warning in
                            Text("• \(warning.message)")
                                .font(.caption2)
                                .foregroundColor(.orange)
                        }
                        
                        if progress.warnings.count > 3 {
                            Text("... và \(progress.warnings.count - 3) cảnh báo khác")
                                .font(.caption2)
                                .foregroundColor(.orange)
                        }
                    }
                    .padding(.top, 4)
                }
                
                if case .failed(let error) = progress.phase {
                    Text(error.localizedDescription)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.top, 4)
                }
            }
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(8)
    }
}

struct DataStatisticsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    @EnvironmentObject var localizationManager: LocalizationManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.bar")
                    .foregroundColor(.orange)
                Text(localizationManager.currentLanguage == "en" ? "Data Overview" : "Tổng Quan Dữ Liệu")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                StatCard(
                    title: localizationManager.currentLanguage == "en" ? "Total Roasts" : "Tổng Roast",
                    value: "\(viewModel.totalRoastsGenerated)",
                    icon: "flame.fill",
                    color: .orange
                )
                
                StatCard(
                    title: localizationManager.currentLanguage == "en" ? "Favorites" : "Yêu Thích",
                    value: "\(viewModel.totalFavorites)",
                    icon: "heart.fill",
                    color: .red
                )
            }
            
            if let category = viewModel.mostPopularCategory {
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                    Text(localizationManager.currentLanguage == "en" ? "Most Popular:" : "Phổ biến nhất:")
                        .font(.caption)
                    Text(localizationManager.categoryName(category))
                        .font(.caption)
                        .fontWeight(.semibold)
                    Spacer()
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
}

#Preview {
    DataManagementView(viewModel: SettingsViewModel())
        .environmentObject(LocalizationManager.shared)
}
