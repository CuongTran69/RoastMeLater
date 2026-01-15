import Foundation

// MARK: - Roast Generator Strings

extension Strings {
    enum RoastGenerator {
        // Header
        static let title = L("RoastMe", "RoastMe")
        
        // Category Selection
        static let category = L("Category", "Danh mục")
        static let selectCategory = L("Select Category", "Chọn Danh Mục")
        
        // Spice Level
        static let spiceLevel = L("Spice Level", "Mức độ cay")
        static let mild = L("Mild", "Nhẹ nhàng")
        static let light = L("Light", "Nhẹ")
        static let medium = L("Medium", "Trung bình")
        static let spicy = L("Spicy", "Cay nồng")
        static let extraHot = L("Extra Hot", "Cực cay")
        
        // Generate Button
        static let generateRoast = L("Generate New Roast", "Tạo Roast Mới")
        static let generating = L("Generating...", "Đang tạo...")
        
        // Placeholder
        static let placeholderText = L(
            "Choose category and spice level, then tap generate roast!",
            "Chọn danh mục và mức độ cay, sau đó nhấn tạo roast!"
        )
        
        // Actions
        static let addToFavorites = L("Add to Favorites", "Thêm vào yêu thích")
        static let removeFromFavorites = L("Remove from Favorites", "Xóa khỏi yêu thích")
        static let copyRoast = L("Copy Roast", "Sao chép Roast")
        static let shareRoast = L("Share Roast", "Chia sẻ Roast")

        // Roast Card
        static let yourRoast = L("Your roast:", "Roast của bạn:")
        static let liked = L("Liked", "Đã thích")
        static let like = L("Like", "Thích")
        static let selected = L("Selected", "Đã chọn")

        // Category Picker
        static let categoryPickerSubtitle = L("Choose the work situation you want to be roasted about", "Chọn tình huống công việc bạn muốn được roast")
        
        // Categories
        enum Categories {
            static let general = L("General", "Chung")
            static let generalDesc = L("General workplace humor", "Hài hước chung về công việc")

            static let deadlines = L("Deadlines", "Deadline")
            static let deadlinesDesc = L("About missing deadlines", "Về việc trễ deadline")

            static let meetings = L("Meetings", "Họp hành")
            static let meetingsDesc = L("Meeting and discussion humor", "Hài hước về họp hành")

            static let kpis = L("KPIs", "KPI")
            static let kpisDesc = L("Performance metrics jokes", "Đùa về chỉ số hiệu suất")

            static let codeReviews = L("Code Reviews", "Code Review")
            static let codeReviewsDesc = L("Code review and programming", "Code review và lập trình")

            static let workload = L("Workload", "Khối lượng công việc")
            static let workloadDesc = L("Work overload and stress", "Quá tải công việc và stress")

            static let colleagues = L("Colleagues", "Đồng nghiệp")
            static let colleaguesDesc = L("Colleagues and work environment", "Đồng nghiệp và môi trường làm việc")

            static let management = L("Management", "Quản lý")
            static let managementDesc = L("Management and leadership", "Quản lý và leadership")

            static let emails = L("Emails", "Email")
            static let emailsDesc = L("Email and communication chaos", "Hỗn loạn email và giao tiếp")

            static let coffeeBreaks = L("Coffee Breaks", "Giờ nghỉ cafe")
            static let coffeeBreaksDesc = L("Coffee and break time humor", "Hài hước về giờ nghỉ cafe")
        }
        
        // Spice Level Names
        static func spiceLevelName(_ level: Int) -> L {
            switch level {
            case 1: return mild
            case 2: return light
            case 3: return medium
            case 4: return spicy
            case 5: return extraHot
            default: return medium
            }
        }
    }
}

