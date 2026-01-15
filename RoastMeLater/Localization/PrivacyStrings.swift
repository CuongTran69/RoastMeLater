import Foundation

// MARK: - Privacy Strings

extension Strings {
    enum Privacy {
        // Navigation
        static let privacyNotice = L("Privacy Notice", "Thông Báo Quyền Riêng Tư")
        
        // Sections
        static let dataIncluded = L("Data Included", "Dữ Liệu Được Bao Gồm")
        static let privacyConcerns = L("Privacy Concerns", "Vấn Đề Quyền Riêng Tư")
        static let recommendations = L("Recommendations", "Khuyến Nghị")
        static let privacyDetails = L("Privacy Details", "Chi Tiết Quyền Riêng Tư")
        
        // Sensitivity Levels
        static let low = L("Low", "Thấp")
        static let medium = L("Medium", "Trung bình")
        static let high = L("High", "Cao")
        
        // Privacy Details Items
        static let dataProcessing = L("Data Processing", "Xử Lý Dữ Liệu")
        static let dataProcessingDesc = L(
            "Data is processed locally on your device and exported as a JSON file.",
            "Dữ liệu được xử lý cục bộ trên thiết bị của bạn và xuất dưới dạng file JSON."
        )
        static let dataStorage = L("Data Storage", "Lưu Trữ Dữ Liệu")
        static let dataStorageDesc = L(
            "Exported files are stored in your device's Files app and can be shared manually.",
            "File đã xuất được lưu trong ứng dụng Files của thiết bị và có thể được chia sẻ thủ công."
        )
        static let thirdPartyAccess = L("Third-Party Access", "Truy Cập Bên Thứ Ba")
        static let thirdPartyAccessDesc = L(
            "No data is automatically sent to third parties. You control all sharing.",
            "Không có dữ liệu nào được tự động gửi đến bên thứ ba. Bạn kiểm soát mọi việc chia sẻ."
        )
        
        // Acknowledgment
        static let acknowledgment = L(
            "I have read and understand this privacy notice",
            "Tôi đã đọc và hiểu thông báo quyền riêng tư này"
        )
        
        // Warnings
        static let highRiskWarning = L(
            "High-risk privacy issues detected. Consider reviewing export options.",
            "Phát hiện vấn đề quyền riêng tư rủi ro cao. Xem xét lại tùy chọn xuất."
        )
        
        // Actions
        static let continueExport = L("Continue Export", "Tiếp Tục Xuất")
    }
}

