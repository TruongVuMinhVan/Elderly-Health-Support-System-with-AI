# 📚 Tài Liệu Training

## 📖 Tài Liệu Chính

### **1. colab_training_setup.py**
- 🚀 Script setup cho Google Colab
- ✅ Tự động kiểm tra dataset
- ✅ Tự động đề xuất cấu hình
- ✅ Tự động sync checkpoint
- ✅ Hỗ trợ ResNet50 và ViT training

---

## 🔧 Scripts Có Sẵn

### **Training:**
- `backend/scripts/train_model.py` - Script training chính
- `doc/colab_training_setup.py` - Script setup cho Google Colab (tự động kiểm tra dataset, sync checkpoint)

### **Dataset Management:**
- `backend/scripts/generate_label_map_from_dataset.py` - Tạo label map từ dataset
- `backend/scripts/cleanup_unused_files.py` - Dọn dẹp các file checkpoint/label map không còn sử dụng

**Lưu ý:** Chức năng kiểm tra dataset đã được tích hợp vào `colab_training_setup.py` (CELL 5.5)

---

## 🚀 Quick Start

### **1. Training trên Google Colab:**
Sử dụng `doc/colab_training_setup.py` - script tự động setup và kiểm tra dataset

### **2. Training trên Local:**
```bash
python backend/scripts/train_model.py \
    --model resnet50 \
    --epochs 100 \
    --batch-size 32 \
    --lr 0.0001 \
    --config from_dataset \
    --cosine-scheduler \
    --weighted-loss \
    --early-stopping 20
```

---

## 📋 Checklist Trước Khi Training

**Tóm tắt:**
- [x] Dataset đã được kiểm tra (tự động trong colab_training_setup.py)
- [x] Dataset đã được tái tổ chức/cân bằng
- [ ] Cấu hình training đã được cập nhật
- [ ] `USE_WEIGHTED_LOSS = True` (nếu có class imbalance - tự động đề xuất)
- [ ] `EARLY_STOPPING_PATIENCE = 20-30`
- [ ] `USE_COSINE_SCHEDULER = True`

---

## 💡 Lưu Ý

- Tất cả scripts đều có `--help` để xem hướng dẫn
- `colab_training_setup.py` tự động kiểm tra và đề xuất cấu hình
- Luôn chạy `cleanup_unused_files.py` với `--execute` sau khi training để dọn dẹp

