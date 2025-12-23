# 🚀 Hướng Dẫn Setup Cho Người Khác

## ❓ Câu Hỏi: Có Cần Train Lại Từ Đầu Không?

**Trả lời: KHÔNG** - Nếu đã có trained model files. Chỉ cần download và sử dụng.

**Khi nào cần train lại:**
- ✅ Muốn thêm classes mới (hiện tại: 11 loại bệnh da)
- ✅ Có dataset tốt hơn (hiện tại: 24,086 ảnh)
- ✅ Muốn thử hyperparameters khác
- ✅ Research và development

---

## 📋 Quick Start (3 phút)

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
├── resnet50_best.pth      # 295MB (30/11/2025) - ResNet50 model
├── vit_best.pth           # 345MB (11/12/2025) - Vision Transformer
└── label_map_from_dataset.json  # 2.5KB (có sẵn trong git)
```

### **Bước 3: Setup Environment**

```bash
# Backend
cd backend
python -m venv venv
source venv/bin/activate  # Linux/Mac
# venv\Scripts\activate   # Windows

pip install -r requirements.txt

# Frontend
cd ../frontend
npm install

# Mobile (optional)
cd ../mobile
flutter pub get
```

### **Bước 4: Setup Database**

```sql
-- MySQL
CREATE DATABASE elderly_health_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'elderly_user'@'localhost' IDENTIFIED BY 'elderly_password';
GRANT ALL PRIVILEGES ON elderly_health_db.* TO 'elderly_user'@'localhost';

-- Import schema
USE elderly_health_db;
SOURCE database/schema.sql;
SOURCE database/sample_data.sql;
```

### **Bước 5: Verify Setup**

```bash
# Kiểm tra AI models
python backend/ml/test_predictor.py

# Chạy ứng dụng
python start-dev.py  # Chạy cả backend + frontend

