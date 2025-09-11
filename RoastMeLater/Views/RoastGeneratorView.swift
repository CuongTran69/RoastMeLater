import SwiftUI
import UIKit

struct RoastGeneratorView: View {
    @StateObject private var viewModel = RoastGeneratorViewModel()
    @State private var showingCategoryPicker = false
    @State private var isGenerating = false
    @State private var showCopySuccess = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Simple Header
                    VStack(spacing: 12) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.orange)
                            .scaleEffect(isGenerating ? 1.1 : 1.0)
                            .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isGenerating)

                        Text("RoastMe")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                    }
                    .padding(.top, 10)

                    // Current Roast Display - Only show ONE roast at a time
                    Group {
                        if let currentRoast = viewModel.currentRoast {
                            RoastCardView(
                                roast: currentRoast,
                                onFavoriteToggle: {
                                    viewModel.toggleFavorite(roast: currentRoast)
                                },
                                onCopy: {
                                    viewModel.copyRoastToClipboard()
                                    showCopySuccess = true

                                    // Hide the success message after 2 seconds
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                        showCopySuccess = false
                                    }
                                },
                                onShare: {
                                    viewModel.shareRoast(currentRoast)
                                }
                            )
                            .id(currentRoast.id) // Force view recreation when roast changes
                        } else {
                            RoastPlaceholderView()
                                .id("placeholder") // Unique ID for placeholder
                        }
                    }
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    .animation(.easeInOut(duration: 0.4), value: viewModel.currentRoast?.id)
                
                    // Controls Section
                    VStack(spacing: 20) {
                        // Category Selection
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "tag.fill")
                                    .foregroundColor(.orange)
                                Text("Danh mục")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                Spacer()
                            }

                            Button(action: {
                                showingCategoryPicker = true
                                // Haptic feedback
                                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                impactFeedback.impactOccurred()
                            }) {
                                HStack(spacing: 12) {
                                    Image(systemName: viewModel.selectedCategory.icon)
                                        .foregroundColor(.orange)
                                        .frame(width: 24, height: 24)

                                    Text(viewModel.selectedCategory.displayName)
                                        .font(.body)
                                        .fontWeight(.medium)
                                        .foregroundColor(.primary)

                                    Spacer()

                                    Image(systemName: "chevron.down")
                                        .foregroundColor(.secondary)
                                        .font(.caption)
                                }
                                .padding(12)
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                            }
                        }

                        // Spice Level
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "flame.fill")
                                    .foregroundColor(.orange)
                                Text("Mức độ cay")
                                    .font(.headline)
                                    .fontWeight(.semibold)

                                Spacer()

                                Text("\(viewModel.spiceLevel)/5")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(.orange)
                            }

                            HStack(spacing: 8) {
                                ForEach(1...5, id: \.self) { level in
                                    Button(action: {
                                        viewModel.updateSpiceLevel(level)
                                        // Haptic feedback
                                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                        impactFeedback.impactOccurred()
                                    }) {
                                        Image(systemName: level <= viewModel.spiceLevel ? "flame.fill" : "flame")
                                            .font(.title2)
                                            .foregroundColor(level <= viewModel.spiceLevel ? .orange : .gray.opacity(0.4))
                                            .scaleEffect(level <= viewModel.spiceLevel ? 1.1 : 1.0)
                                            .animation(.easeInOut(duration: 0.2), value: viewModel.spiceLevel)
                                    }
                                }

                                Spacer()

                                Text(getSpiceLevelDescription(viewModel.spiceLevel))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .italic()
                            }
                            .padding(12)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }

                        // Generate Button
                        Button(action: generateRoast) {
                            HStack {
                                if isGenerating {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "sparkles")
                                }
                                Text(isGenerating ? "Đang tạo..." : "Tạo Roast Mới")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
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
                        .disabled(isGenerating)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                }
            }
            .navigationBarHidden(true)
        }
        .overlay(
            // Copy success toast
            VStack {
                if showCopySuccess {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Đã copy vào clipboard!")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(10)
                    .shadow(radius: 5)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
                Spacer()
            }
            .padding(.top, 50)
            .animation(.easeInOut(duration: 0.3), value: showCopySuccess)
        )
        .sheet(isPresented: $showingCategoryPicker) {
            CategoryPickerView(
                selectedCategory: viewModel.selectedCategory,
                onCategorySelected: { category in
                    viewModel.updateSelectedCategory(category)
                }
            )
        }
        .sheet(isPresented: $viewModel.showAPISetup) {
            APISetupView()
        }
        .onReceive(viewModel.$isLoading) { loading in
            isGenerating = loading
        }
    }
    
    private func generateRoast() {
        // Directly generate new roast without clearing current one
        // This keeps the current roast visible until new one is ready
        viewModel.generateRoast(category: viewModel.selectedCategory, spiceLevel: viewModel.spiceLevel)
    }

    private func getSpiceLevelDescription(_ level: Int) -> String {
        switch level {
        case 1: return "Nhẹ nhàng"
        case 2: return "Vừa phải"
        case 3: return "Trung bình"
        case 4: return "Cay nồng"
        case 5: return "Cực cay"
        default: return "Trung bình"
        }
    }

    private func getSpiceLevelEmoji(_ level: Int) -> String {
        switch level {
        case 1: return "😊"
        case 2: return "😄"
        case 3: return "😏"
        case 4: return "🔥"
        case 5: return "💀"
        default: return "😏"
        }
    }

    private func getFlameColor(_ level: Int) -> Color {
        switch level {
        case 1: return .orange.opacity(0.6)
        case 2: return .orange.opacity(0.8)
        case 3: return .orange
        case 4: return .red.opacity(0.8)
        case 5: return .red
        default: return .orange
        }
    }
}

