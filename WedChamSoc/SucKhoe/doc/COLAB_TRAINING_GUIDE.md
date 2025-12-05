# 🚀 Hướng Dẫn Training Trên Google Colab

## 📚 Google Colab là gì?

**Google Colab** (Colaboratory) là một môi trường Jupyter Notebook miễn phí chạy trên cloud của Google, cung cấp:
- ✅ **GPU miễn phí** (Tesla T4, V100) - Nhanh hơn CPU hàng trăm lần
- ✅ **RAM miễn phí** (12-15GB)
- ✅ **Không cần cài đặt** - Chạy trên trình duyệt
- ✅ **Lưu trữ trên Google Drive** - Dễ dàng lưu models và datasets

---

## 🎯 Tại sao dùng Colab?

### **So sánh tốc độ:**

| Môi trường | Thời gian train (50 epochs) | Chi phí |
|------------|----------------------------|---------|
| **CPU (laptop)** | 2-4 giờ | Miễn phí |
| **GPU (Colab)** | 20-30 phút | Miễn phí |
| **GPU (local)** | 20-30 phút | Cần GPU (đắt) |

→ **Colab nhanh hơn CPU 5-10 lần!**

---

## 📋 Các Bước Setup Colab

### **Bước 1: Tạo Notebook mới**

1. Truy cập: https://colab.research.google.com/
2. Click **"New Notebook"**
3. Đổi tên notebook: `Skin Disease Training`

### **Bước 2: Kích hoạt GPU**

1. Menu: **Runtime** → **Change runtime type**
2. **Hardware accelerator**: Chọn **GPU** (T4 hoặc V100)
3. Click **Save**

### **Bước 3: Mount Google Drive**

```python
# CELL 1: Mount Google Drive
from google.colab import drive
drive.mount('/content/drive')

# Sau khi chạy, click link để authorize
# Copy mã xác thực và paste vào ô input
```

**Giải thích:**
- Mount Drive để truy cập dataset và lưu models
- Drive sẽ được mount tại `/content/drive/MyDrive/`

---

## 💻 Code Setup Chi Tiết

### **CELL 2: Cài đặt Dependencies**

```python
# Cài đặt các thư viện cần thiết
!pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118
!pip install timm
!pip install pillow
!pip install tqdm

# Kiểm tra GPU
import torch
print(f"CUDA available: {torch.cuda.is_available()}")
print(f"GPU: {torch.cuda.get_device_name(0)}")
print(f"CUDA version: {torch.version.cuda}")
```

**Giải thích:**
- `!pip install`: Chạy lệnh shell trong notebook
- `--index-url`: Cài PyTorch với CUDA 11.8 (hỗ trợ GPU)
- Kiểm tra GPU để đảm bảo đã kích hoạt

**Output mong đợi:**
```
CUDA available: True
GPU: Tesla T4
CUDA version: 11.8
```

---

### **CELL 3: Setup Project Structure**

```python
import os
from pathlib import Path

# Đường dẫn project trên Drive
DRIVE_PATH = '/content/drive/MyDrive/STUDY/DACN/App/DoAnCN/WedChamSoc/SucKhoe'

# Hoặc nếu project ở vị trí khác, thay đổi đường dẫn
# DRIVE_PATH = '/content/drive/MyDrive/your-project-path'

# Tạo symlink để dễ truy cập
PROJECT_ROOT = Path('/content/project')
if not PROJECT_ROOT.exists():
    !ln -s {DRIVE_PATH} {PROJECT_ROOT}

# Chuyển vào thư mục project
os.chdir(PROJECT_ROOT)
print(f"Current directory: {os.getcwd()}")
```

**Giải thích:**
- Tạo symlink từ Drive sang `/content/project` để dễ truy cập
- `os.chdir()`: Chuyển working directory

---

### **CELL 4: Upload Dataset (Nếu chưa có trên Drive)**

**Option A: Upload từ máy tính**

```python
# Upload dataset.zip
from google.colab import files
uploaded = files.upload()

# Giải nén
import zipfile
with zipfile.ZipFile('dataset.zip', 'r') as zip_ref:
    zip_ref.extractall('/content/drive/MyDrive/datasets/')
```

**Option B: Copy từ Drive (Nếu đã có)**

```python
# Dataset đã có trên Drive
DATASET_PATH = '/content/drive/MyDrive/datasets/skin_disease_dataset'

# Kiểm tra cấu trúc
import os
if os.path.exists(DATASET_PATH):
    print("✅ Dataset found!")
    print(f"Train classes: {len(os.listdir(f'{DATASET_PATH}/train'))}")
else:
    print("❌ Dataset not found. Please upload first.")
```

---

### **CELL 5: Import Training Script**

