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

# ============================================
# 🚀 CHẠY CELL NÀY ĐỂ CÀI ĐẶT DEPENDENCIES
# ============================================
# Bỏ comment dòng dưới để cài đặt:
install_packages()

# ============================================
# CELL 2: Mount Google Drive (REQUIRED)
# ============================================
def mount_drive():
    from google.colab import drive
    drive.mount('/content/drive')
    print("✅ Google Drive mounted")
    return '/content/drive/MyDrive/STUDY/DACN'

# Mount Drive và lấy đường dẫn
DRIVE_PATH = mount_drive()
print(f"📁 Drive path: {DRIVE_PATH}")

# ============================================
# CELL 3: Load Dataset từ Google Drive
# ============================================
def load_dataset_from_drive(drive_path):
    import zipfile
    import os
    from pathlib import Path
    
    dataset_zip = Path(drive_path) / 'dataset.zip'
    dataset_dir = Path('/content/dataset')
    
    if dataset_zip.exists():
        print(f"📦 Found dataset.zip at {dataset_zip}")
        print("📦 Extracting dataset...")
        
        # Xóa dataset cũ nếu có
        if dataset_dir.exists():
            import shutil
            shutil.rmtree(dataset_dir)
        
        # Giải nén
        with zipfile.ZipFile(dataset_zip, 'r') as zip_ref:
            zip_ref.extractall('/content')
        
        print(f'✅ Dataset extracted to /content/dataset')
        
        # Kiểm tra cấu trúc
        if (dataset_dir / 'train').exists():
            train_classes = len(list((dataset_dir / 'train').iterdir()))
            print(f"   Found {train_classes} classes in train set")
        return str(dataset_dir)
    else:
        print(f"❌ dataset.zip not found at {dataset_zip}")
        print("   Please upload dataset.zip to MyDrive/STUDY/DACN/")
        return None

# Load dataset từ Drive
DATASET_ROOT = load_dataset_from_drive(DRIVE_PATH)

# ============================================
# CELL 4: Load Training Scripts từ Google Drive
# ============================================
def load_scripts_from_drive(drive_path):
    import shutil
    import os
    from pathlib import Path
    
    drive_path_obj = Path(drive_path)
    
    # Tạo thư mục local
    os.makedirs('backend/scripts', exist_ok=True)
    os.makedirs('backend/models', exist_ok=True)
    
    # Copy train_model.py từ Drive
    train_script_drive = drive_path_obj / 'train_model.py'
    train_script_local = Path('backend/scripts/train_model.py')
    
    if train_script_drive.exists():
        shutil.copy2(train_script_drive, train_script_local)
        print(f'✅ Copied train_model.py from Drive to backend/scripts/')
    else:
        print(f"⚠️  train_model.py not found at {train_script_drive}")
        print("   Please upload train_model.py to MyDrive/STUDY/DACN/")
    
    # Copy label_map từ Drive
    label_map_drive = drive_path_obj / 'label_map_from_dataset.json'
    label_map_local = Path('backend/models/label_map_from_dataset.json')
    
    if label_map_drive.exists():
        shutil.copy2(label_map_drive, label_map_local)
        print(f'✅ Copied label_map_from_dataset.json from Drive to backend/models/')
    else:
        print(f"⚠️  label_map_from_dataset.json not found at {label_map_drive}")
        print("   Please upload label_map_from_dataset.json to MyDrive/STUDY/DACN/")
    
    return label_map_local if label_map_local.exists() else None

# Load scripts từ Drive
LABEL_MAP_FILE = load_scripts_from_drive(DRIVE_PATH)

# Copy check_dataset_quality.py nếu có (optional)
def load_check_script_from_drive(drive_path):
    """Load check_dataset_quality.py từ Drive nếu có"""
    import shutil
    from pathlib import Path
    
    drive_path_obj = Path(drive_path)
    check_script_drive = drive_path_obj / 'check_dataset_quality.py'
    check_script_local = Path('backend/scripts/check_dataset_quality.py')
    
    if check_script_drive.exists():
        shutil.copy2(check_script_drive, check_script_local)
        print(f'✅ Copied check_dataset_quality.py from Drive')
        return True
    return False

