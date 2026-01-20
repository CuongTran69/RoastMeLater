import Foundation

struct WidgetRoastData: Codable {
    let roastOfTheDay: String
    let category: String
    let categoryIcon: String
    let spiceLevel: Int
    let generatedDate: Date
    let currentStreak: Int
    
    static var placeholder: WidgetRoastData {
        WidgetRoastData(
            roastOfTheDay: "Bạn đẹp trai/xinh gái đến mức gương cũng phải ghen tị! 🔥",
            category: "general",
            categoryIcon: "flame.fill",
            spiceLevel: 3,
            generatedDate: Date(),
            currentStreak: 7
        )
    }
    
    static var empty: WidgetRoastData {
        WidgetRoastData(
            roastOfTheDay: "Chưa có roast nào. Mở app để tạo roast đầu tiên!",
            category: "general",
            categoryIcon: "flame.fill",
            spiceLevel: 1,
            generatedDate: Date(),
            currentStreak: 0
        )
    }
}

