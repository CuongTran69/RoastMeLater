import SwiftUI

struct LibraryView: View {
    @StateObject private var viewModel = LibraryViewModel()
    @EnvironmentObject var localizationManager: LocalizationManager
    @State private var showingFilterSheet = false
    @State private var showingShareSheet = false
    @State private var shareText = ""
    let onNavigateToRoastGenerator: () -> Void

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                segmentedControl
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                if viewModel.isLoading && viewModel.displayedRoasts.isEmpty {
                    loadingView
                } else if viewModel.displayedRoasts.isEmpty {
                    LibraryEmptyStateView(
                        filterMode: viewModel.filterMode,
                        onNavigateToRoastGenerator: onNavigateToRoastGenerator
                    )
                } else {
                    roastList
                }
            }
            .navigationTitle(Strings.Library.tabName.localized(localizationManager.currentLanguage))
            .searchable(
                text: $viewModel.searchText,
                prompt: Strings.Library.searchPlaceholder.localized(localizationManager.currentLanguage)
            )
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    toolbarMenu
                }
            }
        }
        .sheet(isPresented: $showingFilterSheet) {
            LibraryFilterSheetView(selectedCategory: $viewModel.selectedCategory)
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(activityItems: [shareText])
        }
        .onAppear {
            viewModel.loadRoasts()
        }
        .dismissKeyboard()
    }

    private var segmentedControl: some View {
        Picker("", selection: $viewModel.filterMode) {
            Text(Strings.Library.segmentAll.localized(localizationManager.currentLanguage))
                .tag(LibraryFilterMode.all)
            Text(Strings.Library.segmentFavorites.localized(localizationManager.currentLanguage))
                .tag(LibraryFilterMode.favoritesOnly)
        }
        .pickerStyle(.segmented)
        .onChange(of: viewModel.filterMode) { _ in
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
        }
    }

    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView()
                .scaleEffect(1.2)
            Spacer()
        }
    }

    private var roastList: some View {
        List {
            ForEach(Array(viewModel.displayedRoasts.enumerated()), id: \.element.id) { index, roast in
                LibraryRoastRowView(
                    roast: roast,
                    onFavoriteToggle: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            viewModel.toggleFavorite(roast: roast)
                        }
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                    },
                    onDelete: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            viewModel.deleteRoast(roast: roast)
                        }
                        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                        impactFeedback.impactOccurred()
                    },
                    onShare: {
                        shareRoast(roast)
                    }
                )
                .onAppear {
                    if index == viewModel.displayedRoasts.count - 1 {
                        viewModel.loadMore()
                    }
                }
            }

            if viewModel.isLoadingMore {
                HStack {
                    Spacer()
                    ProgressView()
                        .padding()
                    Spacer()
                }
            }
        }
        .listStyle(.plain)
        .refreshable {
            viewModel.loadRoasts()
        }
    }

    private var toolbarMenu: some View {
        Menu {
            Button(action: { showingFilterSheet = true }) {
                Label(
                    Strings.Library.filterByCategory.localized(localizationManager.currentLanguage),
                    systemImage: "line.3.horizontal.decrease.circle"
                )
            }

            if viewModel.selectedCategory != nil {
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        viewModel.clearFilters()
                    }
                }) {
                    Label(
                        Strings.Library.allCategories.localized(localizationManager.currentLanguage),
                        systemImage: "xmark.circle"
                    )
                }
            }

            Divider()

            Button(role: .destructive, action: {
                // Clear all action would go here
            }) {
                Label(
                    Strings.Library.clearAll.localized(localizationManager.currentLanguage),
                    systemImage: "trash"
                )
            }
        } label: {
            Image(systemName: "ellipsis.circle")
        }
    }

    private func shareRoast(_ roast: Roast) {
        let spiceLevelText = Strings.Favorites.spiceLevel.localized(localizationManager.currentLanguage)
        let createdByText = Strings.Favorites.createdByApp.localized(localizationManager.currentLanguage)

        shareText = """
        🔥 RoastMe - \(localizationManager.categoryName(roast.category))

        \(roast.content)

        \(spiceLevelText): \(String(repeating: "🌶️", count: roast.spiceLevel))

        \(createdByText)
        """
        showingShareSheet = true
    }
}

// MARK: - LibraryRoastRowView

