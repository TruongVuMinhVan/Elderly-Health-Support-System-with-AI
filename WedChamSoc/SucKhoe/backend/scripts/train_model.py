"""
Training script for skin disease classification
Based on the food recognition code sample
Supports ResNet50, EfficientNet-B6, and Vision Transformer
"""

import torch
import torch.nn as nn
import torch.optim as optim
from torch.utils.data import DataLoader, Dataset
from torchvision import transforms
from torchvision.models import (
    resnet50, ResNet50_Weights,
    efficientnet_b0, EfficientNet_B0_Weights,
    efficientnet_b1, EfficientNet_B1_Weights,
    efficientnet_b2, EfficientNet_B2_Weights,
    efficientnet_b3, EfficientNet_B3_Weights,
    efficientnet_b4, EfficientNet_B4_Weights,
    efficientnet_b5, EfficientNet_B5_Weights,
    efficientnet_b6, EfficientNet_B6_Weights,
    efficientnet_b7, EfficientNet_B7_Weights,
)
import timm
from PIL import Image
import json
import os
import sys
import io
from pathlib import Path
from tqdm import tqdm
import argparse
from datetime import datetime

# Fix encoding for Windows console
if sys.platform == "win32":
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')

# Device configuration
device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
print(f"Using device: {device}")

# Configuration
CONFIG = {
    "batch_size": 32,
    "num_epochs": 50,
    "learning_rate": 0.001,
    "image_size": 224,
    "num_workers": 0 if sys.platform == "win32" else 4,  # Windows: 0, Linux/Mac: 4
    "pin_memory": False,  # Only useful with GPU
    "save_dir": "backend/models",
    "dataset_root": "dataset",
    "label_map_file": "backend/models/label_map.json"
}

# Default configs for different setups
CONFIGS = {
    "default": {
        "dataset_root": "dataset",
        "label_map_file": "backend/models/label_map.json"
    },
    "10classes": {
        "dataset_root": "dataset_10classes",
        "label_map_file": "backend/models/label_map_10classes.json"
    },
    "from_dataset": {
        "dataset_root": "dataset",
        "label_map_file": "backend/models/label_map_from_dataset.json"
    }
}

class SkinDiseaseDataset(Dataset):
    """Dataset class for skin disease images"""
    
    def __init__(self, root_dir, split="train", transform=None, label_map_file=None):
        """
        Args:
            root_dir: Root directory containing train/val/test folders
            split: 'train', 'val', or 'test'
            transform: Optional transform to be applied on a sample
            label_map_file: Path to label map JSON file (if None, uses CONFIG default)
        """
        self.root_dir = Path(root_dir)
        self.split = split
        self.transform = transform
        
        # Load label map
        if label_map_file is None:
            label_map_file = CONFIG["label_map_file"]
        label_map_path = Path(label_map_file)
        if not label_map_path.exists():
            raise FileNotFoundError(f"Label map not found: {label_map_path}")
        
        with open(label_map_path, "r", encoding="utf-8") as f:
            label_data = json.load(f)
        
        self.label_to_idx = label_data["label_to_idx"]
        self.idx_to_label = label_data["idx_to_label"]
        self.num_classes = label_data["num_classes"]
        
        # Load images and labels
        self.images = []
        self.labels = []
        
        split_dir = self.root_dir / split
        image_extensions = {".jpg", ".jpeg", ".png", ".bmp", ".webp"}
        
        for disease_name, class_idx in self.label_to_idx.items():
            disease_dir = split_dir / disease_name
            if not disease_dir.exists():
                continue
            
            for img_file in disease_dir.iterdir():
                if img_file.suffix.lower() in image_extensions:
                    self.images.append(str(img_file))
                    self.labels.append(class_idx)
        
        print(f"📊 Loaded {len(self.images)} images from {split} set")
    
    def __len__(self):
        return len(self.images)
    
    def __getitem__(self, idx):
        img_path = self.images[idx]
        label = self.labels[idx]
        
        # Load image with better error handling
        try:
            # Try to open and verify image
            with Image.open(img_path) as img:
                # Check if image is valid by trying to get a pixel
                img.verify()
            
            # Reopen for actual use (verify() closes the file)
            image = Image.open(img_path).convert("RGB")
        except Exception as e:
            # If image is corrupted, use a black image as fallback
            # This will be filtered out during training if needed
            import warnings
            warnings.warn(f"Skipping corrupted image {img_path}: {e}")
            image = Image.new("RGB", (224, 224))
        
        # Apply transforms
        if self.transform:
            image = self.transform(image)
        
        return image, label


