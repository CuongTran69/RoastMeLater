import SwiftUI

struct RoastGeneratorView: View {
    @StateObject private var viewModel = RoastGeneratorViewModel()
    @State private var selectedCategory: RoastCategory = .general
    @State private var spiceLevel: Int = 3
    @State private var showingCategoryPicker = false
    @State private var isGenerating = false
    @State private var showCopySuccess = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.orange)
                    
                    Text("RoastMe")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Giải tỏa stress với những câu roast vui nhộn!")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top)
                
                Spacer()
                
                // Current Roast Display
                if let currentRoast = viewModel.currentRoast {
                    RoastCardView(roast: currentRoast, onFavoriteToggle: {
                        viewModel.toggleFavorite(roast: currentRoast)
                    }, onCopy: {
                        viewModel.copyRoastToClipboard()
                        showCopySuccess = true

                        // Hide the success message after 2 seconds
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            showCopySuccess = false
                        }
                    })
                    .transition(.asymmetric(
                        insertion: .scale.combined(with: .opacity),
                        removal: .opacity
                    ))
                } else {
                    RoastPlaceholderView()
                }
                
                Spacer()
                
                // Controls
                VStack(spacing: 20) {
                    // Category Selection
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "tag.fill")
                                .foregroundColor(.orange)
                            Text("Danh mục")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }

                        Button(action: { showingCategoryPicker = true }) {
                            HStack {
                                Image(systemName: selectedCategory.icon)
                                    .foregroundColor(.orange)
                                    .frame(width: 24)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(selectedCategory.displayName)
                                        .font(.body)
                                        .fontWeight(.medium)
                                        .foregroundColor(.primary)

                                    Text(selectedCategory.description)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }

                                Spacer()

                                Image(systemName: "chevron.down")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }
                            .padding()
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

                            Text("\(spiceLevel)/5")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.orange)
                        }

                        HStack(spacing: 8) {
                            ForEach(1...5, id: \.self) { level in
                                Button(action: {
                                    spiceLevel = level
                                }) {
                                    Image(systemName: level <= spiceLevel ? "flame.fill" : "flame")
                                        .font(.title2)
                                        .foregroundColor(level <= spiceLevel ? .orange : .gray.opacity(0.4))
                                        .scaleEffect(level <= spiceLevel ? 1.1 : 1.0)
                                        .animation(.easeInOut(duration: 0.2), value: spiceLevel)
                                }
                            }

                            Spacer()

                            Text(getSpiceLevelDescription(spiceLevel))
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .italic()
                        }
                        .padding()
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
                .padding(.horizontal)
                .padding(.bottom)
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
            CategoryPickerView(selectedCategory: $selectedCategory)
        }
        .sheet(isPresented: $viewModel.showAPISetup) {
            APISetupView()
        }
        .onReceive(viewModel.$isLoading) { loading in
            isGenerating = loading
        }
    }
    
    private func generateRoast() {
        viewModel.generateRoast(category: selectedCategory, spiceLevel: spiceLevel)
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
}

struct RoastCardView: View {
    let roast: Roast
    let onFavoriteToggle: () -> Void
    let onCopy: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: roast.category.icon)
                    .foregroundColor(.orange)
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
                .font(.title3)
                .fontWeight(.medium)
                .lineLimit(nil)
                .multilineTextAlignment(.leading)
            
            HStack {
                Text(roast.createdAt, style: .time)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Button(action: onCopy) {
                    Image(systemName: "doc.on.doc")
                        .foregroundColor(.blue)
                }
                .padding(.trailing, 8)

                Button(action: onFavoriteToggle) {
                    Image(systemName: roast.isFavorite ? "heart.fill" : "heart")
                        .foregroundColor(roast.isFavorite ? .red : .gray)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        .padding(.horizontal)
    }
}

struct RoastPlaceholderView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "key")
                .font(.system(size: 50))
                .foregroundColor(.gray.opacity(0.5))

            Text("Cần cấu hình API để tạo roast!")
                .font(.headline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Text("Nhấn 'Tạo Roast Mới' để thiết lập API key")
                .font(.subheadline)
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
    @Binding var selectedCategory: RoastCategory
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List(RoastCategory.allCases, id: \.self) { category in
                Button(action: {
                    selectedCategory = category
                    dismiss()
                }) {
                    HStack {
                        Image(systemName: category.icon)
                            .foregroundColor(.orange)
                            .frame(width: 30)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(category.displayName)
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Text(category.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }
                        
                        Spacer()
                        
                        if category == selectedCategory {
                            Image(systemName: "checkmark")
                                .foregroundColor(.orange)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Chọn Danh Mục")
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
    RoastGeneratorView()
}
