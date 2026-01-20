import SwiftUI

/// Template types for generating shareable roast images
enum ShareTemplate: String, CaseIterable, Identifiable {
    case classic = "classic"
    case minimal = "minimal"
    case vibrant = "vibrant"
    case story = "story"      // 9:16 aspect ratio for Instagram Stories
    case square = "square"    // 1:1 aspect ratio for Instagram/Facebook
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .classic: return "Classic"
        case .minimal: return "Minimal"
        case .vibrant: return "Vibrant"
        case .story: return "Story"
        case .square: return "Square"
        }
    }
    
    var localizedName: String {
        switch self {
        case .classic: return "Cổ điển"
        case .minimal: return "Tối giản"
        case .vibrant: return "Sống động"
        case .story: return "Story"
        case .square: return "Vuông"
        }
    }
    
    var aspectRatio: CGFloat {
        switch self {
        case .classic, .minimal, .vibrant: return 4/3
        case .story: return 9/16
        case .square: return 1
        }
    }
    
    var size: CGSize {
        switch self {
        case .classic, .minimal, .vibrant: return CGSize(width: 400, height: 300)
        case .story: return CGSize(width: 1080, height: 1920)
        case .square: return CGSize(width: 1080, height: 1080)
        }
    }
    
    var backgroundColor: Color {
        switch self {
        case .classic: return Color(red: 0.11, green: 0.21, blue: 0.34) // Navy #1D3557
        case .minimal: return .white
        case .vibrant: return Color(red: 0.90, green: 0.22, blue: 0.27) // Crimson #E63946
        case .story: return Color(red: 0.11, green: 0.21, blue: 0.34)
        case .square: return Color(red: 0.90, green: 0.22, blue: 0.27)
        }
    }
    
    var textColor: Color {
        switch self {
        case .classic, .story: return .white
        case .minimal: return Color(red: 0.11, green: 0.21, blue: 0.34)
        case .vibrant, .square: return .white
        }
    }
    
    var accentColor: Color {
        switch self {
        case .classic, .story: return Color(red: 0.90, green: 0.22, blue: 0.27) // Crimson
        case .minimal: return Color(red: 0.90, green: 0.22, blue: 0.27)
        case .vibrant, .square: return Color(red: 0.96, green: 0.64, blue: 0.38) // Sand #F4A261
        }
    }
}