# Hoặc chạy riêng lẻ:
# Backend: python backend/main.py
# Frontend: cd frontend && npm run dev
```

**URLs:**
- **Frontend:** http://localhost:3000
- **Backend API:** http://localhost:8000
- **API Docs:** http://localhost:8000/docs

---

## 🔍 Chi Tiết Về AI Models

### **1. Model Files Hiện Có**

| Model | Size | Accuracy | Speed | Best For |
|-------|------|----------|-------|----------|
| **ResNet50** | 295MB | 87.8% | 45ms | Production, Real-time |
| **ViT** | 345MB | 92.1% | 120ms | High accuracy |
| **Ensemble** | 640MB | 94.1% | 165ms | Best accuracy |

### **2. Tại sao không commit vào git?**

- **Kích thước lớn:** 640MB total (vượt GitHub limit)
- **Git performance:** Làm chậm clone, pull, push
- **Storage cost:** GitHub có giới hạn repository size
- **Version control:** Binary files không diff được

### **3. Giải pháp lưu trữ:**

```bash
# Option 1: Git LFS (Large File Storage) - Khuyến nghị
git lfs track "*.pth"
git add .gitattributes
git add backend/models/*.pth
git commit -m "Add AI models with LFS"

# Option 2: External storage
# Google Drive, Dropbox, AWS S3, GitHub Releases

# Option 3: Model registry
# MLflow, Weights & Biases, Hugging Face Hub
```

---

## 🎓 Nếu Muốn Train Lại Models

### **Yêu cầu:**
- **Dataset:** 24,086 ảnh da liễu (11 classes)
- **GPU:** NVIDIA GPU với CUDA (khuyến nghị)
- **RAM:** 16GB+ (cho training)
- **Storage:** 50GB+ (cho dataset + checkpoints)

### **Training Commands:**

```bash
# Train ResNet50 (nhanh hơn)
python backend/scripts/train_model.py \
    --model resnet50 \
    --config from_dataset \
    --epochs 50 \
    --batch-size 32

# Train Vision Transformer (chính xác hơn)
python backend/scripts/train_model.py \
    --model vit \
    --config from_dataset \
    --epochs 100 \
    --batch-size 16

# Thời gian training:
# - CPU: 4-8 giờ (ResNet50), 8-12 giờ (ViT)
# - GPU: 30-60 phút (ResNet50), 2-3 giờ (ViT)
```

### **Google Colab Training (Miễn phí):**

```bash
# Xem hướng dẫn chi tiết:
doc/COLAB_TRAINING_GUIDE.md

# Upload notebook:
backend/scripts/skin disease predict.ipynb
```

---

## 📊 Dataset Information

### **11 Loại Bệnh Da Liễu:**

```json
{
  "basal_cell_carcinoma": 6421,    // Ung thư tế bào đáy
  "seborrheic_keratosis": 4925,    // U sừng bã nhờn
  "melanoma": 4342,                // Ung thư hắc tố
  "lichen_planus": 2457,           // Liken phẳng
  "healthy": 2009,                 // Da khỏe mạnh
  "eczema": 1677,                  // Chàm
  "squamous_cell_carcinoma": 1000, // Ung thư tế bào vảy
  "actinic_keratosis": 852,        // U sừng quang hóa
  "spider_angioma": 491,           // U mạch máu hình nhện
  "keratoacanthoma": 477,          // U sừng tự tiêu
  "dermatofibroma": 335            // U xơ da
}
```

### **Dataset Structure:**
```bash
dataset/
├── train/ (16,399 ảnh - 68%)
├── val/ (3,864 ảnh - 16%)
└── test/ (3,823 ảnh - 16%)
```

**⚠️ Dataset KHÔNG được commit vào git** (quá lớn: ~5GB)

**Nếu cần dataset:**
- Liên hệ maintainer để lấy link download
- Hoặc sử dụng public datasets: HAM10000, ISIC, DermNet

---

## 📁 Cấu Trúc Files

```
elderly-health-system/
├── backend/
│   ├── models/
│   │   ├── label_map_from_dataset.json  ✅ (có trong git)
│   │   ├── resnet50_best.pth            ⚠️  (cần download - 295MB)
│   │   ├── vit_best.pth                 ⚠️  (cần download - 345MB)
│   │   └── checkpoints/                 ⚠️  (training checkpoints)
│   ├── scripts/
│   │   ├── train_model.py               ✅ (training script)
│   │   ├── test_predictor.py            ✅ (testing script)
│   │   └── skin disease predict.ipynb   ✅ (Colab notebook)
│   ├── ml/
│   │   └── predictor.py                 ✅ (inference code)
│   └── requirements.txt                 ✅
├── frontend/
│   ├── package.json                     ✅
│   └── ...
├── mobile/
│   ├── pubspec.yaml                     ✅
│   └── ...
├── database/
│   ├── schema.sql                       ✅
│   └── sample_data.sql                  ✅
├── dataset/                             ⚠️  (cần có để train - ~5GB)
│   ├── train/
│   ├── val/
│   └── test/
└── doc/
    ├── COLAB_TRAINING_GUIDE.md          ✅
    └── PREDICTION_AND_TRAINING_GUIDE.md ✅
```

**Legend:**
- ✅ Có trong git
- ⚠️ Cần download hoặc tạo

---

## 🛠️ Troubleshooting

### **❓ Lỗi: Model file not found**

```bash
# Kiểm tra model files
ls -la backend/models/*.pth

# Nếu không có:
# 1. Download từ Git LFS: git lfs pull
# 2. Download manual từ Google Drive
# 3. Train lại: python backend/scripts/train_model.py
```

### **❓ Lỗi: Module not found**

```bash
# Backend dependencies
cd backend
pip install -r requirements.txt

# Frontend dependencies
cd frontend
npm install

# Mobile dependencies
cd mobile
flutter pub get
```

### **❓ Lỗi: Database connection**

```bash
# Kiểm tra MySQL service
sudo systemctl status mysql  # Linux
brew services list | grep mysql  # Mac

# Test connection
mysql -u elderly_user -p elderly_health_db

# Tạo lại database nếu cần
SOURCE database/schema.sql;
```

### **❓ Lỗi: AI inference failed**

```bash
# Test AI models
python backend/ml/test_predictor.py

# Kiểm tra GPU (optional)
python -c "import torch; print(f'CUDA: {torch.cuda.is_available()}')"

# Kiểm tra model integrity
python -c "
import torch
model = torch.load('backend/models/vit_best.pth', map_location='cpu')
print('✅ Model loaded successfully')
"
```

### **❓ Lỗi: Port already in use**

```bash
# Kiểm tra ports
netstat -an | findstr :8000  # Backend
netstat -an | findstr :3000  # Frontend

# Kill processes
taskkill /PID <PID> /F  # Windows
kill -9 <PID>           # Linux/Mac
```

---

## 📚 Tài Liệu Tham Khảo

- **[Main README](README.md)** - Tổng quan dự án
- **[AI Training Guide](doc/COLAB_TRAINING_GUIDE.md)** - Hướng dẫn train trên Colab
- **[Prediction Guide](doc/PREDICTION_AND_TRAINING_GUIDE.md)** - Chi tiết về AI system
- **[API Documentation](http://localhost:8000/docs)** - FastAPI auto-docs
- **[Mobile README](mobile/README.md)** - Flutter app development

---

## 💡 Tóm Tắt

### **Câu trả lời cho câu hỏi ban đầu:**

- ❌ **KHÔNG cần train lại** nếu có model files
- ✅ **Chỉ cần download** model files (295MB + 345MB)
- ✅ **Có thể train lại** nếu muốn customize hoặc research
- ✅ **Sử dụng Google Colab** để train miễn phí với GPU

### **Các bước setup:**

1. **Clone repo** + **Download models** (Git LFS hoặc manual)
2. **Install dependencies** (Python + Node.js + Flutter)
3. **Setup database** (MySQL)
4. **Run application** (Backend + Frontend)
5. **Test features** (AI prediction, Chat, Health tracking)

### **Thời gian setup:**

- **Có models:** 5-10 phút
- **Cần train lại:** 2-8 giờ (tùy GPU)
- **First time setup:** 15-30 phút

---

**🎯 Mục tiêu:** Giúp developers setup nhanh chóng và bắt đầu contribute vào dự án!

**Made with ❤️ by Elderly Health Support Team**