def get_data_transforms(image_size=224, minimal_augmentation=False, strong_augmentation=False):
    """Get data augmentation transforms for training and validation"""
    
    if minimal_augmentation:
        # Minimal augmentation for faster training
        train_transform = transforms.Compose([
            transforms.Resize((image_size, image_size)),
            transforms.RandomHorizontalFlip(p=0.5),
            transforms.ToTensor(),
            transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225])
        ])
    elif strong_augmentation:
        # Strong augmentation (best for reducing overfitting) - Tăng cường mạnh nhất
        train_transform = transforms.Compose([
            transforms.Resize((image_size, image_size)),
            transforms.RandomHorizontalFlip(p=0.5),
            transforms.RandomRotation(45),  # Tăng từ 30 lên 45
            transforms.ColorJitter(brightness=0.4, contrast=0.4, saturation=0.4, hue=0.2),  # Tăng cường
            transforms.RandomAffine(degrees=0, translate=(0.2, 0.2), scale=(0.8, 1.2)),  # Tăng cường
            transforms.RandomResizedCrop(image_size, scale=(0.8, 1.0)),  # Thêm RandomResizedCrop
            transforms.ToTensor(),
            transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225]),
            transforms.RandomErasing(p=0.2, scale=(0.02, 0.1), ratio=(0.3, 3.3), value=0, inplace=False)  # RandomErasing phải sau ToTensor()
        ])
    else:
        # Full augmentation (better accuracy, slower) - Tăng cường để giảm overfitting
        train_transform = transforms.Compose([
            transforms.Resize((image_size, image_size)),
            transforms.RandomHorizontalFlip(p=0.5),
            transforms.RandomRotation(30),  # Tăng từ 15 lên 30
            transforms.ColorJitter(brightness=0.3, contrast=0.3, saturation=0.3, hue=0.15),  # Tăng cường
            transforms.RandomAffine(degrees=0, translate=(0.15, 0.15)),  # Tăng từ 0.1
            transforms.ToTensor(),
            transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225])
        ])
    
    val_transform = transforms.Compose([
        transforms.Resize((image_size, image_size)),
        transforms.ToTensor(),
        transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225])
    ])
    
    return train_transform, val_transform


def create_model(model_name="resnet50", num_classes=61, pretrained=True, dropout_rate=0.8):
    """Create and return a model
    
    Supported models:
    - resnet50: ResNet-50 (fast, good accuracy)
    - efficientnet_b0 to b7: EfficientNet variants (b0 fastest, b7 most accurate)
    - vit: Vision Transformer Base (good accuracy, slower)
    - vit_small: ViT Small (faster than base)
    - vit_large: ViT Large (best accuracy, slowest)
    
    Args:
        dropout_rate: Dropout rate for classifier layers (default: 0.8 for better regularization)
    """
    
    model_name_lower = model_name.lower()
    
    # ResNet50
    if model_name_lower == "resnet50":
        model = resnet50(weights=ResNet50_Weights.IMAGENET1K_V2 if pretrained else None)
        model.fc = nn.Sequential(
            nn.Linear(model.fc.in_features, 512),
            nn.ReLU(),
            nn.Dropout(dropout_rate),  # Tăng lên 0.8 để giảm overfitting mạnh hơn
            nn.Linear(512, num_classes)
        )
    
    # EfficientNet variants
    elif model_name_lower == "efficientnet_b0":
        model = efficientnet_b0(weights=EfficientNet_B0_Weights.IMAGENET1K_V1 if pretrained else None)
        in_features = model.classifier[1].in_features
        model.classifier = nn.Sequential(
            nn.Linear(in_features, 512),
            nn.ReLU(),
            nn.Dropout(dropout_rate),  # Sử dụng parameter để dễ điều chỉnh
            nn.Linear(512, num_classes)
        )
    elif model_name_lower == "efficientnet_b1":
        model = efficientnet_b1(weights=EfficientNet_B1_Weights.IMAGENET1K_V2 if pretrained else None)
        in_features = model.classifier[1].in_features
        model.classifier = nn.Sequential(
            nn.Linear(in_features, 512),
            nn.ReLU(),
            nn.Dropout(dropout_rate),  # Sử dụng parameter để dễ điều chỉnh
            nn.Linear(512, num_classes)
        )
    elif model_name_lower == "efficientnet_b2":
        model = efficientnet_b2(weights=EfficientNet_B2_Weights.IMAGENET1K_V1 if pretrained else None)
        in_features = model.classifier[1].in_features
        model.classifier = nn.Sequential(
            nn.Linear(in_features, 512),
            nn.ReLU(),
            nn.Dropout(dropout_rate),  # Sử dụng parameter để dễ điều chỉnh
            nn.Linear(512, num_classes)
        )
    elif model_name_lower == "efficientnet_b3":
        model = efficientnet_b3(weights=EfficientNet_B3_Weights.IMAGENET1K_V1 if pretrained else None)
        in_features = model.classifier[1].in_features
        model.classifier = nn.Sequential(
            nn.Linear(in_features, 512),
            nn.ReLU(),
            nn.Dropout(dropout_rate),  # Sử dụng parameter để dễ điều chỉnh
            nn.Linear(512, num_classes)
        )
    elif model_name_lower == "efficientnet_b4":
        model = efficientnet_b4(weights=EfficientNet_B4_Weights.IMAGENET1K_V1 if pretrained else None)
        in_features = model.classifier[1].in_features
        model.classifier = nn.Sequential(
            nn.Linear(in_features, 512),
            nn.ReLU(),
            nn.Dropout(dropout_rate),  # Sử dụng parameter để dễ điều chỉnh
            nn.Linear(512, num_classes)
        )
    elif model_name_lower == "efficientnet_b5":
        model = efficientnet_b5(weights=EfficientNet_B5_Weights.IMAGENET1K_V1 if pretrained else None)
        in_features = model.classifier[1].in_features
        model.classifier = nn.Sequential(
            nn.Linear(in_features, 512),
            nn.ReLU(),
            nn.Dropout(dropout_rate),  # Sử dụng parameter để dễ điều chỉnh
            nn.Linear(512, num_classes)
        )
    elif model_name_lower == "efficientnet_b6":
        model = efficientnet_b6(weights=EfficientNet_B6_Weights.IMAGENET1K_V1 if pretrained else None)
        in_features = model.classifier[1].in_features
        model.classifier = nn.Sequential(
            nn.Linear(in_features, 512),
            nn.ReLU(),
            nn.Dropout(dropout_rate),  # Sử dụng parameter để dễ điều chỉnh
            nn.Linear(512, num_classes)
        )
    elif model_name_lower == "efficientnet_b7":
        model = efficientnet_b7(weights=EfficientNet_B7_Weights.IMAGENET1K_V1 if pretrained else None)
        in_features = model.classifier[1].in_features
        model.classifier = nn.Sequential(
            nn.Linear(in_features, 512),
            nn.ReLU(),
            nn.Dropout(dropout_rate),  # Sử dụng parameter để dễ điều chỉnh
            nn.Linear(512, num_classes)
        )
    
    # Vision Transformer variants
    elif model_name_lower == "vit" or model_name_lower == "vit_base":
        model = timm.create_model('vit_base_patch16_224', pretrained=pretrained)
        model.head = nn.Sequential(
            nn.Linear(model.head.in_features, 512),
            nn.ReLU(),
            nn.Dropout(dropout_rate),  # Sử dụng parameter để dễ điều chỉnh
            nn.Linear(512, num_classes)
        )
    elif model_name_lower == "vit_small":
        model = timm.create_model('vit_small_patch16_224', pretrained=pretrained)
        model.head = nn.Sequential(
            nn.Linear(model.head.in_features, 512),
            nn.ReLU(),
            nn.Dropout(dropout_rate),  # Sử dụng parameter để dễ điều chỉnh
            nn.Linear(512, num_classes)
        )
    elif model_name_lower == "vit_large":
        model = timm.create_model('vit_large_patch16_224', pretrained=pretrained)
        model.head = nn.Sequential(
            nn.Linear(model.head.in_features, 512),
            nn.ReLU(),
            nn.Dropout(dropout_rate),  # Sử dụng parameter để dễ điều chỉnh
            nn.Linear(512, num_classes)
        )
    
    else:
        raise ValueError(
            f"Unknown model: {model_name}\n"
            f"Supported models: resnet50, efficientnet_b0-b7, vit, vit_small, vit_large"
        )
    
    return model.to(device)