# Load check script (optional)
load_check_script_from_drive(DRIVE_PATH)

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
# CELL 5.5: Kiểm tra Dataset Quality và Tự Động Đề Xuất Cấu Hình
# ============================================
def check_dataset_quality_and_recommend(dataset_root="dataset", label_map_file=None):
    """Kiểm tra dataset và tự động đề xuất cấu hình training"""
    from pathlib import Path
    from collections import Counter
    import json
    
    dataset_path = Path(dataset_root)
    if not dataset_path.exists():
        print("⚠️  Dataset not found, skipping quality check")
        return {}
    
    print("\n" + "=" * 80)
    print("🔍 KIỂM TRA DATASET QUALITY VÀ ĐỀ XUẤT CẤU HÌNH")
    print("=" * 80)
    
    # Load label map if provided
    label_to_idx = {}
    if label_map_file and Path(label_map_file).exists():
        with open(label_map_file, "r", encoding="utf-8") as f:
            label_data = json.load(f)
            label_to_idx = label_data.get("label_to_idx", {})
            print(f"📄 Loaded label map: {len(label_to_idx)} classes")
    
    # Check each split
    splits = ["train", "val", "test"]
    all_counts = {}
    image_extensions = [".jpg", ".jpeg", ".png", ".bmp", ".webp"]
    
    for split in splits:
        split_dir = dataset_path / split
        if not split_dir.exists():
            print(f"\n⚠️  {split.upper()}: NOT FOUND")
            continue
        
        print(f"\n📁 {split.upper()} Set:")
        print("-" * 80)
        
        class_counts = {}
        total_images = 0
        
        for disease_dir in sorted(split_dir.iterdir()):
            if not disease_dir.is_dir():
                continue
            
            disease_name = disease_dir.name
            count = 0
            for ext in image_extensions:
                count += len(list(disease_dir.glob(f"*{ext}")))
                count += len(list(disease_dir.glob(f"*{ext.upper()}")))
            
            if count > 0:
                class_counts[disease_name] = count
                total_images += count
        
        all_counts[split] = class_counts
        
        if class_counts:
            print(f"   Total classes: {len(class_counts)}")
            print(f"   Total images: {total_images}")
            print(f"   Average per class: {total_images / len(class_counts):.1f}")
            
            min_class = min(class_counts.items(), key=lambda x: x[1])
            max_class = max(class_counts.items(), key=lambda x: x[1])
            
            print(f"   Min: {min_class[0]} ({min_class[1]} images)")
            print(f"   Max: {max_class[0]} ({max_class[1]} images)")
            
            if max_class[1] > 0 and min_class[1] > 0:
                imbalance_ratio = max_class[1] / min_class[1]
                if imbalance_ratio > 5:
                    print(f"   ⚠️  Class imbalance: {imbalance_ratio:.1f}x")
        else:
            print(f"   ⚠️  No images found!")
    
    # Analyze and generate recommendations
    recommendations = {
        "use_weighted_loss": False,
        "early_stopping_patience": 20,
        "warnings": [],
        "issues": []
    }
    
    print("\n" + "=" * 80)
    print("📊 PHÂN TÍCH VÀ ĐỀ XUẤT")
    print("=" * 80)
    
    # Check class imbalance
    if "train" in all_counts:
        train_counts = all_counts["train"]
        if train_counts:
            min_count = min(train_counts.values())
            max_count = max(train_counts.values())
            imbalance_ratio = max_count / min_count if min_count > 0 else 0
            
            if imbalance_ratio > 5:
                recommendations["use_weighted_loss"] = True
                recommendations["warnings"].append(f"Class imbalance detected: {imbalance_ratio:.1f}x")
                print(f"   ⚠️  Class imbalance: {imbalance_ratio:.1f}x")
                print(f"   → Đề xuất: USE_WEIGHTED_LOSS = True")
    
    # Check validation set
    if "train" in all_counts and "val" in all_counts:
        train_counts = all_counts["train"]
        val_counts = all_counts["val"]
        
        # Check missing classes
        missing_in_val = set(train_counts.keys()) - set(val_counts.keys())
        if missing_in_val:
            recommendations["issues"].append(f"Classes missing in validation: {len(missing_in_val)}")
            print(f"   ❌ Classes missing in validation: {len(missing_in_val)}")
            print(f"      {list(missing_in_val)[:5]}...")
        
        # Check ratios
        problem_classes = []
        for class_name in train_counts.keys():
            train_count = train_counts.get(class_name, 0)
            val_count = val_counts.get(class_name, 0)
            
            if train_count > 0:
                ratio = val_count / train_count if train_count > 0 else 0
                if ratio < 0.05:
                    problem_classes.append((class_name, ratio))
        
        if problem_classes:
            recommendations["warnings"].append(f"{len(problem_classes)} classes have < 5% validation images")
            print(f"   ⚠️  {len(problem_classes)} classes have too few validation images:")
            for class_name, ratio in problem_classes[:3]:
                print(f"      - {class_name}: {ratio:.1%}")
        
        # Check validation ratio
        train_total = sum(train_counts.values())
        val_total = sum(val_counts.values())
        if train_total > 0:
            val_ratio = val_total / (train_total + val_total)
            if val_ratio < 0.1:
                recommendations["warnings"].append("Validation set too small (< 10%)")
                print(f"   ⚠️  Validation ratio: {val_ratio:.1%} (too small)")
            elif val_ratio > 0.3:
                recommendations["warnings"].append("Validation set too large (> 30%)")
                print(f"   ⚠️  Validation ratio: {val_ratio:.1%} (too large)")
            else:
                print(f"   ✅ Validation ratio: {val_ratio:.1%} (OK)")
    
    # Adjust early stopping based on issues
    if recommendations["issues"]:
        recommendations["early_stopping_patience"] = 15
        print(f"   → Đề xuất: EARLY_STOPPING_PATIENCE = 15 (có vấn đề dataset)")
    elif recommendations["warnings"]:
        recommendations["early_stopping_patience"] = 20
        print(f"   → Đề xuất: EARLY_STOPPING_PATIENCE = 20")
    else:
        recommendations["early_stopping_patience"] = 25
        print(f"   → Đề xuất: EARLY_STOPPING_PATIENCE = 25 (dataset OK)")
    
    print("\n" + "=" * 80)
    print("💡 TỔNG HỢP ĐỀ XUẤT CẤU HÌNH")
    print("=" * 80)
    
    if recommendations["use_weighted_loss"]:
        print("   ✅ USE_WEIGHTED_LOSS = True  (BẮT BUỘC)")
    else:
        print("   ⚪ USE_WEIGHTED_LOSS = False (không cần)")
    
    print(f"   ✅ EARLY_STOPPING_PATIENCE = {recommendations['early_stopping_patience']}")
    print("   ✅ USE_COSINE_SCHEDULER = True")
    
    if recommendations["issues"]:
        print("\n   ⚠️  CẢNH BÁO: Dataset có vấn đề nghiêm trọng!")
        print("      Nên tái tổ chức dataset trước khi training")
    
    print("=" * 80)
    
    return recommendations

# Chạy kiểm tra và lấy recommendations
DATASET_RECOMMENDATIONS = check_dataset_quality_and_recommend(DATASET_ROOT, LABEL_MAP_FILE)

# Tự động cập nhật cấu hình nếu có recommendations
if DATASET_RECOMMENDATIONS:
    if DATASET_RECOMMENDATIONS.get("use_weighted_loss"):
        print("\n💡 Tự động cập nhật: USE_WEIGHTED_LOSS = True")
        USE_WEIGHTED_LOSS = True
    
    recommended_patience = DATASET_RECOMMENDATIONS.get("early_stopping_patience", 20)
    if recommended_patience != EARLY_STOPPING_PATIENCE:
        print(f"💡 Tự động cập nhật: EARLY_STOPPING_PATIENCE = {recommended_patience}")
        EARLY_STOPPING_PATIENCE = recommended_patience

# ============================================
# CELL 6: Cấu hình Training - ViT TRAINING
# ============================================
# 🎯 OPTION 2: Train Vision Transformer (ViT) từ đầu với pretrained weights
# Mục tiêu: Đạt 90% validation accuracy với ViT (thường tốt hơn ResNet50)
# ⚠️ LƯU Ý: ViT không thể dùng ResNet50 checkpoint (architecture khác nhau)
# ============================================
# Thay đổi các giá trị này
MODEL_NAME = "vit"  # vit (base), vit_small (faster), vit_large (best accuracy but slower)
NUM_EPOCHS = 100  # ViT thường cần nhiều epochs hơn để converge
BATCH_SIZE = 16  # ⚠️ GIẢM BATCH SIZE (ViT tốn nhiều GPU memory hơn ResNet50)
LEARNING_RATE = 1e-4  # Learning rate cho ViT (có thể cao hơn ResNet50 một chút)
MIN_LR = 1e-6  # Min learning rate
IMAGE_SIZE = 224
CONFIG_NAME = "from_dataset"
VERBOSE = True  # Hiển thị thông tin chi tiết
GRADIENT_ACCUMULATION_STEPS = 1  # Tăng lên 2-4 nếu hết RAM (giảm batch size thực tế)

