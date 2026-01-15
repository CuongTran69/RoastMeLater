import Foundation

// MARK: - Error Strings

extension Strings {
    enum Errors {
        // General
        static let operationFailed = L("Operation Failed", "Thao Tác Thất Bại")
        static let errorDetails = L("Error Details", "Chi Tiết Lỗi")
        static let unknownError = L("Unknown error occurred", "Đã xảy ra lỗi không xác định")
        
        // Context
        static let operation = L("Operation", "Thao tác")
        static let phase = L("Phase", "Giai đoạn")
        static let progress = L("Progress", "Tiến độ")
        static let time = L("Time", "Thời gian")
        
        // Suggestions
        static let suggestion = L("Suggestion:", "Gợi ý:")
        static let recommended = L("Recommended", "Khuyến nghị")
        static let whatToDo = L("What would you like to do?", "Bạn muốn làm gì?")

        // Operations
        static let exportData = L("Export Data", "Xuất Dữ Liệu")
        static let importData = L("Import Data", "Nhập Dữ Liệu")
        static let dataValidation = L("Data Validation", "Xác Thực Dữ Liệu")
        
        // Actions
        static let freeUpStorage = L("Free Up Storage", "Giải phóng dung lượng")
        static let skipCorruptedData = L("Skip Corrupted Data", "Bỏ qua dữ liệu lỗi")
        static let stopOperation = L("Stop Operation", "Dừng thao tác")
        static let checkConnection = L("Check Connection", "Kiểm tra kết nối")
        
        // Network
        static let noConnection = L("No Connection", "Không có kết nối")
        static let networkErrorMessage = L(
            "Please check your internet connection and try again.",
            "Vui lòng kiểm tra kết nối internet và thử lại."
        )
        
        // AI Service
        static let roastGenerationError = L("Roast Generation Error", "Lỗi tạo roast")
        static let aiServiceErrorMessage = L(
            "Cannot generate roast at this time. Please try again later.",
            "Không thể tạo roast lúc này. Vui lòng thử lại sau."
        )
        
        // Generic
        static let genericErrorTitle = L("An Error Occurred", "Có lỗi xảy ra")
        
        // Storage
        static let insufficientStorage = L("Insufficient Storage", "Không đủ dung lượng")
        static func storageRequired(_ required: Int64, available: Int64) -> L {
            let requiredMB = required / 1_000_000
            let availableMB = available / 1_000_000
            return L(
                "Required: \(requiredMB)MB, Available: \(availableMB)MB",
                "Cần: \(requiredMB)MB, Còn trống: \(availableMB)MB"
            )
        }
        
        // Data
        static let dataCorrupted = L("Data Corrupted", "Dữ liệu bị hỏng")
        static let invalidFormat = L("Invalid Format", "Định dạng không hợp lệ")
        static let versionMismatch = L("Version Mismatch", "Phiên bản không khớp")
    }
}