def train_epoch(model, dataloader, criterion, optimizer, epoch, verbose=False, gradient_accumulation_steps=1):
    """Train for one epoch with memory optimization"""
    model.train()
    running_loss = 0.0
    correct = 0
    total = 0
    
    optimizer.zero_grad()  # Zero grad at the start
    
    pbar = tqdm(dataloader, desc=f"Epoch {epoch} [Train]", disable=not verbose)
    for batch_idx, (images, labels) in enumerate(pbar):
        images = images.to(device, non_blocking=True)
        labels = labels.to(device, non_blocking=True)
        
        # Forward pass
        outputs = model(images)
        loss = criterion(outputs, labels)
        
        # Scale loss for gradient accumulation
        loss = loss / gradient_accumulation_steps
        
        # Backward pass
        loss.backward()
        
        # Update weights only after accumulating gradients
        if (batch_idx + 1) % gradient_accumulation_steps == 0:
            optimizer.step()
            optimizer.zero_grad()
        
        # Statistics (use original loss value for display)
        loss_value = loss.item() * gradient_accumulation_steps
        running_loss += loss_value
        _, predicted = torch.max(outputs.data, 1)
        total += labels.size(0)
        correct += (predicted == labels).sum().item()
        
        # Clear variables to free memory
        del images, labels, outputs, loss
        
        # Update progress bar
        if verbose:
            pbar.set_postfix({
                "loss": f"{loss_value:.4f}",
                "acc": f"{100 * correct / total:.2f}%",
                "batch": f"{batch_idx + 1}/{len(dataloader)}"
            })
    
    # Handle remaining gradients
    if len(dataloader) % gradient_accumulation_steps != 0:
        optimizer.step()
        optimizer.zero_grad()
    
    # Clear cache periodically
    if torch.cuda.is_available():
        torch.cuda.empty_cache()
    
    epoch_loss = running_loss / len(dataloader)
    epoch_acc = 100 * correct / total
    
    return epoch_loss, epoch_acc


