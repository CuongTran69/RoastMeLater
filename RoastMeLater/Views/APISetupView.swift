import SwiftUI

struct APISetupView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showingSuccess = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "key.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.orange)
                    
                    Text("Cấu Hình API")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
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
                                .font(.headline)
                                .fontWeight(.semibold)
                            Text("*")
                                .foregroundColor(.red)
                        }
                        
                        SecureField("sk-xxxxxxxxxxxxxxxx", text: $viewModel.apiKey)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .font(.system(.body, design: .monospaced))
                        
                        Text("API key từ OpenAI, Anthropic, hoặc dịch vụ tương thích")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Base URL")
                                .font(.headline)
                                .fontWeight(.semibold)
                            Text("*")
                                .foregroundColor(.red)
                        }
                        
                        TextField("https://api.openai.com/v1/chat/completions", text: $viewModel.baseURL)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .font(.system(.body, design: .monospaced))
                        
                        Text("Endpoint API của dịch vụ AI")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Model")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("deepseek:deepseek-v3")
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.primary)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        
                        Text("Model được sử dụng để tạo roast")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Buttons
                VStack(spacing: 12) {
                    // Test button
                    Button(action: {
                        viewModel.testAPIConnection()
                    }) {
                        HStack {
                            if viewModel.apiTestResult == nil {
                                Image(systemName: "checkmark.circle")
                            } else if viewModel.apiTestResult == true {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            } else {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.red)
                            }
                            Text("Test Kết Nối")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(viewModel.apiKey.isEmpty || viewModel.baseURL.isEmpty ? Color.gray.opacity(0.3) : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(viewModel.apiKey.isEmpty || viewModel.baseURL.isEmpty)
                    
                    // Test result
                    if let testResult = viewModel.apiTestResult {
                        HStack {
                            Image(systemName: testResult ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundColor(testResult ? .green : .red)
                            Text(testResult ? "✅ Kết nối thành công!" : "❌ Không thể kết nối. Vui lòng kiểm tra lại.")
                                .font(.subheadline)
                                .foregroundColor(testResult ? .green : .red)
                            Spacer()
                        }
                    }
                    
                    // Save button
                    Button(action: {
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
                            LinearGradient(
                                colors: [.orange, .red],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(viewModel.apiKey.isEmpty || viewModel.baseURL.isEmpty)
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
