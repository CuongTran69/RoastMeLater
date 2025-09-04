import Foundation
import RxSwift

protocol AIServiceProtocol {
    func generateRoast(category: RoastCategory, spiceLevel: Int, language: String) -> Observable<Roast>
    func testAPIConnection(apiKey: String, baseURL: String, modelName: String) -> Observable<Bool>
}

class AIService: AIServiceProtocol {
    private let session = URLSession.shared
    private let storageService: StorageServiceProtocol

    init(storageService: StorageServiceProtocol = StorageService()) {
        self.storageService = storageService
    }

    private func getAPIConfiguration() -> APIConfiguration {
        return storageService.getUserPreferences().apiConfiguration
    }
    
    func generateRoast(category: RoastCategory, spiceLevel: Int, language: String) -> Observable<Roast> {
        let apiConfig = getAPIConfiguration()

        // Debug logging
        print("🔍 API Config Debug:")
        print("  apiKey: \(apiConfig.apiKey.isEmpty ? "EMPTY" : "HAS_VALUE")")
        print("  baseURL: \(apiConfig.baseURL)")
        print("  modelName: \(apiConfig.modelName)")

        // Use mock data if no API configuration is provided
        if apiConfig.apiKey.isEmpty || apiConfig.baseURL.isEmpty {
            print("❌ Using mock data - API config not valid")
            return generateMockRoast(category: category, spiceLevel: spiceLevel, language: language)
        }

        print("✅ Using real API call")

        return Observable.create { observer in
            let prompt = self.createPrompt(category: category, spiceLevel: spiceLevel, language: language)

            guard let url = URL(string: apiConfig.baseURL) else {
                observer.onError(AIServiceError.invalidResponse)
                return Disposables.create()
            }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("Bearer \(apiConfig.apiKey)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.timeoutInterval = Constants.API.requestTimeout

            let requestBody: [String: Any] = [
                "model": apiConfig.modelName,
                "messages": [
                    [
                        "role": "system",
                        "content": "You are a witty office humor assistant that creates workplace-appropriate roasts in Vietnamese. Keep content light-hearted and suitable for office environments."
                    ],
                    [
                        "role": "user",
                        "content": prompt
                    ]
                ],
                "max_tokens": Constants.API.maxTokens,
                "temperature": Constants.API.temperature
            ]

            print("📤 API Request:")
            print("  URL: \(url)")
            print("  Model: \(apiConfig.modelName)")
            print("  Prompt: \(prompt)")
            print("  Headers: Authorization: Bearer \(apiConfig.apiKey.prefix(10))...")
            
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
            } catch {
                observer.onError(error)
                return Disposables.create()
            }
            
            let task = self.session.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("❌ Network Error: \(error.localizedDescription)")
                    observer.onError(error)
                    return
                }

                if let httpResponse = response as? HTTPURLResponse {
                    print("📡 HTTP Status: \(httpResponse.statusCode)")
                }

                guard let data = data else {
                    print("❌ No data received")
                    observer.onError(AIServiceError.noData)
                    return
                }

                // Log raw response for debugging
                if let responseString = String(data: data, encoding: .utf8) {
                    print("📥 Raw Response: \(responseString)")
                }

                do {
                    let response = try JSONDecoder().decode(OpenAIResponse.self, from: data)
                    if let content = response.choices.first?.message.content {
                        print("✅ API Success: \(content)")
                        let roast = Roast(
                            content: content.trimmingCharacters(in: .whitespacesAndNewlines),
                            category: category,
                            spiceLevel: spiceLevel,
                            language: language
                        )
                        observer.onNext(roast)
                        observer.onCompleted()
                    } else {
                        print("❌ Invalid response structure")
                        observer.onError(AIServiceError.invalidResponse)
                    }
                } catch {
                    print("❌ JSON Decode Error: \(error)")
                    observer.onError(error)
                }
            }
            
            task.resume()
            
