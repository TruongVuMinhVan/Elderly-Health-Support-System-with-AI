# 📋 Hướng Dẫn Setup và Deployment

Tài liệu này mô tả các file cần thiết để chạy project và cách setup để người khác có thể chạy được code.

## 📁 Cấu Trúc Project

```
SucKhoe/
├── backend/              # FastAPI Backend
│   ├── models/          # Database models & ML models
│   ├── routers/         # API routes
│   ├── ml/              # Machine Learning module
│   ├── scripts/         # Training scripts
│   ├── uploads/         # User uploaded files (gitignored)
│   ├── venv/            # Python virtual environment (gitignored)
│   ├── requirements.txt # Python dependencies
│   └── .env             # Environment variables (gitignored - CẦN TẠO)
├── frontend/            # Next.js Frontend
│   ├── node_modules/    # Node dependencies (gitignored)
│   ├── .next/           # Next.js build (gitignored)
│   └── package.json     # Node dependencies
├── mobile/              # Flutter Mobile App
│   ├── android/         # Android native code
│   ├── ios/             # iOS native code
│   ├── build/           # Build artifacts (gitignored)
│   └── pubspec.yaml     # Flutter dependencies
├── database/            # Database SQL scripts
│   ├── schema.sql       # Database schema
│   ├── sample_data.sql  # Sample data
│   └── update_user_settings_mysql.sql
└── doc/                 # Documentation
```

---

## 🚫 Các File/Folder Bị Ignore Bởi .gitignore

### Root `.gitignore` (D:\STUDY\DACN\App\DoAnCN\.gitignore)

Các file/folder sau **KHÔNG** được commit vào Git:

1. **Environment Variables**
   - `*.env`
   - `.env.*`
   - `.env.local`
   - `.env.production`
   - `.env.development`

2. **Python**
   - `**/__pycache__/`
   - `*.pyc`, `*.pyo`, `*.pyd`
   - `venv/`, `.venv/`, `ENV/`, `env/`
   - `build/`, `dist/`
   - `*.egg-info/`

3. **Database Files**
   - `*.db`
   - `*.sqlite`
   - `*.sqlite3`

4. **Node.js / Frontend**
   - `node_modules/`
   - `.next/`
   - `out/`
   - `coverage/`

5. **Model Files (Quan trọng!)**
   - `backend/models/*.pth` (PyTorch models)
   - `backend/models/*.pt`
   - `backend/models/*.pkl`
   - `backend/models/*.h5`
   - `backend/models/resnet*.pth`
   - **NHƯNG**: `label_map*.json` và `*history*.json` **ĐƯỢC** commit

6. **Dataset**
   - `dataset/`
   - `dataset_10classes/`
   - `dataset_*/`

7. **Uploads**
   - `backend/uploads/*` (user uploaded images)
   - `uploads/*`

8. **Build Artifacts**
   - `build/`
   - `dist/`
   - `*.log`

9. **IDE & OS**
   - `.vscode/` (trừ settings.json, tasks.json, launch.json)
   - `.idea/`
   - `.DS_Store`
   - `Thumbs.db`

10. **Flutter/Mobile**
    - `mobile/build/`
    - `mobile/.dart_tool/`
    - `mobile/.pub/`
    - `mobile/android/local.properties`
    - `mobile/android/app/debug/`, `profile/`, `release/`

---

## ✅ Các File Cần Thiết Để Chạy Project

### 1. **Backend Files**

#### A. Environment Variables (`.env` file) - **CẦN TẠO**

Tạo file `backend/.env` với nội dung:

```env
# Database Configuration
DATABASE_URL=mysql+pymysql://root:123456@localhost:3306/elderly_health_db
# Hoặc SQLite: sqlite:///./elderly_health.db

# Database Pool Settings (Optional)
DB_POOL_SIZE=10
DB_MAX_OVERFLOW=20

# Debug Mode
DEBUG=False

# CORS Settings
ALLOWED_ORIGINS=http://localhost:3000,http://localhost:8080

# JWT Authentication
SECRET_KEY=your-super-secret-key-change-in-production
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30

# Email Configuration (Optional - for 2FA)
MAIL_USERNAME=your-email@gmail.com
MAIL_PASSWORD=your-app-password
MAIL_FROM=noreply@suckhoe.com
MAIL_PORT=587
MAIL_SERVER=smtp.gmail.com
MAIL_STARTTLS=True
MAIL_SSL_TLS=False

# AI Chat (Google Gemini)
GEMINI_API_KEY=your-gemini-api-key-here
GEMINI_MODEL=gemini-2.0-flash
```

