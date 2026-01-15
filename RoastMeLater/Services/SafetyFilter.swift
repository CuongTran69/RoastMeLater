import Foundation

class SafetyFilter {
    private let inappropriateWords: Set<String> = [
        // Vietnamese inappropriate words (workplace context)
        "ngu", "đần", "khốn", "chết", "tệ hại", "thảm hại", "vô dụng",
        "tồi tệ", "kinh khủng", "ghê tởm", "đáng ghét", "mất dạy"
    ]
    
    private let sensitiveTopics: Set<String> = [
        "tôn giáo", "chính trị", "giới tính", "chủng tộc", "ngoại hình",
        "thu nhập", "gia đình", "bệnh tật", "tình dục"
    ]
    
    func isContentSafe(_ content: String) -> Bool {
        let lowercasedContent = content.lowercased()
        
        // Check for inappropriate words
        for word in inappropriateWords {
            if lowercasedContent.contains(word.lowercased()) {
                return false
            }
        }
        
        // Check for sensitive topics
        for topic in sensitiveTopics {
            if lowercasedContent.contains(topic.lowercased()) {
                return false
            }
        }
        
        // Additional checks
        return !containsPersonalAttacks(lowercasedContent) &&
               !containsDiscrimination(lowercasedContent) &&
               !containsExcessiveProfanity(lowercasedContent)
    }
    
    func filterContent(_ content: String) -> String {
        if isContentSafe(content) {
            return content
        }
        
        // Return a safe alternative if content is inappropriate
        return generateSafeAlternative()
    }
    
    private func containsPersonalAttacks(_ content: String) -> Bool {
        let personalAttackPatterns = [
            "bạn là", "bạn thật", "bạn quá", "bạn rất"
        ]

        for pattern in personalAttackPatterns {
            if content.contains(pattern) {
                // Check if it's followed by negative words
                let words = content.components(separatedBy: " ")

                // Find the index of the word containing the pattern
                guard let index = words.firstIndex(where: { $0.contains(pattern) }) else {
                    continue
                }

                // Safely check if there's a next word and if it's inappropriate
                let nextIndex = index + 1
                guard nextIndex < words.count else {
                    continue
                }

                let nextWord = words[nextIndex].lowercased()
                if inappropriateWords.contains(nextWord) {
                    return true
                }
            }
        }

        return false
    }
    
    private func containsDiscrimination(_ content: String) -> Bool {
        let discriminatoryPatterns = [
            "vì bạn là", "do bạn là", "bởi vì bạn"
        ]
        
        return discriminatoryPatterns.contains { content.contains($0) }
    }
    
    private func containsExcessiveProfanity(_ content: String) -> Bool {
        let profanityCount = inappropriateWords.reduce(0) { count, word in
            return count + content.lowercased().components(separatedBy: word.lowercased()).count - 1
        }
        
        return profanityCount > 1 // Allow max 1 mild profanity
    }
    
    private func generateSafeAlternative() -> String {
        let safeRoasts = [
            "Bạn làm việc chăm chỉ như một con ốc sên đang thi chạy marathon!",
            "Hiệu suất của bạn như internet Việt Nam - có lúc nhanh, có lúc chậm!",
            "Bạn multitask như Windows 95 - cố gắng nhưng hay bị treo!",
            "Deadline trong mắt bạn chỉ là... gợi ý, phải không?",
            "Bạn làm việc như một nghệ sĩ - chậm nhưng có tâm hồn!"
        ]
        
        return safeRoasts.randomElement() ?? "Bạn là một nhân viên... đặc biệt!"
    }
    
    func adjustSpiceLevelForSafety(_ spiceLevel: Int, content: String) -> Int {
        if !isContentSafe(content) {
            return min(spiceLevel, 2) // Reduce spice level for unsafe content
        }
        return spiceLevel
    }
    
    func validateRoastForWorkplace(_ roast: Roast) -> Bool {
        // Additional workplace-specific validation
        let workplaceInappropriate = [
            "sa thải", "đuổi việc", "lương", "thưởng", "sếp", "cấp trên"
        ]
        
        let content = roast.content.lowercased()
        
        for word in workplaceInappropriate {
            if content.contains(word) && roast.spiceLevel > 3 {
                return false
            }
        }
        
        return isContentSafe(roast.content)
    }
}