struct RoastCardView: View {
    let roast: Roast
    let onFavoriteToggle: () -> Void
    let onCopy: () -> Void
    let onShare: () -> Void
    @State private var showCopyFeedback = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with category and spice level
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: roast.category.icon)
                        .foregroundColor(.orange)
                        .frame(width: 20, height: 20)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(6)

                    Text(roast.category.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                }

                Spacer()

                // Spice level indicator
                HStack(spacing: 4) {
                    ForEach(1...roast.spiceLevel, id: \.self) { level in
                        Image(systemName: "flame.fill")
                            .font(.caption)
                            .foregroundColor(getFlameColor(level))
                    }
                    Text("\(roast.spiceLevel)/5")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }

            // Main roast content with better typography
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "quote.bubble.fill")
                        .foregroundColor(.orange.opacity(0.6))
                        .font(.caption)
                    Text("Roast của bạn:")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    Spacer()
                }

                Text(roast.content)
                    .font(.body)
                    .fontWeight(.medium)
                    .lineSpacing(4)
                    .foregroundColor(.primary)
                    .padding(.leading, 8)
                    .overlay(
                        Rectangle()
                            .fill(Color.orange.opacity(0.3))
                            .frame(width: 3)
                            .cornerRadius(1.5),
                        alignment: .leading
                    )
            }

            // Action buttons with responsive layout
            VStack(spacing: 12) {
                // Timestamp row
                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(roast.createdAt, style: .time)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }

                // Action buttons - responsive layout
                HStack(spacing: 12) {
                    actionButtons
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.orange.opacity(0.2), lineWidth: 1)
        )
        .padding(.horizontal)
    }

    // MARK: - Action Button Components
    @ViewBuilder
    private var actionButtons: some View {
        // Use flexible layout that wraps naturally on small screens
        HStack(spacing: 8) {
            copyButton
                .layoutPriority(1)
            shareButton
                .layoutPriority(1)
            favoriteButton
                .layoutPriority(1)
        }
    }

    private var copyButton: some View {
        Button(action: {
            onCopy()
            showCopyFeedback = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                showCopyFeedback = false
            }
        }) {
            HStack(spacing: 3) {
                Image(systemName: showCopyFeedback ? "checkmark" : "doc.on.doc")
                    .font(.caption)
                Text(showCopyFeedback ? "Copied!" : "Copy")
                    .font(.caption2)
                    .fontWeight(.medium)
            }
            .foregroundColor(showCopyFeedback ? .green : .blue)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(Color(.systemGray6))
            .cornerRadius(6)
        }
        .animation(.easeInOut(duration: 0.2), value: showCopyFeedback)
    }

    private var shareButton: some View {
        Button(action: onShare) {
            HStack(spacing: 3) {
                Image(systemName: "square.and.arrow.up")
                    .font(.caption)
                Text("Share")
                    .font(.caption2)
                    .fontWeight(.medium)
            }
            .foregroundColor(.orange)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(Color(.systemGray6))
            .cornerRadius(6)
        }
    }

    private var favoriteButton: some View {
        Button(action: onFavoriteToggle) {
            HStack(spacing: 3) {
                Image(systemName: roast.isFavorite ? "heart.fill" : "heart")
                    .font(.caption)
                Text(roast.isFavorite ? "Liked" : "Like")
                    .font(.caption2)
                    .fontWeight(.medium)
            }
            .foregroundColor(roast.isFavorite ? .red : .gray)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(Color(.systemGray6))
            .cornerRadius(6)
        }
    }

    private func getFlameColor(_ level: Int) -> Color {
        switch level {
        case 1: return .orange.opacity(0.6)
        case 2: return .orange.opacity(0.8)
        case 3: return .orange
        case 4: return .red.opacity(0.8)
        case 5: return .red
        default: return .orange
        }
    }
}

