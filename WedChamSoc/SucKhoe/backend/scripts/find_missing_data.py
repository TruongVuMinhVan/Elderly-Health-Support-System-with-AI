"""
Script to find diseases with missing or insufficient data
Provides detailed report on what needs to be added
"""

import json
from pathlib import Path
from collections import defaultdict
import sys
import io

# Fix encoding for Windows console
if sys.platform == "win32":
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')

def find_missing_data(dataset_root="dataset_10classes", label_map_file="backend/models/label_map_10classes.json"):
    """Find diseases with missing or insufficient data"""
    
    dataset_path = Path(dataset_root)
    label_map_path = Path(label_map_file)
    
    print("=" * 80)
    print("🔍 FINDING MISSING DATA")
    print("=" * 80)
    print()
    
    # Load label map
    if not label_map_path.exists():
        print(f"❌ Label map not found: {label_map_path}")
        return False
    
    with open(label_map_path, "r", encoding="utf-8") as f:
        label_data = json.load(f)
    
    label_to_idx = label_data["label_to_idx"]
    num_classes = label_data["num_classes"]
    
    print(f"Dataset: {dataset_path}")
    print(f"Classes: {num_classes}")
    print()
    
    # Check each disease
    image_extensions = {".jpg", ".jpeg", ".png", ".bmp", ".webp"}
    splits = ["train", "val", "test"]
    
    disease_stats = {}
    
    for disease_name in sorted(label_to_idx.keys()):
        stats = {
            "train": 0,
            "val": 0,
            "test": 0,
            "total": 0,
            "exists": False
        }
        
        for split in splits:
            split_dir = dataset_path / split
            disease_dir = split_dir / disease_name
            
            if disease_dir.exists():
                stats["exists"] = True
                images = [f for f in disease_dir.iterdir() 
                         if f.suffix.lower() in image_extensions]
                count = len(images)
                stats[split] = count
                stats["total"] += count
        
        disease_stats[disease_name] = stats
    
    # Categorize diseases
    no_data = []
    low_data = []
    missing_splits = []
    good_data = []
    
    min_train = 50
    min_val = 10
    min_test = 10
    
    for disease, stats in disease_stats.items():
        if stats["total"] == 0:
            no_data.append((disease, stats))
        elif stats["train"] < min_train or stats["val"] < min_val or stats["test"] < min_test:
            if stats["train"] < min_train:
                low_data.append((disease, stats, "train", stats["train"], min_train))
            if stats["val"] < min_val:
                low_data.append((disease, stats, "val", stats["val"], min_val))
            if stats["test"] < min_test:
                low_data.append((disease, stats, "test", stats["test"], min_test))
            
            missing = []
            if stats["train"] == 0:
                missing.append("train")
            if stats["val"] == 0:
                missing.append("val")
            if stats["test"] == 0:
                missing.append("test")
            if missing:
                missing_splits.append((disease, stats, missing))
        else:
            good_data.append((disease, stats))
    
    # Report
    print("=" * 80)
    print("📊 RESULTS")
    print("=" * 80)
    print()
    
    if no_data:
        print(f"❌ DISEASES WITH NO DATA ({len(no_data)}):")
        print()
        for disease, stats in no_data:
            print(f"   {disease}")
            print(f"      Status: No images found in any split")
            print(f"      Action: Add images to train/, val/, and test/ folders")
            print()
    else:
        print("✅ All diseases have at least some data")
        print()
    
    if missing_splits:
        print(f"⚠️  DISEASES MISSING SPLITS ({len(missing_splits)}):")
        print()
        for disease, stats, missing in missing_splits:
            print(f"   {disease}")
            print(f"      Missing splits: {', '.join(missing)}")
            print(f"      Current: Train={stats['train']}, Val={stats['val']}, Test={stats['test']}")
            print(f"      Action: Add images to {', '.join(missing)}/ folders")
            print()
    else:
        print("✅ All diseases have data in all splits")
        print()
    
    if low_data:
        print(f"⚠️  DISEASES WITH INSUFFICIENT DATA ({len(set(d[0] for d in low_data))}):")
        print()
        print(f"{'Disease':<30} {'Split':<8} {'Current':>10} {'Minimum':>10} {'Need':>10}")
        print("-" * 80)
        
        # Group by disease
        by_disease = defaultdict(list)
        for disease, stats, split, current, minimum in low_data:
            by_disease[disease].append((split, current, minimum))
        
        for disease in sorted(by_disease.keys()):
            for split, current, minimum in by_disease[disease]:
                need = max(0, minimum - current)
                print(f"{disease:<30} {split:<8} {current:>10} {minimum:>10} {need:>10}")
        print()
    else:
        print("✅ All diseases have sufficient data in all splits")
        print()
    
    if good_data:
        print(f"✅ DISEASES WITH GOOD DATA ({len(good_data)}):")
        for disease, stats in good_data[:5]:  # Show first 5
            print(f"   {disease}: Train={stats['train']}, Val={stats['val']}, Test={stats['test']}")
        if len(good_data) > 5:
            print(f"   ... and {len(good_data) - 5} more")
        print()
    
    # Summary
    print("=" * 80)
    print("📋 SUMMARY")
    print("=" * 80)
    print()
    print(f"Total diseases: {num_classes}")
    print(f"  ✅ Good data: {len(good_data)}")
    print(f"  ⚠️  Need more data: {len(set(d[0] for d in low_data))}")
    print(f"  ❌ No data: {len(no_data)}")
    print()
    
    # Action items
    if no_data or low_data or missing_splits:
        print("=" * 80)
        print("📝 ACTION ITEMS")
        print("=" * 80)
        print()
        
        if no_data:
            print(f"1. Add data for {len(no_data)} diseases with no images:")
            for disease, _ in no_data:
                print(f"   - {disease}")
            print()
        
        if missing_splits:
            print(f"2. Add missing splits for {len(missing_splits)} diseases:")
            for disease, stats, missing in missing_splits:
                print(f"   - {disease}: add to {', '.join(missing)}/")
            print()
        
        if low_data:
            print(f"3. Add more images for {len(set(d[0] for d in low_data))} diseases:")
            by_disease = defaultdict(list)
            for disease, stats, split, current, minimum in low_data:
                by_disease[disease].append((split, current, minimum))
            
            for disease in sorted(by_disease.keys()):
                needs = []
                for split, current, minimum in by_disease[disease]:
                    need = max(0, minimum - current)
                    if need > 0:
                        needs.append(f"{split}: +{need}")
                if needs:
                    print(f"   - {disease}: {', '.join(needs)}")
            print()
    
    print("=" * 80)
    
    return True


if __name__ == "__main__":
    import argparse
    
    parser = argparse.ArgumentParser(description="Find diseases with missing or insufficient data")
    parser.add_argument("--dataset", type=str, default="dataset_10classes",
                       help="Dataset root directory")
    parser.add_argument("--label-map", type=str, default="backend/models/label_map_10classes.json",
                       help="Path to label map JSON file")
    
    args = parser.parse_args()
    
    success = find_missing_data(args.dataset, args.label_map)
    sys.exit(0 if success else 1)

