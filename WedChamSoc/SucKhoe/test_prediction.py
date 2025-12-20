"""
Test script để kiểm tra prediction với ảnh trong uploads/skin_disease
"""
import sys
import io
from pathlib import Path

# Fix encoding for Windows console
if sys.platform == 'win32':
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8', errors='replace')

# Add backend to path
backend_path = Path(__file__).parent / "backend"
sys.path.insert(0, str(backend_path))

from ml.predictor import get_ensemble_predictor
import logging

# Setup logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

def test_prediction():
    """Test prediction với ảnh trong uploads/skin_disease"""
    
    # Tìm ảnh trong uploads/skin_disease
    uploads_dir = Path("uploads/skin_disease")
    
    if not uploads_dir.exists():
        print(f"❌ Thư mục không tồn tại: {uploads_dir}")
        return
    
    # Tìm tất cả ảnh
    image_extensions = [".jpg", ".jpeg", ".png", ".bmp", ".webp"]
    image_files = []
    for ext in image_extensions:
        image_files.extend(uploads_dir.rglob(f"*{ext}"))
        image_files.extend(uploads_dir.rglob(f"*{ext.upper()}"))
    
    if not image_files:
        print(f"❌ Không tìm thấy ảnh nào trong {uploads_dir}")
        return
    
    print("=" * 80)
    print("🧪 TEST PREDICTION")
    print("=" * 80)
    print(f"📁 Tìm thấy {len(image_files)} ảnh")
    print(f"📂 Thư mục: {uploads_dir}")
    print("=" * 80)
    
    # Load ensemble predictor
    try:
        print("\n📦 Đang load ensemble models (ResNet50 + ViT)...")
        predictor = get_ensemble_predictor(config_name="from_dataset")
        print(f"✅ Ensemble models loaded thành công!")
        print(f"   Models: ResNet50 + ViT (Ensemble)")
        print(f"   Classes: {predictor.num_classes}")
        print(f"   Weights: ResNet50={predictor.resnet_weight:.1%}, ViT={predictor.vit_weight:.1%}")
    except Exception as e:
        print(f"❌ Lỗi khi load ensemble models: {e}")
        import traceback
        traceback.print_exc()
        return
    
    # Test với từng ảnh
    print("\n" + "=" * 80)
    print("🔍 TESTING PREDICTIONS")
    print("=" * 80)
    
    for i, image_path in enumerate(image_files[:5], 1):  # Test với 5 ảnh đầu tiên
        print(f"\n📸 Test {i}/{min(5, len(image_files))}: {image_path.name}")
        print(f"   Path: {image_path}")
        
        try:
            # Predict
            result = predictor.predict(
                image_path,
                top_k=3,
                confidence_threshold=0.5
            )
            
            # Hiển thị kết quả
            print(f"\n   ✅ Prediction thành công!")
            print(f"   🎯 Ensemble Predicted: {result['predicted_disease']}")
            print(f"   📊 Ensemble Confidence: {result['confidence']:.2%}")
            print(f"   ✓ Meets threshold: {result['meets_threshold']}")
            
            # Hiển thị thông tin từ từng model
            if 'ensemble_info' in result:
                ensemble_info = result['ensemble_info']
                print(f"\n   🔍 Individual Model Predictions:")
                print(f"      ResNet50: {ensemble_info['resnet_prediction']} ({ensemble_info['resnet_confidence']:.2%})")
                print(f"      ViT:      {ensemble_info['vit_prediction']} ({ensemble_info['vit_confidence']:.2%})")
                print(f"      Models Agree: {'✅ Yes' if ensemble_info['models_agree'] else '❌ No'}")
            
            print(f"\n   📋 Top {len(result['top_predictions'])} Ensemble Predictions:")
            for j, pred in enumerate(result['top_predictions'], 1):
                print(f"      {j}. {pred['disease']}: {pred['confidence']:.2%}")
            
        except Exception as e:
            print(f"   ❌ Lỗi khi predict: {e}")
            import traceback
            traceback.print_exc()
    
    print("\n" + "=" * 80)
    print("✅ TEST HOÀN TẤT")
    print("=" * 80)

if __name__ == "__main__":
    test_prediction()

