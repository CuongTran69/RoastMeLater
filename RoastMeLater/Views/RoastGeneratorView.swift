import SwiftUI
import UIKit

struct RoastGeneratorView: View {
    @StateObject private var viewModel = RoastGeneratorViewModel()
    @EnvironmentObject var localizationManager: LocalizationManager
    @State private var showingCategoryPicker = false
    @State private var isGenerating = false
    @State private var showCopySuccess = false
    @State private var showingSharePreview = false

    private let primaryColor = Constants.UI.Colors.primary
    private let accentColor = Constants.UI.Colors.accent

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    roastDisplaySection
                    controlsSection
                    generateButton
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
        }
        .overlay(toastOverlay)
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
        .sheet(isPresented: $showingSharePreview) {
            if let currentRoast = viewModel.currentRoast {
                SharePreviewView(roast: currentRoast)
            }
        }
        .alert(
            localizationManager.currentLanguage == "en" ? "Error" : "Lỗi",
            isPresented: $viewModel.showError
        ) {
            Button(localizationManager.currentLanguage == "en" ? "OK" : "Đồng ý", role: .cancel) {
                viewModel.showError = false
            }
            Button(localizationManager.currentLanguage == "en" ? "Retry" : "Thử lại") {
                viewModel.showError = false
                generateRoast()
            }
        } message: {
            Text(viewModel.errorMessage ?? (localizationManager.currentLanguage == "en" ? "An error occurred" : "Có lỗi xảy ra"))
        }
        .onReceive(viewModel.$isLoading) { loading in
            isGenerating = loading
        }
    }

    // MARK: - Roast Display Section
    private var roastDisplaySection: some View {
        Group {
            if let currentRoast = viewModel.currentRoast {
                RoastCardView(
                    roast: currentRoast,
                    onFavoriteToggle: { viewModel.toggleFavorite(roast: currentRoast) },
                    onCopy: {
                        viewModel.copyRoastToClipboard()
                        showCopySuccess = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            showCopySuccess = false
                        }
                    },
                    onShare: { showingSharePreview = true }
                )
                .id(currentRoast.id)
            } else {
                RoastPlaceholderView()
                    .id("placeholder")
            }
        }
        .transition(.opacity.combined(with: .scale(scale: 0.98)))
        .animation(.easeInOut(duration: 0.3), value: viewModel.currentRoast?.id)
    }

    // MARK: - Controls Section
    private var controlsSection: some View {
        VStack(spacing: 12) {
            categorySelector
            spiceLevelSelector
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }

    private var categorySelector: some View {
        Button(action: {
            showingCategoryPicker = true
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(primaryColor.opacity(0.12))
                        .frame(width: 36, height: 36)
                    Image(systemName: viewModel.selectedCategory.icon)
                        .font(.body.weight(.semibold))
                        .foregroundColor(primaryColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(localizationManager.category)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(localizationManager.categoryName(viewModel.selectedCategory))
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.primary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.secondary)
            }
            .padding(12)
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .accessibilityLabel("\(localizationManager.category): \(localizationManager.categoryName(viewModel.selectedCategory))")
        .accessibilityHint(localizationManager.currentLanguage == "en" ? "Double tap to change category" : "Nhấn đúp để thay đổi danh mục")
    }

    private var spiceLevelSelector: some View {
        VStack(spacing: 10) {
            HStack {
                Text(localizationManager.spiceLevel)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.secondary)
                Spacer()
                Text(getSpiceLevelDescription(viewModel.spiceLevel))
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(primaryColor)
            }

            HStack(spacing: 0) {
                ForEach(1...5, id: \.self) { level in
                    Button(action: {
                        viewModel.updateSpiceLevel(level)
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: level <= viewModel.spiceLevel ? "flame.fill" : "flame")
                                .font(.title3)
                                .foregroundColor(level <= viewModel.spiceLevel ? getFlameColor(level) : Color(.systemGray4))
                            Text("\(level)")
                                .font(.caption2.weight(.medium))
                                .foregroundColor(level <= viewModel.spiceLevel ? .primary : .secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            level == viewModel.spiceLevel ?
                            primaryColor.opacity(0.1) : Color.clear
                        )
                        .cornerRadius(8)
                    }
                    .accessibilityLabel(localizationManager.currentLanguage == "en" ? "Spice level \(level)" : "Độ cay \(level)")
                    .accessibilityHint(level == viewModel.spiceLevel
                        ? (localizationManager.currentLanguage == "en" ? "Currently selected" : "Đang được chọn")
                        : (localizationManager.currentLanguage == "en" ? "Double tap to select" : "Nhấn đúp để chọn"))
                    .accessibilityAddTraits(level == viewModel.spiceLevel ? .isSelected : [])
                }
            }
            .padding(4)
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(localizationManager.spiceLevel)
    }

    // MARK: - Generate Button
    private var generateButton: some View {
        Button(action: generateRoast) {
            HStack(spacing: 10) {
                if isGenerating {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.9)
                } else {
                    Image(systemName: "sparkles")
                        .font(.headline)
                }
                Text(isGenerating ? localizationManager.generating : localizationManager.generateRoast)
                    .font(.headline)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(
                LinearGradient(
                    colors: [Constants.UI.Colors.gradientStart, Constants.UI.Colors.gradientEnd],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(14)
            .shadow(color: primaryColor.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .disabled(isGenerating)
        .opacity(isGenerating ? 0.8 : 1.0)
        .accessibilityLabel(isGenerating ? localizationManager.generating : localizationManager.generateRoast)
        .accessibilityHint(isGenerating
            ? (localizationManager.currentLanguage == "en" ? "Please wait while generating" : "Vui lòng đợi trong khi tạo")
            : (localizationManager.currentLanguage == "en" ? "Double tap to generate a new roast" : "Nhấn đúp để tạo roast mới"))
        .accessibilityAddTraits(.isButton)
    }

    // MARK: - Toast Overlay
    private var toastOverlay: some View {
        VStack {
            if showCopySuccess {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text(localizationManager.currentLanguage == "en" ? "Copied!" : "Đã copy!")
                        .font(.subheadline.weight(.medium))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color(.systemBackground))
                .cornerRadius(20)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
            Spacer()
        }
        .padding(.top, 60)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showCopySuccess)
    }

    // MARK: - Actions
    private func generateRoast() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        viewModel.generateRoast(category: viewModel.selectedCategory, spiceLevel: viewModel.spiceLevel)
    }

    private func getSpiceLevelDescription(_ level: Int) -> String {
        return localizationManager.spiceLevelName(level)
    }

    private func getFlameColor(_ level: Int) -> Color {
        switch level {
        case 1: return Constants.UI.Colors.accent
        case 2: return Constants.UI.Colors.accent
        case 3: return Constants.UI.Colors.primary
        case 4: return Constants.UI.Colors.primary
        case 5: return Constants.UI.Colors.gradientEnd
        default: return Constants.UI.Colors.primary
        }
    }
}

struct RoastCardView: View {
    @EnvironmentObject var localizationManager: LocalizationManager
    let roast: Roast
    let onFavoriteToggle: () -> Void
    let onCopy: () -> Void
    let onShare: () -> Void
    @State private var showCopyFeedback = false

    private let primaryColor = Constants.UI.Colors.primary
    private let accentColor = Constants.UI.Colors.accent

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            headerSection
            contentSection
            actionSection
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }

    // MARK: - Header
    private var headerSection: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: roast.category.icon)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(primaryColor)
                Text(localizationManager.categoryName(roast.category))
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.primary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(primaryColor.opacity(0.1))
            .cornerRadius(8)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(localizationManager.currentLanguage == "en" ? "Category: \(localizationManager.categoryName(roast.category))" : "Danh mục: \(localizationManager.categoryName(roast.category))")

            Spacer()

            HStack(spacing: 3) {
                ForEach(1...roast.spiceLevel, id: \.self) { level in
                    Image(systemName: "flame.fill")
                        .font(.caption2)
                        .foregroundColor(getFlameColor(level))
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(localizationManager.currentLanguage == "en" ? "Spice level \(roast.spiceLevel) of 5" : "Độ cay \(roast.spiceLevel) trên 5")
        }
    }

    // MARK: - Content
    private var contentSection: some View {
        Text(roast.content)
            .font(.body)
            .lineSpacing(5)
            .foregroundColor(.primary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 4)
            .accessibilityLabel(roast.content)
    }

    // MARK: - Actions
    private var actionSection: some View {
        HStack(spacing: 0) {
            Text(roast.createdAt, style: .time)
                .font(.caption2)
                .foregroundColor(.secondary)
                .accessibilityLabel(localizationManager.currentLanguage == "en" ? "Created at \(roast.createdAt, style: .time)" : "Tạo lúc \(roast.createdAt, style: .time)")

            Spacer()

            HStack(spacing: 16) {
                Button(action: {
                    onCopy()
                    showCopyFeedback = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        showCopyFeedback = false
                    }
                }) {
                    Image(systemName: showCopyFeedback ? "checkmark" : "doc.on.doc")
                        .font(.body)
                        .foregroundColor(showCopyFeedback ? .green : .secondary)
                }
                .accessibilityLabel(showCopyFeedback
                    ? (localizationManager.currentLanguage == "en" ? "Copied" : "Đã sao chép")
                    : (localizationManager.currentLanguage == "en" ? "Copy roast" : "Sao chép roast"))
                .accessibilityHint(localizationManager.currentLanguage == "en" ? "Double tap to copy roast to clipboard" : "Nhấn đúp để sao chép roast")

                Button(action: onShare) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.body)
                        .foregroundColor(primaryColor)
                }
                .accessibilityLabel(localizationManager.currentLanguage == "en" ? "Share roast" : "Chia sẻ roast")
                .accessibilityHint(localizationManager.currentLanguage == "en" ? "Double tap to share this roast" : "Nhấn đúp để chia sẻ roast này")

                Button(action: onFavoriteToggle) {
                    Image(systemName: roast.isFavorite ? "heart.fill" : "heart")
                        .font(.body)
                        .foregroundColor(roast.isFavorite ? .red : .secondary)
                }
                .accessibilityLabel(roast.isFavorite
                    ? (localizationManager.currentLanguage == "en" ? "Remove from favorites" : "Xóa khỏi yêu thích")
                    : (localizationManager.currentLanguage == "en" ? "Add to favorites" : "Thêm vào yêu thích"))
                .accessibilityHint(roast.isFavorite
                    ? (localizationManager.currentLanguage == "en" ? "Double tap to remove from favorites" : "Nhấn đúp để xóa khỏi yêu thích")
                    : (localizationManager.currentLanguage == "en" ? "Double tap to add to favorites" : "Nhấn đúp để thêm vào yêu thích"))
            }
        }
        .padding(.top, 4)
    }

    private func getFlameColor(_ level: Int) -> Color {
        switch level {
        case 1: return Constants.UI.Colors.accent
        case 2: return Constants.UI.Colors.accent
        case 3: return Constants.UI.Colors.primary
        case 4: return Constants.UI.Colors.primary
        case 5: return Constants.UI.Colors.gradientEnd
        default: return Constants.UI.Colors.primary
        }
    }
}