struct RoastPlaceholderView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "quote.bubble")
                .font(.system(size: 50))
                .foregroundColor(.gray.opacity(0.5))

            Text("Chọn danh mục và mức độ cay, sau đó nhấn tạo roast!")
                .font(.headline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .frame(height: 150)
        .background(Color(.systemGray6))
        .cornerRadius(16)
        .padding(.horizontal)
    }
}

struct CategoryPickerView: View {
    let selectedCategory: RoastCategory
    let onCategorySelected: (RoastCategory) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "tag.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.orange)

                    VStack(spacing: 8) {
                        Text("Chọn Chủ Đề Roast")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("Chọn tình huống công việc bạn muốn được roast")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.top, 20)
                .padding(.horizontal)

                // Categories Grid
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        ForEach(RoastCategory.allCases, id: \.self) { category in
                            CategoryCard(
                                category: category,
                                isSelected: category == selectedCategory,
                                onTap: {
                                    onCategorySelected(category)

                                    // Haptic feedback
                                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                                    impactFeedback.impactOccurred()

                                    // Delay dismiss for better UX
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                        dismiss()
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 24)
                    .padding(.bottom, 100)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Hủy") {
                        dismiss()
                    }
                    .foregroundColor(.secondary)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    if #available(iOS 16.0, *) {
                        Button("Xong") {
                            dismiss()
                        }
                        .foregroundColor(.orange)
                        .fontWeight(.semibold)
                    } else {
                        Button("Xong") {
                            dismiss()
                        }
                        .foregroundColor(.orange)
                    }
                }
            }
        }
    }
}

struct CategoryCard: View {
    let category: RoastCategory
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                // Icon with background
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.orange : Color.orange.opacity(0.1))
                        .frame(width: 50, height: 50)

                    Image(systemName: category.icon)
                        .font(.title2)
                        .foregroundColor(isSelected ? .white : .orange)
                }

                // Title and description
                VStack(spacing: 4) {
                    Text(category.displayName)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)

                    Text(category.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                }

                // Selection indicator
                if isSelected {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                        Text("Đã chọn")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(.green)
                    }
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .frame(height: 140)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(isSelected ? 0.15 : 0.08), radius: isSelected ? 12 : 6, x: 0, y: isSelected ? 6 : 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.orange : Color.clear, lineWidth: 2)
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    RoastGeneratorView()
}
