# Daily Context Tips

Một ứng dụng Android thông minh cung cấp các tips và lời khuyên hàng ngày dựa trên bối cảnh của người dùng như thời tiết, thời gian và thói quen sử dụng thiết bị.

## 🌟 Tính năng chính

### 📱 Ít chủ động - Nhiều thụ động
- App tự động thu thập bối cảnh (thời tiết, giờ trong ngày, mở máy...)
- Đưa ra thông tin hữu ích, đọc trong vài giây
- Không cần tương tác phức tạp từ người dùng

### 🔒 Riêng tư trước
- Dữ liệu lưu trữ hoàn toàn local (SQLite)
- Không yêu cầu đăng nhập hay tài khoản
- Có thể export hoặc xóa dữ liệu bất kỳ lúc nào

### 💡 Daily Context Tips
**Mỗi sáng hoặc lần đầu mở máy:**
- Lấy thời tiết hiện tại + dự báo
- Sinh 1-2 tips theo ngữ cảnh:
  - Ẩm cao → nhắc uống nước/giữ ấm
  - Nóng + UV cao → nhắc nghỉ mắt, bôi kem
  - Mưa → đề xuất "việc indoor"
- Tối đa 1 thông báo ngắn + hiển thị trong app

### 📊 Weekly Recap (Chủ nhật tối)
**Tổng hợp thống kê tuần:**
- Số lần unlock thiết bị
- Tổng thời gian màn hình bật
- Khung giờ hoạt động cao điểm (sáng/chiều/đêm)
- Sinh nhận xét thú vị + "micro-challenge" tuần tới

### 🎭 Passive Mood Guess
**Đoán cảm xúc thụ động:**
- Suy luận từ hành vi thời gian (pattern unlock/online khuya)
- Biến thiên so với trung bình tuần trước
- Output mềm: "Có vẻ tuần này bạn hơi 'cú đêm' 🦉"

### 📚 Daily Life Tips
- Mỗi ngày tối đa 1 tip "trung lập"
- Không phụ thuộc thời tiết
- Xoay vòng đa dạng với cooldown để tránh lặp

## 🛠️ Công nghệ sử dụng

### Framework & Language
- **Flutter** - Cross-platform development
- **Dart** - Programming language
- **Riverpod** - State management

### Local Storage
- **SQLite** (via sqflite) - Local database
- **SharedPreferences** - Simple key-value storage

### External APIs & Services
- **OpenWeatherMap API** - Weather data
- **Geolocator** - Location services
- **Flutter Local Notifications** - Push notifications
- **Workmanager** - Background tasks

### Device Integration
- **Permission Handler** - Runtime permissions
- **Device Info Plus** - Device information
- **Usage Stats** - App usage statistics (Android)

## 🚀 Cài đặt và chạy

### Yêu cầu hệ thống
- Flutter SDK (>= 3.8.0)
- Android Studio hoặc VS Code
- Android device/emulator (API level 21+)

### Các bước cài đặt

1. **Cài đặt dependencies:**
```bash
flutter pub get
```

2. **Cấu hình API Key:**
   - Mở `lib/core/constants/app_constants.dart`
   - Thay đổi `YOUR_WEATHER_API_KEY` bằng API key từ OpenWeatherMap

3. **Chạy ứng dụng:**
```bash
flutter run
```

### Permissions cần thiết
App sẽ tự động yêu cầu các permissions sau:
- **Location** - Để lấy thời tiết theo vị trí
- **Notifications** - Để gửi tips hàng ngày
- **Usage Stats** - Để phân tích thói quen sử dụng (Android)

## 🎯 Cách sử dụng

### Lần đầu sử dụng
1. Mở app và cấp quyền location, notification
2. App sẽ tự động lấy thời tiết và tạo tips đầu tiên
3. Thiết lập notification cho tips hàng ngày

### Sử dụng hàng ngày
- **Sáng:** Nhận notification với context tip dựa trên thời tiết
- **Trong ngày:** Mở app để xem tips và thống kê
- **Tối:** Có thể nhận tips dựa trên thời gian
- **Chủ nhật:** Nhận weekly recap và challenges mới

### Quản lý dữ liệu
- Tất cả dữ liệu được lưu local
- Có thể xem lịch sử tips trong app
- Có thể xóa toàn bộ dữ liệu trong settings

---

**Daily Context Tips** - Làm cho ngày của bạn thông minh hơn! 🌟
