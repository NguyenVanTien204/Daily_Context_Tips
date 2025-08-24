# Smart Tip Management System Documentation

## Tổng quan
Hệ thống quản lý tip thông minh được thiết kế để cung cấp các gợi ý ngữ cảnh phù hợp với thời tiết, thời gian và mức độ sử dụng thiết bị của người dùng.

## Kiến trúc hệ thống

### 1. Core Services

#### SmartTipManagerService
- **Chức năng**: Quản lý logic thông minh cho việc tạo tip
- **Tính năng chính**:
  - Kiểm tra constraint (giới hạn theo thời gian, thời tiết)
  - Tạo tip dựa trên ngữ cảnh hiện tại
  - Tích hợp với weather service và usage statistics
  - Phân tích xu hướng sử dụng

#### MockWeatherService
- **Chức năng**: Cung cấp dữ liệu thời tiết mock khi API thất bại
- **Tính năng**:
  - Mô phỏng thời tiết dựa trên thời gian trong ngày
  - Tạo thời tiết cực đoan (mưa, bão) theo tỷ lệ thực tế
  - Biến đổi theo mùa

#### TipManagerService
- **Chức năng**: Quản lý 5 danh mục tip với 100+ mẫu có sẵn
- **Danh mục tip**:
  - 🌅 **Morning**: Tips buổi sáng (27 tips)
  - ☀️ **Afternoon**: Tips buổi chiều (23 tips)
  - 🌙 **Evening**: Tips buổi tối (20 tips)
  - 🌧️ **Weather**: Tips theo thời tiết (15 tips)
  - 💡 **General**: Tips tổng quát (20 tips)

### 2. Advanced Features

#### Advanced Tip Creator Screen
Giao diện tạo tip nâng cao với các tùy chọn:

**Basic Information**:
- Title, Content, Type, Priority

**Type-Specific Context**:
- **Weather Context**: Điều kiện thời tiết, nhiệt độ, độ ẩm
- **Time Context**: Giờ mục tiêu, ngày trong tuần
- **Daily Context**: Mẫu sử dụng, thời gian màn hình

**Scheduling Options**:
- Hiển thị ngay hoặc lên lịch
- Chọn thời gian cụ thể

**Smart Actions**:
- Generate Smart Tips
- Test với Mock Weather
- Analyze Current Conditions

#### Intelligent Constraints

**Time-based Constraints**:
```dart
// Giới hạn 3 tips trong 2 giờ qua
final recentTips = await _getRecentTips(Duration(hours: 2));
if (recentTips.length >= 3) return false;

// Giới hạn theo giờ hoạt động (6h-23h)
final hour = DateTime.now().hour;
if (hour < 6 || hour > 23) return false;
```

**Weather-based Constraints**:
```dart
// Không tạo weather tip nếu thời tiết ổn định quá 4h
final lastWeatherTip = await _getLastWeatherTip();
if (lastWeatherTip != null &&
    DateTime.now().difference(lastWeatherTip.createdAt).inHours < 4) {
  return false;
}
```

**Usage-based Constraints**:
```dart
// Chỉ tạo tip khi có usage data
final usageToday = await _getTodayUsage();
if (usageToday == null) return false;
```

### 3. Background Task Integration

#### Smart Tip Task
```dart
// Chạy mỗi 2 giờ
BackgroundTaskManager.scheduleSmartTips();

// Handler kiểm tra constraints và tạo tip
Future<void> _handleSmartTipTask() async {
  final shouldGenerateDaily = await smartManager.shouldGenerateTip(TipType.daily);
  final shouldGenerateContext = await smartManager.shouldGenerateTip(TipType.contextWeather);

  if (shouldGenerateDaily || shouldGenerateContext) {
    final smartTips = await smartManager.generateSmartTips(maxTips: 2);
    // Save + notify
  }
}
```

### 4. Database Schema Enhancements

#### Tips Table Context
```sql
context TEXT -- JSON data containing:
{
  "condition": "Clear",
  "temperature": 25.0,
  "humidity": 60.0,
  "target_hour": 14,
  "target_days": [1,2,3,4,5],
  "usage_pattern": "normal",
  "screen_time_hours": 5,
  "created_with_advanced_tool": true,
  "is_mock_data": false
}
```

### 5. Debug Interface

#### Debug Tips Screen Features
- **Tip Generation**: Tạo tip theo category
- **Custom Tips**: Tạo tip tùy chỉnh
- **Advanced Creator**: Mở advanced creator
- **Smart Generation**: Test smart tips
- **Notifications**: Test notification system
- **Analytics**: Xem thống kê tips

#### Analytics Available
```dart
{
  'total_tips': 150,
  'tips_last_7_days': 25,
  'most_active_hour': 14,
  'tips_by_hour': {
    9: 5, 14: 8, 18: 12, ...
  }
}
```

## Cách sử dụng

### 1. Tạo tip thường
```dart
// Sử dụng TipManagerService
final tip = TipManagerService.instance.getTipsByCategory('morning').first;
await DatabaseHelper.instance.insertTip(tip);
```

### 2. Tạo smart tip
```dart
// Sử dụng SmartTipManagerService
final smartTips = await SmartTipManagerService.instance.generateSmartTips(maxTips: 3);
await SmartTipManagerService.instance.saveSmartTips(smartTips);
```

### 3. Tạo tip advanced
- Mở Debug Screen
- Tap "Advanced Creator"
- Cấu hình context và constraints
- Create tip

### 4. Test với mock weather
```dart
final mockWeather = MockWeatherService.instance.generateTimeBasedWeather();
// Sử dụng mock data cho tip weather
```

## Best Practices

### 1. Constraint Management
- Luôn check constraints trước khi tạo tip
- Sử dụng mock weather khi API thất bại
- Giới hạn frequency để tránh spam user

### 2. Context Usage
- Lưu context đầy đủ cho tip analytics
- Sử dụng flag để track data source (real vs mock)
- Maintain backward compatibility với context cũ

### 3. Error Handling
```dart
try {
  final tips = await smartManager.generateSmartTips();
} catch (e) {
  // Fallback to basic tips
  final fallbackTip = TipManagerService.instance.getRandomTip();
}
```

## Troubleshooting

### Common Issues

1. **LocaleData Exception**
   - Solution: Added `initializeDateFormatting('vi', null)` in main.dart

2. **Type Cast Errors**
   - Solution: Enhanced JSON parsing with proper type checking

3. **Weather API Failures**
   - Solution: Automatic fallback to MockWeatherService

4. **Too Many Tips**
   - Solution: Intelligent constraints based on time and frequency

### Performance Optimization

1. **Database Queries**
   - Index trên `created_at` và `type` columns
   - Limit query results với pagination

2. **Background Tasks**
   - Frequency tuning (2h cho smart tips, 4h cho context)
   - Proper error handling để tránh task failure

3. **Memory Usage**
   - Singleton pattern cho services
   - Lazy loading cho tip categories

## Future Enhancements

1. **Machine Learning Integration**
   - User behavior analysis
   - Personalized tip recommendations

2. **Advanced Analytics**
   - Tip effectiveness tracking
   - User engagement metrics

3. **Social Features**
   - Tip sharing
   - Community recommendations

4. **Multi-language Support**
   - Dynamic locale switching
   - Localized tip content
