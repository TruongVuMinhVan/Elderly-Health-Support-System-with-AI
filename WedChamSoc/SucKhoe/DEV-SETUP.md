# 🛠️ Hướng Dẫn Setup Development Environment

## 🎯 Tổng Quan

Hướng dẫn chi tiết để setup **Hệ Thống Hỗ Trợ Sức Khỏe Người Cao Tuổi** cho developers và contributors.

---

## ❓ FAQ: Có Cần Train AI Models Từ Đầu?

**Trả lời: KHÔNG** - Nếu đã có trained model files. Chỉ cần download và sử dụng.

**Khi nào cần train lại:**
- ✅ Muốn thêm classes mới
- ✅ Có dataset tốt hơn
- ✅ Muốn thử hyperparameters khác
- ✅ Research và development

---

## 🚀 Quick Start (5 phút)

### **Bước 1: Clone Repository**

```bash
git clone https://github.com/your-username/elderly-health-system.git
cd elderly-health-system
```

### **Bước 2: Download AI Models**

**⚠️ Models KHÔNG được commit vào git** (quá lớn: 295MB + 345MB)

#### **Option A: Git LFS (Khuyến nghị)**

```bash
git lfs install
git lfs pull  # Tự động download tất cả model files
```

#### **Option B: Manual Download**

