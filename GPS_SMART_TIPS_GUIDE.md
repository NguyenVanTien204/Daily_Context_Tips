# GPS Location & Smart Tip System - Hướng dẫn sử dụng

## 🎯 Tổng quan

Hệ thống đã được nâng cấp với các tính năng:

1. **GPS Location Access**: Tự động phát hiện vị trí người dùng
2. **Reverse Geocoding**: Chuyển đổi GPS coordinates thành địa chỉ thực
3. **Python-based Tip Categories**: Load categories từ file JSON
4. **Smart Weather Integration**: Kết hợp thời tiết + GPS + thời gian
5. **Enhanced Debug Tools**: Test toàn bộ tính năng

## 🚀 Các tính năng mới

### 1. GPS Location Detection
- **Tự động phát hiện vị trí**: App sẽ yêu cầu quyền GPS và tự động lấy vị trí hiện tại
- **Reverse Geocoding**: Chuyển đổi (latitude, longitude) thành tên thành phố/địa chỉ
- **Fallback System**: Nếu GPS không khả dụng, sử dụng địa điểm mặc định (Hanoi)

### 2. Smart Tip Categories (JSON-based)
- **Dynamic Loading**: Tips được load từ `assets/data/tip_categories.json`
- **Intelligent Categorization**:
  - Time-based (morning, afternoon, evening, night)
  - Weather-specific (sunny, rainy, cloudy, hot)
  - Health & wellness
  - Work productivity
  - Special weather conditions

### 3. Enhanced Weather Integration
- **WeatherAPI.com**: Sử dụng GPS coordinates để lấy thời tiết chính xác
- **Smart Conditions**: Phân tích nhiệt độ, độ ẩm, gió để tạo tips phù hợp
- **Location Display**: Hiển thị địa chỉ thực (ví dụ: "Hà Nội, Hanoi")

## 🛠️ Debug Tools

### Smart Tip Debug Screen
Truy cập qua Home Screen → 🧠 Icon (Psychology)

**Các chức năng test:**

1. **Test GPS**: Kiểm tra quyền GPS, lấy coordinates, reverse geocoding
2. **Test Weather**: Test API thời tiết với GPS location
3. **Test Smart Tips**: Kiểm tra generation tips thông minh
4. **Full Generation**: Test toàn bộ hệ thống tip generation
5. **Reload Service**: Reload lại JSON categories

## 🎯 Cách sử dụng GPS Location

### Bước 1: Cấp quyền GPS
```
- App sẽ tự động yêu cầu quyền khi mở lần đầu
- Chọn "Allow" hoặc "Allow while using app"
- Bật Location Services trên thiết bị
```

### Bước 2: Kiểm tra hoạt động
1. Mở app → Tap vào 🧠 icon (Psychology)
2. Tap "Test GPS"
3. Xem kết quả:
   ```
   📡 Location service enabled: true
   🔐 Permission status: granted
   🎯 Getting current position...
   ✅ GPS Coordinates: 21.028511, 105.804817
   📏 Accuracy: 12.50m
   🏘️ Locality: Hanoi
   🏙️ City: Ba Dinh
   🗺️ State: Hanoi
   🌍 Country: Vietnam
   ```

### Bước 3: Test Weather với GPS
1. Tap "Test Weather"
2. Xem kết quả:
   ```
   🌍 GPS Location: 21.028511, 105.804817
   🏙️ Detected city: Hanoi
   ✅ Weather: Partly cloudy, 28°C, 75%
   📍 GPS Location: Hanoi, Hanoi
   ```

## 📝 Tip Categories Structure

### Time-based Tips
- **Morning (6-11h)**: Tips về khởi đầu ngày, tập thể dục
- **Afternoon (12-17h)**: Tips về năng suất, nghỉ ngơi
- **Evening (18-23h)**: Tips về thư giãn, kết thúc ngày
- **Night (0-5h)**: Tips về giấc ngủ

### Weather-based Tips
- **Sunny**: Khuyến khích hoạt động ngoài trời, chống nắng
- **Rainy**: Hoạt động trong nhà, mang ô
- **Cloudy**: Thời tiết dễ chịu, có thể ra ngoài
- **Hot**: Cảnh báo nóng, uống nhiều nước

### Special Conditions
- **High Humidity (>80%)**: Tips về giữ khô ráo
- **Strong Wind (>12 m/s)**: Cảnh báo gió mạnh
- **Extreme Heat (>38°C)**: Cảnh báo nóng cực độ

## 🔧 Troubleshooting

### GPS không hoạt động?
1. **Kiểm tra quyền**: Settings → Apps → Daily Context Tips → Permissions → Location
2. **Bật Location Services**: Settings → Location → On
3. **Check GPS signal**: Ra ngoài trời hoặc gần cửa sổ
4. **Restart app**: Force close và mở lại app

### Không hiển thị địa chỉ?
1. **Internet connection**: Reverse geocoding cần mạng
2. **GPS accuracy**: Chờ 10-15 giây để GPS lock
3. **Fallback**: App sẽ dùng "Unknown Location" nếu không detect được

### Tips không phù hợp?
1. **Reload Service**: Trong Debug Screen → "Reload Service"
2. **Check JSON file**: Đảm bảo `assets/data/tip_categories.json` có dữ liệu
3. **Test Generation**: "Test Smart Tips" để kiểm tra logic

## 📊 Logs và Debugging

### Quan trọng logs cần chú ý:
```
✅ SmartTipCategoryService: Loaded 6 categories
🌍 GPS Location: 21.028511, 105.804817
🏙️ Detected city: Hanoi
📍 Geocoding result: Locality: Hanoi
🎯 Generated smart daily tip for hour: 14
```

### Error logs thường gặp:
```
❌ Location services are disabled - Bật GPS
❌ Location permission denied - Cấp quyền GPS
❌ Error in reverse geocoding - Kiểm tra mạng
❌ Categories not loaded yet - Chờ app load xong
```

## 🎉 Success Indicators

App hoạt động tốt khi thấy:
- GPS coordinates hiển thị chính xác
- Address/city name được detect
- Weather data với location name thực
- Smart tips phù hợp với thời gian và thời tiết
- Notifications tự động theo schedule

## 🔄 Next Steps

Hệ thống đã sẵn sàng cho:
1. **Machine Learning Integration**: Học từ user behavior
2. **More Weather APIs**: Backup weather sources
3. **Location-based Events**: Tips theo địa điểm cụ thể
4. **User Customization**: Cho phép user edit categories
5. **Offline Support**: Cache weather data và tips

---

*Developed with ❤️ for intelligent contextual tips*
