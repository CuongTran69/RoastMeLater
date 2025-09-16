import Foundation

struct Roast: Codable, Identifiable, Equatable {
    let id: UUID
    let content: String
    let category: RoastCategory
    let spiceLevel: Int
    let language: String
    let createdAt: Date
    var isFavorite: Bool
    
    init(content: String, category: RoastCategory, spiceLevel: Int, language: String = "vi") {
        self.id = UUID()
        self.content = content
        self.category = category
        self.spiceLevel = spiceLevel
        self.language = language
        self.createdAt = Date()
        self.isFavorite = false
    }

    // Full initializer for creating instances with all properties
    init(id: UUID, content: String, category: RoastCategory, spiceLevel: Int, language: String, createdAt: Date, isFavorite: Bool) {
        self.id = id
        self.content = content
        self.category = category
        self.spiceLevel = spiceLevel
        self.language = language
        self.createdAt = createdAt
        self.isFavorite = isFavorite
    }
    
    // For preview and testing
    static let sample = Roast(
        content: "Bạn làm việc chăm chỉ như một con ốc sên đang thi chạy marathon!",
        category: .deadlines,
        spiceLevel: 2
    )
    
    static let samples = [
        Roast(content: "Meeting của bạn dài hơn cả phim Titanic, nhưng ít drama hơn!", category: .meetings, spiceLevel: 3),
        Roast(content: "KPI của bạn như WiFi nhà hàng xóm - luôn yếu và không ổn định!", category: .kpis, spiceLevel: 4),
        Roast(content: "Code review của bạn như đi khám bệnh - ai cũng sợ nhưng cần thiết!", category: .codeReviews, spiceLevel: 2),
        Roast(content: "Deadline của bạn như lời hứa của chính trị gia - nghe hay nhưng khó tin!", category: .deadlines, spiceLevel: 5)
    ]
}