**⚠️ QUAN TRỌNG**: File `.env` **KHÔNG** được commit vào Git. Người khác cần tự tạo file này.

#### B. Model Files - **CẦN DOWNLOAD/TRAIN**

Các file model sau **KHÔNG** được commit (quá lớn), cần đặt tại:

```
backend/models/
├── resnet50_best.pth                    # Model weights (CẦN)
├── resnet50_best_checkpoint.pth         # Full checkpoint (CẦN)
└── checkpoints/
    └── resnet50_best_checkpoint.pth     # Checkpoint backup (CẦN)
```

**Cách lấy model files:**
1. **Từ Google Drive/Cloud Storage**: Download từ nơi lưu trữ
2. **Từ training**: Train model bằng script `backend/scripts/train_model.py`
3. **Từ checkpoint**: Load từ checkpoint đã train trước đó

**File label maps (ĐÃ CÓ trong Git):**
- `backend/models/label_map_from_dataset.json` ✅
- `backend/models/label_map_10classes.json` ✅

#### C. Python Dependencies

File `backend/requirements.txt` **ĐÃ CÓ** trong Git. Cài đặt:

```bash
cd backend
python -m venv venv
venv\Scripts\activate  # Windows
# hoặc: source venv/bin/activate  # Linux/Mac
pip install -r requirements.txt
```

**Lưu ý**: `requirements.txt` không bao gồm PyTorch (quá lớn). Nếu cần train model, cài thêm:

```bash
pip install -r requirements_training.txt
```

#### D. Database Setup

1. **Tạo database**:
   ```sql
   CREATE DATABASE elderly_health_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
   ```

2. **Chạy schema**:
   ```bash
   mysql -u root -p elderly_health_db < database/schema.sql
   ```

3. **Chạy sample data (optional)**:
   ```bash
   mysql -u root -p elderly_health_db < database/sample_data.sql
   ```

4. **Update user_settings table (nếu cần)**:
   ```bash
   mysql -u root -p elderly_health_db < database/update_user_settings_mysql.sql
   ```

---

### 2. **Frontend Files**

#### A. Node Dependencies

File `frontend/package.json` **ĐÃ CÓ** trong Git. Cài đặt:

```bash
cd frontend
npm install
```

#### B. Environment Variables (Optional)

Nếu frontend cần config riêng, tạo `frontend/.env.local`:

```env
NEXT_PUBLIC_API_URL=http://localhost:8000
```

---

### 3. **Mobile App Files**

#### A. Flutter Dependencies

File `mobile/pubspec.yaml` **ĐÃ CÓ** trong Git. Cài đặt:

```bash
cd mobile
flutter pub get
```

#### B. Android Configuration

- `mobile/android/local.properties` **KHÔNG** được commit (chứa local paths)
- Tự động tạo khi build Android app

#### C. iOS Configuration

- Cần Xcode để build iOS app
- Cần cấu hình signing certificates

---

## 📦 Checklist Để Người Khác Chạy Được Code

### ✅ Backend Setup

- [ ] Clone repository
- [ ] Tạo file `backend/.env` với các biến môi trường cần thiết
- [ ] Cài đặt Python 3.8+
- [ ] Tạo virtual environment: `python -m venv venv`
- [ ] Activate venv và cài dependencies: `pip install -r requirements.txt`
- [ ] Setup MySQL database và chạy `database/schema.sql`
- [ ] **Download/Place model files** vào `backend/models/`:
  - `resnet50_best.pth`
  - `resnet50_best_checkpoint.pth`
- [ ] Tạo folder `backend/uploads/skin_disease/` (tự động tạo khi upload)
- [ ] Chạy backend: `python main.py` hoặc `uvicorn main:app --reload`

### ✅ Frontend Setup

- [ ] Cài đặt Node.js 18+
- [ ] Cài dependencies: `npm install`
- [ ] Chạy frontend: `npm run dev`

### ✅ Mobile App Setup

- [ ] Cài đặt Flutter SDK
- [ ] Cài dependencies: `flutter pub get`
- [ ] Cấu hình Android SDK (cho Android)
- [ ] Cấu hình Xcode (cho iOS)
- [ ] Build app: `flutter build apk` (Android) hoặc `flutter build ios` (iOS)

