import SwiftUI

struct PrivacyNoticeView: View {
    let privacyNotice: PrivacyNotice
    let complianceIssues: [ComplianceIssue]
    let onAccept: () -> Void
    let onCancel: () -> Void
    
    @EnvironmentObject var localizationManager: LocalizationManager
    @State private var hasReadNotice = false
    @State private var showingDetails = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "shield.checkered")
                            .font(.system(size: 50))
                            .foregroundColor(.blue)
                        
                        Text(privacyNotice.title)
                            .font(.title2.weight(.bold))
                            .multilineTextAlignment(.center)
                        
                        Text(privacyNotice.description)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    
                    // Data Types Section
                    DataTypesSection(dataTypes: privacyNotice.dataTypes)
                    
                    // Compliance Issues (if any)
                    if !complianceIssues.isEmpty {
                        ComplianceIssuesSection(issues: complianceIssues)
                    }
                    
                    // Recommendations
                    RecommendationsSection(recommendations: privacyNotice.recommendations)
                    
                    // Privacy Details (Expandable)
                    PrivacyDetailsSection(showingDetails: $showingDetails)
                    
                    // Acknowledgment
                    AcknowledgmentSection(hasReadNotice: $hasReadNotice)
                    
                    // Action Buttons
                    PrivacyActionButtonsSection(
                        hasReadNotice: hasReadNotice,
                        hasHighSeverityIssues: complianceIssues.contains { $0.severity == .high },
                        onAccept: onAccept,
                        onCancel: onCancel
                    )
                }
                .padding()
            }
            .navigationTitle(Strings.Privacy.privacyNotice.localized(localizationManager.currentLanguage))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(Strings.Common.cancel.localized(localizationManager.currentLanguage)) {
                        onCancel()
                    }
                }
            }
        }
    }
}

struct DataTypesSection: View {
    let dataTypes: [DataType]
    @EnvironmentObject var localizationManager: LocalizationManager

    private var currentLanguage: String { localizationManager.currentLanguage }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "doc.text")
                    .foregroundColor(.blue)
                Text(Strings.Privacy.dataIncluded.localized(currentLanguage))
                    .font(.headline.weight(.semibold))
            }

            VStack(spacing: 8) {
                ForEach(dataTypes, id: \.displayName) { dataType in
                    HStack(spacing: 12) {
                        // Sensitivity indicator
                        Circle()
                            .fill(colorForSensitivity(dataType.sensitivityLevel))
                            .frame(width: 8, height: 8)

                        Text(dataType.displayName)
                            .font(.subheadline)

                        Spacer()

                        Text(sensitivityText(dataType.sensitivityLevel))
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(colorForSensitivity(dataType.sensitivityLevel).opacity(0.2))
                            .foregroundColor(colorForSensitivity(dataType.sensitivityLevel))
                            .cornerRadius(4)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private func colorForSensitivity(_ level: SensitivityLevel) -> Color {
        switch level {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        }
    }

    private func sensitivityText(_ level: SensitivityLevel) -> String {
        switch level {
        case .low: return Strings.Privacy.low.localized(currentLanguage)
        case .medium: return Strings.Privacy.medium.localized(currentLanguage)
        case .high: return Strings.Privacy.high.localized(currentLanguage)
        }
    }
}

struct ComplianceIssuesSection: View {
    let issues: [ComplianceIssue]
    @EnvironmentObject var localizationManager: LocalizationManager

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle")
                    .foregroundColor(.orange)
                Text(Strings.Privacy.privacyConcerns.localized(localizationManager.currentLanguage))
                    .font(.headline.weight(.semibold))
            }

            VStack(spacing: 8) {
                ForEach(issues.indices, id: \.self) { index in
                    let issue = issues[index]
                    ComplianceIssueCard(issue: issue)
                }
            }
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
    }
}

struct ComplianceIssueCard: View {
    let issue: ComplianceIssue
    @EnvironmentObject var localizationManager: LocalizationManager

    private var currentLanguage: String { localizationManager.currentLanguage }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: severityIcon(issue.severity))
                    .foregroundColor(severityColor(issue.severity))

                Text(issue.description)
                    .font(.subheadline.weight(.medium))

                Spacer()

                Text(severityText(issue.severity))
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(severityColor(issue.severity).opacity(0.2))
                    .foregroundColor(severityColor(issue.severity))
                    .cornerRadius(4)
            }

            Text(issue.recommendation)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }

    private func severityIcon(_ severity: ComplianceSeverity) -> String {
        switch severity {
        case .low: return "info.circle"
        case .medium: return "exclamationmark.triangle"
        case .high: return "exclamationmark.octagon"
        }
    }

    private func severityColor(_ severity: ComplianceSeverity) -> Color {
        switch severity {
        case .low: return .blue
        case .medium: return .orange
        case .high: return .red
        }
    }

    private func severityText(_ severity: ComplianceSeverity) -> String {
        switch severity {
        case .low: return Strings.Privacy.low.localized(currentLanguage)
        case .medium: return Strings.Privacy.medium.localized(currentLanguage)
        case .high: return Strings.Privacy.high.localized(currentLanguage)
        }
    }
}

