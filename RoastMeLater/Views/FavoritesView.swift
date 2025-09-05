import SwiftUI

struct FavoritesView: View {
    @StateObject private var viewModel = FavoritesViewModel()
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
                    .searchable(text: $searchText, prompt: "Tìm kiếm roast yêu thích...")
                }
            }
            .navigationTitle("Yêu Thích")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: shareAllFavorites) {
                            Label("Chia sẻ tất cả", systemImage: "square.and.arrow.up")
                        }
                        
                        Button(action: viewModel.clearAllFavorites) {
                            Label("Xóa tất cả", systemImage: "heart.slash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(activityItems: [shareText])
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
                roast.category.displayName.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    private func shareRoast(_ roast: Roast) {
        shareText = """
        🔥 RoastMe - \(roast.category.displayName)
        
        \(roast.content)
        
        Mức độ cay: \(String(repeating: "🌶️", count: roast.spiceLevel))
        
        Được tạo bởi RoastMe App
        """
        showingShareSheet = true
    }
    
    private func shareAllFavorites() {
        let allFavorites = viewModel.favoriteRoasts.map { roast in
            "🔥 \(roast.category.displayName): \(roast.content)"
        }.joined(separator: "\n\n")
        
        shareText = """
        🔥 Bộ sưu tập RoastMe yêu thích của tôi:
        
        \(allFavorites)
        
        Được tạo bởi RoastMe App
        """
        showingShareSheet = true
    }
}

struct FavoriteRoastRowView: View {
    let roast: Roast
    let onFavoriteToggle: () -> Void
    let onShare: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: roast.category.icon)
                    .foregroundColor(.orange)
                    .frame(width: 20)
                
                Text(roast.category.displayName)
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
                        .foregroundColor(.blue)
                }
                
                Button(action: onFavoriteToggle) {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.red)
                }
            }
        }
        .padding(.vertical, 8)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(action: onFavoriteToggle) {
                Label("Bỏ thích", systemImage: "heart.slash")
            }
            .tint(.red)
            
            Button(action: onShare) {
                Label("Chia sẻ", systemImage: "square.and.arrow.up")
            }
            .tint(.blue)
        }
    }
}

struct EmptyFavoritesView: View {
    let onNavigateToRoastGenerator: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "heart.slash")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.5))
            
            Text("Chưa có roast yêu thích")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            
            Text("Nhấn vào biểu tượng trái tim ở các câu roast để thêm vào danh sách yêu thích!")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: onNavigateToRoastGenerator) {
                HStack {
                    Image(systemName: "sparkles")
                    Text("Tạo Roast Mới")
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
        .padding()
    }
}
