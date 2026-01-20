import SwiftUI
import Combine

struct RoastHistoryView: View {
    @StateObject private var viewModel = RoastHistoryViewModel()
    @EnvironmentObject var localizationManager: LocalizationManager
    @State private var searchText = ""
    @State private var debouncedSearchText = ""
    @State private var selectedCategory: RoastCategory? = nil
    @State private var showingFilterSheet = false
    @State private var displayedRoastsCount = 20 // Initial load count
    @State private var isPrefetching = false
    let onNavigateToRoastGenerator: () -> Void

    private let loadMoreThreshold = 5 // Load more when 5 items from bottom
    private let prefetchThreshold = 10 // Start prefetching when 10 items from bottom

    // Debounce timer
    @State private var searchDebounceTimer: AnyCancellable?
    
    var body: some View {
        NavigationView {
            VStack {
                if viewModel.roasts.isEmpty {
                    EmptyHistoryView(onNavigateToRoastGenerator: onNavigateToRoastGenerator)
                } else {
                    List {
                        ForEach(Array(displayedRoasts.enumerated()), id: \.element.id) { index, roast in
                            RoastHistoryRowView(roast: roast) {
                                viewModel.toggleFavorite(roast: roast)
                            } onDelete: {
                                viewModel.deleteRoast(roast: roast)
                            }
                            .onAppear {
                                // Background prefetch when approaching end
                                if shouldPrefetch(currentIndex: index) {
                                    prefetchNextPage()
                                }

                                // Load more when approaching end
                                if shouldLoadMore(currentIndex: index) {
                                    loadMoreRoasts()
                                }
                            }
                        }
                        .onDelete(perform: deleteRoasts)

                        // Loading indicator at bottom
                        if hasMoreRoasts {
                            HStack {
                                Spacer()
                                ProgressView()
                                    .padding()
                                Spacer()
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                    .searchable(text: $searchText, prompt: localizationManager.searchRoasts)
                    .onChange(of: searchText) { newValue in
                        debounceSearch(newValue)
                    }
                }
            }
            .navigationTitle(localizationManager.tabHistory)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { showingFilterSheet = true }) {
                            Label(Strings.History.filterByCategory.localized(localizationManager.currentLanguage), systemImage: "line.3.horizontal.decrease.circle")
                        }

                        Button(action: viewModel.clearAllHistory) {
                            Label(Strings.History.clearAll.localized(localizationManager.currentLanguage), systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .accessibilityLabel(localizationManager.currentLanguage == "en" ? "More options" : "Tùy chọn khác")
                            .accessibilityHint(localizationManager.currentLanguage == "en" ? "Double tap to show more options" : "Nhấn đúp để hiển thị thêm tùy chọn")
                    }
                }
            }
        }
        .sheet(isPresented: $showingFilterSheet) {
            FilterSheetView(selectedCategory: $selectedCategory)
        }
        .alert(
            localizationManager.currentLanguage == "en" ? "Error" : "Lỗi",
            isPresented: $viewModel.showError
        ) {
            Button(localizationManager.currentLanguage == "en" ? "OK" : "Đồng ý", role: .cancel) {
                viewModel.showError = false
            }
        } message: {
            Text(viewModel.errorMessage ?? (localizationManager.currentLanguage == "en" ? "An error occurred" : "Có lỗi xảy ra"))
        }
        .onAppear {
            viewModel.loadRoasts()
        }
        .dismissKeyboard()
    }
    
    private var filteredRoasts: [Roast] {
        var roasts = viewModel.roasts

        // Filter by debounced search text (not immediate searchText)
        if !debouncedSearchText.isEmpty {
            roasts = roasts.filter { roast in
                roast.content.localizedCaseInsensitiveContains(debouncedSearchText) ||
                localizationManager.categoryName(roast.category).localizedCaseInsensitiveContains(debouncedSearchText)
            }
        }

        // Filter by category
        if let selectedCategory = selectedCategory {
            roasts = roasts.filter { $0.category == selectedCategory }
        }

        return roasts
    }

    private func debounceSearch(_ text: String) {
        // Cancel previous timer
        searchDebounceTimer?.cancel()

        // Create new timer that fires after 300ms
        searchDebounceTimer = Just(text)
            .delay(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [self] debouncedText in
                debouncedSearchText = debouncedText
                // Reset displayed count when search changes
                displayedRoastsCount = 20
            }
    }

    private var displayedRoasts: [Roast] {
        let filtered = filteredRoasts
        // Only display up to displayedRoastsCount items for performance
        return Array(filtered.prefix(displayedRoastsCount))
    }

    private var hasMoreRoasts: Bool {
        return filteredRoasts.count > displayedRoastsCount
    }

    private func shouldLoadMore(currentIndex: Int) -> Bool {
        return currentIndex >= displayedRoastsCount - loadMoreThreshold && hasMoreRoasts
    }

    private func shouldPrefetch(currentIndex: Int) -> Bool {
        return currentIndex >= displayedRoastsCount - prefetchThreshold && hasMoreRoasts && !isPrefetching
    }

    private func prefetchNextPage() {
        guard !isPrefetching else { return }

        isPrefetching = true

        // Simulate background prefetch with slight delay
        DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 0.1) { [self] in
            // Prefetch logic - prepare next batch
            let nextBatchStart = displayedRoastsCount
            let nextBatchEnd = min(displayedRoastsCount + 20, filteredRoasts.count)

            // Access the next batch to warm up cache
            _ = Array(filteredRoasts[nextBatchStart..<nextBatchEnd])

            DispatchQueue.main.async {
                isPrefetching = false
            }
        }
    }

