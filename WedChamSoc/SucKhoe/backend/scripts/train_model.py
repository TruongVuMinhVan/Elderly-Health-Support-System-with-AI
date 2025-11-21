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
        
        # Load image
        try:
            image = Image.open(img_path).convert("RGB")
        except Exception as e:
            print(f"⚠️  Error loading {img_path}: {e}")
            # Return a black image as fallback
            image = Image.new("RGB", (224, 224))
        
        # Apply transforms
        if self.transform:
            image = self.transform(image)
        
        return image, label


def get_data_transforms(image_size=224, minimal_augmentation=False):
    """Get data augmentation transforms for training and validation"""
    
    if minimal_augmentation:
        # Minimal augmentation for faster training
        train_transform = transforms.Compose([
            transforms.Resize((image_size, image_size)),
            transforms.RandomHorizontalFlip(p=0.5),
            transforms.ToTensor(),
            transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225])
        ])
    else:
        # Full augmentation (better accuracy, slower)
        train_transform = transforms.Compose([
            transforms.Resize((image_size, image_size)),
            transforms.RandomHorizontalFlip(p=0.5),
            transforms.RandomRotation(15),
            transforms.ColorJitter(brightness=0.2, contrast=0.2, saturation=0.2, hue=0.1),
            transforms.RandomAffine(degrees=0, translate=(0.1, 0.1)),
            transforms.ToTensor(),
            transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225])
        ])
    
    val_transform = transforms.Compose([
        transforms.Resize((image_size, image_size)),
        transforms.ToTensor(),
        transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225])
    ])
    
    return train_transform, val_transform


def create_model(model_name="resnet50", num_classes=61, pretrained=True):
    """Create and return a model
    
    Supported models:
    - resnet50: ResNet-50 (fast, good accuracy)
    - efficientnet_b0 to b7: EfficientNet variants (b0 fastest, b7 most accurate)
    - vit: Vision Transformer Base (good accuracy, slower)
    - vit_small: ViT Small (faster than base)
    - vit_large: ViT Large (best accuracy, slowest)
    """
    
    model_name_lower = model_name.lower()
    
    # ResNet50
    if model_name_lower == "resnet50":
        model = resnet50(weights=ResNet50_Weights.IMAGENET1K_V2 if pretrained else None)
        model.fc = nn.Sequential(
            nn.Linear(model.fc.in_features, 512),
            nn.ReLU(),
            nn.Dropout(0.5),
            nn.Linear(512, num_classes)
        )
    
    # EfficientNet variants
    elif model_name_lower == "efficientnet_b0":
        model = efficientnet_b0(weights=EfficientNet_B0_Weights.IMAGENET1K_V1 if pretrained else None)
        in_features = model.classifier[1].in_features
        model.classifier = nn.Sequential(
            nn.Linear(in_features, 512),
            nn.ReLU(),
            nn.Dropout(0.5),
            nn.Linear(512, num_classes)
        )
    elif model_name_lower == "efficientnet_b1":
        model = efficientnet_b1(weights=EfficientNet_B1_Weights.IMAGENET1K_V2 if pretrained else None)
        in_features = model.classifier[1].in_features
        model.classifier = nn.Sequential(
            nn.Linear(in_features, 512),
            nn.ReLU(),
            nn.Dropout(0.5),
            nn.Linear(512, num_classes)
        )
    elif model_name_lower == "efficientnet_b2":
        model = efficientnet_b2(weights=EfficientNet_B2_Weights.IMAGENET1K_V1 if pretrained else None)
        in_features = model.classifier[1].in_features
        model.classifier = nn.Sequential(
            nn.Linear(in_features, 512),
            nn.ReLU(),
            nn.Dropout(0.5),
            nn.Linear(512, num_classes)
        )
    elif model_name_lower == "efficientnet_b3":
        model = efficientnet_b3(weights=EfficientNet_B3_Weights.IMAGENET1K_V1 if pretrained else None)
        in_features = model.classifier[1].in_features
        model.classifier = nn.Sequential(
            nn.Linear(in_features, 512),
            nn.ReLU(),
            nn.Dropout(0.5),
            nn.Linear(512, num_classes)
        )
    elif model_name_lower == "efficientnet_b4":
        model = efficientnet_b4(weights=EfficientNet_B4_Weights.IMAGENET1K_V1 if pretrained else None)
        in_features = model.classifier[1].in_features
        model.classifier = nn.Sequential(
            nn.Linear(in_features, 512),
            nn.ReLU(),
            nn.Dropout(0.5),
            nn.Linear(512, num_classes)
        )
    elif model_name_lower == "efficientnet_b5":
        model = efficientnet_b5(weights=EfficientNet_B5_Weights.IMAGENET1K_V1 if pretrained else None)
        in_features = model.classifier[1].in_features
        model.classifier = nn.Sequential(
            nn.Linear(in_features, 512),
            nn.ReLU(),
            nn.Dropout(0.5),
            nn.Linear(512, num_classes)
        )
    elif model_name_lower == "efficientnet_b6":
        model = efficientnet_b6(weights=EfficientNet_B6_Weights.IMAGENET1K_V1 if pretrained else None)
        in_features = model.classifier[1].in_features
        model.classifier = nn.Sequential(
            nn.Linear(in_features, 512),
            nn.ReLU(),
            nn.Dropout(0.5),
            nn.Linear(512, num_classes)
        )
    elif model_name_lower == "efficientnet_b7":
        model = efficientnet_b7(weights=EfficientNet_B7_Weights.IMAGENET1K_V1 if pretrained else None)
        in_features = model.classifier[1].in_features
        model.classifier = nn.Sequential(
            nn.Linear(in_features, 512),
            nn.ReLU(),
            nn.Dropout(0.5),
            nn.Linear(512, num_classes)
        )
    
    # Vision Transformer variants
    elif model_name_lower == "vit" or model_name_lower == "vit_base":
        model = timm.create_model('vit_base_patch16_224', pretrained=pretrained)
        model.head = nn.Sequential(
            nn.Linear(model.head.in_features, 512),
            nn.ReLU(),
            nn.Dropout(0.5),
            nn.Linear(512, num_classes)
        )
    elif model_name_lower == "vit_small":
        model = timm.create_model('vit_small_patch16_224', pretrained=pretrained)
        model.head = nn.Sequential(
            nn.Linear(model.head.in_features, 512),
            nn.ReLU(),
            nn.Dropout(0.5),
            nn.Linear(512, num_classes)
        )
    elif model_name_lower == "vit_large":
        model = timm.create_model('vit_large_patch16_224', pretrained=pretrained)
        model.head = nn.Sequential(
            nn.Linear(model.head.in_features, 512),
            nn.ReLU(),
            nn.Dropout(0.5),
            nn.Linear(512, num_classes)
        )
    
    else:
        raise ValueError(
            f"Unknown model: {model_name}\n"
            f"Supported models: resnet50, efficientnet_b0-b7, vit, vit_small, vit_large"
        )
    
    return model.to(device)


