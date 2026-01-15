import Foundation

// MARK: - Library Strings

extension Strings {
    enum Library {
        // Tab
        static let tabName = L("Library", "Thư viện")

        // Segment Control
        static let segmentAll = L("All", "Tất cả")
        static let segmentFavorites = L("Favorites", "Yêu thích")

        // Search
        static let searchPlaceholder = L("Search library...", "Tìm kiếm thư viện...")

        // Empty States - All
        static let emptyAllTitle = L("No Roasts Yet", "Chưa có Roast nào")
        static let emptyAllMessage = L(
            "Start generating roasts to build your library!",
            "Bắt đầu tạo roast để xây dựng thư viện của bạn!"
        )

        // Empty States - Favorites
        static let emptyFavoritesTitle = L("No Favorites Yet", "Chưa có roast yêu thích")
        static let emptyFavoritesMessage = L(
            "Tap the heart icon on roasts to add them to your favorites!",
            "Nhấn vào biểu tượng trái tim ở các câu roast để thêm vào danh sách yêu thích!"
        )

        // Empty State Action
        static let createNewRoast = L("Create New Roast", "Tạo Roast Mới")

        // Filter Options
        static let filterByCategory = L("Filter by Category", "Lọc theo danh mục")
        static let allCategories = L("All Categories", "Tất cả danh mục")
        static let filterByDate = L("Filter by Date", "Lọc theo ngày")
        static let filterBySpiceLevel = L("Filter by Spice Level", "Lọc theo mức độ cay")
        static let sortBy = L("Sort by", "Sắp xếp theo")
        static let sortNewest = L("Newest First", "Mới nhất")
        static let sortOldest = L("Oldest First", "Cũ nhất")

        // Actions
        static let delete = L("Delete", "Xóa")
        static let deleteRoast = L("Delete Roast", "Xóa Roast")
        static let addToFavorites = L("Add to Favorites", "Thêm vào yêu thích")
        static let removeFromFavorites = L("Remove from Favorites", "Xóa khỏi yêu thích")
        static let share = L("Share", "Chia sẻ")
        static let shareRoast = L("Share Roast", "Chia sẻ Roast")

        // Clear All Confirmation
        static let clearAll = L("Clear All", "Xóa tất cả")
        static let clearAllConfirmTitle = L("Clear All Roasts?", "Xóa tất cả Roast?")
        static let clearAllConfirmMessage = L(
            "This action cannot be undone. All your roasts will be permanently deleted.",
            "Hành động này không thể hoàn tác. Tất cả roast của bạn sẽ bị xóa vĩnh viễn."
        )
        static let clearFavoritesConfirmTitle = L("Clear All Favorites?", "Xóa tất cả yêu thích?")
        static let clearFavoritesConfirmMessage = L(
            "This action cannot be undone. All your favorite roasts will be removed from favorites.",
            "Hành động này không thể hoàn tác. Tất cả roast yêu thích của bạn sẽ bị xóa khỏi danh sách."
        )

        // Stats Labels
        static let totalCount = L("Total Roasts", "Tổng số Roast")
        static let favoritesCount = L("Favorites", "Yêu thích")
        static let roastCount = L("%d roasts", "%d roast")
        static let favoriteCount = L("%d favorites", "%d yêu thích")
    }
}