# Các tính năng mới để cải thiện accuracy và tránh overfitting
# ⚠️ LƯU Ý: Các giá trị này sẽ được tự động cập nhật sau khi kiểm tra dataset (CELL 5.5)
USE_COSINE_SCHEDULER = True  # Sử dụng CosineAnnealingLR cho fine-tuning
FREEZE_BACKBONE_EPOCHS = 0  # Freeze backbone epochs (0 = không freeze, 10 = freeze 10 epochs đầu)
USE_WEIGHTED_LOSS = True  # Sẽ được tự động cập nhật dựa trên class imbalance
EARLY_STOPPING_PATIENCE = 30  # ⚠️ TĂNG PATIENCE lên 30 để cho model nhiều cơ hội cải thiện

# Các cải tiến mới để fine-tune tốt hơn
# ⚠️ ĐIỀU CHỈNH CHO ViT: Tăng regularization để giảm overfitting
DROPOUT_RATE = 0.8  # ⚠️ TĂNG DROPOUT lên 0.8 để giảm overfitting (ViT dễ overfit hơn ResNet)
WEIGHT_DECAY = 1e-4  # ⚠️ TĂNG WEIGHT DECAY lên 1e-4 để tăng regularization
USE_LABEL_SMOOTHING = True  # Sử dụng label smoothing để giảm overfitting
LABEL_SMOOTHING = 0.15  # ⚠️ TĂNG LABEL SMOOTHING lên 0.15 để giảm overfitting mạnh hơn
USE_STRONG_AUGMENTATION = True  # Sử dụng augmentation mạnh hơn (rotation 45°, RandomErasing, etc.)

# Lưu ý: Sau khi chạy CELL 5.5, các giá trị này sẽ được cập nhật tự động

# Đường dẫn checkpoint trên Drive (sẽ tự động tạo)
CHECKPOINT_DIR_DRIVE = f"{DRIVE_PATH}/checkpoints"
CHECKPOINT_DIR_LOCAL = "/content/checkpoints"  # Tạm thời lưu local, sau đó sync lên Drive

# Tạo thư mục checkpoint
import os
os.makedirs(CHECKPOINT_DIR_LOCAL, exist_ok=True)
os.makedirs(CHECKPOINT_DIR_DRIVE, exist_ok=True)

# Label map file (đã load từ Drive)
if LABEL_MAP_FILE is None:
    LABEL_MAP_FILE = "backend/models/label_map_from_dataset.json"

print("\n" + "=" * 80)
print("🎯 ViT TRAINING MODE: Vision Transformer từ đầu với pretrained weights")
print("=" * 80)
print("⚙️  Training Configuration:")
print(f"   Model: {MODEL_NAME} (Vision Transformer)")
print(f"   Mode: TRAIN FROM SCRATCH (pretrained ImageNet weights)")
print(f"   Total Epochs: {NUM_EPOCHS}")
print(f"   Batch Size: {BATCH_SIZE}")
if GRADIENT_ACCUMULATION_STEPS > 1:
    print(f"   Gradient Accumulation: {GRADIENT_ACCUMULATION_STEPS} steps")
    print(f"   Effective Batch Size: {BATCH_SIZE * GRADIENT_ACCUMULATION_STEPS}")
print(f"   Learning Rate: {LEARNING_RATE} (⚠️ reduced 10x for fine-tuning)")
print(f"   Min Learning Rate: {MIN_LR} (⚠️ reduced for deeper fine-tuning)")
print(f"   Image Size: {IMAGE_SIZE}")
print(f"   Verbose: {VERBOSE}")
print(f"   Dataset: {DATASET_ROOT}")
print(f"   Label Map: {LABEL_MAP_FILE}")
print(f"   Checkpoint Dir (Drive): {CHECKPOINT_DIR_DRIVE}")
print(f"   Checkpoint Dir (Local): {CHECKPOINT_DIR_LOCAL}")
print(f"\n🎯 Fine-Tune Settings:")
print(f"   Early Stopping: {EARLY_STOPPING_PATIENCE} epochs patience" if EARLY_STOPPING_PATIENCE > 0 else "   Early Stopping: DISABLED")
print(f"   Cosine Scheduler: {USE_COSINE_SCHEDULER} (enabled for fine-tuning)")
print(f"   Weighted Loss: {USE_WEIGHTED_LOSS}")
print(f"   Dropout Rate: {DROPOUT_RATE} (⚠️ TĂNG để giảm overfitting cho ViT)")
print(f"   Weight Decay: {WEIGHT_DECAY} (⚠️ TĂNG để tăng regularization)")
print(f"   Label Smoothing: {USE_LABEL_SMOOTHING} (factor: {LABEL_SMOOTHING})" if USE_LABEL_SMOOTHING else "   Label Smoothing: DISABLED")
print(f"   Strong Augmentation: {USE_STRONG_AUGMENTATION}")
print(f"   Freeze Backbone: {FREEZE_BACKBONE_EPOCHS} epochs" if FREEZE_BACKBONE_EPOCHS > 0 else "   Freeze Backbone: DISABLED")
print("=" * 80)

# ============================================
# CELL 7: Tìm Best Checkpoint để Fine-tune
# ============================================
def find_best_checkpoint(checkpoint_dir):
    """Tìm best checkpoint (ưu tiên best_checkpoint.pth, sau đó tìm epoch có val acc cao nhất)"""
    from pathlib import Path
    import re
    
    checkpoint_path = Path(checkpoint_dir)
    if not checkpoint_path.exists():
        return None
    
    # Ưu tiên 1: Tìm best_checkpoint.pth
    best_checkpoint = checkpoint_path / f"{MODEL_NAME}_best_checkpoint.pth"
    if best_checkpoint.exists():
        print(f"   ✅ Found best checkpoint: {best_checkpoint.name}")
        return str(best_checkpoint)
    
    # Ưu tiên 2: Tìm checkpoint từ epoch 79 (best val acc 81.77%)
    epoch_79_checkpoint = checkpoint_path / f"{MODEL_NAME}_checkpoint_epoch_79.pth"
    if epoch_79_checkpoint.exists():
        print(f"   ✅ Found epoch 79 checkpoint (best val acc: 81.77%)")
        return str(epoch_79_checkpoint)
    
    # Ưu tiên 3: Tìm checkpoint mới nhất
    checkpoint_files = list(checkpoint_path.glob(f"{MODEL_NAME}_checkpoint_epoch_*.pth"))
    if checkpoint_files:
        # Sắp xếp theo epoch number, lấy epoch cao nhất
        def get_epoch_number(file_path):
            match = re.search(r'epoch_(\d+)', file_path.name)
            return int(match.group(1)) if match else 0
        
        latest_checkpoint = max(checkpoint_files, key=get_epoch_number)
        epoch_num = get_epoch_number(latest_checkpoint)
        print(f"   ⚠️  Best checkpoint not found, using latest: epoch {epoch_num}")
        return str(latest_checkpoint)
    
    return None

