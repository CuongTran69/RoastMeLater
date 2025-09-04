import Foundation
import RxSwift

/// Helper class để test API connection tương tự như script Python
class APITestHelper {
    static let shared = APITestHelper()
    private let session = URLSession.shared
    
    private init() {}
    
    /// Test API connection với model cố định anthropic:3.7-sonnet
    /// - Parameters:
    ///   - apiKey: API key
    ///   - baseURL: Base URL của API
    ///   - modelName: Tên model (luôn sử dụng "anthropic:3.7-sonnet")
    /// - Returns: Observable<Bool> indicating success/failure
    func testAPIConnection(apiKey: String, baseURL: String, modelName: String) -> Observable<Bool> {
        return Observable.create { observer in
            let effectiveModelName = "anthropic:3.7-sonnet" // Cố định model
            
            guard let url = URL(string: baseURL) else {
                print("❌ Invalid base URL: \(baseURL)")
                observer.onNext(false)
                observer.onCompleted()
                return Disposables.create()
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.timeoutInterval = 30.0
            
            let requestBody: [String: Any] = [
                "model": effectiveModelName,
                "messages": [
                    ["role": "user", "content": "Hello"]
                ],
                "max_tokens": 10
            ]
            
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
            } catch {
                print("❌ Failed to serialize request body: \(error)")
                observer.onNext(false)
                observer.onCompleted()
                return Disposables.create()
            }
            
            print("🔄 Testing API...")
            print("URL: \(baseURL)")
            print("Model: \(effectiveModelName)")
            
            let task = self.session.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("❌ API Error: \(error.localizedDescription)")
                    observer.onNext(false)
                    observer.onCompleted()
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    print("❌ Invalid response type")
                    observer.onNext(false)
                    observer.onCompleted()
                    return
                }
                
                print("📡 HTTP Status: \(httpResponse.statusCode)")
                
                if (200...299).contains(httpResponse.statusCode) {
                    if let data = data,
                       let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let choices = json["choices"] as? [[String: Any]],
                       let firstChoice = choices.first,
                       let message = firstChoice["message"] as? [String: Any],
                       let content = message["content"] as? String {
                        print("✅ API hoạt động tốt!")
                        print("Response: \(content)")
                        observer.onNext(true)
                    } else {
                        print("✅ API connected but response format unexpected")
                        observer.onNext(true)
                    }
                } else {
                    print("❌ API Error - HTTP \(httpResponse.statusCode)")
                    if let data = data,
                       let errorString = String(data: data, encoding: .utf8) {
                        print("Error details: \(errorString)")
                    }
                    observer.onNext(false)
                }
                
                observer.onCompleted()
            }
            
            task.resume()
            
            return Disposables.create {
                task.cancel()
            }
        }
    }
    
    /// Validate API configuration
    func validateConfiguration(apiKey: String, baseURL: String) -> (isValid: Bool, errors: [String]) {
        var errors: [String] = []

        if apiKey.isEmpty {
            errors.append("API key không được để trống")
        }

        if baseURL.isEmpty {
            errors.append("Base URL không được để trống")
        } else if URL(string: baseURL) == nil {
            errors.append("Base URL không hợp lệ")
        }

        return (errors.isEmpty, errors)
    }
}
