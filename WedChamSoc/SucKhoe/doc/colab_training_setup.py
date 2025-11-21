"""
Setup script for Google Colab training
Chạy script này trong Colab để setup môi trường và chạy training
"""

# ============================================
# CELL 1: Cài đặt Dependencies
# ============================================
print("📦 Installing dependencies...")
import subprocess
import sys

def install_packages():
    packages = [
        "torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118",
        "timm",
        "tqdm",
        "pillow"
    ]
    
    for package in packages:
        print(f"Installing {package}...")
        subprocess.check_call([sys.executable, "-m", "pip", "install"] + package.split())

# Uncomment để cài đặt
# install_packages()

# ============================================
# CELL 2: Mount Google Drive (Optional)
# ============================================
def mount_drive():
    from google.colab import drive
    drive.mount('/content/drive')
    print("✅ Google Drive mounted")

# Uncomment nếu dùng Drive
# mount_drive()

# ============================================
# CELL 3: Upload và giải nén Dataset
# ============================================
def upload_dataset():
    from google.colab import files
    import zipfile
    import os
    
    print("📤 Upload dataset.zip file:")
    uploaded = files.upload()
    
    for filename in uploaded.keys():
        if filename.endswith('.zip'):
            print(f'📦 Extracting {filename}...')
            with zipfile.ZipFile(filename, 'r') as zip_ref:
                zip_ref.extractall('.')
            print(f'✅ Extracted to current directory')
            break

# Uncomment để upload
# upload_dataset()

# ============================================
# CELL 4: Upload Training Scripts
# ============================================
def upload_scripts():
    from google.colab import files
    import shutil
    import os
    
    # Tạo thư mục
    os.makedirs('backend/scripts', exist_ok=True)
    os.makedirs('backend/models', exist_ok=True)
    
    print("📤 Upload train_model.py:")
    uploaded_scripts = files.upload()
    
    for filename in uploaded_scripts.keys():
        if 'train_model' in filename:
            shutil.move(filename, f'backend/scripts/{filename}')
            print(f'✅ Moved {filename} to backend/scripts/')
    
    print("\n📤 Upload label_map_from_dataset.json:")
    uploaded_labels = files.upload()
    for filename in uploaded_labels.keys():
        if 'label_map' in filename:
            shutil.move(filename, f'backend/models/{filename}')
            print(f'✅ Moved {filename} to backend/models/')

# Uncomment để upload
# upload_scripts()

# ============================================
# CELL 5: Kiểm tra GPU và Dataset
# ============================================
def check_setup():
    import torch
    import os
    from pathlib import Path
    
    # Kiểm tra GPU
    print(f"🔍 GPU Available: {torch.cuda.is_available()}")
    if torch.cuda.is_available():
        print(f"   GPU Name: {torch.cuda.get_device_name(0)}")
        print(f"   GPU Memory: {torch.cuda.get_device_properties(0).total_memory / 1024**3:.2f} GB")
    
    # Kiểm tra dataset
    DATASET_ROOT = 'dataset'
    
    if os.path.exists(DATASET_ROOT):
        print(f"\n📁 Dataset found at: {DATASET_ROOT}")
        
        for split in ['train', 'val', 'test']:
            split_path = Path(DATASET_ROOT) / split
            if split_path.exists():
                classes = [d for d in split_path.iterdir() if d.is_dir()]
                total_images = sum(len(list(d.glob('*.jpg'))) + len(list(d.glob('*.JPG'))) 
                                 for d in classes)
                print(f"   {split}: {len(classes)} classes, ~{total_images} images")
            else:
                print(f"   ⚠️  {split}: Not found")
    else:
        print(f"\n❌ Dataset not found at: {DATASET_ROOT}")

# Chạy kiểm tra
check_setup()

# ============================================
# CELL 6: Cấu hình Training
# ============================================
# Thay đổi các giá trị này
MODEL_NAME = "resnet50"  # resnet50, efficientnet_b0-b7, vit, vit_small, vit_large
NUM_EPOCHS = 50
BATCH_SIZE = 32  # Giảm xuống nếu hết GPU memory
LEARNING_RATE = 0.001
IMAGE_SIZE = 224
CONFIG_NAME = "from_dataset"
DATASET_ROOT = "dataset"
LABEL_MAP_FILE = "backend/models/label_map_from_dataset.json"

print("⚙️  Training Configuration:")
print(f"   Model: {MODEL_NAME}")
print(f"   Epochs: {NUM_EPOCHS}")
print(f"   Batch Size: {BATCH_SIZE}")
print(f"   Learning Rate: {LEARNING_RATE}")
print(f"   Image Size: {IMAGE_SIZE}")
print(f"   Dataset: {DATASET_ROOT}")
print(f"   Label Map: {LABEL_MAP_FILE}")

# ============================================
# CELL 7: Chạy Training
# ============================================
def run_training():
    import sys
    sys.path.append('backend/scripts')
    
    from train_model import train
    import train_model as tm
    
    # Override config cho Colab
    tm.CONFIG.update({
        'batch_size': BATCH_SIZE,
        'num_epochs': NUM_EPOCHS,
        'learning_rate': LEARNING_RATE,
        'image_size': IMAGE_SIZE,
        'dataset_root': DATASET_ROOT,
        'label_map_file': LABEL_MAP_FILE,
        'num_workers': 4,
        'pin_memory': True,
        'save_dir': 'backend/models',
        'use_weighted_loss': True
    })
    
    print("🚀 Starting training...")
    train(
        model_name=MODEL_NAME,
        resume_from=None,
        config_name=CONFIG_NAME
    )

# Uncomment để chạy training
# run_training()

# ============================================
# CELL 8: Download Model
# ============================================
def download_model():
    from google.colab import files
    from pathlib import Path
    
    models_dir = Path('backend/models')
    model_files = list(models_dir.glob('*.pth'))
    
    if model_files:
        print("📦 Models available:")
        for i, model_file in enumerate(model_files, 1):
            size_mb = model_file.stat().st_size / (1024 * 1024)
            print(f"   {i}. {model_file.name} ({size_mb:.2f} MB)")
        
        # Tìm best model
        best_model = None
        for model_file in model_files:
            if 'best' in model_file.name:
                best_model = model_file
                break
        
        if not best_model and model_files:
            best_model = max(model_files, key=lambda p: p.stat().st_mtime)
        
        if best_model:
            print(f"\n⬇️  Downloading {best_model.name}...")
            files.download(str(best_model))
            print("✅ Download completed!")
    else:
        print("❌ No model files found")

# Uncomment để download
# download_model()

