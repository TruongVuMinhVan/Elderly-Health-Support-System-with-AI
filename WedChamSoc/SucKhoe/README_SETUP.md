# 🚀 Hướng Dẫn Setup Cho Người Khác

## ❓ Câu Hỏi: Có Cần Train Lại Từ Đầu Không?

**Trả lời: KHÔNG**, nếu đã có trained model files. Chỉ cần download models.

---

## 📋 Quick Start

### **Bước 1: Clone Repository**

```bash
git clone https://github.com/your-username/repo.git
cd repo
```

### **Bước 2: Download Models**

**Models KHÔNG được commit vào git** (quá lớn). Bạn cần download:

#### **Option A: Git LFS (Nếu repo dùng Git LFS)**

```bash
git lfs install
git lfs pull  # Tự động download model files
```

#### **Option B: Manual Download**

Download từ: **[LINK GOOGLE DRIVE / DROPBOX]**

Đặt vào thư mục: `backend/models/`

**Files cần:**
- `resnet50_best.pth` (~100MB)
- `efficientnet_b6_best.pth` (~200MB) - Optional
- `vit_best.pth` (~300MB) - Optional

### **Bước 3: Setup Environment**

```bash
# Backend
cd backend
pip install -r requirements.txt
pip install -r requirements_training.txt
```

### **Bước 4: Verify Setup**

```bash
python backend/scripts/check_setup.py
```

Script sẽ kiểm tra:
- ✅ Label maps
- ✅ Model files
- ✅ Dataset structure
- ✅ Python dependencies
- ✅ Database files

### **Bước 5: Run Application**

```bash
# Backend API
uvicorn backend.main:app --reload

# Test inference
python backend/scripts/inference.py \
    --image path/to/test_image.jpg \
    --model resnet50 \
    --model-path backend/models/resnet50_best.pth
```

---

## 🔍 Chi Tiết

### **1. Model Files**

**Tại sao không commit vào git?**
- Model files rất lớn (100-500MB mỗi file)
- Git không phù hợp cho binary files lớn
- Làm chậm git operations

**Giải pháp:**
- ✅ Dùng **Git LFS** (nếu repo đã setup)
- ✅ Hoặc download từ **external storage** (Google Drive, Dropbox)
- ✅ Hoặc từ **GitHub Releases**

### **2. Nếu Không Có Model Files**

Bạn có thể **train lại**:

```bash
# Train ResNet50
python backend/scripts/train_model.py \
    --model resnet50 \
    --config 10classes \
    --epochs 50 \
    --batch-size 32

# Thời gian: ~2-4 giờ (CPU) hoặc ~30 phút (GPU)
```

**Lưu ý:**
- ⚠️ Cần dataset đầy đủ (`dataset_10classes/`)
- ⚠️ Kết quả có thể khác một chút (do random seed)
- ⚠️ Mất thời gian training

### **3. Dataset**

**Dataset KHÔNG được commit vào git:**
- Quá lớn (hàng GB)
- Có thể download từ nguồn khác

**Nếu cần dataset:**
- Xem `backend/docs/DATASET_SOURCES.md` để biết nguồn download
- Hoặc liên hệ maintainer

---

## 📁 Cấu Trúc Files

```
repo/
├── backend/
│   ├── models/
│   │   ├── label_map_10classes.json  ✅ (có trong git)
│   │   ├── resnet50_best.pth         ⚠️  (cần download)
│   │   └── ...
│   ├── scripts/
│   │   ├── train_model.py            ✅
│   │   ├── inference.py              ✅
│   │   └── check_setup.py            ✅
│   └── ...
├── dataset_10classes/                ⚠️  (cần có để train lại)
└── ...
```

**Legend:**
- ✅ Có trong git
- ⚠️ Cần download hoặc tạo

---

## 🛠️ Troubleshooting

### **Lỗi: Model file not found**

```bash
# Kiểm tra
ls backend/models/*.pth

# Nếu không có, download hoặc train lại
```

### **Lỗi: Module not found**

```bash
# Cài đặt dependencies
pip install -r backend/requirements.txt
pip install -r backend/requirements_training.txt
```

### **Lỗi: Dataset not found**

```bash
# Nếu chỉ cần inference, không cần dataset
# Nếu cần train, xem backend/docs/DATASET_SOURCES.md
```

---

## 📚 Tài Liệu Tham Khảo

- `backend/docs/SETUP_FOR_OTHERS.md` - Hướng dẫn chi tiết
- `backend/docs/HOW_IT_WORKS.md` - Cách thức hoạt động
- `backend/docs/TRAINING_10CLASSES.md` - Hướng dẫn training

---

## 💡 Tóm Tắt

**Câu trả lời:**
- ❌ **KHÔNG cần train lại** nếu có model files
- ✅ **Chỉ cần download** model files
- ✅ **Có thể train lại** nếu muốn hoặc không có models

**Các bước:**
1. Clone repo
2. Download models (Git LFS hoặc manual)
3. Install dependencies
4. Run application

