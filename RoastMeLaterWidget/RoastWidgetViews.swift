import SwiftUI
import WidgetKit

// MARK: - Main Entry View
struct RoastWidgetEntryView: View {
    @Environment(\.widgetFamily) var widgetFamily
    let entry: RoastWidgetEntry
    
    // App colors
    private let primaryColor = Color(red: 0.90, green: 0.22, blue: 0.27) // #E63946
    private let secondaryColor = Color(red: 0.11, green: 0.21, blue: 0.34) // #1D3557
    private let accentColor = Color(red: 0.96, green: 0.64, blue: 0.38) // #F4A261
    
    var body: some View {
        switch widgetFamily {
        case .systemSmall:
            SmallWidgetView(entry: entry, primaryColor: primaryColor, secondaryColor: secondaryColor)
        case .systemMedium:
            MediumWidgetView(entry: entry, primaryColor: primaryColor, secondaryColor: secondaryColor, accentColor: accentColor)
        case .systemLarge:
            LargeWidgetView(entry: entry, primaryColor: primaryColor, secondaryColor: secondaryColor, accentColor: accentColor)
        default:
            SmallWidgetView(entry: entry, primaryColor: primaryColor, secondaryColor: secondaryColor)
        }
    }
}

// MARK: - Small Widget (2x2)
struct SmallWidgetView: View {
    let entry: RoastWidgetEntry
    let primaryColor: Color
    let secondaryColor: Color
    
    var body: some View {
        ZStack {
            secondaryColor
            
            VStack(alignment: .leading, spacing: 8) {
                // Header
                HStack {
                    Image(systemName: "flame.fill")
                        .foregroundColor(primaryColor)
                        .font(.caption)
                    Text("RoastMe")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                // Roast preview
                Text(entry.roastData.roastOfTheDay)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.9))
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                // Streak
                HStack {
                    Image(systemName: "flame")
                        .foregroundColor(primaryColor)
                        .font(.caption2)
                    Text("\(entry.roastData.currentStreak)")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
            }
            .padding(12)
        }
        .widgetURL(URL(string: "roastmelater://open"))
    }
}

// MARK: - Medium Widget (4x2)
struct MediumWidgetView: View {
    let entry: RoastWidgetEntry
    let primaryColor: Color
    let secondaryColor: Color
    let accentColor: Color
    
    var body: some View {
        ZStack {
            secondaryColor
            
            HStack(spacing: 16) {
                // Left side - Roast content
                VStack(alignment: .leading, spacing: 8) {
                    // Header
                    HStack {
                        Image(systemName: "flame.fill")
                            .foregroundColor(primaryColor)
                        Text("Roast của ngày")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    
                    // Roast text
                    Text(entry.roastData.roastOfTheDay)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.9))
                        .lineLimit(4)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                    
                    // Category & Spice
                    HStack(spacing: 8) {
                        Image(systemName: entry.roastData.categoryIcon)
                            .font(.caption2)
                            .foregroundColor(accentColor)
                        
                        HStack(spacing: 2) {
                            ForEach(0..<entry.roastData.spiceLevel, id: \.self) { _ in
                                Image(systemName: "flame.fill")
                                    .font(.caption2)
                                    .foregroundColor(primaryColor)
                            }
                        }
                    }
                }
                
                // Right side - Streak
                VStack {
                    Spacer()
                    
                    VStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(.title2)
                            .foregroundColor(primaryColor)
                        
                        Text("\(entry.roastData.currentStreak)")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("ngày")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(12)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(12)
                    
                    Spacer()
                }
                .frame(width: 70)
            }
            .padding(16)
        }
        .widgetURL(URL(string: "roastmelater://open"))
    }
}

// MARK: - Large Widget (4x4)
struct LargeWidgetView: View {
    let entry: RoastWidgetEntry
    let primaryColor: Color
    let secondaryColor: Color
    let accentColor: Color

    var body: some View {
        ZStack {
            secondaryColor

            VStack(spacing: 16) {
                // Header
                HStack {
                    Image(systemName: "flame.fill")
                        .foregroundColor(primaryColor)
                        .font(.title3)
                    Text("RoastMeLater")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Spacer()

                    // Streak badge
                    HStack(spacing: 4) {
                        Image(systemName: "flame")
                            .foregroundColor(primaryColor)
                        Text("\(entry.roastData.currentStreak) ngày")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    }
                    .font(.caption)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.15))
                    .cornerRadius(12)
                }

                Divider()
                    .background(Color.white.opacity(0.2))

                // Main roast content
                VStack(spacing: 12) {
                    Text("🔥 Roast của ngày")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(accentColor)

                    Text(entry.roastData.roastOfTheDay)
                        .font(.body)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(6)
                        .padding(.horizontal, 8)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.white.opacity(0.08))
                .cornerRadius(16)

                Spacer()

                // Footer
                HStack {
                    // Category
                    HStack(spacing: 6) {
                        Image(systemName: entry.roastData.categoryIcon)
                            .font(.caption)
                        Text(categoryDisplayName)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(accentColor)

                    Spacer()

                    // Spice level
                    HStack(spacing: 3) {
                        ForEach(0..<entry.roastData.spiceLevel, id: \.self) { _ in
                            Image(systemName: "flame.fill")
                                .font(.caption)
                                .foregroundColor(primaryColor)
                        }
                        ForEach(0..<(5 - entry.roastData.spiceLevel), id: \.self) { _ in
                            Image(systemName: "flame")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.3))
                        }
                    }

                    Spacer()

                    // Date
                    Text(formattedDate)
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            .padding(20)
        }
        .widgetURL(URL(string: "roastmelater://open"))
    }

    private var categoryDisplayName: String {
        switch entry.roastData.category {
        case "deadlines": return "Deadline"
        case "meetings": return "Họp hành"
        case "kpis": return "KPI"
        case "code_reviews": return "Code Review"
        case "workload": return "Công việc"
        case "colleagues": return "Đồng nghiệp"
        case "management": return "Quản lý"
        default: return "Chung"
        }
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM"
        return formatter.string(from: entry.roastData.generatedDate)
    }
}

