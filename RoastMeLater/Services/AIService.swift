import Foundation
import RxSwift

protocol AIServiceProtocol {
    func generateRoast(category: RoastCategory, spiceLevel: Int, language: String?) -> Observable<Roast>
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
    
    func generateRoast(category: RoastCategory, spiceLevel: Int, language: String? = nil) -> Observable<Roast> {
        let currentLanguage = language ?? LocalizationManager.shared.currentLanguage
        let apiConfig = getAPIConfiguration()

        // Debug logging
        print("🔍 API Config Debug:")
        print("  apiKey: \(apiConfig.apiKey.isEmpty ? "EMPTY" : "HAS_VALUE")")
        print("  baseURL: \(apiConfig.baseURL)")
        print("  modelName: \(apiConfig.modelName)")

        // Use mock data if no API configuration is provided
        if apiConfig.apiKey.isEmpty || apiConfig.baseURL.isEmpty {
            print("❌ Using mock data - API config not valid")
            return generateMockRoast(category: category, spiceLevel: spiceLevel, language: currentLanguage)
        }

        print("✅ Using real API call")

        return Observable.create { observer in
            let prompt = self.createPrompt(category: category, spiceLevel: spiceLevel, language: currentLanguage)

            guard let url = URL(string: apiConfig.baseURL) else {
                observer.onError(AIServiceError.invalidResponse)
                return Disposables.create()
            }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("Bearer \(apiConfig.apiKey)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.timeoutInterval = Constants.API.requestTimeout

            // Create dynamic system prompt based on language
            let systemPrompt = self.createSystemPrompt(language: currentLanguage)

            let requestBody: [String: Any] = [
                "model": apiConfig.modelName,
                "messages": [
                    [
                        "role": "system",
                        "content": systemPrompt
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
                        // Clean and process the content to ensure only one roast
                        let cleanedContent = self.cleanRoastContent(content)
                        print("✅ API Success: \(cleanedContent)")

                        let roast = Roast(
                            content: cleanedContent,
                            category: category,
                            spiceLevel: spiceLevel,
                            language: language ?? "vi"
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
                let randomRoast = mockRoasts.randomElement() ?? "Bạn làm việc chăm chỉ như một con ốc sên đang thi chạy marathon! 🐌"

                print("🎭 Generated mock roast:")
                print("  category: \(category.displayName)")
                print("  requestedSpiceLevel: \(spiceLevel)")
                print("  content: \(randomRoast)")

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

    private func cleanRoastContent(_ content: String) -> String {
        // Remove extra whitespace and newlines
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)

        // Split by common separators and take only the first meaningful sentence
        let separators = ["\n\n", "\n", ". ", "! ", "? "]
        var cleanedContent = trimmed

        for separator in separators {
            if let firstPart = trimmed.components(separatedBy: separator).first,
               !firstPart.isEmpty && firstPart.count > 10 { // Ensure it's a meaningful sentence
                cleanedContent = firstPart
                break
            }
        }

        // Remove any quotes or extra formatting
        cleanedContent = cleanedContent.replacingOccurrences(of: "\"", with: "")
        cleanedContent = cleanedContent.replacingOccurrences(of: "\u{201C}", with: "") // Left double quotation mark
        cleanedContent = cleanedContent.replacingOccurrences(of: "\u{201D}", with: "") // Right double quotation mark
        cleanedContent = cleanedContent.replacingOccurrences(of: "\u{2018}", with: "'") // Left single quotation mark
        cleanedContent = cleanedContent.replacingOccurrences(of: "\u{2019}", with: "'") // Right single quotation mark

        // Ensure it ends with proper punctuation
        let lastChar = cleanedContent.last
        if lastChar != "!" && lastChar != "?" && lastChar != "." {
            cleanedContent += "!"
        }

        return cleanedContent.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func createSystemPrompt(language: String) -> String {
        switch language.lowercased() {
        case "vi", "vietnamese", "vi-vn":
            return """
            Bạn là “Trợ lý Hài Hước Công Sở” – chuyên tạo MỘT câu roast duy nhất, dí dỏm, lịch sự và an toàn cho môi trường làm việc tại Việt Nam.

            Mục tiêu: chọc nhẹ để tăng không khí vui vẻ, KHÔNG gây khó chịu hay xúc phạm.

            Quy tắc:
            - Chỉ trả về 1 câu duy nhất. Không tiêu đề, không gạch đầu dòng, không xuống dòng.
            - Không dùng tục/18+, không chửi rủa, không miệt thị.
            - Tránh mọi thuộc tính nhạy cảm: giới tính, sắc tộc, tôn giáo, chính trị, ngoại hình, tuổi, khuyết tật.
            - Ưu tiên chơi chữ/công việc: họp, email, deadline, KPI, code review, slide, backlog, quy trình.
            - Không meta (“Đây là…”), không giải thích, không hashtag, không emoji trừ khi đầu vào có emoji.

            Phong cách: thông minh, ngắn gọn, thiện ý, “cà khịa” vừa đủ.

            Thiếu ngữ cảnh thì tạo câu chung phù hợp công sở.

            Ví dụ (chỉ tham khảo, KHÔNG lặp lại nguyên văn):
            - "Deadline chạy còn nhanh hơn wifi phòng họp của bạn."
            - "Bạn commit rất đều—mỗi lần là một bug có trách nhiệm."
            - "Standup của bạn dài đến mức ghế cũng muốn ngồi xuống lần hai."
            """
        case "en", "english", "en-us", "en-gb":
            return """
            You are the “Office Roast Assistant” — produce EXACTLY ONE workplace-safe roast that’s witty, light, and professional.

            Goal: playful nudge, never mean.

            Rules:
            - Output exactly 1 sentence, max 18 words. No titles, no bullets, no line breaks.
            - No profanity/NSFW, no slurs, no harassment.
            - Avoid sensitive attributes: gender, race, religion, politics, appearance, age, disability.
            - Prefer office humor: meetings, emails, deadlines, KPIs, code reviews, slides, calendars, backlog.
            - No meta (“Here’s a roast”), no explanations, no hashtags, no emojis unless the input includes them.

            Tone: clever, concise, friendly; tease, don’t sting.

            If no context, write a generic office-safe quip.

            Examples (for guidance only; do NOT repeat verbatim):
            - "Your slide deck spends 20 minutes warming up and one minute landing the plane."
            - "Your calendar has more meetings than your code has comments."
            - "Your deadline management is agile—mostly the part where it keeps sprinting past."
            """
        default:
            return """
            Bạn là “Trợ lý Hài Hước Công Sở” – chuyên tạo MỘT câu roast duy nhất, dí dỏm, lịch sự và an toàn cho môi trường làm việc tại Việt Nam.

            Mục tiêu: chọc nhẹ để tăng không khí vui vẻ, KHÔNG gây khó chịu hay xúc phạm.

            Quy tắc:
            - Chỉ trả về 1 câu duy nhất, tối đa 18 từ. Không tiêu đề, không gạch đầu dòng, không xuống dòng.
            - Không dùng tục/18+, không chửi rủa, không miệt thị.
            - Tránh mọi thuộc tính nhạy cảm: giới tính, sắc tộc, tôn giáo, chính trị, ngoại hình, tuổi, khuyết tật.
            - Ưu tiên chơi chữ/công việc: họp, email, deadline, KPI, code review, slide, backlog, quy trình.
            - Không meta (“Đây là…”), không giải thích, không hashtag, không emoji trừ khi đầu vào có emoji.

            Phong cách: thông minh, ngắn gọn, thiện ý, “cà khịa” vừa đủ.

            Thiếu ngữ cảnh thì tạo câu chung phù hợp công sở.

            Ví dụ (chỉ tham khảo, KHÔNG lặp lại nguyên văn):
            - "Deadline chạy còn nhanh hơn wifi phòng họp của bạn."
            - "Bạn commit rất đều—mỗi lần là một bug có trách nhiệm."
            - "Standup của bạn dài đến mức ghế cũng muốn ngồi xuống lần hai."
            """
        }
    }

    private func createPrompt(category: RoastCategory, spiceLevel: Int, language: String) -> String {
        let categoryContext = getCategoryContext(category)
        let spiceLevelGuidance = getSpiceLevelGuidance(spiceLevel)
        let languageInstruction = getLanguageInstruction(language)

        return """
        \(languageInstruction)

        Chủ đề: \(categoryContext.topic)
        Bối cảnh: \(categoryContext.context)
        Mức độ cay: \(spiceLevelGuidance.description) (Level \(spiceLevel)/5)

        Hướng dẫn tạo roast:
        \(spiceLevelGuidance.guidelines)

        Yêu cầu kỹ thuật:
        - Độ dài: 15-40 từ (1-2 câu ngắn gọn)
        - Phong cách: \(spiceLevelGuidance.style)
        - Tông điệu: \(spiceLevelGuidance.tone)
        - Sử dụng ví dụ: \(categoryContext.examples.randomElement() ?? "ví dụ thực tế")
        - Tránh: từ ngữ thô tục, xúc phạm cá nhân, nội dung nhạy cảm

        Trả về MỘT câu roast hoàn chỉnh duy nhất, không giải thích gì thêm.
        """
    }
    
    private func getLanguageInstruction(_ language: String) -> String {
        switch language.lowercased() {
        case "vi", "vietnamese":
            return "QUAN TRỌNG: Trả lời HOÀN TOÀN bằng tiếng Việt. Tạo một câu roast bằng tiếng Việt tự nhiên, sử dụng từ ngữ phù hợp với văn hóa Việt Nam và môi trường công sở."
        case "en", "english":
            return "IMPORTANT: Respond ENTIRELY in English. Create a witty roast in English suitable for office environment and professional context."
        default:
            return "QUAN TRỌNG: Trả lời HOÀN TOÀN bằng tiếng Việt. Tạo một câu roast bằng tiếng Việt tự nhiên, sử dụng từ ngữ phù hợp với văn hóa Việt Nam và môi trường công sở."
        }
    }

    private func getCategoryContext(_ category: RoastCategory) -> (topic: String, context: String, examples: [String]) {
        switch category {
        case .deadlines:
            return (
                topic: "Deadline và quản lý thời gian",
                context: "Những tình huống về deadline trễ, quản lý thời gian kém, hoặc ước tính thời gian không chính xác trong công việc",
                examples: ["deadline như gợi ý", "làm việc như rùa", "thời gian là tương đối", "deadline chỉ là con số"]
            )
        case .meetings:
            return (
                topic: "Cuộc họp và meeting",
                context: "Những tình huống về meeting dài, không hiệu quả, hoặc quá nhiều cuộc họp không cần thiết",
                examples: ["meeting marathon", "họp để họp", "cuộc họp vô tận", "meeting như phim dài"]
            )
        case .kpis:
            return (
                topic: "KPI và hiệu suất làm việc",
                context: "Những tình huống về KPI không đạt, chỉ số hiệu suất thấp, hoặc áp lực về target",
                examples: ["KPI như WiFi", "target như ước mơ", "hiệu suất biến động", "chỉ số thần thoại"]
            )
        case .codeReviews:
            return (
                topic: "Code review và technical review",
                context: "Những tình huống về code review khó khăn, bug nhiều, hoặc technical debt",
                examples: ["code như mê cung", "bug như sao trời", "review như phẫu thuật", "code spaghetti"]
            )
        case .workload:
            return (
                topic: "Khối lượng công việc và áp lực",
                context: "Những tình huống về công việc quá tải, stress, hoặc work-life balance kém",
                examples: ["việc như núi", "stress như áp suất", "làm việc 24/7", "burnout syndrome"]
            )
        case .colleagues:
            return (
                topic: "Đồng nghiệp và teamwork",
                context: "Những tình huống về làm việc nhóm, communication, hoặc dynamic trong team",
                examples: ["teamwork như solo", "communication như mã morse", "đồng nghiệp như alien", "team spirit"]
            )
        case .management:
            return (
                topic: "Quản lý và leadership",
                context: "Những tình huống về phong cách quản lý, decision making, hoặc leadership skills",
                examples: ["quản lý như GPS hỏng", "quyết định như tung xu", "leadership như mù đường", "micro-management"]
            )
        case .general:
            return (
                topic: "Công việc văn phòng nói chung",
                context: "Những tình huống chung về cuộc sống văn phòng, corporate culture, hoặc work habits",
                examples: ["văn phòng như rạp xiếc", "corporate life", "9-to-5 lifestyle", "office politics"]
            )
        }
    }

    private func getSpiceLevelGuidance(_ level: Int) -> (description: String, style: String, tone: String, guidelines: String) {
        switch level {
        case 1:
            return (
                description: "Nhẹ nhàng, dễ thương",
                style: "Hài hước nhẹ nhàng, đáng yêu",
                tone: "Thân thiện, vui vẻ, không gây tổn thương",
                guidelines: "- Sử dụng so sánh dễ thương, hình ảnh đáng yêu\n- Tập trung vào tình huống hài hước thay vì chỉ trích\n- Giữ tông điệu tích cực và khuyến khích"
            )
        case 2:
            return (
                description: "Vừa phải, hài hước",
                style: "Hài hước thông minh, witty",
                tone: "Vui tươi, sáng tạo, có chút tinh nghịch",
                guidelines: "- Sử dụng wordplay, pun, hoặc double meaning\n- So sánh với những tình huống quen thuộc\n- Giữ sự cân bằng giữa hài hước và tôn trọng"
            )
        case 3:
            return (
                description: "Trung bình, châm biếm",
                style: "Châm biếm thông minh, sarcastic",
                tone: "Hơi chua cay, nhưng vẫn chấp nhận được",
                guidelines: "- Sử dụng irony và sarcasm một cách khéo léo\n- Chỉ ra sự mâu thuẫn hoặc absurdity trong tình huống\n- Giữ ranh giới giữa châm biếm và xúc phạm"
            )
        case 4:
            return (
                description: "Cay nồng, sắc sảo",
                style: "Sắc sảo, thẳng thắn, có edge",
                tone: "Cứng rắn, direct, nhưng vẫn professional",
                guidelines: "- Sử dụng ngôn từ mạnh mẽ nhưng không thô tục\n- Chỉ trích trực tiếp nhưng tập trung vào hành vi, không phải cá nhân\n- Có thể gây shock nhẹ nhưng vẫn trong giới hạn chấp nhận"
            )
        case 5:
            return (
                description: "Cực cay, thẳng thắn",
                style: "Brutal honesty, không mercy",
                tone: "Thẳng thắn tối đa, savage nhưng vẫn clever",
                guidelines: "- Sử dụng ngôn từ mạnh nhất có thể trong giới hạn professional\n- Không giữ lại gì, nói thẳng sự thật\n- Có thể gây shock mạnh nhưng vẫn phải thông minh và witty"
            )
        default:
            return (
                description: "Trung bình",
                style: "Cân bằng",
                tone: "Vừa phải",
                guidelines: "- Giữ cân bằng giữa hài hước và tôn trọng"
            )
        }
    }
    
    private func getMockRoasts(for category: RoastCategory, spiceLevel: Int) -> [String] {
        let roasts = getMockRoastsByCategory(category)

        // Filter roasts by spice level appropriateness
        let filteredRoasts = roasts.filter { roast in
            let roastSpiceLevel = estimateSpiceLevel(roast.content)
            return abs(roastSpiceLevel - spiceLevel) <= 1 // Allow ±1 level tolerance
        }

        // Extract content strings from tuples
        let finalRoasts = filteredRoasts.isEmpty ? roasts : filteredRoasts
        return finalRoasts.map { $0.content }
    }

    private func getMockRoastsByCategory(_ category: RoastCategory) -> [(content: String, spiceLevel: Int)] {
        switch category {
        case .deadlines:
            return [
                ("Deadline của bạn như lời hứa chính trị gia - nghe hay nhưng ai tin? 🤔", 3),
                ("Bạn làm việc với deadline như rùa thi chạy marathon! 🐢", 2),
                ("Deadline trong mắt bạn chỉ là... gợi ý nhẹ nhàng thôi! 😊", 1),
                ("Deadline? Bạn nghĩ nó là deadline suggestion à? 😏", 4),
                ("Bạn và deadline như parallel lines - không bao giờ gặp nhau! 💀", 5)
            ]
        case .meetings:
            return [
                ("Meeting của bạn dài hơn phim Titanic nhưng ít drama hơn! 🎬", 3),
                ("Cuộc họp như WiFi công ty - chậm và hay bị gián đoạn! 📶", 2),
                ("Bạn họp nhiều đến mức có thể mở khóa học 'Nghệ thuật họp hành'! 😄", 1),
                ("Meeting với bạn = torture session không lương! 😤", 4),
                ("Bạn họp để họp, họp để... quên mình đang họp gì! 🤯", 5)
            ]
        case .kpis:
            return [
                ("KPI của bạn như WiFi hàng xóm - yếu và không ổn định! 📊", 3),
                ("Chỉ số của bạn tăng chậm như... rùa leo núi! 🐢⛰️", 2),
                ("KPI của bạn đáng yêu như em bé học bò! 👶", 1),
                ("KPI của bạn flatter hơn cả đường thẳng! 📉", 4),
                ("Target của bạn như unicorn - ai cũng nghe nhưng chưa ai thấy! 🦄", 5)
            ]
        case .codeReviews:
            return [
                ("Code review như đi khám bệnh - sợ nhưng cần thiết! 👨‍⚕️", 3),
                ("Code của bạn như món phở - càng review càng thấy thiếu gia vị! 🍜", 2),
                ("Code của bạn cute như hello world đầu tiên! 💕", 1),
                ("Review code của bạn = giải mã hieroglyph Ai Cập! 🔍", 4),
                ("Code của bạn là definition của 'spaghetti code'! 🍝💀", 5)
            ]
        case .workload:
            return [
                ("Workload của bạn như núi Everest - nhìn thôi đã mệt! ⛰️", 3),
                ("Bạn multitask như... single-task với extra steps! 🤹", 2),
                ("Công việc của bạn nhiều như sao trời, cute như sao nhí! ⭐", 1),
                ("Work-life balance của bạn = 99% work, 1% thinking about life! ⚖️", 4),
                ("Bạn làm việc 25/8 - vượt cả giới hạn thời gian! ⏰💀", 5)
            ]
        case .colleagues:
            return [
                ("Teamwork với bạn như chơi game solo nhưng có audience! 🎮", 3),
                ("Communication skills của bạn như... mã morse thời hiện đại! 📡", 2),
                ("Bạn là teammate đáng yêu như mascot của team! 🧸", 1),
                ("Collaboration với bạn = mission impossible! 🕵️", 4),
                ("Bạn làm việc nhóm như... alien trying to blend in! 👽", 5)
            ]
        case .management:
            return [
                ("Leadership style của bạn như GPS hỏng - dẫn đường lung tung! 🧭", 3),
                ("Bạn quản lý như... shepherd mà cừu đi lạc hết! 🐑", 2),
                ("Phong cách quản lý của bạn warm như hot chocolate! ☕", 1),
                ("Management skills của bạn = chaos theory in action! 🌪️", 4),
                ("Bạn lead team như blind person leading the blind! 🦯💀", 5)
            ]
        case .general:
            return [
                ("Bạn làm việc chăm chỉ như ốc sên thi marathon! 🐌", 2),
                ("Office life với bạn như sitcom không có tiếng cười! 📺", 3),
                ("Bạn là sunshine của văn phòng! ☀️😊", 1),
                ("Productivity của bạn = internet explorer của con người! 🐌💻", 4),
                ("Bạn là living proof rằng evolution có thể đi backwards! 🦕💀", 5)
            ]
        }
    }

    private func estimateSpiceLevel(_ content: String) -> Int {
        let lowercased = content.lowercased()

        // Level 5 indicators
        if lowercased.contains("💀") || lowercased.contains("backwards") ||
           lowercased.contains("blind") || lowercased.contains("alien") {
            return 5
        }

        // Level 4 indicators
        if lowercased.contains("impossible") || lowercased.contains("chaos") ||
           lowercased.contains("torture") || lowercased.contains("flatter") {
            return 4
        }

        // Level 1 indicators
        if lowercased.contains("cute") || lowercased.contains("đáng yêu") ||
           lowercased.contains("😊") || lowercased.contains("💕") {
            return 1
        }

        // Level 2 indicators
        if lowercased.contains("🐢") || lowercased.contains("😄") ||
           lowercased.contains("single-task") {
            return 2
        }

        // Default to level 3
        return 3
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
