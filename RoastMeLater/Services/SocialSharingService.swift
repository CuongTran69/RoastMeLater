import SwiftUI
import UIKit

/// Service for generating branded shareable images from roasts
class SocialSharingService {
    static let shared = SocialSharingService()
    
    private init() {}
    
    /// Generate a shareable image for a roast using the specified template
    @MainActor
    func generateShareImage(for roast: Roast, template: ShareTemplate) -> UIImage? {
        let view = ShareableRoastView(roast: roast, template: template)
        
        if #available(iOS 16.0, *) {
            let renderer = ImageRenderer(content: view)
            renderer.scale = UIScreen.main.scale
            return renderer.uiImage
        } else {
            return renderViewToImage(view: view, size: template.size)
        }
    }
    
    private func renderViewToImage<V: View>(view: V, size: CGSize) -> UIImage? {
        let controller = UIHostingController(rootView: view)
        controller.view.bounds = CGRect(origin: .zero, size: size)
        controller.view.backgroundColor = .clear
        
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            controller.view.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
        }
    }
    
    func getAvailableTemplates() -> [ShareTemplate] {
        return ShareTemplate.allCases
    }
    
    @MainActor
    func createShareItems(for roast: Roast, template: ShareTemplate, includeText: Bool = true) -> [Any] {
        var items: [Any] = []
        
        if let image = generateShareImage(for: roast, template: template) {
            items.append(image)
        }
        
        if includeText {
            let shareText = createShareText(for: roast)
            items.append(shareText)
        }
        
        return items
    }
    
    func createShareText(for roast: Roast) -> String {
        let categoryName = roast.category.displayName
        let spiceEmoji = String(repeating: "🌶️", count: roast.spiceLevel)
        
        return """
        🔥 RoastMeLater - \(categoryName)
        
        \(roast.content)
        
        Mức độ cay: \(spiceEmoji)
        
        #RoastMeLater #AIRoast
        """
    }
}

// MARK: - ShareableRoastView
struct ShareableRoastView: View {
    let roast: Roast
    let template: ShareTemplate
    
    var body: some View {
        ZStack {
            template.backgroundColor
            
            VStack(spacing: 16) {
                headerView
                Spacer()
                roastContentView
                Spacer()
                footerView
            }
            .padding(24)
        }
        .frame(width: template.size.width, height: template.size.height)
    }
    
    private var headerView: some View {
        HStack {
            Image(systemName: "flame.fill")
                .font(.title2)
                .foregroundColor(template.accentColor)
            
            Text("RoastMeLater")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(template.textColor)
            
            Spacer()
        }
    }
    
    private var roastContentView: some View {
        Text(roast.content)
            .font(contentFont)
            .fontWeight(.medium)
            .foregroundColor(template.textColor)
            .multilineTextAlignment(.center)
            .lineSpacing(4)
            .padding(.horizontal, 8)
    }
    
    private var footerView: some View {
        HStack {
            HStack(spacing: 4) {
                Image(systemName: roast.category.icon)
                    .font(.caption)
                Text(roast.category.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundColor(template.accentColor)
            
            Spacer()
            
            HStack(spacing: 2) {
                ForEach(0..<roast.spiceLevel, id: \.self) { _ in
                    Image(systemName: "flame.fill")
                        .font(.caption)
                        .foregroundColor(template.accentColor)
                }
            }
        }
    }
    
    private var contentFont: Font {
        switch template {
        case .story: return .title2
        case .square: return .title3
        default: return .body
        }
    }
}

// MARK: - Preview
#Preview {
    let sampleRoast = Roast(
        content: "Bạn đẹp trai/xinh gái đến mức gương cũng phải ghen tị! Nhưng mà não thì... để sau nhé! 🔥",
        category: .general,
        spiceLevel: 3
    )
    
    return VStack(spacing: 20) {
        ShareableRoastView(roast: sampleRoast, template: .classic)
            .frame(width: 300, height: 225)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        
        ShareableRoastView(roast: sampleRoast, template: .vibrant)
            .frame(width: 300, height: 225)
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    .padding()
}

