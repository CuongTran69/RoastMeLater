import SwiftUI

struct ErrorRecoveryView: View {
    let error: Error
    let context: ErrorContext
    let recoveryOptions: [ErrorRecoveryOption]
    let onRecovery: (ErrorRecoveryStrategy) -> Void
    let onDismiss: () -> Void
    
    @EnvironmentObject var localizationManager: LocalizationManager
    @State private var selectedOption: ErrorRecoveryOption?
    @State private var showingDetails = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Error Icon and Title
            VStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.red)
                
                Text(Strings.Errors.operationFailed.localized(localizationManager.currentLanguage))
                    .font(.title2.weight(.bold))
                
                Text(error.localizedDescription)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
            }
            
            // Error Details (Expandable)
            VStack(spacing: 8) {
                Button(action: { showingDetails.toggle() }) {
                    HStack {
                        Text(Strings.Errors.errorDetails.localized(localizationManager.currentLanguage))
                            .font(.subheadline.weight(.medium))
                        Spacer()
                        Image(systemName: showingDetails ? "chevron.up" : "chevron.down")
                            .font(.caption)
                    }
                    .foregroundColor(.blue)
                }
                
                if showingDetails {
                    VStack(alignment: .leading, spacing: 8) {
                        ErrorDetailRow(
                            label: Strings.Errors.operation.localized(localizationManager.currentLanguage),
                            value: operationDisplayName(context.operation)
                        )
                        ErrorDetailRow(
                            label: Strings.Errors.phase.localized(localizationManager.currentLanguage),
                            value: context.phase
                        )
                        ErrorDetailRow(
                            label: Strings.Errors.progress.localized(localizationManager.currentLanguage),
                            value: "\(context.itemsProcessed)/\(context.totalItems)"
                        )
                        ErrorDetailRow(
                            label: Strings.Errors.time.localized(localizationManager.currentLanguage),
                            value: DateFormatter.localizedString(from: context.timestamp, dateStyle: .none, timeStyle: .medium)
                        )

                        if let managementError = error as? DataManagementError,
                           let suggestion = managementError.recoverySuggestion {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(Strings.Errors.suggestion.localized(localizationManager.currentLanguage))
                                    .font(.caption.weight(.semibold))
                                    .foregroundColor(.blue)
                                Text(suggestion)
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                            .padding(.top, 4)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
            }
            
            // Recovery Options
            if !recoveryOptions.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text(Strings.Errors.whatToDo.localized(localizationManager.currentLanguage))
                        .font(.headline.weight(.semibold))
                    
                    VStack(spacing: 8) {
                        ForEach(recoveryOptions.indices, id: \.self) { index in
                            let option = recoveryOptions[index]
                            RecoveryOptionCard(
                                option: option,
                                isSelected: selectedOption?.strategy == option.strategy,
                                onSelect: { selectedOption = option }
                            )
                        }
                    }
                }
            }
            
            // Action Buttons
            HStack(spacing: 12) {
                Button(action: onDismiss) {
                    Text(Strings.Common.cancel.localized(localizationManager.currentLanguage))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray5))
                        .foregroundColor(.primary)
                        .cornerRadius(10)
                }
                
                if let selectedOption = selectedOption {
                    Button(action: { onRecovery(selectedOption.strategy) }) {
                        Text(selectedOption.title)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(selectedOption.isRecommended ? Color.blue : Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                } else if let defaultOption = recoveryOptions.first(where: { $0.isRecommended }) ?? recoveryOptions.first {
                    Button(action: { onRecovery(defaultOption.strategy) }) {
                        Text(defaultOption.title)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(defaultOption.isRecommended ? Color.blue : Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 10)
        .onAppear {
            // Auto-select recommended option
            selectedOption = recoveryOptions.first(where: { $0.isRecommended })
        }
    }
    
    private func operationDisplayName(_ operation: DataOperation) -> String {
        switch operation {
        case .export:
            return Strings.Errors.exportData.localized(localizationManager.currentLanguage)
        case .dataImport:
            return Strings.Errors.importData.localized(localizationManager.currentLanguage)
        case .validation:
            return Strings.Errors.dataValidation.localized(localizationManager.currentLanguage)
        }
    }
}

struct RecoveryOptionCard: View {
    let option: ErrorRecoveryOption
    let isSelected: Bool
    let onSelect: () -> Void

    @EnvironmentObject var localizationManager: LocalizationManager

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                // Selection indicator
                ZStack {
                    Circle()
                        .stroke(isSelected ? Color.blue : Color(.systemGray4), lineWidth: 2)
                        .frame(width: 20, height: 20)

                    if isSelected {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 12, height: 12)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(option.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.primary)

                        if option.isRecommended {
                            Text(Strings.Errors.recommended.localized(localizationManager.currentLanguage))
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.2))
                                .foregroundColor(.blue)
                                .cornerRadius(4)
                        }

                        Spacer()
                    }

                    Text(option.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }

                Spacer()
            }
            .padding()
            .background(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ErrorDetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 80, alignment: .leading)
            
            Text(value)
                .font(.caption.weight(.medium))
            
            Spacer()
        }
    }
}

// MARK: - Error Alert Modifier

struct ErrorRecoveryAlert: ViewModifier {
    @Binding var error: DataManagementError?
    let context: ErrorContext?
    let onRecovery: (ErrorRecoveryStrategy) -> Void
    
    @State private var recoveryOptions: [ErrorRecoveryOption] = []
    private let errorHandler = DataErrorHandler()
    
    func body(content: Content) -> some View {
        content
            .overlay(
                Group {
                    if let error = error, let context = context {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()
                            .onTapGesture {
                                self.error = nil
                            }
                        
                        ErrorRecoveryView(
                            error: error,
                            context: context,
                            recoveryOptions: recoveryOptions,
                            onRecovery: { strategy in
                                onRecovery(strategy)
                                self.error = nil
                            },
                            onDismiss: {
                                self.error = nil
                            }
                        )
                        .padding(.horizontal, 20)
                    }
                }
            )
            .onChange(of: error) { newError in
                if let error = newError, let context = context {
                    recoveryOptions = errorHandler.getRecoveryOptions(for: error, context: context)
                }
            }
    }
}

extension View {
    func errorRecoveryAlert(
        error: Binding<DataManagementError?>,
        context: ErrorContext?,
        onRecovery: @escaping (ErrorRecoveryStrategy) -> Void
    ) -> some View {
        modifier(ErrorRecoveryAlert(error: error, context: context, onRecovery: onRecovery))
    }
}

#Preview {
    VStack {
        Text("Main Content")
    }
    .errorRecoveryAlert(
        error: .constant(DataManagementError.exportInsufficientStorage(required: 1000000, available: 500000)),
        context: ErrorContext(
            operation: .export,
            phase: "writing",
            itemsProcessed: 50,
            totalItems: 100,
            timestamp: Date(),
            additionalInfo: [:]
        ),
        onRecovery: { strategy in
            print("Recovery strategy: \(strategy)")
        }
    )
    .environmentObject(LocalizationManager.shared)
}
