import Foundation

enum RoastCategory: String, CaseIterable, Codable {
    case deadlines = "deadlines"
    case meetings = "meetings"
    case kpis = "kpis"
    case codeReviews = "code_reviews"
    case workload = "workload"
    case colleagues = "colleagues"
    case management = "management"
    case general = "general"
    
    var displayName: String {
        switch self {
        case .deadlines:
            return "Deadline"
        case .meetings:
            return "Họp hành"
        case .kpis:
            return "KPI"
        case .codeReviews:
            return "Code Review"
        case .workload:
            return "Khối lượng công việc"
        case .colleagues:
            return "Đồng nghiệp"
        case .management:
            return "Quản lý"
        case .general:
            return "Chung"
        }
    }
    
    var icon: String {
        switch self {
        case .deadlines:
            return "clock.badge.exclamationmark"
        case .meetings:
            return "person.3.fill"
        case .kpis:
            return "chart.line.uptrend.xyaxis"
        case .codeReviews:
            return "doc.text.magnifyingglass"
        case .workload:
            return "briefcase.fill"
        case .colleagues:
            return "person.2.fill"
        case .management:
            return "person.crop.circle.badge.checkmark"
        case .general:
            return "flame.fill"
        }
    }
    
    var description: String {
        switch self {
        case .deadlines:
            return "Những câu roast về deadline và thời hạn công việc"
        case .meetings:
            return "Roast về các cuộc họp và meeting"
        case .kpis:
            return "Những câu roast về KPI và chỉ số hiệu suất"
        case .codeReviews:
            return "Roast về code review và technical review"
        case .workload:
            return "Roast về khối lượng công việc và áp lực"
        case .colleagues:
            return "Roast về đồng nghiệp và môi trường làm việc"
        case .management:
            return "Roast về quản lý và leadership"
        case .general:
            return "Roast chung về công việc văn phòng"
        }
    }
}
