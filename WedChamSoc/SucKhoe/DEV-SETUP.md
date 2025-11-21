# 🚀 SucKhoe Development Setup

Scripts để chạy cả backend và frontend cùng lúc trong môi trường development.

## 📋 Yêu cầu

- **Backend**: Python 3.8+, FastAPI, uvicorn
- **Frontend**: Node.js 16+, npm/yarn
- **Database**: MySQL (đã cấu hình)

## 🛠️ Cài đặt

### Backend
```bash
cd backend
pip install -r requirements.txt
```

### Frontend  
```bash
cd frontend
npm install
```

## 🚀 Chạy Development

### Cách 1: PowerShell (Windows - Khuyến nghị)
```powershell
.\start-dev.ps1
```

### Cách 2: Batch (Windows)
```cmd
start-dev.bat
```

### Cách 3: Bash (Linux/Mac)
```bash
chmod +x start-dev.sh
./start-dev.sh
```

### Cách 4: Python (Cross-platform)
```bash
python start-dev.py
```

## 🌐 URLs

Sau khi chạy script, truy cập:

- **Frontend**: http://localhost:3000
- **Backend API**: http://localhost:8000  
- **API Documentation**: http://localhost:8000/docs
- **2FA Endpoints**: http://localhost:8000/api/auth/2fa/

## 🛑 Dừng servers

- **PowerShell/Bash**: Nhấn `Ctrl+C`
- **Batch**: Đóng các cửa sổ terminal
- **Python**: Nhấn `Ctrl+C`

## 📁 Cấu trúc thư mục

```
SucKhoe/
├── backend/                 # FastAPI backend
│   ├── main.py             # Main application
│   ├── models/             # Database models
│   ├── routers/            # API routes
│   └── requirements.txt    # Python dependencies
├── frontend/               # Next.js frontend
│   ├── pages/              # Next.js pages
│   ├── components/         # React components
│   └── package.json        # Node dependencies
├── start-dev.ps1           # PowerShell script
├── start-dev.sh            # Bash script  
├── start-dev.bat           # Batch script
├── start-dev.py            # Python script
└── DEV-SETUP.md           # This file
```

## 🔧 Troubleshooting

### Port đã được sử dụng
```bash
# Kiểm tra port 8000
netstat -an | findstr :8000

# Kiểm tra port 3000  
netstat -an | findstr :3000

# Kill process sử dụng port
taskkill /PID <PID> /F
```

### Lỗi dependencies
```bash
# Backend
cd backend
pip install -r requirements.txt

# Frontend
cd frontend  
npm install
```

### Database connection
- Đảm bảo MySQL đang chạy
- Kiểm tra cấu hình trong `backend/database.py`
- Chạy migration nếu cần

## 📝 Notes

- Scripts sẽ tự động kiểm tra port availability
- Logs từ cả backend và frontend sẽ hiển thị cùng lúc
- 2FA đã được tích hợp đầy đủ vào hệ thống
- Sử dụng `Ctrl+C` để dừng cả hai servers cùng lúc
