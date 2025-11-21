# 🚀 Hướng dẫn Train Model trên Google Colab

## 📋 Chuẩn bị

### 1. Chuẩn bị Dataset
- Dataset phải có cấu trúc:
  ```
  dataset/
  ├── train/
  │   ├── disease1/
  │   ├── disease2/
  │   └── ...
  ├── val/
  │   ├── disease1/
  │   ├── disease2/
  │   └── ...
  └── test/
      ├── disease1/
      ├── disease2/
      └── ...
  ```

- Nén dataset thành file `.zip`:
  ```bash
  # Trên Windows (PowerShell)
  Compress-Archive -Path dataset -DestinationPath dataset.zip
  
  # Trên Linux/Mac
  zip -r dataset.zip dataset/
  ```

### 2. Chuẩn bị Files
- `train_model.py` - Script training
- `label_map_from_dataset.json` - Label map từ dataset

## 🎯 Các bước thực hiện

### Bước 1: Mở Google Colab
1. Truy cập: https://colab.research.google.com/
2. Tạo notebook mới: `File > New notebook`
3. Đổi tên notebook: `Skin Disease Training`

### Bước 2: Upload Notebook
1. Upload file `train_on_colab.ipynb` vào Colab
2. Hoặc copy nội dung từ file và tạo notebook mới

### Bước 3: Bật GPU
1. `Runtime > Change runtime type`
2. Chọn `GPU` (T4 hoặc V100 nếu có)
3. Click `Save`

### Bước 4: Chạy các Cell

#### Cell 1: Cài đặt Dependencies
```python
!pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118
!pip install timm tqdm pillow
```

#### Cell 2: Mount Google Drive (Nếu dataset ở Drive)
```python
from google.colab import drive
drive.mount('/content/drive')
```

#### Cell 3: Upload Dataset
- **Cách 1**: Upload trực tiếp vào Colab
  - Chạy cell upload
  - Chọn file `dataset.zip`
  - Đợi upload và giải nén xong

- **Cách 2**: Từ Google Drive
  - Upload `dataset.zip` lên Drive
  - Mount Drive và giải nén:
    ```python
    !unzip /content/drive/MyDrive/dataset.zip -d /content/
    ```

#### Cell 4: Upload Scripts
- Upload `train_model.py` và `label_map_from_dataset.json`
- Hoặc clone từ GitHub nếu có:
  ```python
  !git clone https://github.com/your-repo/skin-disease-app.git
  ```

#### Cell 5: Kiểm tra GPU và Dataset
- Chạy cell để kiểm tra GPU và cấu trúc dataset

#### Cell 6: Cấu hình Training
- Thay đổi các tham số:
  - `MODEL_NAME`: Chọn model (resnet50, efficientnet_b0-b7, vit, etc.)
  - `NUM_EPOCHS`: Số epoch (khuyến nghị: 50-100)
  - `BATCH_SIZE`: Batch size (32 cho T4, 16 cho GPU nhỏ hơn)
  - `LEARNING_RATE`: Learning rate (0.001 mặc định)

#### Cell 7: Chạy Training
- Chạy cell này để bắt đầu training
- Quá trình có thể mất vài giờ tùy vào dataset size

#### Cell 8: Download Model
- Sau khi training xong, download model về máy

#### Cell 9: (Tùy chọn) Lưu lên Drive
- Lưu model lên Google Drive để backup

## ⚙️ Cấu hình nâng cao

### Tối ưu cho GPU nhỏ
```python
BATCH_SIZE = 16  # Giảm batch size
IMAGE_SIZE = 224  # Giữ nguyên hoặc giảm xuống 192
```

### Tối ưu cho GPU lớn (V100, A100)
```python
BATCH_SIZE = 64  # Tăng batch size
IMAGE_SIZE = 384  # Tăng image size cho độ chính xác cao hơn
```

### Resume Training
```python
# Nếu muốn tiếp tục từ checkpoint
train(
    model_name=MODEL_NAME,
    resume_from='backend/models/resnet50_epoch_30.pth',
    config_name=CONFIG_NAME
)
```

## 📊 Monitoring Training

### Xem Training History
```python
import json
import matplotlib.pyplot as plt

# Load history
with open('backend/models/resnet50_history.json', 'r') as f:
    history = json.load(f)

# Plot
plt.figure(figsize=(12, 4))
plt.subplot(1, 2, 1)
plt.plot(history['train_loss'], label='Train Loss')
plt.plot(history['val_loss'], label='Val Loss')
plt.legend()
plt.title('Loss')

plt.subplot(1, 2, 2)
plt.plot(history['train_acc'], label='Train Acc')
plt.plot(history['val_acc'], label='Val Acc')
plt.legend()
plt.title('Accuracy')
plt.show()
```

## 🐛 Troubleshooting

### Lỗi: Out of Memory
- Giảm `BATCH_SIZE` xuống 16, 8, hoặc 4
- Giảm `IMAGE_SIZE` xuống 192 hoặc 160
- Sử dụng gradient accumulation

### Lỗi: Dataset not found
- Kiểm tra đường dẫn `DATASET_ROOT`
- Đảm bảo dataset đã được giải nén đúng cách
- Kiểm tra cấu trúc thư mục

### Lỗi: Label map not found
- Upload `label_map_from_dataset.json` vào `backend/models/`
- Hoặc tạo mới bằng script `generate_label_map_from_dataset.py`

### Training quá chậm
- Kiểm tra GPU đã được bật chưa
- Tăng `num_workers` lên 4 hoặc 8
- Sử dụng `pin_memory=True`

## 📝 Notes

- **Thời gian training**: 
  - ResNet50: ~2-4 giờ cho 50 epochs
  - EfficientNet-B6: ~4-6 giờ
  - VIT: ~6-8 giờ

- **GPU Runtime**: Colab free có giới hạn ~12 giờ, sau đó sẽ disconnect
  - Lưu checkpoint thường xuyên
  - Sử dụng Google Drive để backup

- **Best Practices**:
  - Bắt đầu với ResNet50 (nhanh, ổn định)
  - Sau đó thử EfficientNet-B4 hoặc B6 (độ chính xác cao hơn)
  - VIT cho dataset lớn và muốn độ chính xác cao nhất

## 🔗 Links hữu ích

- [PyTorch Documentation](https://pytorch.org/docs/)
- [Timm Models](https://github.com/rwightman/pytorch-image-models)
- [Google Colab FAQ](https://research.google.com/colaboratory/faq.html)

