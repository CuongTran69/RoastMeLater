import SwiftUI

struct ImportPreviewView: View {
    @ObservedObject var viewModel: SettingsViewModel
    @EnvironmentObject var localizationManager: LocalizationManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var importStrategy: ImportStrategy = .merge
    @State private var skipDuplicates = true
    @State private var preserveExistingFavorites = true
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    if let preview = viewModel.importPreview {
                        // File Information
                        FileInfoSection(preview: preview)
                        
                        // Data Summary
                        DataSummarySection(preview: preview)
                        
                        // Import Options
                        ImportOptionsSection(
                            importStrategy: $importStrategy,
                            skipDuplicates: $skipDuplicates,
                            preserveExistingFavorites: $preserveExistingFavorites
                        )
                        
                        // Warnings
                        if !preview.warnings.isEmpty {
                            WarningsSection(warnings: preview.warnings)
                        }
                        
                        // Preferences Changes
                        if !preview.summary.preferencesChanges.isEmpty {
                            PreferencesChangesSection(changes: preview.summary.preferencesChanges)
                        }
                        
                        // Action Buttons
                        ActionButtonsSection(
                            isCompatible: preview.isCompatible,
                            onConfirm: {
                                let options = ImportOptions(
                                    strategy: importStrategy,
                                    validateData: true,
                                    skipDuplicates: skipDuplicates,
                                    preserveExistingFavorites: preserveExistingFavorites
                                )
                                viewModel.confirmImport(with: options)
                                dismiss()
                            },
                            onCancel: {
                                viewModel.cancelImport()
                                dismiss()
                            }
                        )
                    }
                }
                .padding()
            }
            .navigationTitle(localizationManager.currentLanguage == "en" ? "Import Preview" : "Xem Trước Nhập")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(localizationManager.cancel) {
                        viewModel.cancelImport()
                        dismiss()
                    }
                }
            }
        }
    }
}

