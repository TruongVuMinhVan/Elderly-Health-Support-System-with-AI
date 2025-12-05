# 📚 Hướng Dẫn Chi Tiết: Cơ Chế Dự Đoán và Training Mô Hình

## 🎯 Tổng Quan

Hệ thống sử dụng **Deep Learning** (Học sâu) để phân loại bệnh da liễu từ hình ảnh. Mô hình được train trên dataset ảnh bệnh da và có thể dự đoán loại bệnh khi người dùng upload ảnh.

---

## 🏗️ Kiến Trúc Mô Hình

### 1. **Mô Hình Chính: ResNet-50**

Hệ thống hiện tại sử dụng **ResNet-50** (Residual Network 50 layers) - một kiến trúc CNN (Convolutional Neural Network) rất phổ biến và hiệu quả.

#### **Tại sao ResNet-50?**
- ✅ **Đã được pre-trained** trên ImageNet (1.4 triệu ảnh, 1000 classes)
- ✅ **Transfer Learning**: Tận dụng kiến thức đã học, chỉ cần fine-tune cho bệnh da
- ✅ **Cân bằng tốt** giữa độ chính xác và tốc độ
- ✅ **Kiến trúc Residual**: Giúp train mô hình sâu hơn mà không bị vanishing gradient

#### **Cấu Trúc Mô Hình:**

```
ResNet-50 Backbone (Pre-trained)
    ↓
    [Feature Extraction Layers]
    ↓
Custom Classifier Head:
    - Linear(2048 → 512)      # Giảm chiều từ 2048 xuống 512
    - ReLU Activation
    - Dropout(0.8)            # Giảm overfitting
    - Linear(512 → num_classes)  # Output: số lượng bệnh (11 classes)
```

**Giải thích:**
- **Backbone**: Phần feature extraction (trích xuất đặc trưng) từ ResNet-50, đã được train trên ImageNet
- **Classifier Head**: Phần tùy chỉnh để phân loại bệnh da, được train từ đầu

### 2. **Các Mô Hình Khác Được Hỗ Trợ**

Hệ thống cũng hỗ trợ các mô hình khác (có thể train):

- **EfficientNet-B0 đến B7**: Hiệu quả hơn về tham số, độ chính xác cao hơn
- **Vision Transformer (ViT)**: Kiến trúc Transformer cho ảnh, độ chính xác rất cao nhưng chậm hơn

---

## 🔄 Cơ Chế Hoạt Động của Prediction

### **Luồng Dữ Liệu Khi Dự Đoán:**

```
1. User upload ảnh
   ↓
2. Backend nhận ảnh (API endpoint)
   ↓
3. Preprocessing ảnh:
   - Resize về 224x224 pixels
   - Convert sang RGB
   - Normalize (chuẩn hóa) theo ImageNet stats
   - Chuyển thành Tensor
   ↓
4. Load mô hình (nếu chưa load):
   - Tạo ResNet-50 architecture
   - Load weights từ file .pth
   - Chuyển sang evaluation mode
   ↓
5. Forward pass (dự đoán):
   - Đưa ảnh qua mô hình
   - Mô hình trả về logits (scores cho mỗi class)
   - Áp dụng Softmax để chuyển thành probabilities
   ↓
6. Xử lý kết quả:
   - Lấy class có probability cao nhất
   - Tính confidence (độ tin cậy)
   - Lấy top 3 predictions
   ↓
7. Map với database:
   - Tìm bệnh tương ứng trong database
   - Lấy thông tin chi tiết (triệu chứng, điều trị...)
   ↓
8. Trả về kết quả cho user
```

### **Chi Tiết Code Prediction:**

#### **File: `backend/ml/predictor.py`**

```python
class SkinDiseasePredictor:
    def predict(self, image_input, top_k=3, confidence_threshold=0.6):
        # 1. Preprocess ảnh
        image_tensor = self.preprocess_image(image_input)
        
        # 2. Dự đoán (không tính gradient)
        with torch.no_grad():
            outputs = self.model(image_tensor)  # Logits
            probs = torch.softmax(outputs, dim=1)  # Probabilities
            confidence, predicted_idx = torch.max(probs, 1)
        
        # 3. Map index → tên bệnh
        predicted_disease = self.idx_to_label[predicted_idx.item()]
        
        # 4. Lấy top k predictions
        top_predictions = [...]
        
        return {
            "predicted_disease": predicted_disease,
            "confidence": confidence,
            "top_predictions": top_predictions
        }
```

