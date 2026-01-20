import SwiftUI

struct FavoritesView: View {
    @StateObject private var viewModel = FavoritesViewModel()
    @EnvironmentObject var localizationManager: LocalizationManager
    @State private var searchText = ""
    let onNavigateToRoastGenerator: () -> Void
    @State private var showingShareSheet = false
    @State private var shareText = ""

    var body: some View {
        NavigationView {
            VStack {
                if viewModel.favoriteRoasts.isEmpty {
                    EmptyFavoritesView(onNavigateToRoastGenerator: onNavigateToRoastGenerator)
                } else {
                    List {
                        ForEach(filteredFavorites) { roast in
                            FavoriteRoastRowView(roast: roast) {
                                viewModel.toggleFavorite(roast: roast)
                            } onShare: {
                                shareRoast(roast)
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                    .searchable(text: $searchText, prompt: localizationManager.searchFavorites)
                }
            }
            .navigationTitle(localizationManager.tabFavorites)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: shareAllFavorites) {
                            Label(Strings.Favorites.shareAll.localized(localizationManager.currentLanguage), systemImage: "square.and.arrow.up")
                        }

                        Button(action: viewModel.clearAllFavorites) {
                            Label(Strings.Favorites.clearAll.localized(localizationManager.currentLanguage), systemImage: "heart.slash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .accessibilityLabel(localizationManager.currentLanguage == "en" ? "More options" : "Tùy chọn khác")
                            .accessibilityHint(localizationManager.currentLanguage == "en" ? "Double tap to show more options" : "Nhấn đúp để hiển thị thêm tùy chọn")
                    }
                }
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(activityItems: [shareText])
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
            viewModel.loadFavorites()
        }
        .dismissKeyboard()
    }

    private var filteredFavorites: [Roast] {
        if searchText.isEmpty {
            return viewModel.favoriteRoasts
        } else {
            return viewModel.favoriteRoasts.filter { roast in
                roast.content.localizedCaseInsensitiveContains(searchText) ||
                localizationManager.categoryName(roast.category).localizedCaseInsensitiveContains(searchText)
            }
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

    private func shareAllFavorites() {
        let allFavorites = viewModel.favoriteRoasts.map { roast in
            "🔥 \(localizationManager.categoryName(roast.category)): \(roast.content)"
        }.joined(separator: "\n\n")

        let collectionText = Strings.Favorites.myCollection.localized(localizationManager.currentLanguage)
        let createdByText = Strings.Favorites.createdByApp.localized(localizationManager.currentLanguage)

        shareText = """
        🔥 \(collectionText)

        \(allFavorites)

        \(createdByText)
        """
        showingShareSheet = true
    }
}

struct FavoriteRoastRowView: View {
    @EnvironmentObject var localizationManager: LocalizationManager
    let roast: Roast
    let onFavoriteToggle: () -> Void
    let onShare: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
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
            }

            Text(roast.content)
                .font(.body)
                .lineLimit(nil)
                .multilineTextAlignment(.leading)

            HStack {
                Text(roast.createdAt, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Button(action: onShare) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.body)
                        .foregroundColor(.blue)
                }
                .accessibilityLabel(localizationManager.currentLanguage == "en" ? "Share roast" : "Chia sẻ roast")
                .accessibilityHint(localizationManager.currentLanguage == "en" ? "Double tap to share this roast" : "Nhấn đúp để chia sẻ roast này")

                Button(action: onFavoriteToggle) {
                    Image(systemName: "heart.fill")
                        .font(.body)
                        .foregroundColor(.red)
                }
                .accessibilityLabel(localizationManager.currentLanguage == "en" ? "Remove from favorites" : "Xóa khỏi yêu thích")
                .accessibilityHint(localizationManager.currentLanguage == "en" ? "Double tap to remove from favorites" : "Nhấn đúp để xóa khỏi yêu thích")
            }
        }
        .padding(.vertical, 8)
        .accessibilityElement(children: .contain)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(action: onFavoriteToggle) {
                Label(Strings.Favorites.removeFromFavorites.localized(localizationManager.currentLanguage), systemImage: "heart.slash")
            }
            .tint(.red)

            Button(action: onShare) {
                Label(Strings.Common.share.localized(localizationManager.currentLanguage), systemImage: "square.and.arrow.up")
            }
            .tint(.blue)
        }
    }
}

struct EmptyFavoritesView: View {
    @EnvironmentObject var localizationManager: LocalizationManager
    let onNavigateToRoastGenerator: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "heart.slash")
                .font(.largeTitle)
                .foregroundColor(.gray.opacity(0.5))
                .accessibilityHidden(true)

            Text(Strings.Favorites.emptyTitle.localized(localizationManager.currentLanguage))
                .font(.title2.weight(.semibold))
                .foregroundColor(.secondary)

            Text(Strings.Favorites.emptyMessage.localized(localizationManager.currentLanguage))
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button(action: onNavigateToRoastGenerator) {
                HStack {
                    Image(systemName: "sparkles")
                    Text(Strings.Favorites.createNewRoast.localized(localizationManager.currentLanguage))
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
            .accessibilityLabel(Strings.Favorites.createNewRoast.localized(localizationManager.currentLanguage))
            .accessibilityHint(localizationManager.currentLanguage == "en" ? "Double tap to create a new roast" : "Nhấn đúp để tạo roast mới")
        }
        .padding()
        .accessibilityElement(children: .contain)
    }
}