struct RecommendationsSection: View {
    let recommendations: [String]
    @EnvironmentObject var localizationManager: LocalizationManager

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb")
                    .foregroundColor(.yellow)
                Text(Strings.Privacy.recommendations.localized(localizationManager.currentLanguage))
                    .font(.headline.weight(.semibold))
            }

            VStack(alignment: .leading, spacing: 8) {
                ForEach(recommendations, id: \.self) { recommendation in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "checkmark.circle")
                            .foregroundColor(.green)
                            .font(.caption)

                        Text(recommendation)
                            .font(.subheadline)

                        Spacer()
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct PrivacyDetailsSection: View {
    @Binding var showingDetails: Bool
    @EnvironmentObject var localizationManager: LocalizationManager

    private var currentLanguage: String { localizationManager.currentLanguage }

    var body: some View {
        VStack(spacing: 8) {
            Button(action: { showingDetails.toggle() }) {
                HStack {
                    Text(Strings.Privacy.privacyDetails.localized(currentLanguage))
                        .font(.subheadline.weight(.medium))
                    Spacer()
                    Image(systemName: showingDetails ? "chevron.up" : "chevron.down")
                        .font(.caption)
                }
                .foregroundColor(.blue)
            }

            if showingDetails {
                VStack(alignment: .leading, spacing: 12) {
                    PrivacyDetailItem(
                        title: Strings.Privacy.dataProcessing.localized(currentLanguage),
                        description: Strings.Privacy.dataProcessingDesc.localized(currentLanguage)
                    )

                    PrivacyDetailItem(
                        title: Strings.Privacy.dataStorage.localized(currentLanguage),
                        description: Strings.Privacy.dataStorageDesc.localized(currentLanguage)
                    )

                    PrivacyDetailItem(
                        title: Strings.Privacy.thirdPartyAccess.localized(currentLanguage),
                        description: Strings.Privacy.thirdPartyAccessDesc.localized(currentLanguage)
                    )
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
        }
    }
}

struct PrivacyDetailItem: View {
    let title: String
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundColor(.blue)
            
            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct AcknowledgmentSection: View {
    @Binding var hasReadNotice: Bool
    @EnvironmentObject var localizationManager: LocalizationManager

    var body: some View {
        VStack(spacing: 12) {
            Toggle(isOn: $hasReadNotice) {
                Text(Strings.Privacy.acknowledgment.localized(localizationManager.currentLanguage))
                    .font(.subheadline)
            }
            .toggleStyle(CheckboxToggleStyle())
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct PrivacyActionButtonsSection: View {
    let hasReadNotice: Bool
    let hasHighSeverityIssues: Bool
    let onAccept: () -> Void
    let onCancel: () -> Void

    @EnvironmentObject var localizationManager: LocalizationManager

    private var currentLanguage: String { localizationManager.currentLanguage }

    var body: some View {
        VStack(spacing: 12) {
            if hasHighSeverityIssues {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text(Strings.Privacy.highRiskWarning.localized(currentLanguage))
                        .font(.caption)
                        .foregroundColor(.red)
                }
                .padding()
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
            }

            HStack(spacing: 12) {
                Button(action: onCancel) {
                    Text(Strings.Common.cancel.localized(currentLanguage))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray5))
                        .foregroundColor(.primary)
                        .cornerRadius(10)
                }

                Button(action: onAccept) {
                    Text(Strings.Privacy.continueExport.localized(currentLanguage))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(hasReadNotice ? (hasHighSeverityIssues ? Color.orange : Color.green) : Color(.systemGray4))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(!hasReadNotice)
            }
        }
    }
}

struct CheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                .foregroundColor(configuration.isOn ? .blue : .gray)
                .onTapGesture {
                    configuration.isOn.toggle()
                }
            
            configuration.label
        }
    }
}

#Preview {
    PrivacyNoticeView(
        privacyNotice: PrivacyNotice(
            title: "Thông Báo Quyền Riêng Tư",
            description: "File xuất này chứa dữ liệu cá nhân của bạn.",
            dataTypes: [.roastContent, .userPreferences, .apiConfiguration],
            recommendations: ["Xem lại nội dung trước khi chia sẻ", "Không tải lên dịch vụ công cộng"]
        ),
        complianceIssues: [
            ComplianceIssue(
                type: .sensitiveDataIncluded,
                severity: .high,
                description: "API key được bao gồm",
                recommendation: "Xem xét loại bỏ API key"
            )
        ],
        onAccept: {},
        onCancel: {}
    )
    .environmentObject(LocalizationManager.shared)
}