#### **Preprocessing Chi Tiết:**

```python
transform = transforms.Compose([
    transforms.Resize((224, 224)),  # Resize về kích thước chuẩn
    transforms.ToTensor(),          # Chuyển PIL Image → Tensor [0,1]
    transforms.Normalize(
        mean=[0.485, 0.456, 0.406],  # ImageNet mean
        std=[0.229, 0.224, 0.225]    # ImageNet std
    )
])
```

**Tại sao normalize?**
- Mô hình được train với ảnh đã normalize theo ImageNet stats
- Để dự đoán chính xác, ảnh input cũng phải normalize tương tự

---

## 🎓 Cách Train Mô Hình

### **1. Chuẩn Bị Dataset**

#### **Cấu Trúc Thư Mục:**

```
dataset/
├── train/
│   ├── basal_cell_carcinoma/
│   │   ├── image1.jpg
│   │   ├── image2.jpg
│   │   └── ...
│   ├── melanoma/
│   │   ├── image1.jpg
│   │   └── ...
│   └── ... (các bệnh khác)
├── val/
│   ├── basal_cell_carcinoma/
│   └── ...
└── test/
    ├── basal_cell_carcinoma/
    └── ...
```

**Lưu ý:**
- Mỗi thư mục con = 1 class (bệnh)
- Tên thư mục phải khớp với tên trong `label_map.json`
- Tỷ lệ train/val/test thường là 70/15/15 hoặc 80/10/10

#### **Label Map File:**

File `backend/models/label_map_from_dataset.json` chứa mapping:

```json
{
  "num_classes": 11,
  "label_to_idx": {
    "basal_cell_carcinoma": 0,
    "melanoma": 1,
    ...
  },
  "idx_to_label": {
    "0": "basal_cell_carcinoma",
    "1": "melanoma",
    ...
  }
}
```

### **2. Quá Trình Training**

#### **File: `backend/scripts/train_model.py`**

#### **A. Khởi Tạo Mô Hình:**

```python
def create_model(model_name="resnet50", num_classes=11, pretrained=True):
    # Load ResNet-50 pre-trained trên ImageNet
    model = resnet50(weights=ResNet50_Weights.IMAGENET1K_V2)
    
    # Thay thế classifier head
    model.fc = nn.Sequential(
        nn.Linear(2048, 512),      # 2048 features → 512
        nn.ReLU(),
        nn.Dropout(0.8),           # Giảm overfitting
        nn.Linear(512, num_classes) # 512 → số classes
    )
    
    return model
```

**Giải thích:**
- `pretrained=True`: Sử dụng weights đã train trên ImageNet
- Chỉ train lại phần `fc` (fully connected layers), giữ nguyên backbone

#### **B. Data Augmentation (Tăng Cường Dữ Liệu):**

```python
train_transform = transforms.Compose([
    transforms.Resize((224, 224)),
    transforms.RandomHorizontalFlip(p=0.5),      # Lật ngang 50%
    transforms.RandomRotation(30),                # Xoay ±30 độ
    transforms.ColorJitter(                       # Thay đổi màu sắc
        brightness=0.3, contrast=0.3, 
        saturation=0.3, hue=0.15
    ),
    transforms.RandomAffine(                      # Biến đổi affine
        degrees=0, translate=(0.15, 0.15)
    ),
    transforms.ToTensor(),
    transforms.Normalize(mean=[...], std=[...])
])
```

**Tại sao cần augmentation?**
- ✅ Tăng số lượng ảnh training (ảo)
- ✅ Giảm overfitting (mô hình không học thuộc lòng)
- ✅ Tăng khả năng generalize (tổng quát hóa)

#### **C. Training Loop:**

