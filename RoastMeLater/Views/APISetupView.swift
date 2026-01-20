import SwiftUI

struct APISetupView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showingSuccess = false

    // Computed property to check if form is valid
    private var isFormValid: Bool {
        viewModel.isAPIFormValid
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "key.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.orange)

                    Text("Cấu Hình API")
                        .font(.largeTitle.weight(.bold))

                    Text("Để tạo roast, bạn cần cung cấp API key từ dịch vụ AI tương thích OpenAI")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Spacer()

                // Form
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("API Key")
                                .font(.headline.weight(.semibold))
                            Text("*")
                                .foregroundColor(.red)
                        }

                        SecureField("sk-xxxxxxxxxxxxxxxx", text: $viewModel.apiKey)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .font(.system(.body, design: .monospaced))
                            .overlay(
                                RoundedRectangle(cornerRadius: 5)
                                    .stroke(viewModel.apiKeyError != nil ? Color.red : Color.clear, lineWidth: 1)
                            )
                            .onChange(of: viewModel.apiKey) { newValue in
                                print("📝 API Key changed: \(newValue.isEmpty ? "EMPTY" : "HAS_VALUE (\(newValue.count) chars)")")
                                viewModel.validateAPIKey()
                            }

                        if let error = viewModel.apiKeyError {
                            HStack(spacing: 4) {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .font(.caption)
                                Text(error)
                                    .font(.caption)
                            }
                            .foregroundColor(.red)
                        } else {
                            Text("API key từ OpenAI, Anthropic, hoặc dịch vụ tương thích")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Base URL")
                                .font(.headline.weight(.semibold))
                            Text("*")
                                .foregroundColor(.red)
                        }

                        TextField("https://api.openai.com/v1/chat/completions", text: $viewModel.baseURL)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .font(.system(.body, design: .monospaced))
                            .overlay(
                                RoundedRectangle(cornerRadius: 5)
                                    .stroke(viewModel.baseURLError != nil ? Color.red : Color.clear, lineWidth: 1)
                            )
                            .onChange(of: viewModel.baseURL) { newValue in
                                print("📝 Base URL changed: \(newValue.isEmpty ? "EMPTY" : newValue)")
                                viewModel.validateBaseURL()
                            }

                        if let error = viewModel.baseURLError {
                            HStack(spacing: 4) {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .font(.caption)
                                Text(error)
                                    .font(.caption)
                            }
                            .foregroundColor(.red)
                        } else {
                            Text("Endpoint API của dịch vụ AI")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Model")
                            .font(.headline.weight(.semibold))

                        TextField("gemini:gemini-2.5-pro, gpt-4, claude-3-opus...", text: $viewModel.modelName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .font(.system(.body, design: .monospaced))
                            .overlay(
                                RoundedRectangle(cornerRadius: 5)
                                    .stroke(viewModel.modelNameError != nil ? Color.red : Color.clear, lineWidth: 1)
                            )
                            .onChange(of: viewModel.modelName) { newValue in
                                print("📝 Model changed: \(newValue.isEmpty ? "EMPTY" : newValue)")
                                viewModel.validateModelName()
                            }

                        if let error = viewModel.modelNameError {
                            HStack(spacing: 4) {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .font(.caption)
                                Text(error)
                                    .font(.caption)
                            }
                            .foregroundColor(.red)
                        } else {
                            Text("Model được sử dụng để tạo roast (mặc định: gemini:gemini-2.5-pro)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Buttons
                VStack(spacing: 12) {
                    // Test button
                    Button(action: {
                        print("🔍 Test button tapped")
                        print("  API Key: \(viewModel.apiKey.isEmpty ? "EMPTY" : "HAS_VALUE")")
                        print("  Base URL: \(viewModel.baseURL.isEmpty ? "EMPTY" : viewModel.baseURL)")
                        print("  Model: \(viewModel.modelName)")
                        print("  Is Valid: \(isFormValid)")
                        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                        impactFeedback.impactOccurred()
                        viewModel.testAPIConnection()
                    }) {
                        HStack {
                            if viewModel.isTestingConnection {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else if viewModel.apiTestResult == nil {
                                Image(systemName: "antenna.radiowaves.left.and.right")
                            } else if viewModel.apiTestResult == true {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            } else {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.red)
                            }
                            Text(viewModel.isTestingConnection ? "Đang kiểm tra..." : "Test Kết Nối")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isFormValid && !viewModel.isTestingConnection ? Color.blue : Color.gray.opacity(0.3))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(!isFormValid || viewModel.isTestingConnection)

                    // Test result
                    if let testResult = viewModel.apiTestResult {
                        HStack {
                            Image(systemName: testResult ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundColor(testResult ? .green : .red)
                            Text(testResult ? "✅ Kết nối thành công! Đã lưu cấu hình." : "❌ Không thể kết nối. Vui lòng kiểm tra lại.")
                                .font(.subheadline)
                                .foregroundColor(testResult ? .green : .red)
                            Spacer()
                        }
                    }
                    
                    // Save button
                    Button(action: {
                        print("💾 Save button tapped")
                        print("  API Key: \(viewModel.apiKey.isEmpty ? "EMPTY" : "HAS_VALUE")")
                        print("  Base URL: \(viewModel.baseURL.isEmpty ? "EMPTY" : viewModel.baseURL)")
                        print("  Is Valid: \(isFormValid)")

                        viewModel.updateAPIConfiguration()
                        showingSuccess = true

                        // Auto dismiss after 1.5 seconds
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            dismiss()
                        }
                    }) {
                        HStack {
                            Image(systemName: "checkmark")
                            Text("Lưu & Tiếp Tục")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            isFormValid ?
                            LinearGradient(
                                colors: [.orange, .red],
                                startPoint: .leading,
                                endPoint: .trailing
                            ) :
                            LinearGradient(
                                colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.3)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(!isFormValid)
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Bỏ qua") {
                        dismiss()
                    }
                    .foregroundColor(.secondary)
                }
            }
        }
        .overlay(
            // Success toast
            VStack {
                if showingSuccess {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Đã lưu cấu hình!")
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
            .animation(.easeInOut(duration: 0.3), value: showingSuccess)
        )
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
}

#Preview {
    APISetupView()
}