# Tìm checkpoint để resume (ưu tiên best checkpoint)
# 🎯 FINE-TUNE MODE: Resume từ best checkpoint (81.77% val acc) để đạt 90%
from pathlib import Path
import re

# ⚠️ QUAN TRỌNG: 
# - Nếu bạn muốn resume từ checkpoint cụ thể, đặt RESUME_FROM ở CUỐI CELL này (sau tất cả code)
# - Ví dụ: RESUME_FROM = f"{CHECKPOINT_DIR_DRIVE}/resnet50_checkpoint_epoch_80.pth"
# - Giá trị bạn đặt ở cuối sẽ OVERRIDE giá trị tự động tìm được

# ⚠️ QUAN TRỌNG: ViT không thể dùng ResNet50 checkpoint!
# ViT sẽ train từ đầu với pretrained ImageNet weights (tốt hơn train từ đầu hoàn toàn)
# Nếu bạn muốn resume từ ViT checkpoint cũ, hãy đặt RESUME_FROM ở cuối cell này

# Tự động tìm ViT checkpoint (nếu có)
RESUME_FROM = find_best_checkpoint(CHECKPOINT_DIR_DRIVE)

# Tự động kiểm tra và cảnh báo nếu checkpoint có vấn đề
if RESUME_FROM and MODEL_NAME in RESUME_FROM:
    print(f"\n📂 FINE-TUNE MODE: Resuming from checkpoint")
    print(f"   Checkpoint: {Path(RESUME_FROM).name}")
    
    # Extract epoch number từ tên file hoặc từ bên trong checkpoint
    epoch_num = None
    epoch_match = re.search(r'epoch_(\d+)', Path(RESUME_FROM).name)
    if epoch_match:
        epoch_num = int(epoch_match.group(1))
        print(f"   📊 Checkpoint epoch: {epoch_num} (from filename)")
    else:
        # Thử đọc epoch từ bên trong checkpoint file
        try:
            import torch
            checkpoint_path = Path(RESUME_FROM)
            # Kiểm tra xem file có tồn tại không (có thể là đường dẫn Drive)
            if not checkpoint_path.exists():
                # Thử đường dẫn Drive
                drive_checkpoint = Path(CHECKPOINT_DIR_DRIVE) / checkpoint_path.name
                if drive_checkpoint.exists():
                    checkpoint_path = drive_checkpoint
            
            if checkpoint_path.exists():
                checkpoint = torch.load(checkpoint_path, map_location='cpu', weights_only=False)
                if isinstance(checkpoint, dict) and 'epoch' in checkpoint:
                    epoch_num = checkpoint['epoch']
                    print(f"   📊 Checkpoint epoch: {epoch_num} (from checkpoint file)")
                elif isinstance(checkpoint, dict) and 'best_val_acc' in checkpoint:
                    # Best checkpoint thường là epoch 79 (81.77% val acc)
                    print(f"   📊 Best checkpoint detected (likely epoch 79 with 81.77% val acc)")
                    epoch_num = 79  # Best checkpoint thường là epoch 79
                else:
                    print(f"   📊 Best checkpoint (epoch info not available, assuming epoch 79)")
                    epoch_num = 79  # Best checkpoint thường là epoch 79
            else:
                print(f"   📊 Best checkpoint (file not accessible, assuming epoch 79)")
                epoch_num = 79  # Best checkpoint thường là epoch 79
        except Exception as e:
            print(f"   📊 Best checkpoint (could not read epoch: {e}, assuming epoch 79)")
            epoch_num = 79  # Best checkpoint thường là epoch 79
    
    if epoch_num is not None:
        print(f"   📊 Will resume from epoch {epoch_num + 1}")
        if MODEL_NAME.startswith("vit"):
            print(f"   🎯 Target: Train ViT to achieve 90% val acc")
        else:
            print(f"   🎯 Target: Improve from 81.77% to 90% val acc")
    else:
        if MODEL_NAME.startswith("vit"):
            print(f"   🎯 Target: Train ViT to achieve 90% val acc")
        else:
            print(f"   🎯 Target: Improve from 81.77% to 90% val acc")
    
    if MODEL_NAME.startswith("vit"):
        print(f"\n   ⚙️  ViT Training settings:")
        print(f"      - Learning Rate: {LEARNING_RATE} (optimized for ViT)")
        print(f"      - Dropout: {DROPOUT_RATE}")
        print(f"      - Weight Decay: {WEIGHT_DECAY}")
        print(f"      - Early Stopping Patience: {EARLY_STOPPING_PATIENCE}")
        print(f"      - Total Epochs: {NUM_EPOCHS}")
        print(f"      - Batch Size: {BATCH_SIZE} (reduced for ViT memory usage)")
    else:
        print(f"\n   ⚙️  Fine-tune settings:")
        print(f"      - Learning Rate: {LEARNING_RATE} (reduced 10x)")
        print(f"      - Dropout: {DROPOUT_RATE} (reduced)")
        print(f"      - Weight Decay: {WEIGHT_DECAY} (reduced)")
        print(f"      - Early Stopping Patience: {EARLY_STOPPING_PATIENCE}")
        print(f"      - Additional Epochs: {NUM_EPOCHS}")
else:
    if MODEL_NAME.startswith("vit"):
        print("📂 No ViT checkpoint found, starting from scratch")
        print("   ✅ ViT will use pretrained ImageNet weights (better than random init)")
        print("   💡 ViT pretrained weights are automatically loaded by timm library")
        RESUME_FROM = None  # Force start from scratch for ViT
    else:
        print("📂 No checkpoint found, starting from scratch")
        print("   ⚠️  WARNING: Fine-tune mode requires a checkpoint!")
        print("   💡 Please ensure best checkpoint exists on Drive")

