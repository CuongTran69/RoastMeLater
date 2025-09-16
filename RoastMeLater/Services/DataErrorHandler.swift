import Foundation
import RxSwift

// MARK: - Error Recovery Strategies

enum ErrorRecoveryStrategy: Equatable {
    case retry
    case skip
    case abort
    case fallback(Data)

    static func == (lhs: ErrorRecoveryStrategy, rhs: ErrorRecoveryStrategy) -> Bool {
        switch (lhs, rhs) {
        case (.retry, .retry), (.skip, .skip), (.abort, .abort):
            return true
        case (.fallback(let lhsData), .fallback(let rhsData)):
            return lhsData == rhsData
        default:
            return false
        }
    }
}

struct ErrorRecoveryOption {
    let strategy: ErrorRecoveryStrategy
    let title: String
    let description: String
    let isRecommended: Bool
}

// MARK: - Error Context

struct ErrorContext {
    let operation: DataOperation
    let phase: String
    let itemsProcessed: Int
    let totalItems: Int
    let timestamp: Date
    let additionalInfo: [String: Any]
}

enum DataOperation {
    case export
    case dataImport  // Changed from 'import' to avoid keyword conflict
    case validation
}

// MARK: - Enhanced Error Types

enum DataManagementError: Error, LocalizedError, Equatable {
    // Export Errors
    case exportNoData
    case exportSerializationFailed(underlying: Error)
    case exportFileWriteFailed(path: String, underlying: Error)
    case exportInsufficientStorage(required: Int64, available: Int64)
    case exportPermissionDenied(path: String)
    case exportCancelled
    
    // Import Errors
    case importInvalidFileFormat(details: String)
    case importUnsupportedVersion(version: Int, supported: [Int])
    case importCorruptedData(field: String, reason: String)
    case importValidationFailed(errors: [ValidationError])
    case importStorageError(underlying: Error)
    case importCancelled
    case importFileNotFound(path: String)
    case importPermissionDenied(path: String)
    
    // General Errors
    case networkError(underlying: Error)
    case unknownError(underlying: Error)
    
    var errorDescription: String? {
        switch self {
        // Export Errors
        case .exportNoData:
            return "Không có dữ liệu để xuất. Hãy tạo một số roast trước khi xuất dữ liệu."
        case .exportSerializationFailed(let error):
            return "Lỗi tạo file JSON: \(error.localizedDescription)"
        case .exportFileWriteFailed(let path, let error):
            return "Không thể ghi file tại \(path): \(error.localizedDescription)"
        case .exportInsufficientStorage(let required, let available):
            let requiredMB = Double(required) / 1024 / 1024
            let availableMB = Double(available) / 1024 / 1024
            return "Không đủ dung lượng lưu trữ. Cần: \(String(format: "%.1f", requiredMB))MB, Có sẵn: \(String(format: "%.1f", availableMB))MB"
        case .exportPermissionDenied(let path):
            return "Không có quyền ghi file tại \(path). Vui lòng kiểm tra quyền truy cập."
        case .exportCancelled:
            return "Đã hủy xuất dữ liệu"
            
        // Import Errors
        case .importInvalidFileFormat(let details):
            return "Định dạng file không hợp lệ: \(details)"
        case .importUnsupportedVersion(let version, let supported):
            return "Phiên bản dữ liệu \(version) không được hỗ trợ. Các phiên bản hỗ trợ: \(supported.map(String.init).joined(separator: ", "))"
        case .importCorruptedData(let field, let reason):
            return "Dữ liệu bị hỏng tại trường '\(field)': \(reason)"
        case .importValidationFailed(let errors):
            return "Xác thực dữ liệu thất bại với \(errors.count) lỗi"
        case .importStorageError(let error):
            return "Lỗi lưu trữ: \(error.localizedDescription)"
        case .importCancelled:
            return "Đã hủy nhập dữ liệu"
        case .importFileNotFound(let path):
            return "Không tìm thấy file tại \(path)"
        case .importPermissionDenied(let path):
            return "Không có quyền đọc file tại \(path)"
            
        // General Errors
        case .networkError(let error):
            return "Lỗi mạng: \(error.localizedDescription)"
        case .unknownError(let error):
            return "Lỗi không xác định: \(error.localizedDescription)"
        }
    }
    
