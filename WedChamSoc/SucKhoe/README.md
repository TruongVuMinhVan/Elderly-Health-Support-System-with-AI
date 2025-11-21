# 🏥 Hệ Thống Hỗ Trợ Sức Khỏe Người Cao Tuổi

Một ứng dụng web toàn diện giúp người cao tuổi quản lý sức khỏe, thuốc men, lịch hẹn khám bệnh và tương tác với AI hỗ trợ y tế.

## 🌟 Tính Năng Chính

### 📊 **Dashboard Tổng Quan**

- Hiển thị thống kê sức khỏe tổng quan
- Lịch hẹn sắp tới
- Thuốc cần uống hôm nay
- Biểu đồ xu hướng sức khỏe

### 💊 **Quản Lý Thuốc**

- ✅ Thêm/sửa/xóa thuốc
- ✅ Theo dõi liều lượng và tần suất
- ✅ Ghi chú hướng dẫn sử dụng
- ✅ Quản lý ngày bắt đầu/kết thúc

### 📅 **Quản Lý Lịch Hẹn**

- ✅ Thêm/sửa/xóa lịch hẹn khám bệnh
- ✅ Thông tin bác sĩ và địa điểm
- ✅ Nhắc nhở trước cuộc hẹn
- ✅ Phân loại theo loại khám

### 📈 **Theo Dõi Sức Khỏe**

- ✅ Ghi nhận chỉ số huyết áp
- ✅ Theo dõi nhịp tim
- ✅ Đo đường huyết
- ✅ Cân nặng và nhiệt độ
- ✅ Múi giờ chính xác (GMT+7)

### 👤 **Hồ Sơ Cá Nhân**

- ✅ Cập nhật thông tin cá nhân
- ✅ Hồ sơ sức khỏe chi tiết
- ✅ Thông tin liên hệ khẩn cấp
- ✅ Quản lý bệnh mãn tính và dị ứng

### 🤖 **AI Chat Hỗ Trợ**

- Tư vấn sức khỏe cơ bản
- Trả lời câu hỏi về thuốc
- Hướng dẫn chăm sóc sức khỏe
- Sử dụng Google Gemini AI

## 🛠️ Công Nghệ Sử Dụng

### **Frontend**

- **Next.js 14** - React framework
- **TypeScript** - Type safety
- **Tailwind CSS** - Styling
- **Heroicons** - Icon library

### **Backend**

- **FastAPI** - Python web framework
- **SQLAlchemy** - ORM
- **MySQL** - Database
- **JWT** - Authentication
- **Pydantic** - Data validation

### **AI Integration**

- **Google Gemini API** - AI chat functionality

## 📋 Yêu Cầu Hệ Thống

- **Node.js** >= 18.0.0
- **Python** >= 3.8
- **MySQL** >= 8.0
- **npm** hoặc **yarn**

## 🚀 Hướng Dẫn Cài Đặt

### 1. **Clone Repository**

```bash
git clone <repository-url>
cd SucKhoe
```

### 2. **Cài Đặt Database MySQL**

### Mở file sql lên rồi chạy

### 3. **Cài Đặt Backend**

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
pip install -r requirements_simple.txt

# Cấu hình database trong database.py (nếu cần)
# DATABASE_URL = "mysql+pymysql://elderly_user:elderly_password@localhost/elderly_health_db"

# Chạy server
python main.py
```

**Backend sẽ chạy tại:** `http://localhost:8000`

### 4. **Cài Đặt Frontend**

```bash
cd frontend

# Cài đặt dependencies
npm install

# Chạy development server
npm run dev
```

**Frontend sẽ chạy tại:** `http://localhost:3000`

### 5. **Cấu Hình AI Chat (Tùy chọn)**

Để sử dụng tính năng AI chat, cần cấu hình Google Gemini API:

```bash
# Trong backend, tạo file .env hoặc cập nhật config
GEMINI_API_KEY=your_gemini_api_key_here
```

## 🔐 Thông Tin Đăng Nhập

**Email:** `duong@gmail.com`  
**Password:** `123456`