    private func loadMoreRoasts() {
        let increment = 20
        displayedRoastsCount = min(displayedRoastsCount + increment, filteredRoasts.count)
    }
    
    private func deleteRoasts(offsets: IndexSet) {
        for index in offsets {
            let roast = filteredRoasts[index]
            viewModel.deleteRoast(roast: roast)
        }
    }
}

struct RoastHistoryRowView: View {
    @EnvironmentObject var localizationManager: LocalizationManager
    let roast: Roast
    let onFavoriteToggle: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: roast.category.icon)
                    .foregroundColor(.orange)
                    .frame(width: 20)
                    .accessibilityHidden(true)

                Text(localizationManager.categoryName(roast.category))
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                HStack(spacing: 2) {
                    ForEach(1...roast.spiceLevel, id: \.self) { _ in
                        Image(systemName: "flame.fill")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(localizationManager.currentLanguage == "en" ? "Spice level \(roast.spiceLevel) of 5" : "Độ cay \(roast.spiceLevel) trên 5")

                Text(formatTimeOnly(roast.createdAt))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Text(roast.content)
                .font(.body)
                .lineLimit(3)
                .multilineTextAlignment(.leading)

            HStack {
                Spacer()

                Button(action: {
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                    onFavoriteToggle()
                }) {
                    Image(systemName: roast.isFavorite ? "heart.fill" : "heart")
                        .foregroundColor(roast.isFavorite ? .red : .gray)
                        .font(.title3)
                }
                .buttonStyle(PlainButtonStyle())
                .accessibilityLabel(roast.isFavorite
                    ? (localizationManager.currentLanguage == "en" ? "Remove from favorites" : "Xóa khỏi yêu thích")
                    : (localizationManager.currentLanguage == "en" ? "Add to favorites" : "Thêm vào yêu thích"))
                .accessibilityHint(roast.isFavorite
                    ? (localizationManager.currentLanguage == "en" ? "Double tap to remove from favorites" : "Nhấn đúp để xóa khỏi yêu thích")
                    : (localizationManager.currentLanguage == "en" ? "Double tap to add to favorites" : "Nhấn đúp để thêm vào yêu thích"))

                Button(action: {
                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                    impactFeedback.impactOccurred()
                    onDelete()
                }) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                        .font(.title3)
                }
                .buttonStyle(PlainButtonStyle())
                .accessibilityLabel(localizationManager.currentLanguage == "en" ? "Delete roast" : "Xóa roast")
                .accessibilityHint(localizationManager.currentLanguage == "en" ? "Double tap to delete this roast" : "Nhấn đúp để xóa roast này")
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .contain)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(action: onDelete) {
                Label(Strings.Common.delete.localized(localizationManager.currentLanguage), systemImage: "trash")
            }
            .tint(.red)
        }
        .swipeActions(edge: .leading, allowsFullSwipe: false) {
            Button(action: onFavoriteToggle) {
                Label(roast.isFavorite
                      ? Strings.Favorites.removeFromFavorites.localized(localizationManager.currentLanguage)
                      : Strings.TabBar.favorites.localized(localizationManager.currentLanguage),
                      systemImage: roast.isFavorite ? "heart.slash" : "heart")
            }
            .tint(.orange)
        }
    }

    private func formatTimeOnly(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: date)
    }
}