Download từ: **[Google Drive Link](https://drive.google.com/drive/folders/your-folder-id)**

```bash
# Đặt vào thư mục backend/models/
backend/models/
├── resnet50_best.pth      # 295MB (30/11/2025)
├── vit_best.pth           # 345MB (11/12/2025) 
└── label_map_from_dataset.json  # Có sẵn trong git
```

### **Bước 3: Setup Backend**

```bash
cd backend

# Tạo virtual environment
python -m venv venv
source venv/bin/activate  # Linux/Mac
# venv\Scripts\activate   # Windows

# Cài đặt dependencies
pip install -r requirements.txt

# Setup database
mysql -u root -p
CREATE DATABASE elderly_health_db;
SOURCE ../database/schema.sql;

# Cấu hình .env
cp .env.example .env
# Cập nhật database credentials và API keys

# Chạy server
python main.py
```

### **Bước 4: Setup Frontend**

```bash
cd frontend

# Cài đặt dependencies
npm install

# Cấu hình environment
cp .env.local.example .env.local

# Chạy development server
npm run dev
```

### **Bước 5: Verify Setup**

```bash
# Kiểm tra backend
curl http://localhost:8000/health

# Kiểm tra AI models
python backend/ml/test_predictor.py

# Kiểm tra frontend
open http://localhost:3000
```

---

## 🔍 Setup Chi Tiết

### **1. AI Models Management**

#### **Tại sao không commit models vào git?**
- **Kích thước lớn:** ResNet50 (295MB) + ViT (345MB) = 640MB
- **Git performance:** Làm chậm clone, pull, push
- **Storage cost:** GitHub có giới hạn repository size
- **Version control:** Binary files không diff được

#### **Giải pháp lưu trữ:**
```bash
# Option 1: Git LFS (Large File Storage)
git lfs track "*.pth"
git add .gitattributes
git add backend/models/*.pth
git commit -m "Add AI models with LFS"

# Option 2: External storage
# Google Drive, Dropbox, AWS S3, GitHub Releases

# Option 3: Model registry
# MLflow, Weights & Biases, Hugging Face Hub
```

#### **Model files cần thiết:**
```bash
backend/models/
├── resnet50_best.pth              # 295MB - ResNet50 trained model
├── vit_best.pth                   # 345MB - Vision Transformer model  
├── label_map_from_dataset.json    # 2.5KB - Class mapping (có trong git)
├── resnet50_history.json          # Training history (optional)
└── vit_history.json               # Training history (optional)
```

### **2. Database Setup Chi Tiết**

```sql
-- Tạo database với charset UTF-8
CREATE DATABASE elderly_health_db 
CHARACTER SET utf8mb4 
COLLATE utf8mb4_unicode_ci;

-- Tạo user với permissions
CREATE USER 'elderly_user'@'localhost' IDENTIFIED BY 'elderly_password';
GRANT ALL PRIVILEGES ON elderly_health_db.* TO 'elderly_user'@'localhost';
FLUSH PRIVILEGES;

-- Import schema và sample data
USE elderly_health_db;
SOURCE database/schema.sql;
SOURCE database/sample_data.sql;

-- Verify tables
SHOW TABLES;
SELECT COUNT(*) FROM users;
```

### **3. Environment Configuration**

#### **Backend (.env):**
```bash
# Database
DATABASE_URL=mysql+pymysql://elderly_user:elderly_password@localhost/elderly_health_db

# JWT
SECRET_KEY=your-super-secret-jwt-key-here
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30

# AI APIs
GEMINI_API_KEY=your-gemini-api-key-here
OPENAI_API_KEY=your-openai-key-here  # Optional

# Email (for notifications)
MAIL_USERNAME=your-email@gmail.com
MAIL_PASSWORD=your-app-password
MAIL_FROM=your-email@gmail.com
MAIL_PORT=587
MAIL_SERVER=smtp.gmail.com

# AI Models
MODEL_PATH=backend/models
DEFAULT_MODEL=vit  # resnet50, vit, ensemble
```

#### **Frontend (.env.local):**
```bash
# API Endpoints
NEXT_PUBLIC_API_URL=http://localhost:8000
NEXT_PUBLIC_WS_URL=ws://localhost:8000

# Features
NEXT_PUBLIC_ENABLE_AI_CHAT=true
NEXT_PUBLIC_ENABLE_SKIN_PREDICTION=true
NEXT_PUBLIC_ENABLE_2FA=true

# Analytics (optional)
NEXT_PUBLIC_GA_ID=your-google-analytics-id
```

### **4. Mobile App Setup**

```bash
cd mobile

# Kiểm tra Flutter environment
flutter doctor

# Cài đặt dependencies
flutter pub get

# Cấu hình API endpoints
# lib/config/api_config.dart
const String baseUrl = 'http://10.0.2.2:8000';  # Android emulator
# const String baseUrl = 'http://localhost:8000';  # iOS simulator

# Build và chạy
flutter run

# Build release APK
flutter build apk --release
```

---

## 🚀 Development Scripts

### **Cách 1: PowerShell (Windows - Khuyến nghị)**
```powershell
.\start-dev.ps1
```

### **Cách 2: Batch (Windows)**
```cmd
start-dev.bat
```

### **Cách 3: Bash (Linux/Mac)**
```bash
chmod +x start-dev.sh
./start-dev.sh
```

### **Cách 4: Python (Cross-platform)**
```bash
python start-dev.py
```

### **URLs sau khi chạy:**
- **Frontend**: http://localhost:3000
- **Backend API**: http://localhost:8000  
- **API Documentation**: http://localhost:8000/docs
- **2FA Endpoints**: http://localhost:8000/api/auth/2fa/

---

## 🧪 Testing & Development

### **1. Backend Testing**

```bash
# Unit tests
python -m pytest backend/tests/ -v

# API testing
python -m pytest backend/tests/test_api.py -v

# AI model testing
python backend/ml/test_predictor.py

# Load testing
python backend/tests/load_test.py
```

### **2. Frontend Testing**

```bash
cd frontend

# Unit tests
npm test

# E2E tests
npm run test:e2e

# Type checking
npm run type-check

# Linting
npm run lint
```

### **3. AI Model Testing**

```bash
# Test single prediction
python backend/ml/test_predictor.py \
    --image test_images/eczema_sample.jpg \
    --model vit

# Batch testing
python backend/scripts/evaluate_model.py \
    --test-dir test_images/ \
    --model ensemble \
    --output results.json

# Performance benchmarking
python backend/scripts/benchmark_models.py
```

---

## 🔄 Development Workflow

### **1. Git Workflow**

```bash
# Tạo feature branch
git checkout -b feature/new-ai-model

# Development
# ... code changes ...

# Commit với conventional commits
git commit -m "feat(ai): add new skin disease classification model"

# Push và tạo PR
git push origin feature/new-ai-model
```

### **2. AI Model Development**

```bash
# Train new model
python backend/scripts/train_model.py \
    --model vit \
    --config from_dataset \
    --epochs 100 \
    --batch-size 16

# Evaluate model
python backend/scripts/evaluate_model.py \
    --model-path backend/models/vit_best.pth \
    --test-data dataset/test/

# Deploy model
cp backend/models/vit_best.pth backend/models/vit_production.pth
```

### **3. Database Migrations**

```bash
# Tạo migration
alembic revision --autogenerate -m "Add new table for notifications"

# Apply migration
alembic upgrade head

# Rollback migration
alembic downgrade -1
```

---

## 🛠️ Troubleshooting

### **❓ AI Models không load được**

```bash
# Kiểm tra model files
ls -la backend/models/*.pth

# Kiểm tra file integrity
python -c "
import torch
model = torch.load('backend/models/vit_best.pth', map_location='cpu')
print('Model loaded successfully')
print(f'Model keys: {list(model.keys()) if isinstance(model, dict) else \"State dict\"}')
"

# Download lại models
git lfs pull
# Hoặc download manual từ Google Drive
```

### **❓ Database connection failed**

```bash
# Kiểm tra MySQL service
sudo systemctl status mysql  # Linux
brew services list | grep mysql  # Mac

# Test connection
mysql -u elderly_user -p elderly_health_db

# Reset password
ALTER USER 'elderly_user'@'localhost' IDENTIFIED BY 'new_password';
FLUSH PRIVILEGES;
```

### **❓ Frontend không kết nối Backend**

```bash
# Kiểm tra CORS settings
# backend/main.py
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Kiểm tra .env.local
NEXT_PUBLIC_API_URL=http://localhost:8000

# Restart cả hai services
```

### **❓ Mobile app build failed**

```bash
# Clean Flutter
flutter clean
flutter pub get

# Kiểm tra Android SDK
flutter doctor --android-licenses

# Build với verbose
flutter build apk --verbose
```

### **❓ AI inference quá chậm**

```bash
# Kiểm tra GPU availability
python -c "import torch; print(f'CUDA: {torch.cuda.is_available()}')"

# Optimize model
python backend/scripts/optimize_model.py \
    --input backend/models/vit_best.pth \
    --output backend/models/vit_optimized.pth \
    --quantize

# Use smaller model
# Thay vit → resnet50 trong config
```

### **❓ Port đã được sử dụng**

```bash
# Kiểm tra port 8000
netstat -an | findstr :8000

# Kiểm tra port 3000  
netstat -an | findstr :3000

# Kill process sử dụng port
taskkill /PID <PID> /F
```

---

## 📁 Project Structure

```
elderly-health-system/
├── backend/                    # FastAPI backend
│   ├── main.py                # Entry point
│   ├── models/                # Database models
│   ├── routers/               # API routes
│   ├── ml/                    # AI models & prediction
│   ├── scripts/               # Training & utility scripts
│   ├── tests/                 # Unit tests
│   └── requirements.txt       # Python dependencies
├── frontend/                  # Next.js frontend
│   ├── pages/                 # Next.js pages
│   ├── components/            # React components
│   ├── lib/                   # Utilities
│   ├── styles/                # CSS styles
│   └── package.json           # Node.js dependencies
├── mobile/                    # Flutter mobile app
│   ├── lib/                   # Dart source code
│   ├── android/               # Android specific
│   ├── ios/                   # iOS specific
│   └── pubspec.yaml           # Flutter dependencies
├── database/                  # Database schemas
│   ├── schema.sql             # Database structure
│   └── sample_data.sql        # Sample data
├── doc/                       # Documentation
│   ├── COLAB_TRAINING_GUIDE.md
│   └── PREDICTION_AND_TRAINING_GUIDE.md
├── start-dev.ps1              # PowerShell development script
├── start-dev.sh               # Bash development script  
├── start-dev.bat              # Batch development script
├── start-dev.py               # Python development script
└── README.md                  # Main documentation
```

---

## 📚 Tài Liệu Tham Khảo

- **[API Documentation](http://localhost:8000/docs)** - FastAPI auto-generated docs
- **[AI Training Guide](doc/COLAB_TRAINING_GUIDE.md)** - Hướng dẫn train models
- **[Database Schema](database/schema.sql)** - Database structure
- **[Mobile Development](mobile/README.md)** - Flutter app development
- **[Deployment Guide](doc/DEPLOYMENT.md)** - Production deployment

---

## 🤝 Contributing Guidelines

### **Code Style:**
- **Python:** Follow PEP 8, use Black formatter
- **JavaScript/TypeScript:** Follow ESLint rules
- **Dart:** Follow Dart style guide

### **Commit Messages:**
```bash
feat(ai): add new skin disease classification model
fix(api): resolve authentication token expiry issue
docs(readme): update installation instructions
test(backend): add unit tests for health records API
```

### **Pull Request Process:**
1. Fork repository
2. Create feature branch
3. Write tests
4. Update documentation
5. Submit PR with clear description

---

## 💡 Development Tips

### **1. AI Model Development:**
- Sử dụng Google Colab cho training (GPU miễn phí)
- Lưu checkpoints thường xuyên
- Monitor training với TensorBoard
- Test trên nhiều loại ảnh khác nhau

### **2. API Development:**
- Sử dụng FastAPI auto-docs: `http://localhost:8000/docs`
- Write comprehensive tests
- Handle errors gracefully
- Log important events

### **3. Frontend Development:**
- Sử dụng TypeScript cho type safety
- Optimize images và assets
- Test trên nhiều devices
- Implement proper error boundaries

### **4. Mobile Development:**
- Test trên cả Android và iOS
- Optimize for different screen sizes
- Handle network connectivity issues
- Implement proper state management

---

## 🎯 Next Steps

Sau khi setup thành công:

1. **Explore codebase:** Đọc hiểu architecture và code structure
2. **Run tests:** Đảm bảo tất cả tests pass
3. **Try features:** Test tất cả tính năng chính
4. **Read documentation:** Hiểu rõ AI models và APIs
5. **Start contributing:** Pick một issue và bắt đầu develop

---

**Happy Coding! 🚀**

Made with ❤️ by Elderly Health Support Team