"""
Script to organize and rename dataset folders and images
- Renames folders to standard snake_case format
- Renames images to standard format: disease_name_XXXX.jpg
- Splits data from train to val and test if needed
"""

import json
import shutil
from pathlib import Path
from collections import defaultdict
import sys
import io
import random

# Fix encoding for Windows console
if sys.platform == "win32":
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')

# Mapping from folder names to standard disease names
FOLDER_MAPPING = {
    "10. Warts Molluscum and other Viral Infections - 2103": None,  # Not in 10 classes
    "6. Benign Keratosis-like Lesions (BKL) 2624": "seborrheic_keratosis",  # Benign keratosis
    "7. Psoriasis pictures Lichen Planus and related diseases - 2k": "lichen_planus",  # Lichen planus
    "9. Tinea Ringworm Candidiasis and other Fungal Infections - 1.7k": None,  # Not in 10 classes
    "eczema": None,  # Not in 10 classes
}

# Standard disease names - will be auto-detected from dataset
STANDARD_DISEASES = set()

def detect_diseases_from_dataset(dataset_root: str) -> set:
    """Auto-detect disease names from dataset folder structure"""
    dataset_path = Path(dataset_root)
    diseases = set()
    
    # Check all splits (train, val, test)
    for split in ["train", "val", "test"]:
        split_path = dataset_path / split
        if split_path.exists():
            for folder in split_path.iterdir():
                if folder.is_dir():
                    diseases.add(folder.name)
    
    return diseases

# Image extensions
IMAGE_EXTENSIONS = {".jpg", ".jpeg", ".png", ".bmp", ".webp", ".JPG", ".JPEG", ".PNG"}


def normalize_image_name(disease_name: str, index: int, extension: str) -> str:
    """Generate normalized image name"""
    return f"{disease_name}_{index:04d}{extension.lower()}"


def rename_images_in_folder(folder_path: Path, disease_name: str, dry_run: bool = False) -> int:
    """Rename all images in a folder to standard format"""
    renamed_count = 0
    
    # Get all image files
    image_files = []
    for ext in IMAGE_EXTENSIONS:
        image_files.extend(list(folder_path.glob(f"*{ext}")))
        image_files.extend(list(folder_path.glob(f"*{ext.upper()}")))
    
    if not image_files:
        return 0
    
    # Sort to ensure consistent ordering
    image_files.sort()
    
    # Rename files
    for idx, old_path in enumerate(image_files, start=1):
        extension = old_path.suffix.lower()
        new_name = normalize_image_name(disease_name, idx, extension)
        new_path = old_path.parent / new_name
        
        # Skip if already in correct format
        if old_path.name == new_name:
            continue
        
        # Handle name conflicts
        conflict_idx = 1
        while new_path.exists() and new_path != old_path:
            new_name = normalize_image_name(disease_name, len(image_files) + conflict_idx, extension)
            new_path = old_path.parent / new_name
            conflict_idx += 1
        
        if not dry_run:
            try:
                old_path.rename(new_path)
                renamed_count += 1
            except Exception as e:
                print(f"  ⚠️  Error renaming {old_path.name}: {e}")
        else:
            print(f"  Would rename: {old_path.name} -> {new_name}")
            renamed_count += 1
    
    return renamed_count


def split_dataset(source_folder: Path, train_ratio: float = 0.7, val_ratio: float = 0.15, 
                  test_ratio: float = 0.15, dry_run: bool = False):
    """Split dataset from train folder to val and test folders"""
    if abs(train_ratio + val_ratio + test_ratio - 1.0) > 0.01:
        raise ValueError("Ratios must sum to 1.0")
    
    dataset_root = source_folder.parent
    val_folder = dataset_root / "val"
    test_folder = dataset_root / "test"
    
    # Create val and test folders if they don't exist
    if not dry_run:
        val_folder.mkdir(exist_ok=True)
        test_folder.mkdir(exist_ok=True)
    
    total_moved = 0
    
    # Process each disease folder
    for disease_folder in sorted(source_folder.iterdir()):
        if not disease_folder.is_dir():
            continue
        
        disease_name = disease_folder.name
        
        # Process all detected diseases
        if disease_name not in STANDARD_DISEASES:
            continue
        
        # Get all image files
        image_files = []
        for ext in IMAGE_EXTENSIONS:
            image_files.extend(list(disease_folder.glob(f"*{ext}")))
        
        if not image_files:
            continue
        
        # Shuffle for random split
        random.seed(42)  # For reproducibility
        random.shuffle(image_files)
        
        total = len(image_files)
        train_count = int(total * train_ratio)
        val_count = int(total * val_ratio)
        test_count = total - train_count - val_count
        
        # Calculate split points
        train_files = image_files[:train_count]
        val_files = image_files[train_count:train_count + val_count]
        test_files = image_files[train_count + val_count:]
        
        # Create disease folders in val and test
        val_disease_folder = val_folder / disease_name
        test_disease_folder = test_folder / disease_name
        
        if not dry_run:
            val_disease_folder.mkdir(exist_ok=True)
            test_disease_folder.mkdir(exist_ok=True)
        
        # Move files to val
        moved_val = 0
        for img_file in val_files:
            dest = val_disease_folder / img_file.name
            if not dry_run:
                try:
                    shutil.move(str(img_file), str(dest))
                    moved_val += 1
                except Exception as e:
                    print(f"  ⚠️  Error moving {img_file.name} to val: {e}")
            else:
                print(f"  Would move to val: {img_file.name}")
                moved_val += 1
        
        # Move files to test
        moved_test = 0
        for img_file in test_files:
            dest = test_disease_folder / img_file.name
            if not dry_run:
                try:
                    shutil.move(str(img_file), str(dest))
                    moved_test += 1
                except Exception as e:
                    print(f"  ⚠️  Error moving {img_file.name} to test: {e}")
            else:
                print(f"  Would move to test: {img_file.name}")
                moved_test += 1
        
        total_moved += moved_val + moved_test
        
        print(f"  ✅ {disease_name}: Train={len(train_files)}, Val={moved_val}, Test={moved_test}")
    
    return total_moved


