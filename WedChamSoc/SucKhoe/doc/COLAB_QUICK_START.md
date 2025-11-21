# 🚀 Quick Start: Train trên Google Colab

## Bước 1: Mở Colab và bật GPU
1. Truy cập: https://colab.research.google.com/
2. Tạo notebook mới
3. `Runtime > Change runtime type > GPU > Save`

## Bước 2: Copy và chạy các cell sau

### Cell 1: Cài đặt
```python
!pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118
!pip install timm tqdm pillow
```

### Cell 2: Upload Dataset
```python
from google.colab import files
import zipfile

# Upload dataset.zip
uploaded = files.upload()

# Giải nén
for filename in uploaded.keys():
    if filename.endswith('.zip'):
        print(f'📦 Extracting {filename}...')
        with zipfile.ZipFile(filename, 'r') as zip_ref:
            zip_ref.extractall('.')
        print('✅ Done!')
        break
```

### Cell 3: Upload Scripts
```python
from google.colab import files
import shutil
import os

# Tạo thư mục
os.makedirs('backend/scripts', exist_ok=True)
os.makedirs('backend/models', exist_ok=True)

# Upload train_model.py
print("📤 Upload train_model.py:")
files.upload()

# Upload label_map_from_dataset.json
print("📤 Upload label_map_from_dataset.json:")
files.upload()

# Di chuyển files
for f in os.listdir('.'):
    if 'train_model' in f and f.endswith('.py'):
        shutil.move(f, 'backend/scripts/train_model.py')
    if 'label_map' in f and f.endswith('.json'):
        shutil.move(f, 'backend/models/label_map_from_dataset.json')
```

### Cell 4: Kiểm tra
```python
import torch
from pathlib import Path

print(f"GPU: {torch.cuda.is_available()}")
if torch.cuda.is_available():
    print(f"GPU Name: {torch.cuda.get_device_name(0)}")

# Kiểm tra dataset
dataset_path = Path('dataset')
if dataset_path.exists():
    for split in ['train', 'val', 'test']:
        split_path = dataset_path / split
        if split_path.exists():
            classes = [d.name for d in split_path.iterdir() if d.is_dir()]
            print(f"{split}: {len(classes)} classes")
```

### Cell 5: Cấu hình và Train
```python
import sys
sys.path.append('backend/scripts')

from train_model import train
import train_model as tm

# Cấu hình
MODEL_NAME = "resnet50"  # hoặc efficientnet_b4, vit, etc.
NUM_EPOCHS = 50
BATCH_SIZE = 32

# Update config
tm.CONFIG.update({
    'batch_size': BATCH_SIZE,
    'num_epochs': NUM_EPOCHS,
    'dataset_root': 'dataset',
    'label_map_file': 'backend/models/label_map_from_dataset.json',
    'num_workers': 4,
    'pin_memory': True,
    'use_weighted_loss': True
})

# Train
train(model_name=MODEL_NAME, config_name="from_dataset")
```

### Cell 6: Download Model
```python
from google.colab import files
from pathlib import Path

models = list(Path('backend/models').glob('*best*.pth'))
if models:
    files.download(str(models[0]))
    print(f"✅ Downloaded {models[0].name}")
```

## Tips
- **Batch size**: Giảm xuống 16 nếu hết GPU memory
- **Model**: Bắt đầu với `resnet50` (nhanh), sau đó thử `efficientnet_b4` (chính xác hơn)
- **Epochs**: 50-100 epochs thường đủ
- **Backup**: Lưu checkpoint thường xuyên lên Drive