    var failureReason: String? {
        switch self {
        case .exportNoData:
            return "Chưa có dữ liệu roast nào được tạo"
        case .exportInsufficientStorage:
            return "Thiết bị không đủ dung lượng trống"
        case .importInvalidFileFormat:
            return "File không phải là định dạng JSON hợp lệ của RoastMeLater"
        case .importUnsupportedVersion:
            return "File được tạo bởi phiên bản ứng dụng không tương thích"
        case .importCorruptedData:
            return "Dữ liệu trong file bị hỏng hoặc thiếu"
        default:
            return nil
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .exportNoData:
            return "Tạo một số roast trước khi thử xuất dữ liệu"
        case .exportInsufficientStorage:
            return "Giải phóng dung lượng lưu trữ và thử lại"
        case .exportPermissionDenied, .importPermissionDenied:
            return "Kiểm tra quyền truy cập file trong Cài đặt > Quyền riêng tư"
        case .importInvalidFileFormat:
            return "Đảm bảo file được xuất từ ứng dụng RoastMeLater"
        case .importUnsupportedVersion:
            return "Cập nhật ứng dụng lên phiên bản mới nhất"
        case .importCorruptedData:
            return "Thử xuất dữ liệu lại từ thiết bị gốc"
        case .networkError:
            return "Kiểm tra kết nối mạng và thử lại"
        default:
            return "Thử lại hoặc liên hệ hỗ trợ nếu vấn đề tiếp tục"
        }
    }

    static func == (lhs: DataManagementError, rhs: DataManagementError) -> Bool {
        switch (lhs, rhs) {
        case (.exportNoData, .exportNoData),
             (.exportCancelled, .exportCancelled),
             (.importCancelled, .importCancelled):
            return true
        case (.exportSerializationFailed, .exportSerializationFailed),
             (.exportStorageError, .exportStorageError),
             (.importStorageError, .importStorageError),
             (.networkError, .networkError),
             (.unknownError, .unknownError):
            return true
        case (.exportFileWriteFailed(let lhsPath, _), .exportFileWriteFailed(let rhsPath, _)):
            return lhsPath == rhsPath
        case (.exportInsufficientStorage(let lhsReq, let lhsAvail), .exportInsufficientStorage(let rhsReq, let rhsAvail)):
            return lhsReq == rhsReq && lhsAvail == rhsAvail
        case (.exportPermissionDenied(let lhsPath), .exportPermissionDenied(let rhsPath)):
            return lhsPath == rhsPath
        case (.importInvalidFileFormat(let lhsDetails), .importInvalidFileFormat(let rhsDetails)):
            return lhsDetails == rhsDetails
        case (.importUnsupportedVersion(let lhsVer, let lhsSupported), .importUnsupportedVersion(let rhsVer, let rhsSupported)):
            return lhsVer == rhsVer && lhsSupported == rhsSupported
        case (.importCorruptedData(let lhsField, let lhsReason), .importCorruptedData(let rhsField, let rhsReason)):
            return lhsField == rhsField && lhsReason == rhsReason
        case (.importValidationFailed(let lhsErrors), .importValidationFailed(let rhsErrors)):
            return lhsErrors == rhsErrors
        case (.importFileNotFound(let lhsPath), .importFileNotFound(let rhsPath)):
            return lhsPath == rhsPath
        case (.importPermissionDenied(let lhsPath), .importPermissionDenied(let rhsPath)):
            return lhsPath == rhsPath
        default:
            return false
        }
    }
}

// MARK: - Error Handler Service

protocol DataErrorHandlerProtocol {
    func handleError(_ error: Error, context: ErrorContext) -> Observable<ErrorRecoveryOption>
    func getRecoveryOptions(for error: Error, context: ErrorContext) -> [ErrorRecoveryOption]
    func logError(_ error: Error, context: ErrorContext)
}

class DataErrorHandler: DataErrorHandlerProtocol {
    private let logger = DataLogger()
    
    func handleError(_ error: Error, context: ErrorContext) -> Observable<ErrorRecoveryOption> {
        return Observable.create { observer in
            // Log the error
            self.logError(error, context: context)
            
            // Get recovery options
            let options = self.getRecoveryOptions(for: error, context: context)
            
            // Return the recommended option or first available
            if let recommended = options.first(where: { $0.isRecommended }) {
                observer.onNext(recommended)
            } else if let firstOption = options.first {
                observer.onNext(firstOption)
            } else {
                // Fallback to abort if no options available
                observer.onNext(ErrorRecoveryOption(
                    strategy: .abort,
                    title: "Dừng thao tác",
                    description: "Không thể khôi phục từ lỗi này",
                    isRecommended: true
                ))
            }
            
            observer.onCompleted()
            return Disposables.create()
        }
    }
    
