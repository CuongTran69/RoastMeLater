import SwiftUI

struct ExportOptionsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    @EnvironmentObject var localizationManager: LocalizationManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var includeAPIConfiguration = false
    @State private var includeDeviceInfo = true
    @State private var includeStatistics = true
    @State private var anonymizeData = false
    
    private var currentLanguage: String {
        localizationManager.currentLanguage
    }

    var body: some View {
        NavigationView {
            Form {
                Section {
                    Text(Strings.DataManagement.Export.optionsDescription.localized(currentLanguage))
                        .font(.caption)
                        .foregroundColor(.secondary)
                } header: {
                    Text(Strings.DataManagement.Export.options.localized(currentLanguage))
                }

                Section {
                    Toggle(isOn: $includeAPIConfiguration) {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Image(systemName: "key.fill")
                                    .foregroundColor(.orange)
                                Text(Strings.DataManagement.Export.apiConfiguration.localized(currentLanguage))
                                    .font(.body.weight(.medium))
                            }
                            Text(Strings.DataManagement.Export.includeAPIKeys.localized(currentLanguage))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Toggle(isOn: $includeDeviceInfo) {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Image(systemName: "iphone")
                                    .foregroundColor(.blue)
                                Text(Strings.DataManagement.Export.deviceInformation.localized(currentLanguage))
                                    .font(.body.weight(.medium))
                            }
                            Text(Strings.DataManagement.Export.includeDeviceInfo.localized(currentLanguage))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Toggle(isOn: $includeStatistics) {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Image(systemName: "chart.bar")
                                    .foregroundColor(.green)
                                Text(Strings.DataManagement.Export.usageStatistics.localized(currentLanguage))
                                    .font(.body.weight(.medium))
                            }
                            Text(Strings.DataManagement.Export.includeStats.localized(currentLanguage))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Toggle(isOn: $anonymizeData) {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Image(systemName: "eye.slash")
                                    .foregroundColor(.purple)
                                Text(Strings.DataManagement.Export.anonymizeData.localized(currentLanguage))
                                    .font(.body.weight(.medium))
                            }
                            Text(Strings.DataManagement.Export.anonymizeDescription.localized(currentLanguage))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text(Strings.DataManagement.Export.dataToInclude.localized(currentLanguage))
                }

                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundColor(.blue)
                            Text(Strings.DataManagement.Export.whatsIncluded.localized(currentLanguage))
                                .font(.body.weight(.semibold))
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            BulletPoint(text: Strings.DataManagement.Export.allRoastHistory.localized(currentLanguage))
                            BulletPoint(text: Strings.DataManagement.Export.favoritesList.localized(currentLanguage))
                            BulletPoint(text: Strings.DataManagement.Export.userPreferences.localized(currentLanguage))
                            BulletPoint(text: Strings.DataManagement.Export.exportMetadata.localized(currentLanguage))
                        }
                    }
                } header: {
                    Text(Strings.DataManagement.Export.details.localized(currentLanguage))
                }

                Section {
                    if includeAPIConfiguration {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(Strings.DataManagement.Export.securityWarning.localized(currentLanguage))
                                    .font(.body.weight(.semibold))
                                    .foregroundColor(.red)
                                Text(Strings.DataManagement.Export.apiKeyWarning.localized(currentLanguage))
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
                                Text(Strings.DataManagement.Export.anonymizationNote.localized(currentLanguage))
                                    .font(.body.weight(.semibold))
                                    .foregroundColor(.blue)
                                Text(Strings.DataManagement.Export.anonymizationDescription.localized(currentLanguage))
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
            .navigationTitle(Strings.DataManagement.Export.options.localized(currentLanguage))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(Strings.Common.cancel.localized(currentLanguage)) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(Strings.DataManagement.Export.exportButton.localized(currentLanguage)) {
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