## 📱 Sử Dụng Ứng Dụng

### **1. Đăng Nhập**

- Truy cập `http://localhost:3000`
- Sử dụng thông tin đăng nhập ở trên

### **2. Dashboard**

- Xem tổng quan sức khỏe
- Kiểm tra lịch hẹn hôm nay
- Theo dõi thuốc cần uống

### **3. Quản Lý Sức Khỏe**

- Vào trang "Sức Khỏe"
- Thêm chỉ số mới bằng nút "+"
- Chọn loại chỉ số và nhập giá trị

### **4. Quản Lý Thuốc**

- Vào trang "Thuốc"
- Thêm thuốc mới với đầy đủ thông tin
- Sửa/xóa thuốc hiện có

### **5. Quản Lý Lịch Hẹn**

- Vào trang "Lịch Hẹn"
- Tạo lịch hẹn mới
- Cập nhật thông tin cuộc hẹn

### **6. Cập Nhật Hồ Sơ**

- Vào trang "Hồ Sơ"
- Cập nhật thông tin cá nhân
- Quản lý hồ sơ sức khỏe

## 🔧 API Endpoints

### **Authentication**

- `POST /api/auth/login` - Đăng nhập
- `GET /api/auth/me` - Thông tin user hiện tại

### **Health Records**

- `GET /api/health/records` - Lấy danh sách chỉ số
- `POST /api/health/records` - Thêm chỉ số mới
- `DELETE /api/health/records/{id}` - Xóa chỉ số

### **Medications**

- `GET /api/medications` - Lấy danh sách thuốc
- `POST /api/medications` - Thêm thuốc mới
- `PUT /api/medications/{id}` - Cập nhật thuốc
- `DELETE /api/medications/{id}` - Xóa thuốc

### **Schedules**

- `GET /api/schedules` - Lấy danh sách lịch hẹn
- `POST /api/schedules` - Thêm lịch hẹn mới
- `PUT /api/schedules/{id}` - Cập nhật lịch hẹn
- `DELETE /api/schedules/{id}` - Xóa lịch hẹn

### **User Profile**

- `GET /api/users/me` - Thông tin user
- `PUT /api/users/me` - Cập nhật thông tin user
- `GET /api/users/me/health-profile` - Hồ sơ sức khỏe
- `POST /api/users/me/health-profile` - Tạo hồ sơ sức khỏe
- `PUT /api/users/me/health-profile` - Cập nhật hồ sơ sức khỏe

## 🐛 Troubleshooting

### **Lỗi Database Connection**

```bash
# Kiểm tra MySQL service đang chạy
# Kiểm tra thông tin kết nối trong database.py
# Đảm bảo database và user đã được tạo
```

### **Lỗi Frontend Build**

```bash
# Xóa node_modules và cài lại
rm -rf node_modules package-lock.json
npm install
```

### **Lỗi Backend Dependencies**

```bash
# Cài lại dependencies
pip uninstall -r requirements_simple.txt -y
pip install -r requirements_simple.txt
```

## 📞 Hỗ Trợ

Nếu gặp vấn đề trong quá trình cài đặt hoặc sử dụng, vui lòng:

1. Kiểm tra logs trong terminal
2. Đảm bảo tất cả services đang chạy
3. Kiểm tra kết nối database
4. Xem lại các bước cài đặt

## 🎯 Tính Năng Đã Hoàn Thành

- ✅ Authentication & Authorization
- ✅ Dashboard với real-time data
- ✅ CRUD hoàn chỉnh cho Health Records
- ✅ CRUD hoàn chỉnh cho Medications
- ✅ CRUD hoàn chỉnh cho Schedules
- ✅ User Profile Management
- ✅ Health Profile Management
- ✅ Responsive UI cho người cao tuổi
- ✅ Timezone handling (GMT+7)
- ✅ Form validation
- ✅ Error handling
- ✅ API integration

---

**Phiên bản:** 1.0.0  
**Cập nhật:** Tháng 6, 2025  
**Tác giả:** Healthcare Development Team