    func getRecoveryOptions(for error: Error, context: ErrorContext) -> [ErrorRecoveryOption] {
        switch error {
        case DataManagementError.exportInsufficientStorage:
            return [
                ErrorRecoveryOption(
                    strategy: .abort,
                    title: "Giải phóng dung lượng",
                    description: "Xóa các file không cần thiết và thử lại",
                    isRecommended: true
                ),
                ErrorRecoveryOption(
                    strategy: .retry,
                    title: "Thử lại",
                    description: "Thử xuất dữ liệu lại",
                    isRecommended: false
                )
            ]
            
        case DataManagementError.exportSerializationFailed,
             DataManagementError.importValidationFailed:
            return [
                ErrorRecoveryOption(
                    strategy: .retry,
                    title: "Thử lại",
                    description: "Thử thực hiện thao tác lại",
                    isRecommended: true
                ),
                ErrorRecoveryOption(
                    strategy: .abort,
                    title: "Hủy",
                    description: "Dừng thao tác",
                    isRecommended: false
                )
            ]
            
        case DataManagementError.importCorruptedData:
            return [
                ErrorRecoveryOption(
                    strategy: .skip,
                    title: "Bỏ qua dữ liệu lỗi",
                    description: "Tiếp tục nhập các dữ liệu hợp lệ",
                    isRecommended: true
                ),
                ErrorRecoveryOption(
                    strategy: .abort,
                    title: "Dừng nhập",
                    description: "Hủy toàn bộ quá trình nhập",
                    isRecommended: false
                )
            ]
            
        case DataManagementError.networkError:
            return [
                ErrorRecoveryOption(
                    strategy: .retry,
                    title: "Thử lại",
                    description: "Kiểm tra kết nối và thử lại",
                    isRecommended: true
                ),
                ErrorRecoveryOption(
                    strategy: .abort,
                    title: "Hủy",
                    description: "Dừng thao tác",
                    isRecommended: false
                )
            ]
            
        default:
            return [
                ErrorRecoveryOption(
                    strategy: .abort,
                    title: "Dừng thao tác",
                    description: "Không thể khôi phục từ lỗi này",
                    isRecommended: true
                )
            ]
        }
    }
    
    func logError(_ error: Error, context: ErrorContext) {
        let errorInfo = ErrorLogEntry(
            error: error,
            context: context,
            timestamp: Date()
        )
        
        logger.logError(errorInfo)
        
        // Also log to console for debugging
        print("🚨 DataManagementError:")
        print("  Operation: \(context.operation)")
        print("  Phase: \(context.phase)")
        print("  Progress: \(context.itemsProcessed)/\(context.totalItems)")
        print("  Error: \(error.localizedDescription)")
        print("  Timestamp: \(context.timestamp)")
    }
}

// MARK: - Error Logging

struct ErrorLogEntry {
    let error: Error
    let context: ErrorContext
    let timestamp: Date
    let id = UUID()
}

class DataLogger {
    private let maxLogEntries = 100
    private var logEntries: [ErrorLogEntry] = []
    private let queue = DispatchQueue(label: "com.roastme.errorlogger", qos: .utility)
    
    func logError(_ entry: ErrorLogEntry) {
        queue.async {
            self.logEntries.append(entry)
            
            // Keep only recent entries
            if self.logEntries.count > self.maxLogEntries {
                self.logEntries.removeFirst(self.logEntries.count - self.maxLogEntries)
            }
            
            // Persist to UserDefaults for crash recovery
            self.persistLogs()
        }
    }
    
    func getRecentErrors(limit: Int = 10) -> [ErrorLogEntry] {
        return queue.sync {
            return Array(logEntries.suffix(limit))
        }
    }
    
    func clearLogs() {
        queue.async {
            self.logEntries.removeAll()
            self.persistLogs()
        }
    }
    
    private func persistLogs() {
        // Store basic error info (without sensitive data)
        let basicLogs = logEntries.suffix(10).map { entry in
            [
                "timestamp": entry.timestamp.timeIntervalSince1970,
                "operation": "\(entry.context.operation)",
                "phase": entry.context.phase,
                "error": entry.error.localizedDescription
            ]
        }
        
        UserDefaults.standard.set(basicLogs, forKey: "data_error_logs")
    }
}