struct EmptyHistoryView: View {
    @EnvironmentObject var localizationManager: LocalizationManager
    let onNavigateToRoastGenerator: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "clock.badge.questionmark")
                .font(.largeTitle)
                .foregroundColor(.gray.opacity(0.5))
                .accessibilityHidden(true)

            Text(Strings.History.emptyTitle.localized(localizationManager.currentLanguage))
                .font(.title2.weight(.semibold))
                .foregroundColor(.secondary)

            Text(Strings.History.emptyMessage.localized(localizationManager.currentLanguage))
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button(action: onNavigateToRoastGenerator) {
                HStack {
                    Image(systemName: "sparkles")
                    Text(Strings.History.createNewRoast.localized(localizationManager.currentLanguage))
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
            .accessibilityLabel(Strings.History.createNewRoast.localized(localizationManager.currentLanguage))
            .accessibilityHint(localizationManager.currentLanguage == "en" ? "Double tap to create a new roast" : "Nhấn đúp để tạo roast mới")
        }
        .padding()
        .accessibilityElement(children: .contain)
    }
}

struct FilterSheetView: View {
    @EnvironmentObject var localizationManager: LocalizationManager
    @Binding var selectedCategory: RoastCategory?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            List {
                Section(Strings.RoastGenerator.category.localized(localizationManager.currentLanguage)) {
                    Button(action: {
                        selectedCategory = nil
                        dismiss()
                    }) {
                        HStack {
                            Text(Strings.Favorites.allCategories.localized(localizationManager.currentLanguage))
                            Spacer()
                            if selectedCategory == nil {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.orange)
                            }
                        }
                    }
                    .foregroundColor(.primary)
                    .accessibilityLabel(Strings.Favorites.allCategories.localized(localizationManager.currentLanguage))
                    .accessibilityHint(localizationManager.currentLanguage == "en" ? "Double tap to show all categories" : "Nhấn đúp để hiển thị tất cả danh mục")
                    .accessibilityAddTraits(selectedCategory == nil ? .isSelected : [])

                    ForEach(RoastCategory.allCases, id: \.self) { category in
                        Button(action: {
                            selectedCategory = category
                            dismiss()
                        }) {
                            HStack {
                                Image(systemName: category.icon)
                                    .foregroundColor(.orange)
                                    .frame(width: 20)

                                Text(localizationManager.categoryName(category))

                                Spacer()

                                if selectedCategory == category {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.orange)
                                }
                            }
                        }
                        .foregroundColor(.primary)
                        .accessibilityLabel(localizationManager.categoryName(category))
                        .accessibilityHint(localizationManager.currentLanguage == "en" ? "Double tap to filter by this category" : "Nhấn đúp để lọc theo danh mục này")
                        .accessibilityAddTraits(selectedCategory == category ? .isSelected : [])
                    }
                }
            }
            .navigationTitle(Strings.History.filterHistory.localized(localizationManager.currentLanguage))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(Strings.Common.done.localized(localizationManager.currentLanguage)) {
                        dismiss()
                    }
                    .accessibilityLabel(Strings.Common.done.localized(localizationManager.currentLanguage))
                    .accessibilityHint(localizationManager.currentLanguage == "en" ? "Double tap to close filter" : "Nhấn đúp để đóng bộ lọc")
                }
            }
        }
    }
}

#Preview {
    RoastHistoryView(onNavigateToRoastGenerator: {})
}