def organize_dataset(dataset_root: str = "dataset", dry_run: bool = False):
    """Main function to organize dataset"""
    dataset_path = Path(dataset_root)
    train_path = dataset_path / "train"
    
    if not train_path.exists():
        print(f"❌ Train folder not found: {train_path}")
        return False
    
    # Auto-detect diseases from dataset
    global STANDARD_DISEASES
    STANDARD_DISEASES = detect_diseases_from_dataset(dataset_root)
    
    print("=" * 80)
    print("📁 ORGANIZING DATASET")
    print("=" * 80)
    print(f"Dataset: {dataset_root}")
    print(f"Mode: {'DRY RUN' if dry_run else 'LIVE'}")
    print(f"Detected diseases: {', '.join(sorted(STANDARD_DISEASES))}")
    print()
    
    # Step 1: Rename folders
    print("=" * 80)
    print("STEP 1: Renaming folders to standard format")
    print("=" * 80)
    
    folders_renamed = 0
    for old_folder_name, new_disease_name in FOLDER_MAPPING.items():
        old_folder_path = train_path / old_folder_name
        
        if not old_folder_path.exists():
            continue
        
        if new_disease_name is None:
            print(f"⚠️  Skipping '{old_folder_name}' (not in 10 classes)")
            continue
        
        new_folder_path = train_path / new_disease_name
        
        # If target folder exists, merge into it
        if new_folder_path.exists():
            print(f"📦 Merging '{old_folder_name}' -> '{new_disease_name}'")
            if not dry_run:
                # Move all files from old folder to new folder
                image_files = []
                for ext in IMAGE_EXTENSIONS:
                    image_files.extend(list(old_folder_path.glob(f"*{ext}")))
                
                for img_file in image_files:
                    dest = new_folder_path / img_file.name
                    # Handle name conflicts
                    conflict_idx = 1
                    while dest.exists():
                        stem = img_file.stem
                        dest = new_folder_path / f"{stem}_{conflict_idx}{img_file.suffix}"
                        conflict_idx += 1
                    
                    try:
                        shutil.move(str(img_file), str(dest))
                    except Exception as e:
                        print(f"  ⚠️  Error moving {img_file.name}: {e}")
                
                # Remove old folder if empty
                try:
                    old_folder_path.rmdir()
                except:
                    pass
        else:
            print(f"📁 Renaming '{old_folder_name}' -> '{new_disease_name}'")
            if not dry_run:
                try:
                    old_folder_path.rename(new_folder_path)
                    folders_renamed += 1
                except Exception as e:
                    print(f"  ⚠️  Error renaming folder: {e}")
    
    print(f"✅ Folders processed: {folders_renamed}")
    print()
    
    # Step 2: Rename images in all folders
    print("=" * 80)
    print("STEP 2: Renaming images to standard format")
    print("=" * 80)
    
    total_images_renamed = 0
    for disease_folder in sorted(train_path.iterdir()):
        if not disease_folder.is_dir():
            continue
        
        disease_name = disease_folder.name
        
        # Process all detected diseases
        if disease_name not in STANDARD_DISEASES:
            print(f"⚠️  Skipping '{disease_name}' (not in detected diseases)")
            continue
        
        print(f"📸 Processing {disease_name}...")
        renamed = rename_images_in_folder(disease_folder, disease_name, dry_run)
        total_images_renamed += renamed
        if renamed > 0:
            print(f"  ✅ Renamed {renamed} images")
    
    print(f"✅ Total images renamed: {total_images_renamed}")
    print()
    
    # Step 3: Split dataset (only if not dry run and user wants to)
    if not dry_run:
        print("=" * 80)
        print("STEP 3: Dataset split status")
        print("=" * 80)
        
        # Check current split
        val_path = dataset_path / "val"
        test_path = dataset_path / "test"
        
        if val_path.exists() and test_path.exists():
            print("✅ Val and test folders already exist")
            print("   (Skipping split - use --force-split to re-split)")
        else:
            print("⚠️  Val or test folders missing")
    
    print()
    print("=" * 80)
    print("✅ ORGANIZATION COMPLETE")
    print("=" * 80)
    
    return True


if __name__ == "__main__":
    import argparse
    
    parser = argparse.ArgumentParser(description="Organize and rename dataset")
    parser.add_argument("--dataset", type=str, default="dataset",
                       help="Dataset root directory")
    parser.add_argument("--dry-run", action="store_true",
                       help="Show what would be done without making changes")
    parser.add_argument("--force-split", action="store_true",
                       help="Force re-split dataset even if val/test exist")
    
    args = parser.parse_args()
    
    success = organize_dataset(args.dataset, dry_run=args.dry_run)
    
    if args.force_split and not args.dry_run:
        print()
        print("=" * 80)
        print("STEP 4: Force splitting dataset")
        print("=" * 80)
        dataset_path = Path(args.dataset)
        train_path = dataset_path / "train"
        moved = split_dataset(train_path, dry_run=False)
        print(f"✅ Moved {moved} images to val/test")
    
    sys.exit(0 if success else 1)