```python
for epoch in range(num_epochs):
    # 1. Training phase
    model.train()  # Bật training mode
    for images, labels in train_loader:
        # Forward pass
        outputs = model(images)
        loss = criterion(outputs, labels)
        
        # Backward pass
        optimizer.zero_grad()
        loss.backward()  # Tính gradients
        optimizer.step()  # Cập nhật weights
    
    # 2. Validation phase
    model.eval()  # Bật evaluation mode
    with torch.no_grad():
        for images, labels in val_loader:
            outputs = model(images)
            # Tính accuracy, loss...
    
    # 3. Save best model
    if val_acc > best_val_acc:
        save_model(model)
```

**Giải thích:**
- **Forward pass**: Đưa ảnh qua mô hình, tính loss
- **Backward pass**: Tính gradients, cập nhật weights
- **Validation**: Kiểm tra độ chính xác trên tập validation (không train)

#### **D. Loss Function & Optimizer:**

```python
# Loss: Cross Entropy (phù hợp cho classification)
criterion = nn.CrossEntropyLoss()

# Optimizer: Adam (adaptive learning rate)
optimizer = optim.Adam(
    model.parameters(),
    lr=0.001,           # Learning rate
    weight_decay=1e-4   # L2 regularization
)

# Learning Rate Scheduler: Giảm LR khi không cải thiện
scheduler = optim.lr_scheduler.ReduceLROnPlateau(
    optimizer, mode='max', factor=0.5, patience=5
)
```

**Giải thích:**
- **Cross Entropy Loss**: Đo khoảng cách giữa prediction và ground truth
- **Adam Optimizer**: Tự động điều chỉnh learning rate cho từng parameter
- **Scheduler**: Giảm learning rate khi validation accuracy không cải thiện

#### **E. Early Stopping:**

```python
patience = 15  # Đợi 15 epochs không cải thiện
patience_counter = 0

if val_acc > best_val_acc:
    best_val_acc = val_acc
    patience_counter = 0
    save_model(model)
else:
    patience_counter += 1
    if patience_counter >= patience:
        print("Early stopping!")
        break
```

**Tại sao cần early stopping?**
- Tránh overfitting (học quá kỹ trên training set)
- Tiết kiệm thời gian training

### **3. Các Kỹ Thuật Nâng Cao**

#### **A. Dropout (0.8):**
- Tắt ngẫu nhiên 80% neurons trong quá trình training
- Giảm overfitting mạnh

#### **B. Freeze Backbone:**
```python
# Freeze backbone trong N epochs đầu
for param in model.backbone.parameters():
    param.requires_grad = False

# Sau đó unfreeze để fine-tune toàn bộ
```

#### **C. Gradient Accumulation:**
```python
# Tích lũy gradients qua nhiều batches
# Giảm memory usage, tăng effective batch size
loss = loss / accumulation_steps
loss.backward()
if (batch_idx + 1) % accumulation_steps == 0:
    optimizer.step()
```

#### **D. Mixup/CutMix:**
- Trộn 2 ảnh với nhau để tạo ảnh mới
- Tăng tính đa dạng của dữ liệu

---

## 📊 Các Tham Số Training Quan Trọng

### **Hyperparameters Mặc Định:**

```python
CONFIG = {
    "batch_size": 32,           # Số ảnh mỗi batch
    "num_epochs": 50,           # Số epochs
    "learning_rate": 0.001,     # Learning rate ban đầu
    "image_size": 224,          # Kích thước ảnh input
    "dropout_rate": 0.8,        # Dropout rate
    "weight_decay": 1e-4,       # L2 regularization
    "early_stopping_patience": 15  # Early stopping
}
```

### **Cách Điều Chỉnh:**

1. **Tăng accuracy:**
   - Tăng `num_epochs`
   - Giảm `learning_rate` (0.0001)
   - Tăng `batch_size` (nếu có GPU)
   - Sử dụng mô hình lớn hơn (EfficientNet-B6, ViT)

2. **Giảm overfitting:**
   - Tăng `dropout_rate` (0.9)
   - Tăng `weight_decay` (1e-3)
   - Tăng data augmentation
   - Giảm số lượng parameters

3. **Tăng tốc độ:**
   - Giảm `batch_size`
   - Giảm `image_size` (180 thay vì 224)
   - Sử dụng mô hình nhỏ hơn (ResNet-50, EfficientNet-B0)