def validate(model, dataloader, criterion, verbose=False):
    """Validate the model with memory optimization"""
    model.eval()
    running_loss = 0.0
    correct = 0
    total = 0
    
    # Handle empty dataloader
    if len(dataloader) == 0:
        if verbose:
            print("⚠️  Validation dataloader is empty, returning default values")
        return 0.0, 0.0
    
    with torch.no_grad():
        pbar = tqdm(dataloader, desc="Validation", disable=not verbose)
        for batch_idx, (images, labels) in enumerate(pbar):
            images = images.to(device, non_blocking=True)
            labels = labels.to(device, non_blocking=True)
            
            outputs = model(images)
            loss = criterion(outputs, labels)
            
            # Save loss value before deleting
            loss_value = loss.item()
            
            running_loss += loss_value
            _, predicted = torch.max(outputs.data, 1)
            total += labels.size(0)
            correct += (predicted == labels).sum().item()
            
            # Update progress bar before clearing
            if verbose:
                pbar.set_postfix({
                    "loss": f"{loss_value:.4f}",
                    "acc": f"{100 * correct / total:.2f}%",
                    "batch": f"{batch_idx + 1}/{len(dataloader)}"
                })
            
            # Clear variables to free memory
            del images, labels, outputs, loss
    
    # Clear cache
    if torch.cuda.is_available():
        torch.cuda.empty_cache()
    
    # Avoid division by zero
    if len(dataloader) == 0 or total == 0:
        return 0.0, 0.0
    
    epoch_loss = running_loss / len(dataloader)
    epoch_acc = 100 * correct / total if total > 0 else 0.0
    
    return epoch_loss, epoch_acc