---

## 🔄 Quy Trình Push Code Lên Git

### 1. **Kiểm tra .gitignore**

Đảm bảo các file sau **KHÔNG** được commit:

```bash
# Kiểm tra status
git status

# Nếu thấy các file sau, cần thêm vào .gitignore:
# - *.env
# - venv/
# - __pycache__/
# - *.pth, *.pt
# - node_modules/
# - build/
# - *.db
```

### 2. **Commit Code**

```bash
# Add files
git add .

# Commit
git commit -m "Your commit message"

# Push
git push origin main
```

### 3. **Các File Quan Trọng CẦN Commit**

✅ **Nên commit:**
- Source code (`.py`, `.dart`, `.tsx`, `.ts`)
- Configuration files (`requirements.txt`, `package.json`, `pubspec.yaml`)
- SQL scripts (`database/*.sql`)
- Documentation (`doc/*.md`)
- Label maps (`backend/models/label_map*.json`)
- Training scripts (`backend/scripts/train_model.py`)
- `.gitignore` files

❌ **KHÔNG commit:**
- `.env` files
- Model files (`.pth`, `.pt`)
- Virtual environments (`venv/`)
- Build artifacts (`build/`, `dist/`, `.next/`)
- Database files (`.db`, `.sqlite`)
- Uploaded files (`uploads/`)
- Dependencies (`node_modules/`, `venv/`)

---

## 📤 Cách Chia Sẻ Model Files

Vì model files quá lớn để commit vào Git, có các cách sau:

### Cách 1: Google Drive / Cloud Storage (Khuyến nghị)

1. Upload model files lên Google Drive/OneDrive/Dropbox
2. Tạo file `doc/MODEL_DOWNLOAD.md` với link download
3. Người khác download và đặt vào `backend/models/`

### Cách 2: Git LFS (Git Large File Storage)

```bash
# Cài Git LFS
git lfs install

# Track .pth files
git lfs track "*.pth"
git lfs track "*.pt"

# Commit .gitattributes
git add .gitattributes
git commit -m "Add Git LFS tracking for model files"

# Add model files
git add backend/models/*.pth
git commit -m "Add model files via Git LFS"
git push
```

### Cách 3: External Storage Service

- Sử dụng AWS S3, Azure Blob Storage, etc.
- Tạo script download tự động

---

## 🚀 Quick Start Guide Cho Người Mới

### Bước 1: Clone Repository

```bash
git clone <repository-url>
cd SucKhoe
```

### Bước 2: Setup Backend

```bash
cd backend

# Tạo .env file
copy .env.example .env  # Windows
# hoặc: cp .env.example .env  # Linux/Mac

# Chỉnh sửa .env với thông tin của bạn

# Tạo venv và cài dependencies
python -m venv venv
venv\Scripts\activate  # Windows
pip install -r requirements.txt

# Setup database
mysql -u root -p -e "CREATE DATABASE elderly_health_db;"
mysql -u root -p elderly_health_db < ../database/schema.sql

# Download model files (từ link trong doc/MODEL_DOWNLOAD.md)
# Đặt vào backend/models/

# Chạy backend
python main.py
```

### Bước 3: Setup Frontend

```bash
cd frontend
npm install
npm run dev
```

### Bước 4: Setup Mobile (Optional)

```bash
cd mobile
flutter pub get
flutter run
```

---

## 📝 Notes Quan Trọng

1. **Model Files**: Luôn đảm bảo có model files trong `backend/models/` trước khi chạy prediction API
2. **Database**: Đảm bảo MySQL đang chạy và database đã được tạo
3. **Environment Variables**: File `.env` là bắt buộc, không có sẽ lỗi
4. **Ports**: Backend mặc định chạy trên port 8000, Frontend trên port 3000
5. **CORS**: Cấu hình `ALLOWED_ORIGINS` trong `.env` để frontend có thể gọi API

---

## 🔗 Tài Liệu Liên Quan

- `README.md` - Tổng quan project
- `DEV-SETUP.md` - Hướng dẫn development
- `doc/README.md` - Tài liệu training
- `doc/colab_training_setup.py` - Script training trên Google Colab
- `doc/QUICK_SETUP_CHECKLIST.md` - Checklist setup nhanh

---

**Cập nhật lần cuối**: 2025-01-19