def train_epoch(model, dataloader, criterion, optimizer, epoch):
    """Train for one epoch"""
    model.train()
    running_loss = 0.0
    correct = 0
    total = 0
    
    pbar = tqdm(dataloader, desc=f"Epoch {epoch} [Train]")
    for images, labels in pbar:
        images = images.to(device)
        labels = labels.to(device)
        
        # Forward pass
        optimizer.zero_grad()
        outputs = model(images)
        loss = criterion(outputs, labels)
        
        # Backward pass
        loss.backward()
        optimizer.step()
        
        # Statistics
        running_loss += loss.item()
        _, predicted = torch.max(outputs.data, 1)
        total += labels.size(0)
        correct += (predicted == labels).sum().item()
        
        # Update progress bar
        pbar.set_postfix({
            "loss": f"{loss.item():.4f}",
            "acc": f"{100 * correct / total:.2f}%"
        })
    
    epoch_loss = running_loss / len(dataloader)
    epoch_acc = 100 * correct / total
    
    return epoch_loss, epoch_acc


def validate(model, dataloader, criterion):
    """Validate the model"""
    model.eval()
    running_loss = 0.0
    correct = 0
    total = 0
    
    with torch.no_grad():
        pbar = tqdm(dataloader, desc="Validation")
        for images, labels in pbar:
            images = images.to(device)
            labels = labels.to(device)
            
            outputs = model(images)
            loss = criterion(outputs, labels)
            
            running_loss += loss.item()
            _, predicted = torch.max(outputs.data, 1)
            total += labels.size(0)
            correct += (predicted == labels).sum().item()
            
            pbar.set_postfix({
                "loss": f"{loss.item():.4f}",
                "acc": f"{100 * correct / total:.2f}%"
            })
    
    epoch_loss = running_loss / len(dataloader)
    epoch_acc = 100 * correct / total
    
    return epoch_loss, epoch_acc


