import Foundation
import RxSwift

class ErrorHandler {
    static let shared = ErrorHandler()
    
    private init() {}
    
    func handle(_ error: Error) -> String {
        switch error {
        case let aiError as AIServiceError:
            return handleAIServiceError(aiError)
        case let settingsError as SettingsError:
            return handleSettingsError(settingsError)
        case let networkError as URLError:
            return handleNetworkError(networkError)
        default:
            return handleGenericError(error)
        }
    }
    
    private func handleAIServiceError(_ error: AIServiceError) -> String {
        switch error {
        case .noData:
            return "Không nhận được dữ liệu từ server. Vui lòng kiểm tra kết nối mạng."
        case .invalidResponse:
            return "Phản hồi từ server không hợp lệ. Vui lòng thử lại sau."
        case .apiKeyMissing:
            return "Thiếu cấu hình API. Vui lòng cấu hình API trong Cài đặt."
        case .invalidURL:
            return "URL API không hợp lệ. Vui lòng kiểm tra lại cấu hình."
        case .httpError(let statusCode, let message):
            if let message = message {
                return "Lỗi server (\(statusCode)): \(message)"
            }
            return "Lỗi server (mã: \(statusCode)). Vui lòng thử lại sau."
        case .unauthorized:
            return "API key không hợp lệ hoặc đã hết hạn. Vui lòng kiểm tra lại cấu hình API."
        case .rateLimited:
            return "Đã vượt quá giới hạn request. Vui lòng thử lại sau ít phút."
        case .serverError:
            return "Server đang gặp sự cố. Vui lòng thử lại sau."
        case .networkTimeout:
            return "Kết nối bị timeout. Vui lòng kiểm tra mạng và thử lại."
        case .decodingError:
            return "Không thể xử lý phản hồi từ server. Vui lòng thử lại."
        }
    }
    
    private func handleSettingsError(_ error: SettingsError) -> String {
        switch error {
        case .exportFailed:
            return "Không thể xuất cài đặt. Vui lòng thử lại."
        case .importFailed:
            return "Không thể nhập cài đặt. Vui lòng kiểm tra file."
        case .invalidData:
            return "Dữ liệu không hợp lệ. Vui lòng chọn file khác."
        }
    }
    
    private func handleNetworkError(_ error: URLError) -> String {
        switch error.code {
        case .notConnectedToInternet:
            return "Không có kết nối internet. Vui lòng kiểm tra mạng."
        case .timedOut:
            return "Kết nối bị timeout. Vui lòng thử lại."
        case .cannotFindHost:
            return "Không thể kết nối đến server. Vui lòng thử lại sau."
        case .networkConnectionLost:
            return "Mất kết nối mạng. Vui lòng kiểm tra và thử lại."
        default:
            return "Lỗi mạng: \(error.localizedDescription)"
        }
    }
    
    private func handleGenericError(_ error: Error) -> String {
        return "Có lỗi xảy ra: \(error.localizedDescription)"
    }
    
    func logError(_ error: Error, context: String = "") {
        let errorMessage = handle(error)
        let logMessage = context.isEmpty ? errorMessage : "\(context): \(errorMessage)"
        
        print("🚨 Error: \(logMessage)")
        
        // In a production app, you might want to send this to a crash reporting service
        // like Firebase Crashlytics or Sentry
    }
}

// MARK: - RxSwift Error Handling Extensions
extension ObservableType {
    func handleErrors() -> Observable<Element> {
        return self.catch { error in
            let errorMessage = ErrorHandler.shared.handle(error)
            ErrorHandler.shared.logError(error)
            
            // You could emit a default value or show an error state
            return Observable.empty()
        }
    }
    
    func handleErrorsWithFallback(_ fallback: Element) -> Observable<Element> {
        return self.catch { error in
            ErrorHandler.shared.logError(error)
            return Observable.just(fallback)
        }
    }
    
    func logErrors(context: String = "") -> Observable<Element> {
        return self.do(onError: { error in
            ErrorHandler.shared.logError(error, context: context)
        })
    }
}
