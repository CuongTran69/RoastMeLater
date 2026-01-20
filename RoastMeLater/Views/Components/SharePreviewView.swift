import SwiftUI

struct SharePreviewView: View {
    let roast: Roast
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var localizationManager: LocalizationManager
    
    @State private var selectedTemplate: ShareTemplate = .classic
    @State private var showingShareSheet = false
    @State private var shareImage: UIImage?
    
    private let sharingService = SocialSharingService.shared
    
    private let primaryColor = Color(red: 0.90, green: 0.22, blue: 0.27)
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(ShareTemplate.allCases) { template in
                            TemplateButton(
                                template: template,
                                isSelected: selectedTemplate == template,
                                action: { selectedTemplate = template }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                
                ShareableRoastView(roast: roast, template: selectedTemplate)
                    .frame(width: previewWidth, height: previewHeight)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                
                Spacer()
                
                Button(action: shareAction) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text(localizationManager.currentLanguage == "vi" ? "Chia sẻ" : "Share")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(primaryColor)
                    .cornerRadius(12)
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
            .navigationTitle(localizationManager.currentLanguage == "vi" ? "Chia sẻ Roast" : "Share Roast")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Text(localizationManager.currentLanguage == "vi" ? "Xong" : "Done")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(primaryColor)
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                if let image = shareImage {
                    ShareSheet(activityItems: [image, sharingService.createShareText(for: roast)])
                }
            }
        }
    }
    
    private var previewWidth: CGFloat {
        min(UIScreen.main.bounds.width - 40, 350)
    }
    
    private var previewHeight: CGFloat {
        previewWidth / selectedTemplate.aspectRatio
    }
    
    @MainActor
    private func shareAction() {
        shareImage = sharingService.generateShareImage(for: roast, template: selectedTemplate)
        showingShareSheet = true
    }
}

struct TemplateButton: View {
    let template: ShareTemplate
    let isSelected: Bool
    let action: () -> Void
    
    private let primaryColor = Color(red: 0.90, green: 0.22, blue: 0.27)
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(template.backgroundColor)
                    .frame(width: 50, height: 40)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isSelected ? primaryColor : Color.clear, lineWidth: 2)
                    )
                
                Text(template.localizedName)
                    .font(.caption2)
                    .foregroundColor(isSelected ? primaryColor : .secondary)
            }
        }
    }
}

#Preview {
    SharePreviewView(roast: Roast(
        content: "Bạn đẹp trai/xinh gái đến mức gương cũng phải ghen tị! 🔥",
        category: .general,
        spiceLevel: 3
    ))
    .environmentObject(LocalizationManager.shared)
}