def train(model_name="resnet50", resume_from=None, config_name="default", verbose=True, gradient_accumulation_steps=1, freeze_backbone_epochs=0, early_stopping_patience=15, dropout_rate=0.8, weight_decay=1e-4, use_label_smoothing=False, label_smoothing=0.1, strong_augmentation=False):
    """Main training function with memory optimization
    
    Args:
        model_name: Model architecture name
        resume_from: Path to checkpoint to resume from
        config_name: Configuration preset name
        verbose: Whether to show detailed progress
        gradient_accumulation_steps: Number of steps to accumulate gradients before updating weights
                                     (effectively increases batch size without using more memory)
        freeze_backbone_epochs: Number of epochs to freeze backbone (0 = no freezing)
        early_stopping_patience: Number of epochs to wait before early stopping (0 = disabled)
        dropout_rate: Dropout rate for classifier layers (default: 0.8)
        weight_decay: Weight decay for optimizer (default: 1e-4)
        use_label_smoothing: Whether to use label smoothing (default: False)
        label_smoothing: Label smoothing factor (default: 0.1)
        strong_augmentation: Whether to use strong data augmentation (default: False)
    """
    
    # Use config based on config_name
    if config_name in CONFIGS:
        current_config = {**CONFIG, **CONFIGS[config_name]}
    else:
        current_config = CONFIG
    
    print("=" * 80)
    print(f"🚀 TRAINING SKIN DISEASE CLASSIFICATION MODEL")
    print(f"   Model: {model_name.upper()}")
    print(f"   Config: {config_name}")
    if gradient_accumulation_steps > 1:
        print(f"   Gradient Accumulation: {gradient_accumulation_steps} steps")
        print(f"   Effective Batch Size: {current_config['batch_size'] * gradient_accumulation_steps}")
    print("=" * 80)
    
    # Load label map to get num_classes
    with open(current_config["label_map_file"], "r", encoding="utf-8") as f:
        label_data = json.load(f)
    num_classes = label_data["num_classes"]
    
    print(f"📊 Number of classes: {num_classes}")
    print(f"📁 Dataset: {current_config['dataset_root']}")
    print(f"📄 Label map: {current_config['label_map_file']}")
    
    # Create datasets
    minimal_aug = current_config.get("minimal_augmentation", False)
    strong_aug = current_config.get("strong_augmentation", False) or strong_augmentation
    train_transform, val_transform = get_data_transforms(
        current_config["image_size"], 
        minimal_augmentation=minimal_aug,
        strong_augmentation=strong_aug
    )
    
    train_dataset = SkinDiseaseDataset(
        current_config["dataset_root"],
        split="train",
        transform=train_transform,
        label_map_file=current_config["label_map_file"]
    )
    # Try to load validation set, fallback to train set if val doesn't exist
    try:
        val_dataset = SkinDiseaseDataset(
            current_config["dataset_root"],
            split="val",
            transform=val_transform,
            label_map_file=current_config["label_map_file"]
        )
        if len(val_dataset) == 0:
            if verbose:
                print("⚠️  Validation set is empty, using test set instead")
            try:
                val_dataset = SkinDiseaseDataset(
                    current_config["dataset_root"],
                    split="test",
                    transform=val_transform,
                    label_map_file=current_config["label_map_file"]
                )
                if len(val_dataset) == 0:
                    if verbose:
                        print("⚠️  Test set also empty, using train set for validation (20% split)")
                    # Use 20% of train set as validation
                    train_size = int(0.8 * len(train_dataset))
                    val_size = len(train_dataset) - train_size
                    train_dataset, val_dataset = torch.utils.data.random_split(
                        train_dataset, [train_size, val_size]
                    )
            except:
                if verbose:
                    print("⚠️  Test set not found, using train set for validation (20% split)")
                train_size = int(0.8 * len(train_dataset))
                val_size = len(train_dataset) - train_size
                train_dataset, val_dataset = torch.utils.data.random_split(
                    train_dataset, [train_size, val_size]
                )
    except Exception as e:
        if verbose:
            print(f"⚠️  Error loading validation set: {e}")
            print("   Using train set for validation (20% split)")
        train_size = int(0.8 * len(train_dataset))
        val_size = len(train_dataset) - train_size
        train_dataset, val_dataset = torch.utils.data.random_split(
            train_dataset, [train_size, val_size]
        )
    
    # Create data loaders with memory optimization
    # Optimize for CPU (especially Windows)
    pin_memory = current_config.get("pin_memory", False) and torch.cuda.is_available()
    
    # Memory optimization: reduce prefetch and persistent workers
    train_loader = DataLoader(
        train_dataset,
        batch_size=current_config["batch_size"],
        shuffle=True,
        num_workers=current_config["num_workers"],
        pin_memory=pin_memory,
        persistent_workers=False,  # Don't keep workers alive (saves memory)
        prefetch_factor=2 if current_config["num_workers"] > 0 else None,  # Reduce prefetch
        drop_last=False  # Don't drop last batch to use all data
    )
    
    val_loader = DataLoader(
        val_dataset,
        batch_size=current_config["batch_size"],
        shuffle=False,
        num_workers=current_config["num_workers"],
        pin_memory=pin_memory,
        persistent_workers=False,
        prefetch_factor=2 if current_config["num_workers"] > 0 else None,
        drop_last=False
    )
    
    if verbose:
        print(f"📦 DataLoader created:")
        print(f"   Train batches: {len(train_loader)}")
        print(f"   Val batches: {len(val_loader)}")
        print(f"   Batch size: {current_config['batch_size']}")
        if gradient_accumulation_steps > 1:
            print(f"   Effective batch size: {current_config['batch_size'] * gradient_accumulation_steps}")
    
    # Create model
    dropout = current_config.get("dropout_rate", dropout_rate)
    model = create_model(model_name, num_classes, pretrained=not resume_from, dropout_rate=dropout)
    
    # Freeze backbone if specified (for fine-tuning strategy)
    if freeze_backbone_epochs > 0:
        # Freeze all layers except classifier
        for name, param in model.named_parameters():
            if 'fc' not in name and 'classifier' not in name and 'head' not in name:
                param.requires_grad = False
        if verbose:
            print(f"🔒 Freezing backbone for first {freeze_backbone_epochs} epochs")
    
    if verbose:
        total_params = sum(p.numel() for p in model.parameters())
        trainable_params = sum(p.numel() for p in model.parameters() if p.requires_grad)
        print(f"✅ Model created: {model_name}")
        print(f"   Total parameters: {total_params:,}")
        print(f"   Trainable parameters: {trainable_params:,}")
        
        # Show memory usage if CUDA available
        if torch.cuda.is_available():
            print(f"   GPU: {torch.cuda.get_device_name(0)}")
            print(f"   GPU Memory: {torch.cuda.get_device_properties(0).total_memory / 1024**3:.2f} GB")
    
    # Calculate class weights for imbalanced dataset
    use_weighted_loss = current_config.get("use_weighted_loss", False)
    class_weights = None
    
    if use_weighted_loss:
        # Count images per class in training set
        from collections import Counter
        class_counts = Counter(train_dataset.labels)
        total_samples = sum(class_counts.values())
        
        # Calculate weights: inverse frequency
        # Weight = total_samples / (num_classes * count_per_class)
        class_weights = torch.zeros(num_classes, device=device)
        for class_idx, count in class_counts.items():
            if count > 0:
                class_weights[class_idx] = total_samples / (num_classes * count)
        
        print(f"📊 Using weighted loss to handle class imbalance")
        print(f"   Class weights: min={class_weights.min():.2f}, max={class_weights.max():.2f}, mean={class_weights.mean():.2f}")
    
    # Loss and optimizer
    use_label_smooth = current_config.get("use_label_smoothing", use_label_smoothing)
    label_smooth = current_config.get("label_smoothing", label_smoothing)
    weight_decay_val = current_config.get("weight_decay", weight_decay)
    
    if use_label_smooth:
        # Label smoothing helps reduce overfitting
        if class_weights is not None:
            # Note: CrossEntropyLoss with label_smoothing doesn't support class_weights directly
            # We'll use label smoothing without weights for now
            criterion = nn.CrossEntropyLoss(label_smoothing=label_smooth)
            if verbose:
                print(f"📊 Using label smoothing (factor={label_smooth}) - class weights disabled")
        else:
            criterion = nn.CrossEntropyLoss(label_smoothing=label_smooth)
            if verbose:
                print(f"📊 Using label smoothing (factor={label_smooth})")
    elif class_weights is not None:
        criterion = nn.CrossEntropyLoss(weight=class_weights)
    else:
        criterion = nn.CrossEntropyLoss()
    
    optimizer = optim.AdamW(model.parameters(), lr=current_config["learning_rate"], weight_decay=weight_decay_val)
    if verbose:
        print(f"📊 Optimizer: AdamW with weight_decay={weight_decay_val}")
    
    # Better scheduler: CosineAnnealingLR for better convergence
    # Note: Scheduler will be recreated after loading checkpoint if resuming
    use_cosine_scheduler = current_config.get("use_cosine_scheduler", False)
    # Get min_lr from config (default to 1e-6 for CosineAnnealingLR, 1e-5 for ReduceLROnPlateau)
    min_lr = current_config.get("min_lr", 1e-6 if use_cosine_scheduler else 1e-5)
    
    if use_cosine_scheduler:
        # CosineAnnealingLR: gradually decrease LR following cosine curve
        # T_max will be adjusted after loading checkpoint if resuming
        scheduler = optim.lr_scheduler.CosineAnnealingLR(
            optimizer, T_max=current_config["num_epochs"], eta_min=min_lr
        )
        if verbose:
            print(f"📉 Using CosineAnnealingLR scheduler (T_max={current_config['num_epochs']}, eta_min={min_lr})")
    else:
        # ReduceLROnPlateau: reduce LR when validation accuracy plateaus
        scheduler = optim.lr_scheduler.ReduceLROnPlateau(
            optimizer, mode='max', factor=0.5, patience=7, min_lr=min_lr
        )
        if verbose:
            print(f"📉 Using ReduceLROnPlateau scheduler (patience=7, factor=0.5, min_lr={min_lr})")
    
    # Early stopping setup
    if early_stopping_patience > 0:
        if verbose:
            print(f"⏹️  Early stopping enabled (patience={early_stopping_patience} epochs)")
    
    # Training setup
    save_dir = Path(current_config["save_dir"])
    save_dir.mkdir(parents=True, exist_ok=True)
    
    # Training history
    history = {
        "train_loss": [],
        "train_acc": [],
        "val_loss": [],
        "val_acc": []
    }
    
    best_val_acc = 0.0
    start_epoch = 1
    patience_counter = 0  # For early stopping
    
    # Load checkpoint if resuming
    if resume_from:
        checkpoint_path = Path(resume_from)
        if checkpoint_path.exists() and checkpoint_path.suffix == ".pth":
            # Try to load as full checkpoint (with optimizer, scheduler, etc.)
            try:
                # Try loading with weights_only=False first (full checkpoint)
                try:
                    checkpoint = torch.load(checkpoint_path, map_location=device, weights_only=False)
                except TypeError:
                    # Older PyTorch versions don't have weights_only parameter
                    checkpoint = torch.load(checkpoint_path, map_location=device)
                
                if isinstance(checkpoint, dict) and "epoch" in checkpoint:
                    # Full checkpoint
                    checkpoint_epoch = checkpoint["epoch"]
                    start_epoch = checkpoint_epoch + 1
                    best_val_acc = checkpoint.get("best_val_acc", 0.0)
                    history = checkpoint.get("history", history)
                    
                    # Adjust num_epochs to train additional epochs from resume point
                    # If resuming, we want to train for (num_epochs) more epochs
                    # So total epochs = start_epoch + num_epochs - 1
                    original_num_epochs = current_config["num_epochs"]
                    if start_epoch > 1:
                        # Resume mode: train additional epochs
                        # num_epochs should be start_epoch + additional_epochs
                        current_config["num_epochs"] = start_epoch + original_num_epochs - 1
                        if verbose:
                            print(f"   📊 Adjusted num_epochs: {original_num_epochs} -> {current_config['num_epochs']} (will train {original_num_epochs} more epochs)")
                    
                    # Load model state
                    model.load_state_dict(checkpoint["model_state_dict"])
                    
                    # Try to load optimizer and scheduler (may fail if config changed)
                    try:
                        optimizer.load_state_dict(checkpoint["optimizer_state_dict"])
                        # Recreate scheduler with adjusted T_max for remaining epochs
                        if use_cosine_scheduler:
                            remaining_epochs = current_config["num_epochs"] - start_epoch + 1
                            scheduler = optim.lr_scheduler.CosineAnnealingLR(
                                optimizer, T_max=remaining_epochs, eta_min=min_lr
                            )
                            if verbose:
                                print(f"   📉 Recreated CosineAnnealingLR scheduler (T_max={remaining_epochs} for remaining epochs)")
                        else:
                            scheduler.load_state_dict(checkpoint["scheduler_state_dict"])
                        print(f"✅ Resumed from epoch {checkpoint_epoch} (full checkpoint)")
                    except:
                        print(f"⚠️  Optimizer/scheduler state mismatch, resetting them")
                        # Recreate scheduler with adjusted T_max
                        if use_cosine_scheduler:
                            remaining_epochs = current_config["num_epochs"] - start_epoch + 1
                            scheduler = optim.lr_scheduler.CosineAnnealingLR(
                                optimizer, T_max=remaining_epochs, eta_min=min_lr
                            )
                            if verbose:
                                print(f"   📉 Recreated CosineAnnealingLR scheduler (T_max={remaining_epochs} for remaining epochs)")
                        print(f"✅ Resumed from epoch {checkpoint_epoch} (model only)")
                    print(f"   Best val acc so far: {best_val_acc:.2f}%")
                else:
                    # Only model weights (old format)
                    try:
                        model.load_state_dict(checkpoint)
                        print(f"⚠️  Loaded model weights only (optimizer/scheduler reset)")
                    except Exception as e2:
                        print(f"⚠️  Error loading model weights: {e2}")
                        print("   Starting from scratch...")
            except Exception as e:
                print(f"⚠️  Error loading checkpoint: {e}")
                print(f"   Checkpoint file may be corrupted: {checkpoint_path}")
                print("   Starting from scratch...")
    
    # Training loop
    print("\n" + "=" * 80)
    print("🎯 STARTING TRAINING")
    if start_epoch > 1:
        print(f"   Resuming from epoch {start_epoch}")
    print("=" * 80)
    
    # Memory monitoring
    def get_memory_info():
        if torch.cuda.is_available():
            allocated = torch.cuda.memory_allocated(0) / 1024**3
            reserved = torch.cuda.memory_reserved(0) / 1024**3
            return f"GPU: {allocated:.2f}GB allocated, {reserved:.2f}GB reserved"
        return "CPU mode"
    
    for epoch in range(start_epoch, current_config["num_epochs"] + 1):
        if verbose:
            print(f"\n📅 Epoch {epoch}/{current_config['num_epochs']}")
            print(f"   {get_memory_info()}")
        else:
            print(f"\n📅 Epoch {epoch}/{current_config['num_epochs']}")
        
        # Unfreeze backbone after freeze_backbone_epochs
        if freeze_backbone_epochs > 0 and epoch == freeze_backbone_epochs + 1:
            for name, param in model.named_parameters():
                param.requires_grad = True
            if verbose:
                print(f"🔓 Unfreezing all layers for fine-tuning")
        
        # Clear cache before epoch
        if torch.cuda.is_available():
            torch.cuda.empty_cache()
        
        # Train
        train_loss, train_acc = train_epoch(
            model, train_loader, criterion, optimizer, epoch, 
            verbose=verbose, 
            gradient_accumulation_steps=gradient_accumulation_steps
        )
        
        # Clear cache after training
        if torch.cuda.is_available():
            torch.cuda.empty_cache()
        
        # Validate
        val_loss, val_acc = validate(model, val_loader, criterion, verbose=verbose)
        
        # Clear cache after validation
        if torch.cuda.is_available():
            torch.cuda.empty_cache()
        
        # Update learning rate
        current_lr = optimizer.param_groups[0]['lr']
        if isinstance(scheduler, optim.lr_scheduler.ReduceLROnPlateau):
            scheduler.step(val_acc)  # ReduceLROnPlateau needs metric
        else:
            scheduler.step()  # CosineAnnealingLR doesn't need metric
        new_lr = optimizer.param_groups[0]['lr']
        
        if verbose and current_lr != new_lr:
            print(f"   📉 Learning rate changed: {current_lr:.6f} -> {new_lr:.6f}")
        
        # Save history
        history["train_loss"].append(train_loss)
        history["train_acc"].append(train_acc)
        history["val_loss"].append(val_loss)
        history["val_acc"].append(val_acc)
        
        # Save best model and handle early stopping
        if val_acc > best_val_acc:
            best_val_acc = val_acc
            patience_counter = 0  # Reset patience counter
            model_path = save_dir / f"{model_name}_best.pth"
            torch.save(model.state_dict(), model_path)
            print(f"💾 Saved best model (val_acc: {val_acc:.2f}%) to {model_path}")
            
            # Also save best model as full checkpoint for resume
            best_checkpoint_path = save_dir / f"{model_name}_best_checkpoint.pth"
            full_checkpoint = {
                "epoch": epoch,
                "model_state_dict": model.state_dict(),
                "optimizer_state_dict": optimizer.state_dict(),
                "scheduler_state_dict": scheduler.state_dict(),
                "best_val_acc": best_val_acc,
                "history": history,
                "config": current_config,
                "model_name": model_name
            }
            torch.save(full_checkpoint, best_checkpoint_path)
        else:
            # Validation accuracy didn't improve
            if early_stopping_patience > 0:
                patience_counter += 1
                if verbose:
                    print(f"   ⚠️  No improvement for {patience_counter}/{early_stopping_patience} epochs")
        
        # Early stopping check
        if early_stopping_patience > 0 and patience_counter >= early_stopping_patience:
            print(f"\n⏹️  Early stopping triggered at epoch {epoch}")
            print(f"   Best validation accuracy: {best_val_acc:.2f}%")
            print(f"   Stopped after {patience_counter} epochs without improvement")
            break
        
        # Save full checkpoint every 5 epochs (includes optimizer, scheduler, history)
        if epoch % 5 == 0:
            checkpoint_path = save_dir / f"{model_name}_checkpoint_epoch_{epoch}.pth"
            full_checkpoint = {
                "epoch": epoch,
                "model_state_dict": model.state_dict(),
                "optimizer_state_dict": optimizer.state_dict(),
                "scheduler_state_dict": scheduler.state_dict(),
                "best_val_acc": best_val_acc,
                "history": history,
                "config": current_config,
                "model_name": model_name
            }
            torch.save(full_checkpoint, checkpoint_path)
            print(f"💾 Saved full checkpoint (epoch {epoch}) to {checkpoint_path}")
        
        # Also save lightweight checkpoint every 10 epochs (model only, for compatibility)
        if epoch % 10 == 0:
            lightweight_path = save_dir / f"{model_name}_epoch_{epoch}.pth"
            torch.save(model.state_dict(), lightweight_path)
        
        if verbose:
            print(f"   Train Loss: {train_loss:.4f}, Train Acc: {train_acc:.2f}%")
            print(f"   Val Loss: {val_loss:.4f}, Val Acc: {val_acc:.2f}%")
            print(f"   Learning Rate: {optimizer.param_groups[0]['lr']:.6f}")
            print(f"   {get_memory_info()}")
        else:
            print(f"   Train Loss: {train_loss:.4f}, Train Acc: {train_acc:.2f}%")
            print(f"   Val Loss: {val_loss:.4f}, Val Acc: {val_acc:.2f}%")
    
    # Save final model
    final_model_path = save_dir / f"{model_name}_final.pth"
    torch.save(model.state_dict(), final_model_path)
    print(f"\n💾 Saved final model to {final_model_path}")
    
    # Save training history
    history_path = save_dir / f"{model_name}_history.json"
    with open(history_path, "w") as f:
        json.dump(history, f, indent=2)
    print(f"💾 Saved training history to {history_path}")
    
    print("\n" + "=" * 80)
    print("✅ TRAINING COMPLETED")
    print(f"   Best validation accuracy: {best_val_acc:.2f}%")
    print("=" * 80)
    
    return model, history


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Train skin disease classification model")
    parser.add_argument("--model", type=str, default="resnet50",
                       choices=[
                           "resnet50",
                           "efficientnet_b0", "efficientnet_b1", "efficientnet_b2", "efficientnet_b3",
                           "efficientnet_b4", "efficientnet_b5", "efficientnet_b6", "efficientnet_b7",
                           "vit", "vit_base", "vit_small", "vit_large"
                       ],
                       help="Model architecture. "
                            "ResNet50: fast, good accuracy. "
                            "EfficientNet: b0 (fastest) to b7 (most accurate). "
                            "ViT: vit_small (fast), vit_base (balanced), vit_large (best accuracy)")
    parser.add_argument("--resume", type=str, default=None,
                       help="Path to checkpoint to resume from")
    parser.add_argument("--batch-size", type=int, default=32,
                       help="Batch size for training")
    parser.add_argument("--epochs", type=int, default=50,
                       help="Number of training epochs")
    parser.add_argument("--lr", type=float, default=0.001,
                       help="Learning rate")
    parser.add_argument("--config", type=str, default="from_dataset",
                       choices=["default", "10classes", "from_dataset"],
                       help="Configuration preset (default: from_dataset)")
    parser.add_argument("--minimal-aug", action="store_true",
                       help="Use minimal data augmentation (faster training)")
    parser.add_argument("--weighted-loss", action="store_true",
                       help="Use weighted loss to handle class imbalance")
    parser.add_argument("--verbose", action="store_true", default=True,
                       help="Show detailed progress (default: True)")
    parser.add_argument("--no-verbose", dest="verbose", action="store_false",
                       help="Disable verbose output")
    parser.add_argument("--gradient-accumulation", type=int, default=1,
                       help="Number of gradient accumulation steps (default: 1). "
                            "Useful for simulating larger batch sizes without using more memory")
    parser.add_argument("--freeze-backbone", type=int, default=0,
                       help="Number of epochs to freeze backbone (default: 0). "
                            "Useful for fine-tuning: freeze first N epochs, then unfreeze")
    parser.add_argument("--cosine-scheduler", action="store_true",
                       help="Use CosineAnnealingLR instead of ReduceLROnPlateau")
    parser.add_argument("--early-stopping", type=int, default=15,
                       help="Early stopping patience (default: 15). Set to 0 to disable early stopping")
    
    args = parser.parse_args()
    
    # Update config from args
    CONFIG["batch_size"] = args.batch_size
    CONFIG["num_epochs"] = args.epochs
    CONFIG["learning_rate"] = args.lr
    CONFIG["minimal_augmentation"] = args.minimal_aug
    CONFIG["use_weighted_loss"] = args.weighted_loss
    CONFIG["use_cosine_scheduler"] = args.cosine_scheduler
    
    # Validate gradient accumulation
    if args.gradient_accumulation < 1:
        print("⚠️  gradient_accumulation must be >= 1, setting to 1")
        args.gradient_accumulation = 1
    
    train(
        args.model, 
        args.resume, 
        config_name=args.config,
        verbose=args.verbose,
        gradient_accumulation_steps=args.gradient_accumulation,
        freeze_backbone_epochs=args.freeze_backbone,
        early_stopping_patience=args.early_stopping
    )

