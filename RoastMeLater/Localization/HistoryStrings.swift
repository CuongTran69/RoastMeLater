import Foundation

// MARK: - History Strings

extension Strings {
    enum History {
        // Navigation
        static let title = L("History", "Lịch sử")
        static let searchPlaceholder = L("Search roasts...", "Tìm kiếm roast...")
        static let filterHistory = L("Filter History", "Lọc Lịch Sử")

        // Empty State
        static let emptyTitle = L("No History Yet", "Chưa Có Lịch Sử")
        static let emptyMessage = L(
            "Start generating roasts to see them here!",
            "Bắt đầu tạo roast để xem chúng ở đây!"
        )
        static let createNewRoast = L("Create New Roast", "Tạo Roast Mới")

        // Actions
        static let filterByCategory = L("Filter by Category", "Lọc theo danh mục")
        static let clearAll = L("Clear All", "Xóa tất cả")
        static let deleteRoast = L("Delete Roast", "Xóa Roast")

        // Date Headers
        static let today = L("Today", "Hôm nay")
        static let yesterday = L("Yesterday", "Hôm qua")
        static let thisWeek = L("This Week", "Tuần này")
        static let thisMonth = L("This Month", "Tháng này")
        static let older = L("Older", "Cũ hơn")

        // Confirmation
        static let clearAllConfirmTitle = L("Clear All History?", "Xóa tất cả lịch sử?")
        static let clearAllConfirmMessage = L(
            "This action cannot be undone. All your roast history will be permanently deleted.",
            "Hành động này không thể hoàn tác. Tất cả lịch sử roast của bạn sẽ bị xóa vĩnh viễn."
        )
    }
}

