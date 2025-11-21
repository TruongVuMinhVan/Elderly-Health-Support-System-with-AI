"""
Script để tự động tạo label_map từ các bệnh thực sự có trong dataset
Chỉ lấy các classes có trong dataset, không dùng label_map cũ
"""

import json
import sys
import io
from pathlib import Path
from collections import Counter
import argparse

# Fix encoding for Windows console
if sys.platform == "win32":
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')

def scan_dataset_for_classes(dataset_root: str, split: str = "train") -> dict:
    """
    Quét dataset để tìm các classes thực sự có
    
    Args:
        dataset_root: Root directory của dataset
        split: Split để quét (train, val, test)
    
    Returns:
        Dict với thông tin về classes và số lượng ảnh
    """
    
    dataset_path = Path(dataset_root)
    split_path = dataset_path / split
    
    if not split_path.exists():
        print(f"[WARNING] Split '{split}' not found: {split_path}")
        return {}
    
    image_extensions = {".jpg", ".jpeg", ".png", ".bmp", ".webp", ".JPG", ".JPEG", ".PNG"}
    classes_info = {}
    
    print(f"Scanning {split} split...")
    
    # Quét các folder trong split
    for item in split_path.iterdir():
        if not item.is_dir():
            continue
        
        class_name = item.name
        
        # Đếm số ảnh
        image_count = sum(1 for f in item.iterdir() 
                         if f.is_file() and f.suffix.lower() in image_extensions)
        
        if image_count > 0:
            if class_name not in classes_info:
                classes_info[class_name] = {
                    "train": 0,
                    "val": 0,
                    "test": 0
                }
            classes_info[class_name][split] = image_count
    
    return classes_info


def generate_label_map_from_dataset(
    dataset_root: str,
    output_file: str = None,
    min_images_per_class: int = 10
):
    """
    Tạo label_map mới từ dataset thực tế
    
    Args:
        dataset_root: Root directory của dataset
        output_file: File output (default: backend/models/label_map_from_dataset.json)
        min_images_per_class: Số ảnh tối thiểu để include class
    """
    
    dataset_path = Path(dataset_root)
    if not dataset_path.exists():
        print(f"[ERROR] Dataset not found: {dataset_path}")
        return False
    
    print("=" * 80)
    print("GENERATE LABEL MAP FROM DATASET")
    print("=" * 80)
    print()
    print(f"Dataset: {dataset_root}")
    print(f"Minimum images per class: {min_images_per_class}")
    print()
    
    # Quét tất cả splits
    all_classes = {}
    
    for split in ["train", "val", "test"]:
        split_classes = scan_dataset_for_classes(dataset_root, split)
        
        # Merge vào all_classes
        for class_name, counts in split_classes.items():
            if class_name not in all_classes:
                all_classes[class_name] = {
                    "train": 0,
                    "val": 0,
                    "test": 0
                }
            all_classes[class_name][split] = counts[split]
    
    if not all_classes:
        print("[ERROR] No classes found in dataset!")
        return False
    
    # Tính tổng số ảnh mỗi class
    class_totals = {}
    for class_name, counts in all_classes.items():
        total = counts["train"] + counts["val"] + counts["test"]
        class_totals[class_name] = total
    
    # Lọc classes có đủ ảnh
    valid_classes = {
        name: total 
        for name, total in class_totals.items() 
        if total >= min_images_per_class
    }
    
    # Sắp xếp theo số lượng ảnh (giảm dần)
    sorted_classes = sorted(valid_classes.items(), key=lambda x: x[1], reverse=True)
    
    print("=" * 80)
    print("CLASSES FOUND IN DATASET")
    print("=" * 80)
    print()
    
    # Hiển thị thống kê
    print(f"{'Class Name':<40} {'Train':>8} {'Val':>8} {'Test':>8} {'Total':>8}")
    print("-" * 80)
    
    for class_name, total in sorted_classes:
        counts = all_classes[class_name]
        print(f"{class_name:<40} {counts['train']:>8} {counts['val']:>8} {counts['test']:>8} {total:>8}")
    
    print()
    print(f"Total classes: {len(sorted_classes)}")
    print(f"Total images: {sum(class_totals.values()):,}")
    print()
    
    # Kiểm tra classes bị loại
    excluded = {
        name: total 
        for name, total in class_totals.items() 
        if total < min_images_per_class
    }
    
    if excluded:
        print("=" * 80)
        print("EXCLUDED CLASSES (too few images)")
        print("=" * 80)
        print()
        for class_name, total in sorted(excluded.items(), key=lambda x: x[1], reverse=True):
            print(f"  {class_name:<40} {total:>8} images (< {min_images_per_class})")
        print()
    
    # Tạo label map
    label_to_idx = {}
    idx_to_label = {}
    
    for idx, (class_name, _) in enumerate(sorted_classes):
        # Normalize class name (lowercase, replace spaces with underscores)
        normalized_name = class_name.lower().replace(" ", "_")
        label_to_idx[normalized_name] = idx
        idx_to_label[str(idx)] = normalized_name
    
    label_map = {
        "num_classes": len(sorted_classes),
        "label_to_idx": label_to_idx,
        "idx_to_label": idx_to_label,
        "classes": [name.lower().replace(" ", "_") for name, _ in sorted_classes],
        "diseases": [name.lower().replace(" ", "_") for name, _ in sorted_classes],
        "class_counts": {
            name.lower().replace(" ", "_"): {
                "train": all_classes[name]["train"],
                "val": all_classes[name]["val"],
                "test": all_classes[name]["test"],
                "total": class_totals[name]
            }
            for name, _ in sorted_classes
        }
    }
    
    # Save label map
    if output_file is None:
        # Tự động tạo tên file dựa trên dataset root
        dataset_name = Path(dataset_root).name
        output_file = f"backend/models/label_map_{dataset_name}.json"
    
    output_path = Path(output_file)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    
    with open(output_path, "w", encoding="utf-8") as f:
        json.dump(label_map, f, indent=2, ensure_ascii=False)
    
    print("=" * 80)
    print("LABEL MAP GENERATED")
    print("=" * 80)
    print()
    print(f"Output file: {output_path}")
    print(f"Total classes: {label_map['num_classes']}")
    print()
    print("Label map structure:")
    print(f"  - num_classes: {label_map['num_classes']}")
    print(f"  - label_to_idx: {len(label_map['label_to_idx'])} mappings")
    print(f"  - idx_to_label: {len(label_map['idx_to_label'])} mappings")
    print(f"  - classes: {len(label_map['classes'])} classes")
    print(f"  - class_counts: Statistics for each class")
    print()
    
    # Hiển thị một vài ví dụ
    print("Example mappings:")
    for i, (class_name, _) in enumerate(sorted_classes[:5]):
        normalized = class_name.lower().replace(" ", "_")
        print(f"  {i}: {normalized} (original: {class_name})")
    if len(sorted_classes) > 5:
        print(f"  ... and {len(sorted_classes) - 5} more")
    print()
    
    return True


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Generate label map from actual dataset classes"
    )
    parser.add_argument(
        "--dataset",
        type=str,
        default="dataset_10classes",
        help="Dataset root directory"
    )
    parser.add_argument(
        "--output",
        type=str,
        default=None,
        help="Output label map file (default: backend/models/label_map_{dataset_name}.json)"
    )
    parser.add_argument(
        "--min-images",
        type=int,
        default=10,
        help="Minimum images per class to include (default: 10)"
    )
    
    args = parser.parse_args()
    
    success = generate_label_map_from_dataset(
        args.dataset,
        args.output,
        args.min_images
    )
    
    sys.exit(0 if success else 1)

