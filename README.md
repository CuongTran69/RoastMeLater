# 🔥 RoastMeLater

**Giải tỏa stress với những câu roast vui nhộn về môi trường làm việc!**

RoastMeLater là ứng dụng iOS độc đáo giúp dân văn phòng giải tỏa căng thẳng thông qua những câu roast hài hước và phù hợp về cuộc sống công sở. Với sự hỗ trợ của AI, ứng dụng tạo ra những câu roast tùy chỉnh theo danh mục và mức độ "cay" mà bạn mong muốn.

## ✨ Tính Năng Chính

### 🎯 **Tạo Roast Thông Minh**
- **AI-Powered**: Sử dụng AI để tạo nội dung roast độc đáo và phù hợp
- **8 Danh Mục**: Deadline, Họp hành, KPI, Code Review, Khối lượng công việc, Đồng nghiệp, Quản lý, Chung
- **5 Mức Độ Cay**: Từ nhẹ nhàng đến cực cay, tùy chỉnh theo sở thích
- **Tiếng Việt**: Nội dung được tối ưu cho văn hóa và ngôn ngữ Việt Nam

### 📱 **Giao Diện Thân Thiện**
- **Khởi động nhanh**: Có sẵn roast chào mừng khi mở app
- **Copy dễ dàng**: Nút copy để chia sẻ với đồng nghiệp
- **Feedback trực quan**: Toast notification và haptic feedback
- **Navigation thông minh**: Giữ nguyên config khi chuyển tab

### 📚 **Quản Lý Nội Dung**
- **Lịch sử**: Xem lại tất cả roast đã tạo
- **Yêu thích**: Lưu những roast hay nhất
- **Tìm kiếm**: Tìm roast theo nội dung hoặc danh mục
- **Lọc**: Lọc theo danh mục cụ thể

### 🔔 **Thông Báo Thông Minh**
- **Nhắc nhở định kỳ**: Từ mỗi giờ đến mỗi ngày
- **Nội dung ngẫu nhiên**: Roast mới mỗi lần thông báo
- **Tùy chỉnh linh hoạt**: Bật/tắt và điều chỉnh tần suất

## 🛠 Cài Đặt & Sử Dụng

### Yêu Cầu Hệ Thống
- iOS 13.0+
- Xcode 12.0+
- Swift 5.0+

### Cài Đặt Dependencies
```bash
# Clone repository
git clone https://github.com/your-username/RoastMeLater.git
cd RoastMeLater

# Cài đặt CocoaPods dependencies
pod install

# Mở workspace
open RoastMeLater.xcworkspace
```

### Lần Đầu Sử Dụng
1. **Mở app**: Sẽ thấy welcome message hướng dẫn
2. **Nhấn "Tạo Roast Mới"**: App sẽ mở màn hình cấu hình API
3. **Nhập thông tin API**:
   - **API Key**: Key của dịch vụ AI (OpenAI, Anthropic, v.v.)
   - **Base URL**: Endpoint API (ví dụ: `https://api.openai.com/v1/chat/completions`)
4. **Test kết nối**: Đảm bảo API hoạt động
5. **Lưu & Tiếp tục**: Cấu hình được lưu cho những lần sau

### Sử Dụng Hàng Ngày
1. **Chọn danh mục**: Deadline, Meeting, KPI, v.v.
2. **Điều chỉnh mức độ cay**: 1-5 flames 🔥
3. **Nhấn "Tạo Roast Mới"**: AI sẽ tạo roast phù hợp
4. **Copy & Share**: Chia sẻ với đồng nghiệp
5. **Lưu yêu thích**: Giữ lại những roast hay nhất

### Cấu Hình Lại API (Tùy Chọn)
- Vào tab **Settings** → **Cấu Hình API** để thay đổi API key hoặc URL

## 🏗 Kiến Trúc

### Tech Stack
- **Framework**: SwiftUI
- **Reactive Programming**: RxSwift, RxCocoa
- **Dependency Management**: CocoaPods
- **Architecture**: MVVM Pattern
- **Storage**: UserDefaults với JSON encoding
- **AI Integration**: OpenAI-compatible API

### Cấu Trúc Project
```
RoastMeLater/
├── Models/              # Data models
│   ├── Roast.swift
│   ├── RoastCategory.swift
│   └── UserPreferences.swift
├── Views/               # SwiftUI Views
│   ├── RoastGeneratorView.swift
│   ├── RoastHistoryView.swift
│   ├── FavoritesView.swift
│   └── SettingsView.swift
├── ViewModels/          # MVVM ViewModels
├── Services/            # Business Logic
│   ├── AIService.swift
│   ├── StorageService.swift
│   └── NotificationManager.swift
└── Utils/               # Utilities & Helpers
```

## 🎨 Screenshots

*Coming soon...*

## 🤝 Đóng Góp

Chúng tôi hoan nghênh mọi đóng góp! Vui lòng:

1. Fork repository
2. Tạo feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to branch (`git push origin feature/AmazingFeature`)
5. Mở Pull Request

## 📝 License

Distributed under the MIT License. See `LICENSE` for more information.

## 📞 Liên Hệ

- **Developer**: Cường Trần

## 🙏 Acknowledgments

- [RxSwift](https://github.com/ReactiveX/RxSwift) - Reactive Programming
- [OpenAI](https://openai.com/) - AI API inspiration
- Vietnamese developer community for feedback and support

---

**Disclaimer**: Ứng dụng này được tạo ra với mục đích giải trí và giảm stress. Tất cả nội dung roast đều mang tính chất hài hước và không nhằm xúc phạm ai.