# ============================================
# ⚠️ OVERRIDE RESUME_FROM (Đặt ở đây để override giá trị tự động)
# ============================================
# 🎯 MẶC ĐỊNH CHO ViT: Start from scratch với pretrained weights
# ViT không thể dùng ResNet50 checkpoint (architecture khác nhau)

# Nếu bạn đã train ViT trước đó và muốn resume:
# RESUME_FROM = f"{CHECKPOINT_DIR_DRIVE}/vit_best_checkpoint.pth"
# hoặc
# RESUME_FROM = f"{CHECKPOINT_DIR_DRIVE}/vit_checkpoint_epoch_XX.pth"

# ⚠️ QUAN TRỌNG: Nếu MODEL_NAME là "vit", đảm bảo RESUME_FROM là None hoặc ViT checkpoint
if MODEL_NAME.startswith("vit") and RESUME_FROM and "resnet50" in RESUME_FROM.lower():
    print("\n⚠️  WARNING: ViT không thể dùng ResNet50 checkpoint!")
    print("   Setting RESUME_FROM = None (will use pretrained ImageNet weights)")
    RESUME_FROM = None

# ============================================
# 🎯 RETRAIN MODE: Train từ đầu với hyperparameters mới (tăng regularization)
# ============================================
# ⚠️ Nếu bạn muốn retrain từ đầu với settings mới (sau khi dừng training cũ):
# 1. Dừng training hiện tại: Click nút "Stop" trong Colab hoặc interrupt kernel
# 2. Uncomment dòng dưới để force train từ đầu:
# RESUME_FROM = None  # ⚠️ Uncomment dòng này để train từ đầu với settings mới
# 3. Chạy lại CELL 6 và CELL 8
#
# 💡 Lưu ý: ViT checkpoint cũ (epoch 25, val_acc 69.42%) sẽ không được dùng
#    Model sẽ train từ đầu với pretrained ImageNet weights + regularization mạnh hơn

# Hiển thị giá trị RESUME_FROM cuối cùng (sau khi override nếu có)
print("\n" + "=" * 80)
print("📋 FINAL RESUME_FROM VALUE (sau khi override nếu có):")
if RESUME_FROM:
    print(f"   ✅ RESUME_FROM = {RESUME_FROM}")
    print(f"   📁 File: {Path(RESUME_FROM).name}")
    # Kiểm tra file có tồn tại không
    if Path(RESUME_FROM).exists() or Path(CHECKPOINT_DIR_DRIVE) / Path(RESUME_FROM).name:
        print(f"   ✅ Checkpoint file exists")
    else:
        print(f"   ⚠️  WARNING: Checkpoint file may not exist!")
        print(f"   💡 Nếu file không tồn tại, CELL 8 sẽ tìm best checkpoint thay thế")
else:
    print(f"   ⚠️  RESUME_FROM = None (will start from scratch)")
print("=" * 80)