def train(model_name="resnet50", resume_from=None, config_name="default"):
    """Main training function"""
    
    # Use config based on config_name
    if config_name in CONFIGS:
        current_config = {**CONFIG, **CONFIGS[config_name]}
    else:
        current_config = CONFIG
    
    print("=" * 80)
    print(f"🚀 TRAINING SKIN DISEASE CLASSIFICATION MODEL")
    print(f"   Model: {model_name.upper()}")
    print(f"   Config: {config_name}")
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
    train_transform, val_transform = get_data_transforms(
        current_config["image_size"], 
        minimal_augmentation=minimal_aug
    )
    
    train_dataset = SkinDiseaseDataset(
        current_config["dataset_root"],
        split="train",
        transform=train_transform,
        label_map_file=current_config["label_map_file"]
    )
    val_dataset = SkinDiseaseDataset(
        current_config["dataset_root"],
        split="val",
        transform=val_transform,
        label_map_file=current_config["label_map_file"]
    )
    
    # Create data loaders
    # Optimize for CPU (especially Windows)
    pin_memory = current_config.get("pin_memory", False) and torch.cuda.is_available()
    
    train_loader = DataLoader(
        train_dataset,
        batch_size=current_config["batch_size"],
        shuffle=True,
        num_workers=current_config["num_workers"],
        pin_memory=pin_memory
    )
    
    val_loader = DataLoader(
        val_dataset,
        batch_size=current_config["batch_size"],
        shuffle=False,
        num_workers=current_config["num_workers"],
        pin_memory=pin_memory
    )
    
    # Create model
    model = create_model(model_name, num_classes, pretrained=not resume_from)
    
    print(f"✅ Model created: {model_name}")
    print(f"   Total parameters: {sum(p.numel() for p in model.parameters()):,}")
    
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
    criterion = nn.CrossEntropyLoss(weight=class_weights) if class_weights is not None else nn.CrossEntropyLoss()
    optimizer = optim.Adam(model.parameters(), lr=current_config["learning_rate"])
    scheduler = optim.lr_scheduler.ReduceLROnPlateau(
        optimizer, mode='max', factor=0.5, patience=5
    )
    
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
    
    # Load checkpoint if resuming
    if resume_from:
        checkpoint_path = Path(resume_from)
        if checkpoint_path.exists() and checkpoint_path.suffix == ".pth":
            # Try to load as full checkpoint (with optimizer, scheduler, etc.)
            try:
                checkpoint = torch.load(checkpoint_path, map_location=device)
                if isinstance(checkpoint, dict) and "epoch" in checkpoint:
                    # Full checkpoint
                    start_epoch = checkpoint["epoch"] + 1
                    best_val_acc = checkpoint.get("best_val_acc", 0.0)
                    history = checkpoint.get("history", history)
                    model.load_state_dict(checkpoint["model_state_dict"])
                    optimizer.load_state_dict(checkpoint["optimizer_state_dict"])
                    scheduler.load_state_dict(checkpoint["scheduler_state_dict"])
                    print(f"✅ Resumed from epoch {checkpoint['epoch']}")
                    print(f"   Best val acc so far: {best_val_acc:.2f}%")
                else:
                    # Only model weights (old format)
                    model.load_state_dict(checkpoint)
                    print(f"⚠️  Loaded model weights only (optimizer/scheduler reset)")
            except Exception as e:
                print(f"⚠️  Error loading checkpoint: {e}")
                print("   Starting from scratch...")
    
    # Training loop
    print("\n" + "=" * 80)
    print("🎯 STARTING TRAINING")
    if start_epoch > 1:
        print(f"   Resuming from epoch {start_epoch}")
    print("=" * 80)
    
    for epoch in range(start_epoch, current_config["num_epochs"] + 1):
        print(f"\n📅 Epoch {epoch}/{current_config['num_epochs']}")
        
        # Train
        train_loss, train_acc = train_epoch(model, train_loader, criterion, optimizer, epoch)
        
        # Validate
        val_loss, val_acc = validate(model, val_loader, criterion)
        
        # Update learning rate (use val_acc for max mode)
        scheduler.step(val_acc)
        
        # Save history
        history["train_loss"].append(train_loss)
        history["train_acc"].append(train_acc)
        history["val_loss"].append(val_loss)
        history["val_acc"].append(val_acc)
        
        # Save best model
        if val_acc > best_val_acc:
            best_val_acc = val_acc
            model_path = save_dir / f"{model_name}_best.pth"
            torch.save(model.state_dict(), model_path)
            print(f"💾 Saved best model (val_acc: {val_acc:.2f}%) to {model_path}")
        
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
    
    args = parser.parse_args()
    
    # Update config from args
    CONFIG["batch_size"] = args.batch_size
    CONFIG["num_epochs"] = args.epochs
    CONFIG["learning_rate"] = args.lr
    CONFIG["minimal_augmentation"] = args.minimal_aug
    CONFIG["use_weighted_loss"] = args.weighted_loss
    
    train(args.model, args.resume, config_name=args.config)

