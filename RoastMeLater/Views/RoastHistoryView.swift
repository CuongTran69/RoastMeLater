import SwiftUI

struct RoastHistoryView: View {
    @StateObject private var viewModel = RoastHistoryViewModel()
    @EnvironmentObject var localizationManager: LocalizationManager
    @State private var searchText = ""
    @State private var selectedCategory: RoastCategory? = nil
    @State private var showingFilterSheet = false
    let onNavigateToRoastGenerator: () -> Void
    
    var body: some View {
        NavigationView {
            VStack {
                if viewModel.roasts.isEmpty {
                    EmptyHistoryView(onNavigateToRoastGenerator: onNavigateToRoastGenerator)
                } else {
                    List {
                        ForEach(filteredRoasts) { roast in
                            RoastHistoryRowView(roast: roast) {
                                viewModel.toggleFavorite(roast: roast)
                            } onDelete: {
                                viewModel.deleteRoast(roast: roast)
                            }
                        }
                        .onDelete(perform: deleteRoasts)
                    }
                    .listStyle(PlainListStyle())
                    .searchable(text: $searchText, prompt: localizationManager.searchRoasts)
                }
            }
            .navigationTitle(localizationManager.tabHistory)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { showingFilterSheet = true }) {
                            Label("Lọc theo danh mục", systemImage: "line.3.horizontal.decrease.circle")
                        }
                        
                        Button(action: viewModel.clearAllHistory) {
                            Label("Xóa tất cả", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .sheet(isPresented: $showingFilterSheet) {
            FilterSheetView(selectedCategory: $selectedCategory)
        }
        .onAppear {
            viewModel.loadRoasts()
        }
        .dismissKeyboard()
    }
    
    private var filteredRoasts: [Roast] {
        var roasts = viewModel.roasts
        
        // Filter by search text
        if !searchText.isEmpty {
            roasts = roasts.filter { roast in
                roast.content.localizedCaseInsensitiveContains(searchText) ||
                roast.category.displayName.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Filter by category
        if let selectedCategory = selectedCategory {
            roasts = roasts.filter { $0.category == selectedCategory }
        }
        
        return roasts
    }
    
    private func deleteRoasts(offsets: IndexSet) {
        for index in offsets {
            let roast = filteredRoasts[index]
            viewModel.deleteRoast(roast: roast)
        }
    }
}

struct RoastHistoryRowView: View {
    let roast: Roast
    let onFavoriteToggle: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
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
            }
        }
        .padding(.vertical, 4)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(action: onDelete) {
                Label("Xóa", systemImage: "trash")
            }
            .tint(.red)
        }
        .swipeActions(edge: .leading, allowsFullSwipe: false) {
            Button(action: onFavoriteToggle) {
                Label(roast.isFavorite ? "Bỏ thích" : "Yêu thích",
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
    let onNavigateToRoastGenerator: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "clock.badge.questionmark")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.5))
            
            Text("Chưa có lịch sử roast")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            
            Text("Hãy tạo câu roast đầu tiên của bạn!")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
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

struct FilterSheetView: View {
    @Binding var selectedCategory: RoastCategory?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section("Danh mục") {
                    Button(action: {
                        selectedCategory = nil
                        dismiss()
                    }) {
                        HStack {
                            Text("Tất cả")
                            Spacer()
                            if selectedCategory == nil {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.orange)
                            }
                        }
                    }
                    .foregroundColor(.primary)
                    
                    ForEach(RoastCategory.allCases, id: \.self) { category in
                        Button(action: {
                            selectedCategory = category
                            dismiss()
                        }) {
                            HStack {
                                Image(systemName: category.icon)
                                    .foregroundColor(.orange)
                                    .frame(width: 20)
                                
                                Text(category.displayName)
                                
                                Spacer()
                                
                                if selectedCategory == category {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.orange)
                                }
                            }
                        }
                        .foregroundColor(.primary)
                    }
                }
            }
            .navigationTitle("Lọc Lịch Sử")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Xong") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    RoastHistoryView(onNavigateToRoastGenerator: {})
}
