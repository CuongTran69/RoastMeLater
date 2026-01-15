import Foundation

// MARK: - Favorites Strings

extension Strings {
    enum Favorites {
        // Navigation
        static let title = L("Favorites", "Yêu thích")
        static let searchPlaceholder = L("Search favorites...", "Tìm kiếm roast yêu thích...")

        // Empty State
        static let emptyTitle = L("No Favorites Yet", "Chưa có roast yêu thích")
        static let emptyMessage = L(
            "Tap the heart icon on roasts to add them to your favorites!",
            "Nhấn vào biểu tượng trái tim ở các câu roast để thêm vào danh sách yêu thích!"
        )
        static let createNewRoast = L("Create New Roast", "Tạo Roast Mới")

        // Actions
        static let removeFromFavorites = L("Remove from Favorites", "Xóa khỏi yêu thích")
        static let shareRoast = L("Share Roast", "Chia sẻ Roast")
        static let shareAll = L("Share all", "Chia sẻ tất cả")
        static let clearAll = L("Clear all", "Xóa tất cả")

        // Filter
        static let filterByCategory = L("Filter by Category", "Lọc theo danh mục")
        static let allCategories = L("All Categories", "Tất cả danh mục")

        // Share Text
        static let spiceLevel = L("Spice level", "Mức độ cay")
        static let createdByApp = L("Created by RoastMe App", "Được tạo bởi RoastMe App")
        static let myCollection = L("My favorite RoastMe collection:", "Bộ sưu tập RoastMe yêu thích của tôi:")
    }
}