```python
# Import training functions từ local script
import sys
sys.path.append('/content/project/backend/scripts')

# Import các modules cần thiết
from train_model import (
    create_model,
    train,
    SkinDiseaseDataset,
    get_data_transforms,
    CONFIGS
)

print("✅ Training modules imported successfully!")
```

**Giải thích:**
- Import functions từ `train_model.py` của project
- Có thể sửa code trực tiếp trong notebook hoặc import từ file

---

### **CELL 6: Kiểm tra Dataset**

```python
# Kiểm tra dataset structure
dataset_root = '/content/drive/MyDrive/datasets/skin_disease_dataset'
# Hoặc: dataset_root = '/content/project/dataset'

import os
from pathlib import Path

train_dir = Path(dataset_root) / 'train'
val_dir = Path(dataset_root) / 'val'

if train_dir.exists():
    classes = [d.name for d in train_dir.iterdir() if d.is_dir()]
    print(f"✅ Found {len(classes)} classes in training set:")
    for cls in classes[:5]:  # Hiển thị 5 classes đầu
        count = len(list((train_dir / cls).iterdir()))
        print(f"   - {cls}: {count} images")
else:
    print("❌ Training directory not found!")
```

**Output mong đợi:**
```
✅ Found 11 classes in training set:
   - basal_cell_carcinoma: 150 images
   - melanoma: 200 images
   - eczema: 180 images
   ...
```

---

### **CELL 7: Training Configuration**

```python
# Cấu hình training
TRAINING_CONFIG = {
    "model_name": "resnet50",           # ResNet-50
    "config_name": "from_dataset",      # Sử dụng config từ dataset
    "batch_size": 32,                   # Batch size (có thể tăng nếu GPU đủ RAM)
    "num_epochs": 50,                   # Số epochs
    "learning_rate": 0.001,             # Learning rate
    "dropout_rate": 0.8,                # Dropout rate
    "early_stopping_patience": 15,      # Early stopping
    "dataset_root": "/content/drive/MyDrive/datasets/skin_disease_dataset",
    "save_dir": "/content/drive/MyDrive/models",  # Lưu models trên Drive
}

print("Training Configuration:")
for key, value in TRAINING_CONFIG.items():
    print(f"   {key}: {value}")
```

**Giải thích:**
- `batch_size`: Có thể tăng lên 64 nếu GPU có đủ RAM (T4: 16GB)
- `save_dir`: Lưu trên Drive để không mất khi disconnect

---

### **CELL 8: Bắt đầu Training**

```python
# Bắt đầu training
print("🚀 Starting training...")
print("=" * 80)

model, history = train(
    model_name=TRAINING_CONFIG["model_name"],
    config_name=TRAINING_CONFIG["config_name"],
    verbose=True,                      # Hiển thị progress
    dropout_rate=TRAINING_CONFIG["dropout_rate"],
    early_stopping_patience=TRAINING_CONFIG["early_stopping_patience"],
)

print("=" * 80)
print("✅ Training completed!")
```

**Giải thích:**
- Hàm `train()` sẽ tự động:
  - Load dataset
  - Tạo model
  - Train và validate
  - Lưu best model và checkpoints

**Output trong quá trình training:**
```
🚀 TRAINING SKIN DISEASE CLASSIFICATION MODEL
   Model: RESNET50
   Config: from_dataset
================================================================================
📊 Number of classes: 11
📁 Dataset: /content/drive/MyDrive/datasets/skin_disease_dataset
📄 Label map: backend/models/label_map_from_dataset.json

📦 DataLoader created:
   Train batches: 45
   Val batches: 12
   Batch size: 32

📅 Epoch 1/50
Epoch 1 [Train]: 100%|████████| 45/45 [02:15<00:00, loss=1.234, acc=45.2%]
Epoch 1 [Val]: 100%|████████| 12/12 [00:15<00:00, loss=0.987, acc=52.3%]
   Train Loss: 1.234, Train Acc: 45.2%
   Val Loss: 0.987, Val Acc: 52.3%
   Learning Rate: 0.001000
   GPU: 2.5GB allocated, 3.2GB reserved

💾 Saved best model (val acc: 52.3%) to /content/drive/MyDrive/models/resnet50_best.pth
...
```

---

### **CELL 9: Kiểm tra Kết Quả**

```python
# Load training history
import json

history_path = f'/content/drive/MyDrive/models/{TRAINING_CONFIG["model_name"]}_history.json'
if os.path.exists(history_path):
    with open(history_path, 'r') as f:
        history = json.load(f)
    
    print("📊 Training Results:")
    print(f"   Best validation accuracy: {max(history['val_acc']):.2f}%")
    print(f"   Final train accuracy: {history['train_acc'][-1]:.2f}%")
    print(f"   Final validation accuracy: {history['val_acc'][-1]:.2f}%")
    print(f"   Total epochs: {len(history['train_acc'])}")
else:
    print("❌ History file not found")
```

---

### **CELL 10: Download Model (Tùy chọn)**

