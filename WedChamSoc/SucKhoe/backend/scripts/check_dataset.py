"""
Script to check and validate dataset structure
Helps ensure dataset is ready for training
"""

import json
from pathlib import Path
from collections import Counter
from PIL import Image
import sys

def check_dataset(dataset_root="dataset_10classes", label_map_file="backend/models/label_map_10classes.json"):
    """Check dataset structure and provide statistics"""
    
    dataset_path = Path(dataset_root)
    label_map_path = Path(label_map_file)
    
    print("=" * 80)
    print("📊 DATASET CHECKER")
    print("=" * 80)
    print()
    
    # Check if dataset root exists
    if not dataset_path.exists():
        print(f"❌ Dataset root not found: {dataset_path}")
        print(f"   Please ensure the dataset directory exists")
        return False
    
    print(f"✅ Dataset root: {dataset_path}")
    print()
    
    # Check label map
    if not label_map_path.exists():
        print(f"❌ Label map not found: {label_map_path}")
        print(f"   Please create label map first")
        return False
    
    with open(label_map_path, "r", encoding="utf-8") as f:
        label_data = json.load(f)
    
    label_to_idx = label_data["label_to_idx"]
    num_classes = label_data["num_classes"]
    
    print(f"✅ Label map: {label_map_path}")
    print(f"   Classes: {num_classes}")
    print()
    
    # Check splits
    splits = ["train", "val", "test"]
    image_extensions = {".jpg", ".jpeg", ".png", ".bmp", ".webp"}
    
    total_images = 0
    total_by_class = Counter()
    split_stats = {}
    
    for split in splits:
        split_dir = dataset_path / split
        if not split_dir.exists():
            print(f"⚠️  Split '{split}' directory not found: {split_dir}")
            split_stats[split] = {}
            continue
        
        print(f"📁 Checking {split} split...")
        split_count = 0
        split_by_class = Counter()
        
        for disease_name, class_idx in label_to_idx.items():
            disease_dir = split_dir / disease_name
            if not disease_dir.exists():
                print(f"   ⚠️  Disease folder not found: {disease_name}")
                continue
            
            # Count images
            images = [f for f in disease_dir.iterdir() 
                     if f.suffix.lower() in image_extensions]
            
            # Validate images
            valid_images = []
            invalid_images = []
            
            for img_path in images:
                try:
                    img = Image.open(img_path)
                    img.verify()
                    valid_images.append(img_path)
                except Exception as e:
                    invalid_images.append((img_path, str(e)))
            
            count = len(valid_images)
            split_count += count
            split_by_class[disease_name] = count
            total_by_class[disease_name] += count
            
            if invalid_images:
                print(f"   ⚠️  {len(invalid_images)} invalid images in {disease_name}:")
                for img_path, error in invalid_images[:3]:  # Show first 3
                    print(f"      - {img_path.name}: {error}")
                if len(invalid_images) > 3:
                    print(f"      ... and {len(invalid_images) - 3} more")
            
            if count > 0:
                print(f"   ✅ {disease_name}: {count} images")
            else:
                print(f"   ⚠️  {disease_name}: 0 images")
        
        total_images += split_count
        split_stats[split] = {
            "total": split_count,
            "by_class": dict(split_by_class)
        }
        
        print(f"   Total: {split_count} images")
        print()
    
    # Summary
    print("=" * 80)
    print("📊 SUMMARY")
    print("=" * 80)
    print()
    print(f"Total images across all splits: {total_images}")
    print()
    
    print("Images by split:")
    for split in splits:
        count = split_stats[split].get("total", 0)
        print(f"  {split:8s}: {count:5d} images")
    print()
    
    print("Images by class (across all splits):")
    for disease_name in sorted(label_to_idx.keys()):
        count = total_by_class.get(disease_name, 0)
        print(f"  {disease_name:30s}: {count:5d} images")
    print()
    
    # Analyze missing data
    print("=" * 80)
    print("🔍 MISSING DATA ANALYSIS")
    print("=" * 80)
    print()
    
    # Check for diseases with no data
    diseases_with_no_data = []
    diseases_with_low_data = []
    diseases_missing_splits = {}
    
    min_recommended_train = 50
    min_recommended_val = 10
    min_recommended_test = 10
    
    for disease_name in label_to_idx.keys():
        train_count = split_stats.get("train", {}).get("by_class", {}).get(disease_name, 0)
        val_count = split_stats.get("val", {}).get("by_class", {}).get(disease_name, 0)
        test_count = split_stats.get("test", {}).get("by_class", {}).get(disease_name, 0)
        total_count = total_by_class.get(disease_name, 0)
        
        missing_splits = []
        if train_count == 0:
            missing_splits.append("train")
        if val_count == 0:
            missing_splits.append("val")
        if test_count == 0:
            missing_splits.append("test")
        
        if total_count == 0:
            diseases_with_no_data.append(disease_name)
        elif total_count < min_recommended_train:
            diseases_with_low_data.append((disease_name, total_count, train_count, val_count, test_count))
        
        if missing_splits:
            diseases_missing_splits[disease_name] = {
                "missing": missing_splits,
                "train": train_count,
                "val": val_count,
                "test": test_count,
                "total": total_count
            }
    
    # Report diseases with no data
    if diseases_with_no_data:
        print(f"❌ DISEASES WITH NO DATA ({len(diseases_with_no_data)}):")
        for disease in diseases_with_no_data:
            print(f"   - {disease}")
        print()
    else:
        print("✅ All diseases have at least some data")
        print()
    
    # Report diseases with low data
    if diseases_with_low_data:
        print(f"⚠️  DISEASES WITH LOW DATA (< {min_recommended_train} images) ({len(diseases_with_low_data)}):")
        print(f"{'Disease':<30} {'Total':>8} {'Train':>8} {'Val':>8} {'Test':>8}")
        print("-" * 80)
        for disease, total, train, val, test in sorted(diseases_with_low_data, key=lambda x: x[1]):
            print(f"{disease:<30} {total:>8} {train:>8} {val:>8} {test:>8}")
        print()
    else:
        print(f"✅ All diseases have at least {min_recommended_train} images")
        print()
    
    # Report diseases missing splits
    if diseases_missing_splits:
        print(f"⚠️  DISEASES MISSING SPLITS ({len(diseases_missing_splits)}):")
        for disease, info in sorted(diseases_missing_splits.items()):
            missing = ", ".join(info["missing"])
            print(f"   - {disease:<30} Missing: {missing:<15} (Train: {info['train']}, Val: {info['val']}, Test: {info['test']})")
        print()
    else:
        print("✅ All diseases have data in all splits (train/val/test)")
        print()
    
    # Recommendations
    print("=" * 80)
    print("💡 RECOMMENDATIONS")
    print("=" * 80)
    print()
    
    min_images_per_class = min(total_by_class.values()) if total_by_class else 0
    max_images_per_class = max(total_by_class.values()) if total_by_class else 0
    avg_images_per_class = sum(total_by_class.values()) / len(total_by_class) if total_by_class else 0
    
    print(f"Statistics:")
    print(f"  Minimum images per class: {min_images_per_class}")
    print(f"  Maximum images per class: {max_images_per_class}")
    print(f"  Average images per class: {avg_images_per_class:.1f}")
    print()
    
    if diseases_with_no_data:
        print(f"❌ {len(diseases_with_no_data)} diseases have NO data at all")
        print(f"   Action: Add images for these diseases before training")
        print()
    
    if diseases_with_low_data:
        print(f"⚠️  {len(diseases_with_low_data)} diseases have less than {min_recommended_train} images")
        print(f"   Action: Add more images for better training results")
        print()
    
    if diseases_missing_splits:
        print(f"⚠️  {len(diseases_missing_splits)} diseases are missing data in some splits")
        print(f"   Action: Ensure each disease has data in train, val, and test splits")
        print()
    
    train_count = split_stats.get("train", {}).get("total", 0)
    val_count = split_stats.get("val", {}).get("total", 0)
    test_count = split_stats.get("test", {}).get("total", 0)
    
    if train_count == 0:
        print("❌ No training images found!")
        print("   Training cannot proceed without training data")
        return False
    
    if val_count == 0:
        print("⚠️  No validation images found!")
        print("   Validation is important for monitoring training")
    
    if test_count == 0:
        print("⚠️  No test images found!")
        print("   Test set is recommended for final evaluation")
    
    # Calculate recommended minimums
    if total_by_class:
        recommended_min = max(50, int(avg_images_per_class * 0.5))
        print()
        print(f"Recommended minimum images per class: {recommended_min}")
        print(f"  (Based on average: {avg_images_per_class:.1f})")
    
    print()
    print("=" * 80)
    
    return True


if __name__ == "__main__":
    import argparse
    
    parser = argparse.ArgumentParser(description="Check dataset structure")
    parser.add_argument("--dataset", type=str, default="dataset_10classes",
                       help="Dataset root directory")
    parser.add_argument("--label-map", type=str, default="backend/models/label_map_10classes.json",
                       help="Path to label map JSON file")
    
    args = parser.parse_args()
    
    success = check_dataset(args.dataset, args.label_map)
    sys.exit(0 if success else 1)

