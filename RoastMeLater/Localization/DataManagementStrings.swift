import Foundation

// MARK: - Data Management Strings

extension Strings {
    enum DataManagement {
        // Navigation
        static let title = L("Data Management", "Quản Lý Dữ Liệu")
        
        // MARK: - Export
        enum Export {
            static let title = L("Export Data", "Xuất Dữ Liệu")
            static let exportAll = L("Export All Data", "Xuất Tất Cả Dữ Liệu")
            static let options = L("Export Options", "Tùy Chọn Xuất")
            static let details = L("Export Details", "Chi Tiết Xuất")
            static let success = L("Export successful!", "Xuất dữ liệu thành công!")
            
            static let description = L(
                "Export your roast history, favorites, and settings to a JSON file for backup or transfer.",
                "Xuất lịch sử roast, danh sách yêu thích và cài đặt ra file JSON để sao lưu hoặc chuyển đổi."
            )
            static let optionsDescription = L(
                "Choose what data to include in your export. Sensitive information like API keys can be excluded for security.",
                "Chọn dữ liệu nào sẽ được bao gồm trong file xuất. Thông tin nhạy cảm như API key có thể được loại bỏ để bảo mật."
            )
            static let dataToInclude = L("Data to Include", "Dữ Liệu Bao Gồm")
            static let exportButton = L("Export", "Xuất")

            // Options
            static let apiConfiguration = L("API Configuration", "Cấu Hình API")
            static let deviceInformation = L("Device Information", "Thông Tin Thiết Bị")
            static let usageStatistics = L("Usage Statistics", "Thống Kê Sử Dụng")
            static let anonymizeData = L("Anonymize Data", "Ẩn Danh Dữ Liệu")
            
            static let includeAPIKeys = L(
                "Include API keys and endpoints (not recommended for sharing)",
                "Bao gồm API key và endpoint (không khuyến nghị khi chia sẻ)"
            )
            static let includeDeviceInfo = L(
                "Include device model and iOS version for compatibility",
                "Bao gồm model thiết bị và phiên bản iOS để tương thích"
            )
            static let includeStats = L(
                "Include category breakdown and usage patterns",
                "Bao gồm phân tích danh mục và mẫu sử dụng"
            )
            static let anonymizeDescription = L(
                "Remove potentially identifying information from roast content",
                "Loại bỏ thông tin có thể nhận dạng khỏi nội dung roast"
            )
            
            // What's included
            static let whatsIncluded = L("What's Always Included", "Luôn Được Bao Gồm")
            static let allRoastHistory = L("All roast history and content", "Toàn bộ lịch sử và nội dung roast")
            static let favoritesList = L("Favorite roasts list", "Danh sách roast yêu thích")
            static let userPreferences = L("User preferences and settings", "Tùy chọn và cài đặt người dùng")
            static let exportMetadata = L("Export metadata and timestamp", "Metadata và thời gian xuất")
            
            // Warnings
            static let securityWarning = L("Security Warning", "Cảnh Báo Bảo Mật")
            static let apiKeyWarning = L(
                "API keys will be included in plain text. Only share this file with trusted recipients.",
                "API key sẽ được bao gồm dưới dạng văn bản thuần. Chỉ chia sẻ file này với người tin cậy."
            )
            static let anonymizationNote = L("Anonymization Note", "Lưu Ý Ẩn Danh")
            static let anonymizationDescription = L(
                "Basic anonymization will be applied. Review exported content before sharing.",
                "Ẩn danh cơ bản sẽ được áp dụng. Xem lại nội dung đã xuất trước khi chia sẻ."
            )
        }
        
        // MARK: - Import
        enum Import {
            static let title = L("Import Data", "Nhập Dữ Liệu")
            static let preview = L("Import Preview", "Xem Trước Nhập")
            static let options = L("Import Options", "Tùy Chọn Nhập")
            static let success = L("Import successful!", "Nhập dữ liệu thành công!")
            
            static let description = L(
                "Import previously exported data from a JSON file. You can choose to merge with existing data or replace it completely.",
                "Nhập dữ liệu đã xuất trước đó từ file JSON. Bạn có thể chọn gộp với dữ liệu hiện có hoặc thay thế hoàn toàn."
            )
            
            // Options
            static let strategy = L("Import Strategy", "Chiến lược nhập")
            static let mergeWithExisting = L("Merge with existing data", "Gộp với dữ liệu hiện có")
            static let replaceAll = L("Replace all existing data", "Thay thế toàn bộ dữ liệu")
            static let skipDuplicates = L("Skip duplicate roasts", "Bỏ qua roast trùng lặp")
            static let keepExistingFavorites = L("Keep existing favorites", "Giữ danh sách yêu thích hiện có")
            static let allowPartialImport = L("Allow partial import", "Cho phép nhập một phần")
            static let allowPartialImportDesc = L(
                "Continue importing valid items even if some fail",
                "Tiếp tục nhập các mục hợp lệ ngay cả khi một số mục bị lỗi"
            )
            static func maxErrorsAllowed(_ count: Int) -> L {
                return L("Max errors allowed: \(count)", "Số lỗi tối đa cho phép: \(count)")
            }
            
            // File Info
            static let fileInformation = L("File Information", "Thông Tin File")
            static let appVersion = L("App Version", "Phiên bản ứng dụng")
            static let exportDate = L("Export Date", "Ngày xuất")
            static let dataVersion = L("Data Version", "Phiên bản dữ liệu")
            static let device = L("Device", "Thiết bị")
            
            // Summary
            static let dataSummary = L("Data Summary", "Tổng Quan Dữ Liệu")
            static func duplicatesFound(_ count: Int) -> L {
                return L("\(count) duplicate roasts found", "Tìm thấy \(count) roast trùng lặp")
            }
            
            // Warnings
            static let warnings = L("Warnings", "Cảnh Báo")
            static func moreWarnings(_ count: Int) -> L {
                return L("... and \(count) more warnings", "... và \(count) cảnh báo khác")
            }
            static let settingsChanges = L("Settings Changes", "Thay Đổi Cài Đặt")
            static let incompatibleWarning = L(
                "This data may not be fully compatible with the current app version.",
                "Dữ liệu này có thể không hoàn toàn tương thích với phiên bản ứng dụng hiện tại."
            )
        }
        
        // MARK: - Progress
        enum Progress {
            static let preparing = L("Preparing...", "Chuẩn bị...")
            static let collectingData = L("Collecting data...", "Thu thập dữ liệu...")
            static let processingRoasts = L("Processing roasts...", "Xử lý roast...")
            static let processingFavorites = L("Processing favorites...", "Xử lý yêu thích...")
            static let processingPreferences = L("Processing settings...", "Xử lý cài đặt...")
            static let generatingMetadata = L("Generating metadata...", "Tạo metadata...")
            static let serializing = L("Creating JSON file...", "Tạo file JSON...")
            static let writing = L("Saving file...", "Lưu file...")
            static let validating = L("Validating data...", "Xác thực dữ liệu...")
            static let parsing = L("Parsing data...", "Phân tích dữ liệu...")
            static let saving = L("Saving data...", "Lưu dữ liệu...")
            static let completed = L("Completed!", "Hoàn thành!")
        }
        
        // MARK: - Overview
        static let dataOverview = L("Data Overview", "Tổng Quan Dữ Liệu")
        static let totalRoasts = L("Total Roasts", "Tổng Roast")
        static let favorites = L("Favorites", "Yêu Thích")
        static let mostPopular = L("Most Popular:", "Phổ biến nhất:")
    }
}