struct RoastPlaceholderView: View {
    @EnvironmentObject var localizationManager: LocalizationManager

    private let primaryColor = Constants.UI.Colors.primary

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "flame")
                .font(.largeTitle)
                .foregroundColor(primaryColor.opacity(0.4))
                .accessibilityHidden(true)

            Text(localizationManager.currentLanguage == "en" ? "Tap the button below to generate a roast!" : "Nhấn nút bên dưới để tạo roast!")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(localizationManager.currentLanguage == "en" ? "No roast yet. Tap the button below to generate a roast!" : "Chưa có roast. Nhấn nút bên dưới để tạo roast!")
    }
}

struct CategoryPickerView: View {
    let selectedCategory: RoastCategory
    let onCategorySelected: (RoastCategory) -> Void
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var localizationManager: LocalizationManager

    private let primaryColor = Constants.UI.Colors.primary

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Text(localizationManager.currentLanguage == "en" ? "Choose a category" : "Chọn danh mục")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.top, 8)

                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        ForEach(RoastCategory.allCases, id: \.self) { category in
                            CategoryCard(
                                category: category,
                                isSelected: category == selectedCategory,
                                onTap: {
                                    onCategorySelected(category)
                                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                        dismiss()
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 40)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(localizationManager.selectCategory)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(localizationManager.currentLanguage == "en" ? "Cancel" : "Hủy") {
                        dismiss()
                    }
                    .foregroundColor(.secondary)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Text(localizationManager.done)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(primaryColor)
                }
            }
        }
    }
}

struct CategoryCard: View {
    let category: RoastCategory
    let isSelected: Bool
    let onTap: () -> Void
    @EnvironmentObject var localizationManager: LocalizationManager

    private let primaryColor = Constants.UI.Colors.primary

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(isSelected ? primaryColor : primaryColor.opacity(0.1))
                        .frame(width: 44, height: 44)

                    Image(systemName: category.icon)
                        .font(.body.weight(.semibold))
                        .foregroundColor(isSelected ? .white : primaryColor)
                }

                Text(localizationManager.categoryName(category))
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .padding(12)
            .frame(maxWidth: .infinity)
            .frame(height: 110)
            .background(Color(.systemBackground))
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? primaryColor : Color.clear, lineWidth: 2)
            )
            .shadow(color: .black.opacity(isSelected ? 0.08 : 0.04), radius: isSelected ? 6 : 3, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel(localizationManager.categoryName(category))
        .accessibilityHint(isSelected
            ? (localizationManager.currentLanguage == "en" ? "Currently selected" : "Đang được chọn")
            : (localizationManager.currentLanguage == "en" ? "Double tap to select this category" : "Nhấn đúp để chọn danh mục này"))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview {
    RoastGeneratorView()
}
