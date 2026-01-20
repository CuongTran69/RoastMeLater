import SwiftUI

struct SplashView: View {
    @State private var isAnimating = false
    @State private var textOpacity = 0.0
    @State private var iconScale = 0.5
    @State private var backgroundOpacity = 0.0

    private let primaryColor = Constants.UI.Colors.primary
    private let gradientEnd = Constants.UI.Colors.gradientEnd

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    primaryColor.opacity(0.08),
                    gradientEnd.opacity(0.04),
                    primaryColor.opacity(0.06)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .opacity(backgroundOpacity)
            .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                VStack(spacing: 24) {
                    ZStack {
                        Circle()
                            .fill(primaryColor.opacity(0.15))
                            .frame(width: 140, height: 140)
                            .scaleEffect(isAnimating ? 1.1 : 0.9)
                            .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: isAnimating)

                        Circle()
                            .fill(primaryColor.opacity(0.25))
                            .frame(width: 100, height: 100)
                            .scaleEffect(isAnimating ? 0.9 : 1.1)
                            .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isAnimating)

                        Image(systemName: "flame.fill")
                            .font(.system(size: 60))
                            .foregroundColor(primaryColor)
                            .scaleEffect(iconScale)
                            .rotationEffect(.degrees(isAnimating ? 5 : -5))
                            .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isAnimating)
                    }

                    VStack(spacing: 12) {
                        Text("RoastMe Generator")
                            .font(.largeTitle.weight(.bold))
                            .foregroundColor(.primary)
                            .opacity(textOpacity)

                        HStack(spacing: 8) {
                            Text("🎯")
                                .font(.title2)
                            Text("Tạo câu roast hài hước để giải tỏa stress công việc")
                                .font(.headline.weight(.medium))
                                .foregroundColor(primaryColor)
                                .multilineTextAlignment(.center)
                            Text("🎯")
                                .font(.title2)
                        }
                        .opacity(textOpacity)

                        Text("Chọn chủ đề và mức độ cay, AI sẽ tạo ra những câu roast vui nhộn phù hợp với văn hóa Việt Nam")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                            .opacity(textOpacity)
                    }
                }

                Spacer()

                VStack(spacing: 16) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: primaryColor))
                        .scaleEffect(1.2)
                        .opacity(textOpacity)

                    Text("Đang khởi động...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .opacity(textOpacity)
                }
                .padding(.bottom, 50)
            }
            .padding(.horizontal, 24)
        }
        .onAppear {
            startAnimations()
        }
    }

    private func startAnimations() {
        withAnimation(.easeIn(duration: 0.5)) {
            backgroundOpacity = 1.0
        }

        withAnimation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.2)) {
            iconScale = 1.0
        }

        withAnimation(.easeIn(duration: 0.8).delay(0.5)) {
            textOpacity = 1.0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            isAnimating = true
        }
    }
}

#Preview {
    SplashView()
}