            return Disposables.create {
                task.cancel()
            }
        }
    }
    
    private func generateMockRoast(category: RoastCategory, spiceLevel: Int, language: String) -> Observable<Roast> {
        return Observable.create { observer in
            // Simulate network delay
            DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) {
                let mockRoasts = self.getMockRoasts(for: category, spiceLevel: spiceLevel)
                let randomRoast = mockRoasts.randomElement() ?? "Bạn làm việc chăm chỉ như một con ốc sên đang thi chạy marathon!"
                
                let roast = Roast(
                    content: randomRoast,
                    category: category,
                    spiceLevel: spiceLevel,
                    language: language
                )
                
                observer.onNext(roast)
                observer.onCompleted()
            }
            
            return Disposables.create()
        }
    }
    
    private func createPrompt(category: RoastCategory, spiceLevel: Int, language: String) -> String {
        let categoryDescription = category.description
        let spiceLevelDescription = getSpiceLevelDescription(spiceLevel)
        
        return """
        Tạo một câu roast tiếng Việt về \(categoryDescription) với mức độ \(spiceLevelDescription).
        
        Yêu cầu:
        - Phù hợp với môi trường văn phòng
        - Hài hước nhưng không xúc phạm
        - Độ dài 1-2 câu
        - Sử dụng tiếng Việt tự nhiên
        - Mức độ cay: \(spiceLevel)/5
        
        Chỉ trả về nội dung roast, không cần giải thích thêm.
        """
    }
    
    private func getSpiceLevelDescription(_ level: Int) -> String {
        switch level {
        case 1: return "nhẹ nhàng, dễ thương"
        case 2: return "vừa phải, hài hước"
        case 3: return "trung bình, châm biếm"
        case 4: return "cay nồng, sắc sảo"
        case 5: return "cực cay, thẳng thắn"
        default: return "trung bình"
        }
    }
    
    private func getMockRoasts(for category: RoastCategory, spiceLevel: Int) -> [String] {
        switch category {
        case .deadlines:
            return [
                "Deadline của bạn như lời hứa của chính trị gia - nghe hay nhưng khó tin!",
                "Bạn làm việc với deadline như rùa đua với thỏ, nhưng không có kết thúc có hậu!",
                "Deadline trong mắt bạn chỉ là... gợi ý, phải không?"
            ]
        case .meetings:
            return [
                "Meeting của bạn dài hơn cả phim Titanic, nhưng ít drama hơn!",
                "Cuộc họp của bạn như WiFi công ty - luôn chậm và hay bị gián đoạn!",
                "Bạn họp nhiều đến nỗi có thể mở công ty tư vấn về... cách họp!"
            ]
        case .kpis:
            return [
                "KPI của bạn như WiFi nhà hàng xóm - luôn yếu và không ổn định!",
                "Chỉ số của bạn tăng chậm như giá xăng... à không, giá xăng tăng nhanh hơn!",
                "KPI của bạn như thời tiết Sài Gòn - khó đoán và hay thay đổi!"
            ]
        case .codeReviews:
            return [
                "Code review của bạn như đi khám bệnh - ai cũng sợ nhưng cần thiết!",
                "Code của bạn như món phở - càng review càng thấy thiếu gia vị!",
                "Review code của bạn như giải mã hieroglyph Ai Cập!"
            ]
        default:
            return [
                "Bạn làm việc chăm chỉ như một con ốc sên đang thi chạy marathon!",
                "Hiệu suất làm việc của bạn như internet Việt Nam - có lúc nhanh, có lúc... chậm!",
                "Bạn multitask như Windows 95 - cố gắng nhưng hay bị treo!"
            ]
        }
    }

    // MARK: - API Testing
    func testAPIConnection(apiKey: String, baseURL: String, modelName: String) -> Observable<Bool> {
        return Observable.create { observer in
            guard let url = URL(string: baseURL) else {
                observer.onNext(false)
                observer.onCompleted()
                return Disposables.create()
            }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.timeoutInterval = 10.0 // Shorter timeout for testing

            let testRequestBody: [String: Any] = [
                "model": modelName,
                "messages": [
                    [
                        "role": "user",
                        "content": "Hello"
                    ]
                ],
                "max_tokens": 10
            ]

            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: testRequestBody)
            } catch {
                observer.onNext(false)
                observer.onCompleted()
                return Disposables.create()
            }

            let task = self.session.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("API Test Error: \(error.localizedDescription)")
                    observer.onNext(false)
                    observer.onCompleted()
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse else {
                    observer.onNext(false)
                    observer.onCompleted()
                    return
                }

                // Consider 200-299 as success
                let isSuccess = (200...299).contains(httpResponse.statusCode)
                observer.onNext(isSuccess)
                observer.onCompleted()
            }

            task.resume()

            return Disposables.create {
                task.cancel()
            }
        }
    }
}

enum AIServiceError: Error {
    case noData
    case invalidResponse
    case apiKeyMissing
    
    var localizedDescription: String {
        switch self {
        case .noData:
            return "Không nhận được dữ liệu từ server"
        case .invalidResponse:
            return "Phản hồi từ server không hợp lệ"
        case .apiKeyMissing:
            return "Thiếu API key"
        }
    }
}

// MARK: - OpenAI Response Models
struct OpenAIResponse: Codable {
    let choices: [Choice]
}

struct Choice: Codable {
    let message: Message
}

struct Message: Codable {
    let content: String
}