# ============================================
# CELL 8: Chạy Training với Auto-save to Drive
# ============================================
def run_training():
    import sys
    import shutil
    from pathlib import Path
    import threading
    import time
    import importlib
    import os
    
    # Kiểm tra và mount Drive nếu chưa mount
    try:
        drive_path = DRIVE_PATH
    except NameError:
        print("📁 DRIVE_PATH not found, mounting Drive...")
        from google.colab import drive
        drive.mount('/content/drive')
        drive_path = '/content/drive/MyDrive/STUDY/DACN'
        print(f"✅ Drive mounted: {drive_path}")
    
    # Đảm bảo thư mục tồn tại
    os.makedirs('backend/scripts', exist_ok=True)
    os.makedirs('backend/models', exist_ok=True)
    
    # Kiểm tra và load lại file train_model.py từ Drive nếu cần
    train_script_local = Path('backend/scripts/train_model.py')
    train_script_drive = Path(drive_path) / 'train_model.py'
    
    print(f"🔍 Checking train_model.py...")
    print(f"   Local: {train_script_local} (exists: {train_script_local.exists()})")
    print(f"   Drive: {train_script_drive} (exists: {train_script_drive.exists()})")
    
    if not train_script_local.exists():
        if train_script_drive.exists():
            print("📥 train_model.py not found locally, loading from Drive...")
            try:
                shutil.copy2(train_script_drive, train_script_local)
                print(f"✅ Copied train_model.py from Drive")
            except Exception as e:
                print(f"❌ Error copying file: {e}")
                return
        else:
            print(f"❌ train_model.py not found!")
            print(f"   Please ensure train_model.py is uploaded to {DRIVE_PATH}")
            return
    
    # Kiểm tra và load lại label_map nếu cần
    label_map_local = Path('backend/models/label_map_from_dataset.json')
    label_map_drive = Path(drive_path) / 'label_map_from_dataset.json'
    
    if not label_map_local.exists():
        if label_map_drive.exists():
            print("📥 label_map_from_dataset.json not found locally, loading from Drive...")
            try:
                shutil.copy2(label_map_drive, label_map_local)
                print(f"✅ Copied label_map_from_dataset.json from Drive")
            except Exception as e:
                print(f"⚠️  Error copying label_map: {e}")
        else:
            print(f"⚠️  label_map_from_dataset.json not found, but continuing...")
    
    # Đảm bảo sys.path có đường dẫn đúng
    scripts_path = str(Path('backend/scripts').absolute())
    if scripts_path not in sys.path:
        sys.path.insert(0, scripts_path)
    
    print(f"📂 Python path includes: {scripts_path}")
    print(f"📄 Checking if train_model.py exists: {train_script_local.exists()}")
    
    # Verify file exists before import
    if not train_script_local.exists():
        print(f"❌ train_model.py still not found after copy attempt!")
        print(f"   File path: {train_script_local.absolute()}")
        return
    
    # Force reload module để đảm bảo dùng file mới nhất
    if 'train_model' in sys.modules:
        print("🔄 Reloading train_model module...")
        importlib.reload(sys.modules['train_model'])
    
    try:
        print("📦 Importing train_model...")
        from train_model import train
        import train_model as tm
        print("✅ Successfully imported train_model")
    except ImportError as e:
        print(f"❌ Import error: {e}")
        print(f"   Trying to import from absolute path...")
        import importlib.util
        spec = importlib.util.spec_from_file_location("train_model", train_script_local)
        if spec is None or spec.loader is None:
            print(f"❌ Cannot create module spec from {train_script_local}")
            return
        train_module = importlib.util.module_from_spec(spec)
        sys.modules["train_model"] = train_module
        spec.loader.exec_module(train_module)
        train = train_module.train
        tm = train_module
        print("✅ Successfully loaded train_model from file")
    
    # Kiểm tra xem hàm train có đủ tham số không
    import inspect
    train_signature = inspect.signature(train)
    required_params = ['verbose', 'gradient_accumulation_steps', 'early_stopping_patience']
    missing_params = [p for p in required_params if p not in train_signature.parameters]
    
    if missing_params:
        print(f"⚠️  WARNING: train_model.py trên Drive có thể là version cũ!")
        print(f"   Missing parameters: {missing_params}")
        print(f"   Vui lòng upload lại file train_model.py mới nhất lên Drive")
        print(f"   File mới có các tính năng: Early Stopping, tăng dropout, tăng augmentation")
        
        # Fallback: gọi train() với các tham số cũ
        def train_with_fallback(*args, **kwargs):
            # Loại bỏ các tham số không hỗ trợ
            kwargs.pop('verbose', None)
            kwargs.pop('gradient_accumulation_steps', None)
            kwargs.pop('early_stopping_patience', None)
            return train(*args, **kwargs)
        
        train = train_with_fallback
    
    # Đảm bảo CHECKPOINT_DIR_DRIVE được định nghĩa (phải định nghĩa trước khi dùng)
    try:
        checkpoint_dir_drive = CHECKPOINT_DIR_DRIVE
        checkpoint_dir_local = CHECKPOINT_DIR_LOCAL
    except NameError:
        checkpoint_dir_drive = f"{drive_path}/checkpoints"
        checkpoint_dir_local = "/content/checkpoints"
        os.makedirs(checkpoint_dir_local, exist_ok=True)
        os.makedirs(checkpoint_dir_drive, exist_ok=True)
    
    # Override config cho Colab
    tm.CONFIG.update({
        'batch_size': BATCH_SIZE,
        'num_epochs': NUM_EPOCHS,
        'learning_rate': LEARNING_RATE,
        'min_lr': MIN_LR,
        'image_size': IMAGE_SIZE,
        'dataset_root': DATASET_ROOT,
        'label_map_file': LABEL_MAP_FILE,
        'num_workers': 4,
        'pin_memory': True,
        'save_dir': checkpoint_dir_local,  # Lưu tạm local
        'use_weighted_loss': USE_WEIGHTED_LOSS,
        'use_cosine_scheduler': USE_COSINE_SCHEDULER,
        'dropout_rate': DROPOUT_RATE,
        'weight_decay': WEIGHT_DECAY,
        'use_label_smoothing': USE_LABEL_SMOOTHING,
        'label_smoothing': LABEL_SMOOTHING,
        'strong_augmentation': USE_STRONG_AUGMENTATION,
        'early_stopping_patience': EARLY_STOPPING_PATIENCE
    })
    
    if VERBOSE:
        print("\n💡 Memory Optimization Tips:")
        print("   - Using gradient accumulation to reduce memory usage")
        print("   - Clearing cache after each epoch")
        print("   - Using non_blocking transfers")
        print("   - Optimized DataLoader settings")
    
    # Hàm sync checkpoint lên Drive
    def sync_checkpoint_to_drive():
        """Sync chỉ checkpoint của model hiện tại (MODEL_NAME) từ local lên Drive"""
        try:
            local_path = Path(checkpoint_dir_local)
            drive_path_checkpoint = Path(checkpoint_dir_drive)
            
            if not local_path.exists():
                return
            
            # ⚠️ QUAN TRỌNG: Chỉ sync checkpoint của MODEL_NAME hiện tại
            # Pattern: {MODEL_NAME}_*.pth hoặc {MODEL_NAME}_*.json
            model_prefix = MODEL_NAME.lower()
            
            # Sync checkpoint files - chỉ của model hiện tại
            for checkpoint_file in local_path.glob("*.pth"):
                # Chỉ sync nếu file bắt đầu với MODEL_NAME
                if checkpoint_file.name.startswith(f"{model_prefix}_"):
                    dest_file = drive_path_checkpoint / checkpoint_file.name
                    # Chỉ sync nếu file mới hơn hoặc chưa tồn tại
                    if not dest_file.exists() or checkpoint_file.stat().st_mtime > dest_file.stat().st_mtime:
                        shutil.copy2(checkpoint_file, dest_file)
                        print(f"   💾 Synced {checkpoint_file.name} to Drive")
            
            # Sync history files - chỉ của model hiện tại
            for history_file in local_path.glob("*.json"):
                # Chỉ sync nếu file bắt đầu với MODEL_NAME
                if history_file.name.startswith(f"{model_prefix}_"):
                    dest_file = drive_path_checkpoint / history_file.name
                    if not dest_file.exists() or history_file.stat().st_mtime > dest_file.stat().st_mtime:
                        shutil.copy2(history_file, dest_file)
        except Exception as e:
            print(f"   ⚠️  Sync error: {e}")
    
    # Hàm periodic sync chạy trong background
    sync_running = [True]  # Use list để có thể modify từ outer scope
    
    def periodic_sync():
        """Sync checkpoint lên Drive mỗi 2 phút"""
        while sync_running[0]:
            time.sleep(120)  # 2 phút
            if sync_running[0]:
                sync_checkpoint_to_drive()
    
    # Bắt đầu thread sync
    sync_thread = threading.Thread(target=periodic_sync, daemon=True)
    sync_thread.start()
    print(f"✅ Auto-sync to Drive started (every 2 minutes) - Chỉ sync {MODEL_NAME} checkpoints")
    
    # Tìm checkpoint để resume
    # Ưu tiên: 1) RESUME_FROM từ CELL 7, 2) Best checkpoint trong Drive
    def find_best_checkpoint_in_drive():
        """Tìm best checkpoint trong thư mục Drive (ưu tiên best_checkpoint.pth)"""
        checkpoint_path = Path(checkpoint_dir_drive)
        if not checkpoint_path.exists():
            return None
        
        # Ưu tiên 1: Tìm best_checkpoint.pth
        best_checkpoint = checkpoint_path / f"{MODEL_NAME}_best_checkpoint.pth"
        if best_checkpoint.exists():
            return str(best_checkpoint)
        
        # Ưu tiên 2: Tìm epoch 79 (chỉ cho ResNet50, best val acc 81.77%)
        if MODEL_NAME == "resnet50":
            epoch_79_checkpoint = checkpoint_path / f"{MODEL_NAME}_checkpoint_epoch_79.pth"
            if epoch_79_checkpoint.exists():
                return str(epoch_79_checkpoint)
        
        # Ưu tiên 3: Tìm checkpoint mới nhất
        checkpoint_files = list(checkpoint_path.glob(f"{MODEL_NAME}_checkpoint_epoch_*.pth"))
        if checkpoint_files:
            def get_epoch_number(file_path):
                import re
                match = re.search(r'epoch_(\d+)', file_path.name)
                return int(match.group(1)) if match else 0
            
            latest_checkpoint = max(checkpoint_files, key=get_epoch_number)
            return str(latest_checkpoint)
        
        return None
    
    # Kiểm tra RESUME_FROM từ CELL 7 trước
    try:
        resume_from = RESUME_FROM  # Lấy từ CELL 7
        print(f"🔍 Debug: RESUME_FROM from CELL 7: {resume_from}")
        
        # ⚠️ QUAN TRỌNG: ViT không thể dùng ResNet50 checkpoint
        if MODEL_NAME.startswith("vit") and resume_from and "resnet50" in resume_from.lower():
            print("⚠️  WARNING: ViT cannot use ResNet50 checkpoint!")
            print("   Setting RESUME_FROM = None (will use pretrained ImageNet weights)")
            resume_from = None
        
        if resume_from is None:
            # Nếu RESUME_FROM = None, tìm best checkpoint (chỉ nếu không phải ViT)
            if not MODEL_NAME.startswith("vit"):
                print("🔍 RESUME_FROM is None, searching for best checkpoint...")
                resume_from = find_best_checkpoint_in_drive()
                print(f"🔍 Found checkpoint: {resume_from}")
            else:
                print("🔍 ViT mode: RESUME_FROM = None, will use pretrained ImageNet weights")
    except NameError:
        # Nếu RESUME_FROM không được định nghĩa, tìm best checkpoint (chỉ nếu không phải ViT)
        if not MODEL_NAME.startswith("vit"):
            print("🔍 RESUME_FROM not defined, searching for best checkpoint...")
            resume_from = find_best_checkpoint_in_drive()
            print(f"🔍 Found checkpoint: {resume_from}")
        else:
            print("🔍 ViT mode: RESUME_FROM not defined, will use pretrained ImageNet weights")
            resume_from = None
    
    print("🚀 Starting training...")
    print(f"   🔍 Final resume_from value: {resume_from}")
    if resume_from:
        print(f"   📂 Resuming from: {resume_from}")
        
        # Extract và hiển thị epoch number
        import re
        epoch_match = re.search(r'epoch_(\d+)', Path(resume_from).name)
        if epoch_match:
            epoch_num = int(epoch_match.group(1))
            print(f"   📊 Checkpoint epoch: {epoch_num}")
            print(f"   📊 Will resume from epoch {epoch_num + 1}")
        
        # Xử lý đường dẫn checkpoint
        resume_path = Path(resume_from)
        checkpoint_name = resume_path.name
        
        print(f"   🔍 Processing checkpoint: {checkpoint_name}")
        print(f"   🔍 Full path: {resume_path}")
        print(f"   🔍 Exists: {resume_path.exists()}")
        
        # Kiểm tra checkpoint có tồn tại không
        if not resume_path.exists():
            # Checkpoint không tồn tại ở đường dẫn hiện tại, thử tìm trên Drive
            drive_checkpoint = Path(checkpoint_dir_drive) / checkpoint_name
            print(f"   🔍 Checking Drive: {drive_checkpoint}")
            print(f"   🔍 Drive exists: {drive_checkpoint.exists()}")
            
            if drive_checkpoint.exists():
                print(f"   📥 Checkpoint found on Drive, copying to local...")
                local_resume = Path(checkpoint_dir_local) / checkpoint_name
                try:
                    shutil.copy2(drive_checkpoint, local_resume)
                    print(f"   ✅ Copied checkpoint to local: {local_resume}")
                    resume_from = str(local_resume)
                except Exception as e:
                    print(f"   ⚠️  Error copying checkpoint: {e}")
                    print(f"   Starting from scratch instead...")
                    resume_from = None
            else:
                print(f"   ⚠️  Checkpoint not found at: {resume_from}")
                print(f"   ⚠️  Also not found on Drive at: {drive_checkpoint}")
                print(f"   Starting from scratch instead...")
                resume_from = None
        elif str(resume_path).startswith(drive_path) or '/content/drive' in str(resume_path):
            # Checkpoint trên Drive, copy về local
            local_resume = Path(checkpoint_dir_local) / checkpoint_name
            if not local_resume.exists():
                try:
                    shutil.copy2(resume_path, local_resume)
                    print(f"   📥 Copied checkpoint to local: {local_resume}")
                    resume_from = str(local_resume)
                except Exception as e:
                    print(f"   ⚠️  Error copying checkpoint: {e}")
                    print(f"   Trying to use Drive path directly...")
            else:
                print(f"   ✅ Local checkpoint already exists: {local_resume}")
                resume_from = str(local_resume)
        else:
            # Checkpoint đã ở local
            print(f"   ✅ Using local checkpoint: {resume_from}")
        
        # Verify checkpoint exists và có thể load được
        if resume_from:
            final_path = Path(resume_from)
            if not final_path.exists():
                print(f"   ⚠️  Checkpoint file not found: {resume_from}")
                print(f"   Starting from scratch instead...")
                resume_from = None
            else:
                # Verify checkpoint có thể load được
                try:
                    import torch
                    checkpoint = torch.load(final_path, map_location='cpu', weights_only=False)
                    if isinstance(checkpoint, dict) and 'epoch' in checkpoint:
                        print(f"   ✅ Checkpoint verified: epoch {checkpoint['epoch']}, will resume from epoch {checkpoint['epoch'] + 1}")
                    else:
                        print(f"   ✅ Checkpoint verified: model weights only")
                except Exception as e:
                    print(f"   ⚠️  Error verifying checkpoint: {e}")
                    print(f"   Will try to load anyway...")
    else:
        print("   Starting from scratch (no checkpoint found or RESUME_FROM = None)")
    
    try:
        # Chạy training với các tối ưu RAM
        # Kiểm tra xem hàm có hỗ trợ các tham số mới không
        train_sig = inspect.signature(train)
        import inspect
        train_sig = inspect.signature(train)
        
        train_kwargs = {
            'model_name': MODEL_NAME,
            'resume_from': resume_from,
            'config_name': CONFIG_NAME
        }
        
        # Chỉ thêm các tham số nếu hàm hỗ trợ
        if 'verbose' in train_sig.parameters:
            train_kwargs['verbose'] = VERBOSE
        if 'gradient_accumulation_steps' in train_sig.parameters:
            train_kwargs['gradient_accumulation_steps'] = GRADIENT_ACCUMULATION_STEPS
        if 'freeze_backbone_epochs' in train_sig.parameters:
            train_kwargs['freeze_backbone_epochs'] = FREEZE_BACKBONE_EPOCHS
        if 'early_stopping_patience' in train_sig.parameters:
            train_kwargs['early_stopping_patience'] = EARLY_STOPPING_PATIENCE
        if 'dropout_rate' in train_sig.parameters:
            train_kwargs['dropout_rate'] = DROPOUT_RATE
        if 'weight_decay' in train_sig.parameters:
            train_kwargs['weight_decay'] = WEIGHT_DECAY
        if 'use_label_smoothing' in train_sig.parameters:
            train_kwargs['use_label_smoothing'] = USE_LABEL_SMOOTHING
        if 'label_smoothing' in train_sig.parameters:
            train_kwargs['label_smoothing'] = LABEL_SMOOTHING
        if 'strong_augmentation' in train_sig.parameters:
            train_kwargs['strong_augmentation'] = USE_STRONG_AUGMENTATION
        
        # Hiển thị summary trước khi training
        print("\n" + "=" * 80)
        if MODEL_NAME.startswith("vit"):
            print("🚀 STARTING ViT TRAINING")
        else:
            print("🚀 STARTING FINE-TUNE TRAINING")
        print("=" * 80)
        print(f"📋 Training Parameters:")
        print(f"   Model: {MODEL_NAME}")
        if resume_from:
            print(f"   Resume from: {Path(resume_from).name}")
        elif MODEL_NAME.startswith("vit"):
            print(f"   Resume from: None (using pretrained ImageNet weights)")
        else:
            print(f"   Resume from: None (from scratch)")
        print(f"   Epochs: {NUM_EPOCHS}")
        print(f"   Batch Size: {BATCH_SIZE}")
        print(f"   Learning Rate: {LEARNING_RATE} (min: {MIN_LR})")
        if MODEL_NAME.startswith("vit"):
            print(f"\n🎯 ViT Training Settings:")
        else:
            print(f"\n🎯 Fine-Tune Settings:")
        print(f"   Dropout Rate: {DROPOUT_RATE}")
        print(f"   Weight Decay: {WEIGHT_DECAY}")
        print(f"   Label Smoothing: {USE_LABEL_SMOOTHING} (factor: {LABEL_SMOOTHING})")
        print(f"   Strong Augmentation: {USE_STRONG_AUGMENTATION}")
        print(f"   Cosine Scheduler: {USE_COSINE_SCHEDULER}")
        print(f"   Early Stopping: {EARLY_STOPPING_PATIENCE} epochs patience" if EARLY_STOPPING_PATIENCE > 0 else "   Early Stopping: DISABLED")
        print(f"   Weighted Loss: {USE_WEIGHTED_LOSS}")
        print("=" * 80)
        print()
        
        # Chạy training
        train(**train_kwargs)
    finally:
        # Dừng periodic sync
        sync_running[0] = False
        
        # Sync cuối cùng
        print("\n📤 Final sync to Google Drive...")
        print(f"   ⚠️  Chỉ sync checkpoint của {MODEL_NAME} (không sync checkpoint của model khác)")
        sync_checkpoint_to_drive()
        print(f"✅ {MODEL_NAME} checkpoints synced to Drive!")

