import Foundation

// MARK: - Common Strings

extension Strings {
    enum Common {
        static let ok = L("OK", "OK")
        static let cancel = L("Cancel", "Hủy")
        static let done = L("Done", "Xong")
        static let save = L("Save", "Lưu")
        static let delete = L("Delete", "Xóa")
        static let share = L("Share", "Chia sẻ")
        static let loading = L("Loading...", "Đang tải...")
        static let error = L("Error", "Lỗi")
        static let retry = L("Retry", "Thử lại")
        static let skip = L("Skip", "Bỏ qua")
        static let abort = L("Abort", "Hủy bỏ")
        static let close = L("Close", "Đóng")
        static let confirm = L("Confirm", "Xác nhận")
        static let yes = L("Yes", "Có")
        static let no = L("No", "Không")
        static let back = L("Back", "Quay lại")
        static let next = L("Next", "Tiếp theo")
        static let copy = L("Copy", "Sao chép")
        static let copied = L("Copied!", "Đã sao chép!")
        static let success = L("Success", "Thành công")
        static let failed = L("Failed", "Thất bại")
        static let warning = L("Warning", "Cảnh báo")
        static let info = L("Info", "Thông tin")
        static let days = L("days", "ngày")
        static let day = L("day", "ngày")
        static let hours = L("hours", "giờ")
        static let hour = L("hour", "giờ")
        
        // Dynamic strings
        static func itemCount(_ count: Int) -> L {
            return L("\(count) items", "\(count) mục")
        }
        
        static func newItems(_ count: Int) -> L {
            return L("\(count) new", "\(count) mới")
        }
    }
}