---

## 🚀 Cách Chạy Training

### **1. Training Cơ Bản:**

```bash
cd backend/scripts
python train_model.py --model resnet50 --config from_dataset
```

### **2. Training Với Tùy Chọn:**

```bash
python train_model.py \
    --model resnet50 \
    --config from_dataset \
    --epochs 50 \
    --batch-size 32 \
    --learning-rate 0.001 \
    --dropout 0.8 \
    --early-stopping 15
```

### **3. Resume Training (Tiếp Tục Từ Checkpoint):**

```bash
python train_model.py \
    --model resnet50 \
    --config from_dataset \
    --resume backend/models/checkpoints/resnet50_checkpoint_epoch_20.pth
```

### **4. Training Trên Google Colab:**

Xem file `doc/COLAB_TRAINING_GUIDE.md` để biết cách setup và train trên Colab với GPU miễn phí. Colab cung cấp GPU Tesla T4/V100 miễn phí, giúp training nhanh hơn CPU 5-10 lần (20-30 phút thay vì 2-4 giờ).

---

## 📁 Cấu Trúc Files Quan Trọng

```
backend/
├── ml/
│   └── predictor.py              # Class dự đoán
├── scripts/
│   └── train_model.py            # Script training
├── models/
│   ├── resnet50_best.pth         # Model weights (đã train)
│   ├── label_map_from_dataset.json  # Mapping classes
│   └── checkpoints/              # Checkpoints khi training
└── routers/
    └── skin_disease.py           # API endpoints

dataset/                          # Dataset (không có trong git)
├── train/
├── val/
└── test/
```

---

## 🔍 Kiểm Tra Kết Quả Training

### **1. Training History:**

File `backend/models/resnet50_history.json` chứa:
```json
{
  "train_loss": [0.5, 0.4, 0.3, ...],
  "train_acc": [60, 70, 80, ...],
  "val_loss": [0.6, 0.5, 0.4, ...],
  "val_acc": [55, 65, 75, ...]
}
```

### **2. Best Model:**

- File `resnet50_best.pth`: Model có validation accuracy cao nhất
- Được sử dụng cho prediction

### **3. Checkpoints:**

- Lưu mỗi 5 epochs: `resnet50_checkpoint_epoch_X.pth`
- Chứa đầy đủ: model, optimizer, scheduler, history

---

## ❓ FAQ

### **Q: Tại sao dùng Transfer Learning?**
A: Vì dataset bệnh da thường nhỏ (hàng nghìn ảnh), không đủ để train từ đầu. Transfer Learning tận dụng kiến thức từ ImageNet (1.4M ảnh) và chỉ fine-tune cho bệnh da.

### **Q: Tại sao Dropout 0.8 cao vậy?**
A: Để giảm overfitting mạnh khi dataset nhỏ. 0.8 có nghĩa là tắt 80% neurons ngẫu nhiên trong training.

### **Q: Có thể train trên CPU không?**
A: Có, nhưng rất chậm (2-4 giờ cho 50 epochs). Nên dùng GPU (30 phút) hoặc Google Colab.

### **Q: Làm sao biết model đã train tốt?**
A: Kiểm tra:
- Validation accuracy > 80% (tốt)
- Gap giữa train_acc và val_acc < 10% (không overfit)
- Loss giảm đều và hội tụ

### **Q: Model dự đoán sai, làm sao cải thiện?**
A:
1. Thêm dữ liệu training (quan trọng nhất)
2. Tăng data augmentation
3. Tăng dropout/weight_decay
4. Train lâu hơn (nhiều epochs)
5. Thử mô hình lớn hơn (EfficientNet-B6, ViT)

---

## 📚 Tài Liệu Tham Khảo

- **ResNet Paper**: [Deep Residual Learning for Image Recognition](https://arxiv.org/abs/1512.03385)
- **Transfer Learning**: [A Survey on Transfer Learning](https://ieeexplore.ieee.org/document/5288526)
- **PyTorch Tutorials**: https://pytorch.org/tutorials/

---

**Tác giả**: Hệ thống Sức Khỏe  
**Cập nhật**: 2024