# ============================================
# 🚀 CHẠY CELL NÀY ĐỂ BẮT ĐẦU TRAINING
# ============================================
# Bỏ comment dòng dưới để chạy training:
run_training()

# ============================================
# CELL 9: Xem Checkpoints trên Drive
# ============================================
def list_checkpoints():
    from pathlib import Path
    
    checkpoint_dir = Path(CHECKPOINT_DIR_DRIVE)
    
    if checkpoint_dir.exists():
        checkpoint_files = list(checkpoint_dir.glob("*.pth"))
        history_files = list(checkpoint_dir.glob("*.json"))
        
        if checkpoint_files:
            print("📦 Checkpoints available on Drive:")
            for i, checkpoint_file in enumerate(sorted(checkpoint_files, key=lambda p: p.stat().st_mtime, reverse=True), 1):
                size_mb = checkpoint_file.stat().st_size / (1024 * 1024)
                mtime = checkpoint_file.stat().st_mtime
                from datetime import datetime
                mtime_str = datetime.fromtimestamp(mtime).strftime("%Y-%m-%d %H:%M:%S")
                print(f"   {i}. {checkpoint_file.name} ({size_mb:.2f} MB, {mtime_str})")
        else:
            print("❌ No checkpoint files found on Drive")
        
        if history_files:
            print("\n📊 History files:")
            for history_file in history_files:
                print(f"   - {history_file.name}")
    else:
        print(f"❌ Checkpoint directory not found: {checkpoint_dir}")

# Xem checkpoints
list_checkpoints()

# ============================================
# CELL 10: Download Model từ Drive (Optional)
# ============================================
def download_model_from_drive():
    from google.colab import files
    from pathlib import Path
    
    checkpoint_dir = Path(CHECKPOINT_DIR_DRIVE)
    checkpoint_files = list(checkpoint_dir.glob("*.pth"))
    
    if checkpoint_files:
        print("📦 Models available on Drive:")
        for i, model_file in enumerate(checkpoint_files, 1):
            size_mb = model_file.stat().st_size / (1024 * 1024)
            print(f"   {i}. {model_file.name} ({size_mb:.2f} MB)")
        
        # Tìm best model
        best_model = None
        for model_file in checkpoint_files:
            if 'best' in model_file.name:
                best_model = model_file
                break
        
        if not best_model and checkpoint_files:
            best_model = max(checkpoint_files, key=lambda p: p.stat().st_mtime)
        
        if best_model:
            print(f"\n⬇️  Downloading {best_model.name}...")
            files.download(str(best_model))
            print("✅ Download completed!")
    else:
        print("❌ No model files found on Drive")

# Uncomment để download
# download_model_from_drive()

