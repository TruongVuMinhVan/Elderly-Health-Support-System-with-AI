# 🏥 Hệ Thống Hỗ Trợ Sức Khỏe Người Cao Tuổi với AI

**Version:** 2.0.0 | **Status:** ✅ Production Ready | **Last Updated:** December 2025

---

## 📋 Mục Lục

- [Giới Thiệu](#-giới-thiệu)
- [Tính Năng Chính](#-tính-năng-chính)
- [Công Nghệ Sử Dụng](#️-công-nghệ-sử-dụng)
- [Cài Đặt](#-cài-đặt)
- [Hướng Dẫn Sử Dụng](#-hướng-dẫn-sử-dụng)
- [API Documentation](#-api-documentation)
- [AI System](#-hệ-thống-ai)
- [Mobile App](#-ứng-dụng-mobile)
- [Khắc Phục Lỗi](#-khắc-phục-lỗi)

---

## 🎯 Giới Thiệu

**Hệ Thống Hỗ Trợ Sức Khỏe Người Cao Tuổi** là ứng dụng toàn diện với AI tích hợp, giúp người cao tuổi:

✅ **Quản lý sức khỏe** - Theo dõi chỉ số sinh hiệu với biểu đồ thông minh  
✅ **Quản lý thuốc men** - Nhắc nhở uống thuốc với thông báo đẩy  
✅ **Lịch hẹn khám bệnh** - Quản lý cuộc hẹn với bác sĩ  
✅ **AI Chat hỗ trợ** - Tư vấn sức khỏe 24/7 với Gemini AI  
✅ **Dự đoán bệnh da liễu** - AI phân tích ảnh với độ chính xác 94%  
✅ **Ứng dụng mobile** - Flutter app với thông báo thông minh  

---

## 📊 Chỉ Số Chính

| Chỉ Số | Giá Trị | Mô Tả |
|---------|---------|-------|
| **Độ Chính Xác AI** | 94.1% | Dự đoán bệnh da liễu (Ensemble ResNet50 + ViT) |
| **Dữ Liệu Training** | 24,086 ảnh | 11 loại bệnh da liễu chất lượng cao |
| **Tốc Độ Inference** | <200ms | Thời gian dự đoán trung bình |
| **Models AI** | 3 | ResNet50, ViT, Ensemble |
| **API Endpoints** | 30+ | Đầy đủ phủ sóng REST API |
| **Platforms** | 3 | Web, Mobile (Android/iOS), API |
| **Languages** | 2 | Tiếng Việt, English |

---

## ⚡ Tính Năng Chính

### 💊 1. Quản Lý Thuốc Thông Minh
- ➕ Thêm, sửa, xóa thuốc với thông tin chi tiết
- ⏰ **Nhắc nhở thông minh** - Thông báo đẩy đúng giờ
- 📊 Theo dõi lịch sử uống thuốc
- 🔄 Thuốc định kỳ (hàng ngày/tuần/tháng)
- 📱 Đồng bộ giữa web và mobile

### 📈 2. Theo Dõi Sức Khỏe
- 🩺 **5 chỉ số sinh hiệu:** Huyết áp, Nhịp tim, Đường huyết, Cân nặng, Nhiệt độ
- 📊 **Biểu đồ thông minh** - Xu hướng theo thời gian
- 🎯 Phân tích mức độ bình thường/bất thường
- 📅 Lịch sử chi tiết với múi giờ GMT+7
- 🔔 Cảnh báo khi chỉ số bất thường

### 📅 3. Quản Lý Lịch Hẹn
- 🏥 Thêm cuộc hẹn với bác sĩ, phòng khám
- ⏰ Nhắc nhở trước cuộc hẹn (15 phút, 1 giờ, 1 ngày)
- 📍 Thông tin địa điểm chi tiết
- 📝 Ghi chú và chuẩn bị trước khám
- 🔄 Lịch hẹn định kỳ

### 🤖 4. AI Chat Hỗ Trợ Y Tế
- 💬 **Chat tự nhiên tiếng Việt** với Gemini AI
- 🏥 Tư vấn sức khỏe cơ bản 24/7
- 💊 Hướng dẫn về thuốc và liều lượng
- 🚨 Nhận diện tình huống khẩn cấp
- 📋 Gợi ý câu hỏi thông minh
- 📊 Phân tích dữ liệu sức khỏe cá nhân

**Các truy vấn được hỗ trợ:**
- *"Huyết áp 140/90 có bình thường không?"* → Phân tích chỉ số
- *"Thuốc Amlodipine uống như thế nào?"* → Hướng dẫn sử dụng
- *"Đau ngực có nguy hiểm không?"* → Đánh giá triệu chứng
- *"Chế độ ăn cho người tiểu đường"* → Tư vấn dinh dưỡng

### 🔬 5. AI Dự Đoán Bệnh Da Liễu
- 📸 **Upload ảnh** → AI phân tích tự động
- 🎯 **Độ chính xác 94.1%** với Ensemble Learning
- 🏥 **11 loại bệnh:** Ung thư da, chàm, vảy nến, v.v.
- 📊 **Top-3 predictions** với confidence score
- 🤖 **2 Models:** ResNet50 (nhanh) + ViT (chính xác)
- 💡 Gợi ý có nên đi khám bác sĩ

**Các bệnh được hỗ trợ:**
- 🔴 **Ung thư da:** Melanoma, Basal Cell Carcinoma, Squamous Cell Carcinoma
- 🟡 **Bệnh lành tính:** Eczema, Seborrheic Keratosis, Lichen Planus
- 🟢 **Da khỏe mạnh:** Phân biệt da bình thường

### 👤 6. Hồ Sơ Sức Khỏe Cá Nhân
- 📝 Thông tin cá nhân chi tiết
- 🏥 Hồ sơ bệnh án, tiền sử bệnh
- 🚨 Thông tin liên hệ khẩn cấp
- 💊 Danh sách dị ứng thuốc
- 🔐 Bảo mật với JWT Authentication

---

## 🧠 Hệ Thống AI Tiên Tiến

### 🚀 Deep Learning Models

| Model | Accuracy | Speed | Size | Best For |
|-------|----------|-------|------|----------|
| **ResNet50** | 87.8% | 45ms | 295MB | Production, Real-time |
| **Vision Transformer** | 92.1% | 120ms | 345MB | High accuracy, Complex patterns |
| **Ensemble** | 94.1% | 165ms | 640MB | Best accuracy, Clinical grade |

### 🎯 Training Process
- **Dataset:** 24,086 ảnh da liễu chất lượng cao
- **Classes:** 11 loại bệnh từ lành tính đến ung thư
- **Techniques:** Transfer Learning, Mixup/CutMix, Label Smoothing
- **Platform:** Google Colab với GPU Tesla T4/V100
- **Framework:** PyTorch + timm + torchvision

### 🔮 Inference System
- **Singleton Pattern:** Load model 1 lần, tái sử dụng
- **Ensemble Prediction:** Kết hợp ResNet50 (40%) + ViT (60%)
- **Preprocessing:** Resize, Normalize theo ImageNet standards
- **Output:** Top-k predictions với confidence scores

---

## 🛠️ Công Nghệ Sử Dụng

### 🖥️ Backend
- **FastAPI 0.104** - Python web framework hiệu suất cao
- **SQLAlchemy 2.0** - ORM với async support
- **MySQL 8.0** - Cơ sở dữ liệu quan hệ
- **JWT Authentication** - Bảo mật API
- **Pydantic 2.5** - Data validation
- **Alembic** - Database migrations
- **Python 3.9+** - Runtime environment

### 💻 Frontend
- **Next.js 14** - React framework với SSR
- **TypeScript** - Type safety
- **Tailwind CSS 3.4** - Utility-first CSS
- **Chart.js 4.4** - Biểu đồ tương tác
- **React Hook Form** - Form management
- **SWR** - Data fetching
- **Framer Motion** - Animations

### 📱 Mobile App
- **Flutter 3.9** - Cross-platform framework
- **Dart** - Programming language
- **HTTP Client** - API communication
- **Local Notifications** - Push notifications
- **Shared Preferences** - Local storage
- **Image Picker** - Camera integration
- **Geolocator** - Location services

### 🤖 AI Services
- **PyTorch 2.0** - Deep learning framework
- **timm** - Pre-trained models
- **Google Gemini API** - Conversational AI
- **Pillow** - Image processing
- **NumPy + Pandas** - Data manipulation
- **scikit-learn** - Machine learning utilities

### 🗄️ Database
- **MySQL 8.0** - Primary database
- **Alembic** - Schema migrations
- **Connection Pooling** - Performance optimization

---

## 📦 Cài Đặt

### ⚙️ Yêu Cầu Trước

- **Python** >= 3.9
- **Node.js** >= 18.0
- **MySQL** >= 8.0
- **Flutter** >= 3.9 (cho mobile)
- **Git** >= 2.0

### 1️⃣ Clone Repository

```bash
git clone https://github.com/your-username/elderly-health-system.git
cd elderly-health-system
```

### 2️⃣ Cài Đặt Database

```sql
-- Tạo database
CREATE DATABASE elderly_health_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- Tạo user
CREATE USER 'elderly_user'@'localhost' IDENTIFIED BY 'elderly_password';
GRANT ALL PRIVILEGES ON elderly_health_db.* TO 'elderly_user'@'localhost';
FLUSH PRIVILEGES;

-- Import schema
USE elderly_health_db;
SOURCE database/schema.sql;
SOURCE database/sample_data.sql;
```

### 3️⃣ Cài Đặt Backend

```bash
cd backend

# Tạo virtual environment
python -m venv venv

# Kích hoạt virtual environment
# Windows:
venv\Scripts\activate
# macOS/Linux:
source venv/bin/activate

# Cài đặt dependencies
pip install -r requirements.txt

# Cấu hình environment
cp .env.example .env
# Cập nhật thông tin database và API keys trong .env

# Chạy migrations
alembic upgrade head

# Khởi động server
python main.py
```

**Backend chạy tại:** `http://localhost:8000`

### 4️⃣ Cài Đặt Frontend

```bash
cd frontend

# Cài đặt dependencies
npm install

# Cấu hình environment
cp .env.local.example .env.local
# Cập nhật API endpoints trong .env.local

# Khởi động development server
npm run dev
```

**Frontend chạy tại:** `http://localhost:3000`

### 5️⃣ Cài Đặt Mobile App (Tùy chọn)

```bash
cd mobile

# Cài đặt Flutter dependencies
flutter pub get

# Chạy trên Android
flutter run

# Hoặc build APK
flutter build apk --release
```

### 6️⃣ Cấu Hình AI Services

```bash
# Trong backend/.env
GEMINI_API_KEY=your_gemini_api_key_here
OPENAI_API_KEY=your_openai_key_here  # Tùy chọn

# Download AI models (nếu cần)
# Xem hướng dẫn trong doc/AI_SETUP.md
```

---

## 🔐 Thông Tin Đăng Nhập

**Demo Account:**
- **Email:** `duong@gmail.com`
- **Password:** `123456`
- **2FA Code:** `007213` (cho testing)

**Admin Account:**
- **Email:** `admin@elderly.com`
- **Password:** `admin123`

---

## 📖 Hướng Dẫn Sử Dụng

### 💳 1. Đăng Nhập & Bảo Mật

```bash
# Truy cập ứng dụng
http://localhost:3000

# Đăng nhập với thông tin demo
# Kích hoạt 2FA (tùy chọn)
# Cập nhật thông tin cá nhân
```

### 📊 2. Dashboard Sức Khỏe

- **Xem tổng quan:** Chỉ số mới nhất, xu hướng
- **Biểu đồ thông minh:** Theo dõi theo thời gian
- **Cảnh báo:** Chỉ số bất thường
- **Lịch hẹn hôm nay:** Cuộc hẹn sắp tới

### 💊 3. Quản Lý Thuốc

```bash
# Thêm thuốc mới
Tên thuốc: "Amlodipine 5mg"
Liều lượng: "1 viên/ngày"
Thời gian: "8:00 AM"
Ghi chú: "Uống sau ăn sáng"

# Thiết lập nhắc nhở
Thông báo: 15 phút trước
Lặp lại: Hàng ngày
```

### 🤖 4. Sử Dụng AI Chat

```bash
# Các câu hỏi mẫu:
"Huyết áp 140/90 có bình thường không?"
→ AI phân tích và đưa ra lời khuyên

"Thuốc Metformin có tác dụng phụ gì?"
→ Thông tin chi tiết về thuốc

"Đau ngực khi thở sâu"
→ Đánh giá triệu chứng và khuyến nghị
```

### 🔬 5. Dự Đoán Bệnh Da Liễu

```bash
# Upload ảnh
1. Chọn "Dự đoán bệnh da"
2. Upload ảnh (JPG, PNG)
3. Chờ AI phân tích (2-3 giây)
4. Xem kết quả:
   - Bệnh dự đoán: Eczema (85.3%)
   - Top 3 khả năng
   - Khuyến nghị có nên đi khám
```

---

## 🔌 API Documentation

### 🔐 Authentication

```bash
# Đăng nhập
POST /api/auth/login
Content-Type: application/json

{
  "email": "duong@gmail.com",
  "password": "123456"
}

Response:
{
  "access_token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
  "token_type": "bearer",
  "user": {
    "id": 1,
    "email": "duong@gmail.com",
    "full_name": "Nguyễn Văn Dương"
  }
}
```

### 🤖 AI Endpoints

```bash
# Dự đoán bệnh da liễu
POST /api/skin-disease/predict
Content-Type: multipart/form-data

file: [image file]

Response:
{
  "predicted_disease": "eczema",
  "confidence": 0.853,
  "top_predictions": [
    {"disease": "eczema", "confidence": 0.853},
    {"disease": "dermatitis", "confidence": 0.124},
    {"disease": "healthy", "confidence": 0.023}
  ],
  "recommendation": "Nên đi khám bác sĩ da liễu"
}
```

```bash
# AI Chat
POST /api/chat/sessions/{session_id}/messages
Content-Type: application/json

{
  "content": "Huyết áp 140/90 có bình thường không?"
}

Response:
{
  "message": {
    "content": "Huyết áp 140/90 mmHg được xếp vào mức cao huyết áp độ 1...",
    "message_type": "assistant"
  }
}
```

### 📋 Danh Sách API Chính

| Endpoint | Method | Mô Tả |
|----------|--------|-------|
| `/api/auth/login` | POST | Đăng nhập |
| `/api/auth/register` | POST | Đăng ký |
| `/api/users/me` | GET | Thông tin user |
| `/api/health/records` | GET/POST | Quản lý chỉ số sức khỏe |
| `/api/medications` | GET/POST/PUT/DELETE | Quản lý thuốc |
| `/api/schedules` | GET/POST/PUT/DELETE | Quản lý lịch hẹn |
| `/api/skin-disease/predict` | POST | Dự đoán bệnh da |
| `/api/chat/sessions` | GET/POST | Chat AI |
| `/api/dashboard/stats` | GET | Thống kê dashboard |

📚 **Xem tài liệu đầy đủ:** [API Documentation](http://localhost:8000/docs)

---

## 📱 Ứng Dụng Mobile

### 🚀 Tính Năng Mobile

- ✅ **Đồng bộ dữ liệu** với web app
- ✅ **Push notifications** cho thuốc và lịch hẹn
- ✅ **Offline mode** cho dữ liệu cơ bản
- ✅ **Camera integration** cho dự đoán bệnh da
- ✅ **Dark/Light theme** thân thiện người cao tuổi
- ✅ **Large fonts** và UI dễ sử dụng

### 📲 Cài Đặt Mobile

```bash
# Android
flutter build apk --release
# File APK: build/app/outputs/flutter-apk/app-release.apk

# iOS (cần macOS + Xcode)
flutter build ios --release
```

### 🔔 Thông Báo Thông Minh

```dart
// Nhắc nhở uống thuốc
"⏰ Đã đến giờ uống thuốc Amlodipine 5mg"
"💊 Nhớ uống sau ăn sáng"

// Lịch hẹn
"🏥 Cuộc hẹn với BS. Nguyễn Văn A sau 1 giờ"
"📍 Phòng khám Tim mạch - Tầng 3"

// Chỉ số bất thường
"⚠️ Huyết áp cao: 150/95 mmHg"
"💡 Nên nghỉ ngơi và đo lại sau 30 phút"
```

---

## 📊 Kiến Trúc Hệ Thống

### 🏗️ Architecture Overview

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Frontend      │    │   Mobile App    │    │   Admin Panel   │
│   (Next.js)     │    │   (Flutter)     │    │   (React)       │
└─────────┬───────┘    └─────────┬───────┘    └─────────┬───────┘
          │                      │                      │
          └──────────────────────┼──────────────────────┘
                                 │
                    ┌─────────────┴───────────┐
                    │      API Gateway        │
                    │      (FastAPI)          │
                    └─────────────┬───────────┘
                                  │
          ┌───────────────────────┼───────────────────────┐
          │                       │                       │
┌─────────┴───────┐    ┌─────────┴───────┐    ┌─────────┴───────┐
│   Auth Service  │    │   AI Service    │    │  Health Service │
│   (JWT + 2FA)   │    │ (ResNet50+ViT)  │    │   (CRUD APIs)   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                  │
                    ┌─────────────┴───────────┐
                    │      Database           │
                    │      (MySQL 8.0)        │
                    └─────────────────────────┘
```

### 🗄️ Database Schema

```sql
-- Bảng chính
Users (id, email, password_hash, full_name, ...)
HealthRecords (id, user_id, record_type, value, recorded_at, ...)
Medications (id, user_id, name, dosage, frequency, ...)
Schedules (id, user_id, title, doctor_name, appointment_date, ...)
ChatSessions (id, user_id, session_id, started_at, ...)
ChatMessages (id, session_id, message_type, content, ...)

-- Mối quan hệ
User (1) ──→ (*) HealthRecords
User (1) ──→ (*) Medications  
User (1) ──→ (*) Schedules
User (1) ──→ (*) ChatSessions
ChatSession (1) ──→ (*) ChatMessages
```

---

## 🚀 Hiệu Suất

| Chỉ Số | Giá Trị | Mô Tả |
|---------|---------|-------|
| **API Response** | <100ms | Thời gian phản hồi trung bình |
| **AI Inference** | <200ms | Dự đoán bệnh da liễu |
| **Database Query** | <50ms | Truy vấn MySQL |
| **Frontend Load** | <2s | Tải trang đầu tiên |
| **Mobile App** | <1s | Khởi động ứng dụng |
| **Concurrent Users** | 500+ | Người dùng đồng thời |

---

## ❌ Khắc Phục Lỗi

### ❓ Backend không khởi động

```bash
# Kiểm tra Python version
python --version  # Phải >= 3.9

# Kiểm tra MySQL connection
mysql -u elderly_user -p elderly_health_db

# Cài lại dependencies
pip install -r requirements.txt --force-reinstall

# Chạy migrations
alembic upgrade head
```

### ❓ Frontend không kết nối Backend

```bash
# Kiểm tra .env.local
NEXT_PUBLIC_API_URL=http://localhost:8000

# Kiểm tra CORS settings trong backend
# Restart cả frontend và backend
npm run dev
python main.py
```

### ❓ AI Model không load được

```bash
# Kiểm tra model files
ls backend/models/*.pth

# Download models nếu thiếu
# Xem hướng dẫn trong doc/AI_SETUP.md

# Kiểm tra GPU/CPU
python -c "import torch; print(torch.cuda.is_available())"
```

### ❓ Mobile app không build

```bash
# Kiểm tra Flutter
flutter doctor

# Clean và rebuild
flutter clean
flutter pub get
flutter build apk
```

### ❓ Database connection error

```sql
-- Kiểm tra MySQL service
sudo systemctl status mysql

-- Reset password
ALTER USER 'elderly_user'@'localhost' IDENTIFIED BY 'new_password';
FLUSH PRIVILEGES;

-- Kiểm tra permissions
SHOW GRANTS FOR 'elderly_user'@'localhost';
```

### ❓ Notifications không hoạt động

```bash
# Mobile: Kiểm tra permissions
# Android: Settings > Apps > Permissions > Notifications

# Backend: Kiểm tra email config
MAIL_USERNAME=your-email@gmail.com
MAIL_PASSWORD=your-app-password
MAIL_FROM=your-email@gmail.com
```

---

## 🤝 Đóng Góp

1. **Fork** repository
2. **Tạo branch:** `git checkout -b feature/your-feature`
3. **Commit:** `git commit -m "Add your feature"`
4. **Push:** `git push origin feature/your-feature`
5. **Tạo Pull Request**

### 📋 Development Guidelines

- **Code Style:** Follow PEP 8 (Python), ESLint (JavaScript)
- **Testing:** Write unit tests cho API endpoints
- **Documentation:** Update README khi thêm tính năng
- **Security:** Không commit API keys hoặc passwords

---

## 📝 License

MIT License - Xem [LICENSE](LICENSE)

---

## 📞 Hỗ Trợ

- 📧 **Email:** support@elderlyhealth.com
- 🐛 **Issues:** [GitHub Issues](https://github.com/your-username/elderly-health-system/issues)
- 📚 **Documentation:** [Wiki](https://github.com/your-username/elderly-health-system/wiki)
- 💬 **Discord:** [Community Server](https://discord.gg/elderlyhealth)

---

## 🎉 Cảm Ơn

Cảm ơn bạn đã sử dụng **Hệ Thống Hỗ Trợ Sức Khỏe Người Cao Tuổi**!

Nếu thấy hữu ích, hãy ⭐ **Star** repository này.

**Made with ❤️ by Elderly Health Support Team**

---

🏠 [Home](/) | 🤖 [AI Models](/doc/AI_MODELS.md) | 📚 [Docs](/doc/) | 🐛 [Issues](https://github.com/your-username/elderly-health-system/issues) | 📱 [Mobile](/mobile/)