# Mobile App - Elderly Health Support System

Ứng dụng mobile Flutter cho hệ thống chăm sóc sức khỏe người cao tuổi.

## Yêu cầu hệ thống

- Flutter SDK >= 3.9.2
- Dart SDK >= 3.9.2
- Android Studio / VS Code với Flutter extension
- Android SDK (cho Android) hoặc Xcode (cho iOS)

## Cài đặt

1. **Clone repository và di chuyển vào thư mục mobile:**
   ```bash
   cd mobile
   ```

2. **Cài đặt dependencies:**
   ```bash
   flutter pub get
   ```

3. **Tạo file `android/local.properties` (nếu chưa có):**
   - Mở Android Studio
   - Hoặc tạo file thủ công với nội dung:
     ```
     sdk.dir=/path/to/your/android/sdk
     flutter.sdk=/path/to/your/flutter/sdk
     ```

4. **Kiểm tra thiết bị:**
   ```bash
   flutter devices
   ```

## Chạy ứng dụng

```bash
flutter run
```

## Cấu trúc thư mục

- `lib/` - Source code chính
  - `api/` - API clients và services
  - `models/` - Data models
  - `screens/` - Các màn hình chính
  - `widgets/` - Reusable widgets
  - `utils/` - Utility functions
- `android/` - Android configuration
- `ios/` - iOS configuration
- `pubspec.yaml` - Dependencies và project configuration

## Lưu ý

- File `android/local.properties` không được commit (chứa đường dẫn local)
- Sau khi pull, cần chạy `flutter pub get` để cài đặt dependencies
- Đảm bảo Flutter SDK đã được cài đặt và cấu hình đúng
