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
                            .font(.title2)
                            .fontWeight(.bold)
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
                    ActionButtonsSection(
                        hasReadNotice: hasReadNotice,
                        hasHighSeverityIssues: complianceIssues.contains { $0.severity == .high },
                        onAccept: onAccept,
                        onCancel: onCancel
                    )
                }
                .padding()
            }
            .navigationTitle(localizationManager.currentLanguage == "en" ? "Privacy Notice" : "Thông Báo Quyền Riêng Tư")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(localizationManager.cancel) {
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "doc.text")
                    .foregroundColor(.blue)
                Text(localizationManager.currentLanguage == "en" ? "Data Included" : "Dữ Liệu Được Bao Gồm")
                    .font(.headline)
                    .fontWeight(.semibold)
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
        case .low: return localizationManager.currentLanguage == "en" ? "Low" : "Thấp"
        case .medium: return localizationManager.currentLanguage == "en" ? "Medium" : "Trung bình"
        case .high: return localizationManager.currentLanguage == "en" ? "High" : "Cao"
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
                Text(localizationManager.currentLanguage == "en" ? "Privacy Concerns" : "Vấn Đề Quyền Riêng Tư")
                    .font(.headline)
                    .fontWeight(.semibold)
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: severityIcon(issue.severity))
                    .foregroundColor(severityColor(issue.severity))
                
                Text(issue.description)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
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
        case .low: return localizationManager.currentLanguage == "en" ? "Low" : "Thấp"
        case .medium: return localizationManager.currentLanguage == "en" ? "Medium" : "Trung bình"
        case .high: return localizationManager.currentLanguage == "en" ? "High" : "Cao"
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
                Text(localizationManager.currentLanguage == "en" ? "Recommendations" : "Khuyến Nghị")
                    .font(.headline)
                    .fontWeight(.semibold)
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
    
    var body: some View {
        VStack(spacing: 8) {
            Button(action: { showingDetails.toggle() }) {
                HStack {
                    Text(localizationManager.currentLanguage == "en" ? "Privacy Details" : "Chi Tiết Quyền Riêng Tư")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Spacer()
                    Image(systemName: showingDetails ? "chevron.up" : "chevron.down")
                        .font(.caption)
                }
                .foregroundColor(.blue)
            }
            
            if showingDetails {
                VStack(alignment: .leading, spacing: 12) {
                    PrivacyDetailItem(
                        title: localizationManager.currentLanguage == "en" ? "Data Processing" : "Xử Lý Dữ Liệu",
                        description: localizationManager.currentLanguage == "en" 
                            ? "Data is processed locally on your device and exported as a JSON file."
                            : "Dữ liệu được xử lý cục bộ trên thiết bị của bạn và xuất dưới dạng file JSON."
                    )
                    
                    PrivacyDetailItem(
                        title: localizationManager.currentLanguage == "en" ? "Data Storage" : "Lưu Trữ Dữ Liệu",
                        description: localizationManager.currentLanguage == "en"
                            ? "Exported files are stored in your device's Files app and can be shared manually."
                            : "File đã xuất được lưu trong ứng dụng Files của thiết bị và có thể được chia sẻ thủ công."
                    )
                    
                    PrivacyDetailItem(
                        title: localizationManager.currentLanguage == "en" ? "Third-Party Access" : "Truy Cập Bên Thứ Ba",
                        description: localizationManager.currentLanguage == "en"
                            ? "No data is automatically sent to third parties. You control all sharing."
                            : "Không có dữ liệu nào được tự động gửi đến bên thứ ba. Bạn kiểm soát mọi việc chia sẻ."
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
                .font(.caption)
                .fontWeight(.semibold)
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
                Text(localizationManager.currentLanguage == "en"
                     ? "I have read and understand this privacy notice"
                     : "Tôi đã đọc và hiểu thông báo quyền riêng tư này")
                    .font(.subheadline)
            }
            .toggleStyle(CheckboxToggleStyle())
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct ActionButtonsSection: View {
    let hasReadNotice: Bool
    let hasHighSeverityIssues: Bool
    let onAccept: () -> Void
    let onCancel: () -> Void
    
    @EnvironmentObject var localizationManager: LocalizationManager
    
    var body: some View {
        VStack(spacing: 12) {
            if hasHighSeverityIssues {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text(localizationManager.currentLanguage == "en"
                         ? "High-risk privacy issues detected. Consider reviewing export options."
                         : "Phát hiện vấn đề quyền riêng tư rủi ro cao. Xem xét lại tùy chọn xuất.")
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
                
                Button(action: onAccept) {
                    Text(localizationManager.currentLanguage == "en" ? "Continue Export" : "Tiếp Tục Xuất")
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