struct FileInfoSection: View {
    let preview: ImportPreview
    @EnvironmentObject var localizationManager: LocalizationManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "doc.text")
                    .foregroundColor(.blue)
                Text(localizationManager.currentLanguage == "en" ? "File Information" : "Thông Tin File")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            VStack(spacing: 8) {
                InfoRow(
                    label: localizationManager.currentLanguage == "en" ? "App Version" : "Phiên bản ứng dụng",
                    value: preview.metadata.version
                )
                InfoRow(
                    label: localizationManager.currentLanguage == "en" ? "Export Date" : "Ngày xuất",
                    value: DateFormatter.localizedString(from: preview.metadata.exportDate, dateStyle: .medium, timeStyle: .short)
                )
                InfoRow(
                    label: localizationManager.currentLanguage == "en" ? "Data Version" : "Phiên bản dữ liệu",
                    value: "\(preview.metadata.dataVersion)"
                )
                InfoRow(
                    label: localizationManager.currentLanguage == "en" ? "Device" : "Thiết bị",
                    value: "\(preview.metadata.deviceInfo.platform) \(preview.metadata.deviceInfo.osVersion)"
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct DataSummarySection: View {
    let preview: ImportPreview
    @EnvironmentObject var localizationManager: LocalizationManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.bar")
                    .foregroundColor(.green)
                Text(localizationManager.currentLanguage == "en" ? "Data Summary" : "Tổng Quan Dữ Liệu")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                SummaryCard(
                    title: localizationManager.currentLanguage == "en" ? "Total Roasts" : "Tổng Roast",
                    value: "\(preview.summary.totalRoasts)",
                    subtitle: localizationManager.currentLanguage == "en" ? "\(preview.summary.newRoasts) new" : "\(preview.summary.newRoasts) mới",
                    color: .orange
                )
                
                SummaryCard(
                    title: localizationManager.currentLanguage == "en" ? "Favorites" : "Yêu Thích",
                    value: "\(preview.summary.totalFavorites)",
                    subtitle: localizationManager.currentLanguage == "en" ? "\(preview.summary.newFavorites) new" : "\(preview.summary.newFavorites) mới",
                    color: .red
                )
            }
            
            if preview.summary.duplicateRoasts > 0 {
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(.orange)
                    Text(localizationManager.currentLanguage == "en" 
                         ? "\(preview.summary.duplicateRoasts) duplicate roasts found"
                         : "Tìm thấy \(preview.summary.duplicateRoasts) roast trùng lặp")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct ImportOptionsSection: View {
    @Binding var importStrategy: ImportStrategy
    @Binding var skipDuplicates: Bool
    @Binding var preserveExistingFavorites: Bool
    @EnvironmentObject var localizationManager: LocalizationManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "gear")
                    .foregroundColor(.purple)
                Text(localizationManager.currentLanguage == "en" ? "Import Options" : "Tùy Chọn Nhập")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            VStack(spacing: 12) {
                Picker(localizationManager.currentLanguage == "en" ? "Import Strategy" : "Chiến lược nhập", selection: $importStrategy) {
                    Text(localizationManager.currentLanguage == "en" ? "Merge with existing data" : "Gộp với dữ liệu hiện có")
                        .tag(ImportStrategy.merge)
                    Text(localizationManager.currentLanguage == "en" ? "Replace all existing data" : "Thay thế toàn bộ dữ liệu")
                        .tag(ImportStrategy.replace)
                }
                .pickerStyle(SegmentedPickerStyle())
                
                if importStrategy == .merge {
                    Toggle(isOn: $skipDuplicates) {
                        Text(localizationManager.currentLanguage == "en" ? "Skip duplicate roasts" : "Bỏ qua roast trùng lặp")
                            .font(.subheadline)
                    }
                    
                    Toggle(isOn: $preserveExistingFavorites) {
                        Text(localizationManager.currentLanguage == "en" ? "Keep existing favorites" : "Giữ danh sách yêu thích hiện có")
                            .font(.subheadline)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct WarningsSection: View {
    let warnings: [ImportWarning]
    @EnvironmentObject var localizationManager: LocalizationManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle")
                    .foregroundColor(.orange)
                Text(localizationManager.currentLanguage == "en" ? "Warnings" : "Cảnh Báo")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(warnings.prefix(5), id: \.message) { warning in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "exclamationmark.circle")
                            .foregroundColor(.orange)
                            .font(.caption)
                        Text(warning.message)
                            .font(.caption)
                            .foregroundColor(.orange)
                        Spacer()
                    }
                }
                
                if warnings.count > 5 {
                    Text(localizationManager.currentLanguage == "en" 
                         ? "... and \(warnings.count - 5) more warnings"
                         : "... và \(warnings.count - 5) cảnh báo khác")
                        .font(.caption2)
                        .foregroundColor(.orange)
                        .italic()
                }
            }
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
    }
}

struct PreferencesChangesSection: View {
    let changes: [String]
    @EnvironmentObject var localizationManager: LocalizationManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .foregroundColor(.blue)
                Text(localizationManager.currentLanguage == "en" ? "Settings Changes" : "Thay Đổi Cài Đặt")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                ForEach(changes, id: \.self) { change in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "arrow.right")
                            .foregroundColor(.blue)
                            .font(.caption)
                        Text(change)
                            .font(.caption)
                        Spacer()
                    }
                }
            }
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
    }
}

struct ActionButtonsSection: View {
    let isCompatible: Bool
    let onConfirm: () -> Void
    let onCancel: () -> Void
    @EnvironmentObject var localizationManager: LocalizationManager
    
    var body: some View {
        VStack(spacing: 12) {
            if !isCompatible {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text(localizationManager.currentLanguage == "en"
                         ? "This data may not be fully compatible with the current app version."
                         : "Dữ liệu này có thể không hoàn toàn tương thích với phiên bản ứng dụng hiện tại.")
                        .font(.caption)
                        .foregroundColor(.red)
                }
                .padding()
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
            }
            
            HStack(spacing: 12) {
                Button(action: onCancel) {
                    Text(localizationManager.cancel)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray5))
                        .foregroundColor(.primary)
                        .cornerRadius(10)
                }
                
                Button(action: onConfirm) {
                    Text(localizationManager.currentLanguage == "en" ? "Import Data" : "Nhập Dữ Liệu")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isCompatible ? Color.green : Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
        }
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
        }
    }
}

struct SummaryCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.primary)
            
            Text(subtitle)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
}

#Preview {
    ImportPreviewView(viewModel: SettingsViewModel())
        .environmentObject(LocalizationManager.shared)
}
