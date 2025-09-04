import SwiftUI

struct ErrorView: View {
    let title: String
    let message: String
    let retryAction: (() -> Void)?
    
    init(title: String = "Oops!", 
         message: String, 
         retryAction: (() -> Void)? = nil) {
        self.title = title
        self.message = message
        self.retryAction = retryAction
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(.orange)
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(message)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            if let retryAction = retryAction {
                Button(action: {
                    HapticFeedback.shared.buttonTapped()
                    retryAction()
                }) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Thử lại")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [.orange, .red],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                }
            }
        }
        .padding()
    }
}

struct NetworkErrorView: View {
    let retryAction: () -> Void
    
    var body: some View {
        ErrorView(
            title: "Không có kết nối",
            message: "Vui lòng kiểm tra kết nối internet và thử lại.",
            retryAction: retryAction
        )
    }
}

struct AIServiceErrorView: View {
    let retryAction: () -> Void
    
    var body: some View {
        ErrorView(
            title: "Lỗi tạo roast",
            message: "Không thể tạo roast lúc này. Vui lòng thử lại sau.",
            retryAction: retryAction
        )
    }
}

struct GenericErrorView: View {
    let error: Error
    let retryAction: (() -> Void)?
    
    var body: some View {
        ErrorView(
            title: "Có lỗi xảy ra",
            message: ErrorHandler.shared.handle(error),
            retryAction: retryAction
        )
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    init(icon: String,
         title: String,
         message: String,
         actionTitle: String? = nil,
         action: (() -> Void)? = nil) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.5))
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                
                Text(message)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            if let actionTitle = actionTitle, let action = action {
                Button(action: {
                    HapticFeedback.shared.buttonTapped()
                    action()
                }) {
                    HStack {
                        Image(systemName: "plus")
                        Text(actionTitle)
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [.orange, .red],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                }
            }
        }
        .padding()
    }
}

#Preview("Error View") {
    ErrorView(
        title: "Lỗi kết nối",
        message: "Không thể kết nối đến server. Vui lòng kiểm tra kết nối internet.",
        retryAction: {}
    )
}

#Preview("Network Error View") {
    NetworkErrorView(retryAction: {})
}

#Preview("Empty State View") {
    EmptyStateView(
        icon: "heart.slash",
        title: "Chưa có roast yêu thích",
        message: "Hãy thêm một số roast vào danh sách yêu thích!",
        actionTitle: "Tạo Roast Mới",
        action: {}
    )
}