```python
# Download model về máy tính
from google.colab import files

model_path = f'/content/drive/MyDrive/models/{TRAINING_CONFIG["model_name"]}_best.pth'
if os.path.exists(model_path):
    files.download(model_path)
    print("✅ Model downloaded!")
else:
    print("❌ Model file not found")
```

---

## 🔧 Tối Ưu Hóa Cho Colab

### **1. Tăng Batch Size (Nếu GPU đủ RAM)**

```python
# T4 GPU có 16GB RAM, có thể tăng batch_size
TRAINING_CONFIG["batch_size"] = 64  # Tăng từ 32 lên 64
```

### **2. Sử dụng Mixed Precision (Nhanh hơn 2x)**

```python
from torch.cuda.amp import autocast, GradScaler

scaler = GradScaler()

# Trong training loop:
with autocast():
    outputs = model(images)
    loss = criterion(outputs, labels)

scaler.scale(loss).backward()
scaler.step(optimizer)
scaler.update()
```

### **3. Tăng số workers cho DataLoader**

```python
# Colab có nhiều CPU cores, tăng num_workers
train_loader = DataLoader(
    train_dataset,
    batch_size=32,
    num_workers=4,  # Tăng từ 0 lên 4
    pin_memory=True,  # Nhanh hơn khi dùng GPU
)
```

---

## ⚠️ Lưu Ý Quan Trọng

### **1. Session Timeout**

- Colab free: **12 giờ** timeout
- Colab Pro: **24 giờ** timeout
- **Giải pháp**: Lưu checkpoints thường xuyên (mỗi 5 epochs)

### **2. RAM Limit**

- Colab free: **12-15GB RAM**
- Nếu hết RAM: Giảm `batch_size` hoặc `image_size`

### **3. GPU Limit**

- Colab free: **Giới hạn sử dụng GPU** (có thể bị disconnect)
- Colab Pro: Ưu tiên hơn, ít bị disconnect

### **4. Lưu Trữ**

- **Luôn lưu trên Drive**, không lưu trên `/content/` (sẽ mất khi disconnect)
- Models, checkpoints, logs → Lưu trên Drive

---

## 📊 Monitoring Training

### **Xem GPU Usage**

```python
# CELL: Monitor GPU
!nvidia-smi
```

### **Xem Training Progress**

```python
# Plot training curves
import matplotlib.pyplot as plt

history_path = f'/content/drive/MyDrive/models/{TRAINING_CONFIG["model_name"]}_history.json'
with open(history_path, 'r') as f:
    history = json.load(f)

plt.figure(figsize=(12, 4))

plt.subplot(1, 2, 1)
plt.plot(history['train_loss'], label='Train Loss')
plt.plot(history['val_loss'], label='Val Loss')
plt.xlabel('Epoch')
plt.ylabel('Loss')
plt.legend()
plt.title('Training and Validation Loss')

plt.subplot(1, 2, 2)
plt.plot(history['train_acc'], label='Train Acc')
plt.plot(history['val_acc'], label='Val Acc')
plt.xlabel('Epoch')
plt.ylabel('Accuracy (%)')
plt.legend()
plt.title('Training and Validation Accuracy')

plt.tight_layout()
plt.show()
```

---

## 🎯 Workflow Hoàn Chỉnh

```
1. Mở Colab → Kích hoạt GPU
   ↓
2. Mount Drive
   ↓
3. Cài dependencies
   ↓
4. Setup project structure
   ↓
5. Upload/Check dataset
   ↓
6. Import training script
   ↓
7. Cấu hình training
   ↓
8. Bắt đầu training
   ↓
9. Monitor progress
   ↓
10. Download model (nếu cần)
```

---

## 📝 Template Notebook Hoàn Chỉnh

Tạo file `colab_training.ipynb` với tất cả các cells trên, hoặc copy từng cell vào Colab notebook.

---

## ❓ FAQ

### **Q: Colab bị disconnect, mất hết progress?**
A: 
- Luôn lưu checkpoints trên Drive (mỗi 5 epochs)
- Resume từ checkpoint: `--resume /path/to/checkpoint.pth`

### **Q: GPU không available?**
A:
- Kiểm tra Runtime type: **Runtime** → **Change runtime type** → **GPU**
- Nếu vẫn không có: Colab free có thể hết quota, thử lại sau

### **Q: Hết RAM?**
A:
- Giảm `batch_size`: 32 → 16
- Giảm `image_size`: 224 → 180
- Restart runtime: **Runtime** → **Restart runtime**

### **Q: Training quá chậm?**
A:
- Kiểm tra GPU đã được kích hoạt: `torch.cuda.is_available()`
- Tăng `batch_size` nếu GPU đủ RAM
- Sử dụng mixed precision

---

**Tác giả**: Hệ thống Sức Khỏe  
**Cập nhật**: 2024