struct LibraryRoastRowView: View {
    @EnvironmentObject var localizationManager: LocalizationManager
    let roast: Roast
    let onFavoriteToggle: () -> Void
    let onDelete: () -> Void
    let onShare: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            headerRow
            contentText
            footerRow
        }
        .padding(.vertical, 12)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive, action: onDelete) {
                Label(
                    Strings.Library.delete.localized(localizationManager.currentLanguage),
                    systemImage: "trash"
                )
            }
            .tint(.red)

            Button(action: onShare) {
                Label(
                    Strings.Library.share.localized(localizationManager.currentLanguage),
                    systemImage: "square.and.arrow.up"
                )
            }
            .tint(.blue)
        }
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button(action: onFavoriteToggle) {
                Label(
                    roast.isFavorite
                        ? Strings.Library.removeFromFavorites.localized(localizationManager.currentLanguage)
                        : Strings.Library.addToFavorites.localized(localizationManager.currentLanguage),
                    systemImage: roast.isFavorite ? "heart.slash.fill" : "heart.fill"
                )
            }
            .tint(.orange)
        }
    }

    private var headerRow: some View {
        HStack(spacing: 8) {
            Image(systemName: roast.category.icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.orange)
                .frame(width: 24, height: 24)
                .background(Color.orange.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 6))

            Text(localizationManager.categoryName(roast.category))
                .font(.subheadline.weight(.medium))
                .foregroundColor(.secondary)

            Spacer()

            spiceLevelIndicator
        }
    }

    private var spiceLevelIndicator: some View {
        HStack(spacing: 2) {
            ForEach(1...5, id: \.self) { level in
                Image(systemName: "flame.fill")
                    .font(.system(size: 10))
                    .foregroundColor(level <= roast.spiceLevel ? .orange : .gray.opacity(0.3))
            }
        }
    }

    private var contentText: some View {
        Text(roast.content)
            .font(.body)
            .lineLimit(4)
            .multilineTextAlignment(.leading)
            .foregroundColor(.primary)
    }

    private var footerRow: some View {
        HStack(spacing: 24) {
            dateLabel

            Spacer()

            actionButtons
        }
    }

    private var dateLabel: some View {
        HStack(spacing: 4) {
            Image(systemName: "calendar")
                .font(.caption2)
                .foregroundColor(.secondary)

            Text(roast.createdAt, style: .date)
                .font(.caption)
                .foregroundColor(.secondary)

            Text("•")
                .foregroundColor(.secondary)

            Text(formatTimeOnly(roast.createdAt))
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private var actionButtons: some View {
        HStack(spacing: 16) {
            Button(action: onShare) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 16))
                    .foregroundColor(.blue)
            }
            .buttonStyle(.plain)

            Button(action: onFavoriteToggle) {
                Image(systemName: roast.isFavorite ? "heart.fill" : "heart")
                    .font(.system(size: 16))
                    .foregroundColor(roast.isFavorite ? .red : .gray)
            }
            .buttonStyle(.plain)

            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.system(size: 16))
                    .foregroundColor(.red.opacity(0.8))
            }
            .buttonStyle(.plain)
        }
    }

    private func formatTimeOnly(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: date)
    }
}


// MARK: - LibraryEmptyStateView

struct LibraryEmptyStateView: View {
    @EnvironmentObject var localizationManager: LocalizationManager
    let filterMode: LibraryFilterMode
    let onNavigateToRoastGenerator: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            iconView

            titleAndMessage

            actionButton

            Spacer()
        }
        .padding(.horizontal, 32)
    }

    private var iconView: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [.orange.opacity(0.2), .red.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 120, height: 120)

            Image(systemName: filterMode == .all ? "tray" : "heart.slash")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.orange, .red],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
    }

    private var titleAndMessage: some View {
        VStack(spacing: 12) {
            Text(emptyTitle)
                .font(.title2.weight(.bold))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)

            Text(emptyMessage)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
    }

    private var emptyTitle: String {
        filterMode == .all
            ? Strings.Library.emptyAllTitle.localized(localizationManager.currentLanguage)
            : Strings.Library.emptyFavoritesTitle.localized(localizationManager.currentLanguage)
    }

    private var emptyMessage: String {
        filterMode == .all
            ? Strings.Library.emptyAllMessage.localized(localizationManager.currentLanguage)
            : Strings.Library.emptyFavoritesMessage.localized(localizationManager.currentLanguage)
    }

    private var actionButton: some View {
        Button(action: {
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            onNavigateToRoastGenerator()
        }) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.headline)
                Text(Strings.Library.createNewRoast.localized(localizationManager.currentLanguage))
                    .font(.headline.weight(.semibold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(
                LinearGradient(
                    colors: [.orange, .red],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(Capsule())
            .shadow(color: .orange.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .padding(.top, 8)
    }
}

// MARK: - LibraryFilterSheetView

struct LibraryFilterSheetView: View {
    @EnvironmentObject var localizationManager: LocalizationManager
    @Binding var selectedCategory: RoastCategory?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            List {
                Section(Strings.RoastGenerator.category.localized(localizationManager.currentLanguage)) {
                    allCategoriesButton

                    ForEach(RoastCategory.allCases, id: \.self) { category in
                        categoryButton(category)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(Strings.Library.filterByCategory.localized(localizationManager.currentLanguage))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(Strings.Common.done.localized(localizationManager.currentLanguage)) {
                        dismiss()
                    }
                    .font(.body.weight(.semibold))
                }
            }
        }
    }

    private var allCategoriesButton: some View {
        Button(action: {
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            selectedCategory = nil
            dismiss()
        }) {
            HStack {
                Image(systemName: "square.grid.2x2")
                    .foregroundColor(.orange)
                    .frame(width: 24)

                Text(Strings.Library.allCategories.localized(localizationManager.currentLanguage))
                    .foregroundColor(.primary)

                Spacer()

                if selectedCategory == nil {
                    Image(systemName: "checkmark")
                        .foregroundColor(.orange)
                        .font(.body.weight(.semibold))
                }
            }
        }
    }

    private func categoryButton(_ category: RoastCategory) -> some View {
        Button(action: {
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            selectedCategory = category
            dismiss()
        }) {
            HStack {
                Image(systemName: category.icon)
                    .foregroundColor(.orange)
                    .frame(width: 24)

                Text(localizationManager.categoryName(category))
                    .foregroundColor(.primary)

                Spacer()

                if selectedCategory == category {
                    Image(systemName: "checkmark")
                        .foregroundColor(.orange)
                        .font(.body.weight(.semibold))
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    LibraryView(onNavigateToRoastGenerator: {})
        .environmentObject(LocalizationManager.shared)
}

