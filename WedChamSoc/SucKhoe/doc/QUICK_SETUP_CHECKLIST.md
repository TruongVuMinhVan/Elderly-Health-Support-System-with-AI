# ✅ Quick Setup Checklist

Checklist nhanh để setup project cho người mới.

## 📋 Backend Setup

### 1. Environment Variables
- [ ] Copy `backend/.env.example` thành `backend/.env`
- [ ] Chỉnh sửa `backend/.env` với thông tin của bạn:
  - `DATABASE_URL` - Thông tin kết nối database
  - `SECRET_KEY` - Key bảo mật (đổi thành key mạnh)
  - `GEMINI_API_KEY` - API key cho AI chat (nếu cần)
  - `MAIL_USERNAME`, `MAIL_PASSWORD` - Email cho 2FA (nếu cần)

### 2. Python Dependencies
- [ ] Cài Python 3.8+
- [ ] Tạo virtual environment: `python -m venv venv`
- [ ] Activate venv: `venv\Scripts\activate` (Windows) hoặc `source venv/bin/activate` (Linux/Mac)
- [ ] Cài dependencies: `pip install -r requirements.txt`

### 3. Database
- [ ] Cài đặt MySQL
- [ ] Tạo database: `CREATE DATABASE elderly_health_db;`
- [ ] Chạy schema: `mysql -u root -p elderly_health_db < database/schema.sql`
- [ ] (Optional) Chạy sample data: `mysql -u root -p elderly_health_db < database/sample_data.sql`

### 4. Model Files ⚠️ QUAN TRỌNG
- [ ] Download model files từ Google Drive/Cloud Storage
- [ ] Đặt vào `backend/models/`:
  - `resnet50_best.pth`
  - `resnet50_best_checkpoint.pth`
- [ ] Kiểm tra có file `label_map_from_dataset.json` (đã có trong Git)

### 5. Run Backend
- [ ] Chạy: `python main.py` hoặc `uvicorn main:app --reload`
- [ ] Kiểm tra: http://localhost:8000/docs

---

## 📋 Frontend Setup

- [ ] Cài Node.js 18+
- [ ] `cd frontend`
- [ ] `npm install`
- [ ] `npm run dev`
- [ ] Kiểm tra: http://localhost:3000

---

## 📋 Mobile App Setup

- [ ] Cài Flutter SDK
- [ ] `cd mobile`
- [ ] `flutter pub get`
- [ ] `flutter run` (cần device/emulator)

---

## ⚠️ Các File Quan Trọng KHÔNG Có Trong Git

Các file sau **KHÔNG** được commit, cần tự tạo/download:

1. **`backend/.env`** - Environment variables (copy từ `.env.example`)
2. **`backend/models/*.pth`** - Model files (download từ cloud storage)
3. **`backend/venv/`** - Virtual environment (tự tạo)
4. **`frontend/node_modules/`** - Node dependencies (tự cài)
5. **`mobile/build/`** - Build artifacts (tự build)

---

## 🔗 Xem Chi Tiết

Xem file `doc/SETUP_AND_DEPLOYMENT.md` để biết chi tiết đầy đủ.

