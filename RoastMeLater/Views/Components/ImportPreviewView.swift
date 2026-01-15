import SwiftUI

struct ImportPreviewView: View {
    @ObservedObject var viewModel: SettingsViewModel
    @EnvironmentObject var localizationManager: LocalizationManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var importStrategy: ImportStrategy = .merge
    @State private var skipDuplicates = true
    @State private var preserveExistingFavorites = true
    @State private var allowPartialImport = true
    @State private var maxErrorsAllowed = 10
    
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
                            preserveExistingFavorites: $preserveExistingFavorites,
                            allowPartialImport: $allowPartialImport,
                            maxErrorsAllowed: $maxErrorsAllowed
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
                                    preserveExistingFavorites: preserveExistingFavorites,
                                    allowPartialImport: allowPartialImport,
                                    maxErrorsAllowed: maxErrorsAllowed
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
            .navigationTitle(Strings.DataManagement.Import.preview.localized(localizationManager.currentLanguage))
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
                Text(Strings.DataManagement.Import.fileInformation.localized(localizationManager.currentLanguage))
                    .font(.headline.weight(.semibold))
            }

            VStack(spacing: 8) {
                InfoRow(
                    label: Strings.DataManagement.Import.appVersion.localized(localizationManager.currentLanguage),
                    value: preview.metadata.version
                )
                InfoRow(
                    label: Strings.DataManagement.Import.exportDate.localized(localizationManager.currentLanguage),
                    value: DateFormatter.localizedString(from: preview.metadata.exportDate, dateStyle: .medium, timeStyle: .short)
                )
                InfoRow(
                    label: Strings.DataManagement.Import.dataVersion.localized(localizationManager.currentLanguage),
                    value: "\(preview.metadata.dataVersion)"
                )
                InfoRow(
                    label: Strings.DataManagement.Import.device.localized(localizationManager.currentLanguage),
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
                Text(Strings.DataManagement.Import.dataSummary.localized(localizationManager.currentLanguage))
                    .font(.headline.weight(.semibold))
            }

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                SummaryCard(
                    title: Strings.DataManagement.totalRoasts.localized(localizationManager.currentLanguage),
                    value: "\(preview.summary.totalRoasts)",
                    subtitle: Strings.Common.newItems(preview.summary.newRoasts).localized(localizationManager.currentLanguage),
                    color: .orange
                )

                SummaryCard(
                    title: Strings.DataManagement.favorites.localized(localizationManager.currentLanguage),
                    value: "\(preview.summary.totalFavorites)",
                    subtitle: Strings.Common.newItems(preview.summary.newFavorites).localized(localizationManager.currentLanguage),
                    color: .red
                )
            }

            if preview.summary.duplicateRoasts > 0 {
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(.orange)
                    Text(Strings.DataManagement.Import.duplicatesFound(preview.summary.duplicateRoasts).localized(localizationManager.currentLanguage))
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
    @Binding var allowPartialImport: Bool
    @Binding var maxErrorsAllowed: Int
    @EnvironmentObject var localizationManager: LocalizationManager

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "gear")
                    .foregroundColor(.purple)
                Text(Strings.DataManagement.Import.options.localized(localizationManager.currentLanguage))
                    .font(.headline.weight(.semibold))
            }

            VStack(spacing: 12) {
                Picker(Strings.DataManagement.Import.strategy.localized(localizationManager.currentLanguage), selection: $importStrategy) {
                    Text(Strings.DataManagement.Import.mergeWithExisting.localized(localizationManager.currentLanguage))
                        .tag(ImportStrategy.merge)
                    Text(Strings.DataManagement.Import.replaceAll.localized(localizationManager.currentLanguage))
                        .tag(ImportStrategy.replace)
                }
                .pickerStyle(SegmentedPickerStyle())

                if importStrategy == .merge {
                    Toggle(isOn: $skipDuplicates) {
                        Text(Strings.DataManagement.Import.skipDuplicates.localized(localizationManager.currentLanguage))
                            .font(.subheadline)
                    }

                    Toggle(isOn: $preserveExistingFavorites) {
                        Text(Strings.DataManagement.Import.keepExistingFavorites.localized(localizationManager.currentLanguage))
                            .font(.subheadline)
                    }
                }

                Divider()

                Toggle(isOn: $allowPartialImport) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(Strings.DataManagement.Import.allowPartialImport.localized(localizationManager.currentLanguage))
                            .font(.subheadline)
                        Text(Strings.DataManagement.Import.allowPartialImportDesc.localized(localizationManager.currentLanguage))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                if allowPartialImport {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(Strings.DataManagement.Import.maxErrorsAllowed(maxErrorsAllowed).localized(localizationManager.currentLanguage))
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Stepper("", value: $maxErrorsAllowed, in: 1...100)
                            .labelsHidden()
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
                Text(Strings.DataManagement.Import.warnings.localized(localizationManager.currentLanguage))
                    .font(.headline.weight(.semibold))
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
                    Text(Strings.DataManagement.Import.moreWarnings(warnings.count - 5).localized(localizationManager.currentLanguage))
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
                Text(Strings.DataManagement.Import.settingsChanges.localized(localizationManager.currentLanguage))
                    .font(.headline.weight(.semibold))
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
                    Text(Strings.DataManagement.Import.incompatibleWarning.localized(localizationManager.currentLanguage))
                        .font(.caption)
                        .foregroundColor(.red)
                }
                .padding()
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
            }

            HStack(spacing: 12) {
                Button(action: onCancel) {
                    Text(Strings.Common.cancel.localized(localizationManager.currentLanguage))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray5))
                        .foregroundColor(.primary)
                        .cornerRadius(10)
                }

                Button(action: onConfirm) {
                    Text(Strings.DataManagement.Import.title.localized(localizationManager.currentLanguage))
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
                .font(.caption.weight(.medium))
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
                .font(.title2.weight(.bold))
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
