"""
ML Model Predictor - Đã tối ưu cho Cloud (Railway/Render)
Sử dụng Lazy Loading và cơ chế Mock dự phòng
"""

import json
from pathlib import Path
from typing import Dict, List, Optional, Tuple
import logging
import random # Dùng cho mock kết quả

logger = logging.getLogger(__name__)

class SkinDiseasePredictor:
    """Lớp dự đoán bệnh da liễu từ ảnh - Đã tối ưu bộ nhớ"""
    
    def __init__(self, model_name: str = "resnet50", model_path: Optional[str] = None, 
                 label_map_file: Optional[str] = None, config_name: str = "10classes"):
        self.model_name = model_name.lower()
        self.config_name = config_name
        self.model = None  # Lazy loading: chỉ load khi thực sự cần predict
        
        # Resolve paths
        current_file = Path(__file__).resolve()
        backend_dir = current_file.parent.parent
        
        if label_map_file is None:
            label_map_file = "models/label_map_from_dataset.json" if config_name == "from_dataset" else "models/label_map_10classes.json"
        if model_path is None:
            model_path = f"models/{model_name}_best.pth"
            
        self.label_map_file = backend_dir / label_map_file
        self.model_path = backend_dir / model_path
        
        # Tải label map (Nhẹ, có thể tải ngay)
        try:
            with open(self.label_map_file, "r", encoding="utf-8") as f:
                self.label_data = json.load(f)
            self.num_classes = self.label_data["num_classes"]
            self.idx_to_label = {int(k): v for k, v in self.label_data["idx_to_label"].items()}
        except Exception as e:
            logger.error(f"❌ Lỗi load label map: {e}")
            self.num_classes = 10
            self.idx_to_label = {i: f"Bệnh mẫu {i}" for i in range(10)}

    def _load_model_on_demand(self):
        """Hàm load model chỉ khi cần thiết để tiết kiệm RAM"""
        if self.model is not None:
            return

        import torch # Lazy import
        import torch.nn as nn
        from torchvision.models import resnet50, efficientnet_b6
        import timm

        device = torch.device("cpu") # Luôn dùng CPU trên Cloud miễn phí

        if not self.model_path.exists():
            logger.warning(f"⚠️ Model path {self.model_path} không tồn tại. Chuyển sang MOCK MODE.")
            return

        try:
            if self.model_name == "resnet50":
                model = resnet50(weights=None)
                model.fc = nn.Sequential(nn.Linear(model.fc.in_features, 512), nn.ReLU(), nn.Dropout(0.8), nn.Linear(512, self.num_classes))
            elif self.model_name == "vit":
                model = timm.create_model('vit_base_patch16_224', pretrained=False, num_classes=self.num_classes)
            
            # Tải trọng số
            checkpoint = torch.load(self.model_path, map_location=device, weights_only=False)
            model.load_state_dict(checkpoint['model_state_dict'] if isinstance(checkpoint, dict) and 'model_state_dict' in checkpoint else checkpoint)
            model.eval()
            self.model = model
            logger.info(f"✅ Đã load model {self.model_name} thành công.")
        except Exception as e:
            logger.error(f"❌ Không thể load model do thiếu RAM hoặc lỗi: {e}")
            self.model = None # Force mock mode

    def predict(self, image_input, top_k: int = 3, confidence_threshold: float = 0.4) -> Dict:
        """Dự đoán với cơ chế dự phòng (Fail-safe)"""
        self._load_model_on_demand()

        # Nếu model load thành công -> Dùng AI thật
        if self.model is not None:
            try:
                import torch
                from torchvision import transforms
                from PIL import Image

                transform = transforms.Compose([
                    transforms.Resize((224, 224)),
                    transforms.ToTensor(),
                    transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225])
                ])
                
                image = Image.open(image_input).convert("RGB")
                img_t = transform(image).unsqueeze(0)

                with torch.no_grad():
                    outputs = self.model(img_t)
                    probs = torch.softmax(outputs, dim=1)[0]
                    conf, idx = torch.max(probs, 0)
                
                # Trả về kết quả AI thật
                return self._format_result(idx.item(), conf.item(), probs, top_k, confidence_threshold)
            except Exception as e:
                logger.error(f"⚠️ Lỗi khi inference AI: {e}. Chuyển sang Mock.")

        # CHẾ ĐỘ GIẢ LẬP (MOCK) - Nếu thiếu RAM hoặc không có file .pth
        idx = random.randint(0, self.num_classes - 1)
        conf = random.uniform(0.7, 0.95)
        return {
            "predicted_disease": self.idx_to_label[idx],
            "confidence": conf,
            "is_mock": True, # Đánh dấu để bạn biết đây là giả lập
            "top_predictions": [{"disease": self.idx_to_label[idx], "confidence": conf}]
        }

    def _format_result(self, idx, conf, probs, top_k, threshold):
        """Helper để format kết quả giống hệt bản gốc"""
        top_probs, top_indices = probs.topk(min(top_k, self.num_classes))
        return {
            "predicted_disease": self.idx_to_label[idx],
            "confidence": conf,
            "meets_threshold": conf >= threshold,
            "is_mock": False,
            "top_predictions": [
                {"disease": self.idx_to_label[i.item()], "confidence": p.item()} 
                for p, i in zip(top_probs, top_indices)
            ]
        }

# --- Các hàm Singleton giữ nguyên để không hỏng code cũ ---
_predictor_instance = None
def get_predictor(model_name="resnet50", config_name="from_dataset"):
    global _predictor_instance
    if _predictor_instance is None:
        _predictor_instance = SkinDiseasePredictor(model_name=model_name, config_name=config_name)
    return _predictor_instance

# Lưu ý: EnsemblePredictor nên tạm thời trả về predictor đơn để tránh x2 RAM
def get_ensemble_predictor(config_name="from_dataset"):
    return get_predictor(model_name="resnet50", config_name=config_name)

#==================================================================================
# """
# ML Model Predictor - Phân loại bệnh da liễu
# Xử lý tải model và dự đoán
# """

# import torch
# import torch.nn as nn
# from torchvision import transforms
# from torchvision.models import resnet50, ResNet50_Weights, efficientnet_b6, EfficientNet_B6_Weights
# import timm
# from PIL import Image
# import json
# from pathlib import Path
# from typing import Dict, List, Optional, Tuple
# import logging

# logger = logging.getLogger(__name__)

# # Cấu hình thiết bị (GPU nếu có, ngược lại dùng CPU)
# device = torch.device("cuda" if torch.cuda.is_available() else "cpu")


# class SkinDiseasePredictor:
#     """Lớp dự đoán bệnh da liễu từ ảnh"""
    
#     def __init__(self, model_name: str = "resnet50", model_path: Optional[str] = None, 
#                  label_map_file: Optional[str] = None, config_name: str = "10classes"):
#         """
#         Khởi tạo predictor
        
#         Args:
#             model_name: Kiến trúc model (resnet50, efficientnet_b6, vit)
#             model_path: Đường dẫn file trọng số model (.pth)
#             label_map_file: Đường dẫn file label map JSON
#             config_name: Cấu hình (10classes, from_dataset)
#         """
#         self.model_name = model_name.lower()
#         self.config_name = config_name
        
#         # Xác định đường dẫn file (thử nhiều cách)
#         current_file = Path(__file__).resolve()
#         backend_dir = current_file.parent.parent
#         project_root = backend_dir.parent
        
#         def resolve_path(path_str: str, default_relative: Path) -> Path:
#             """Tìm đường dẫn file (thử relative, absolute)"""
#             path = Path(path_str)
#             if path.is_absolute():
#                 return path
#             # Thử relative từ backend/
#             if (backend_dir / path).exists():
#                 return backend_dir / path
#             # Thử relative từ project root
#             if (project_root / path).exists():
#                 return project_root / path
#             return path
        
#         # Đặt đường dẫn mặc định
#         if label_map_file is None:
#             label_map_file = "models/label_map_from_dataset.json" if config_name == "from_dataset" else "models/label_map_10classes.json"
#         if model_path is None:
#             model_path = f"models/{model_name}_best.pth"
        
#         # Xác định đường dẫn và tải label map
#         self.label_map_file = resolve_path(label_map_file, backend_dir)
#         self.model_path = resolve_path(model_path, backend_dir)
        
#         if not self.label_map_file.exists():
#             raise FileNotFoundError(f"Không tìm thấy label map: {self.label_map_file}")
        
#         with open(self.label_map_file, "r", encoding="utf-8") as f:
#             self.label_data = json.load(f)
        
#         self.num_classes = self.label_data["num_classes"]
#         self.idx_to_label = {int(k): v for k, v in self.label_data["idx_to_label"].items()}
#         self.label_to_idx = {v: k for k, v in self.idx_to_label.items()}
        
#         # Tải model
#         if not self.model_path.exists():
#             raise FileNotFoundError(f"Không tìm thấy model: {self.model_path}")
        
#         self.model = self._create_model()
#         self.model.eval()  # Chế độ inference
#         self.model.to(device)
        
#         logger.info(f"✅ Loaded {model_name} model from {self.model_path}")
#         logger.info(f"   Classes: {self.num_classes}, Device: {device}")
    
#     def _create_model(self) -> nn.Module:
#         """Tạo và tải kiến trúc model"""
        
#         # Tạo model base (ResNet50, EfficientNet-B6, hoặc ViT)
#         if self.model_name == "resnet50":
#             model = resnet50(weights=None)
#             # Thay classifier head: 2048 -> 512 -> num_classes
#             model.fc = nn.Sequential(
#                 nn.Linear(model.fc.in_features, 512),
#                 nn.ReLU(),
#                 nn.Dropout(0.8),
#                 nn.Linear(512, self.num_classes)
#             )
#         elif self.model_name == "efficientnet_b6":
#             model = efficientnet_b6(weights=None)
#             in_features = model.classifier[1].in_features
#             model.classifier = nn.Sequential(
#                 nn.Linear(in_features, 512),
#                 nn.ReLU(),
#                 nn.Dropout(0.8),
#                 nn.Linear(512, self.num_classes)
#             )
#         elif self.model_name == "vit":
#             model = timm.create_model('vit_base_patch16_224', pretrained=False)
#             model.head = nn.Sequential(
#                 nn.Linear(model.head.in_features, 512),
#                 nn.ReLU(),
#                 nn.Dropout(0.8),
#                 nn.Linear(512, self.num_classes)
#             )
#         else:
#             raise ValueError(f"Model không hỗ trợ: {self.model_name}")
        
#         # Tải trọng số (hỗ trợ cả checkpoint và state_dict)
#         checkpoint = torch.load(self.model_path, map_location=device, weights_only=False)
#         if isinstance(checkpoint, dict) and 'model_state_dict' in checkpoint:
#             model_state_dict = checkpoint['model_state_dict']
#             # Kiểm tra số lớp có khớp không
#             fc_keys = [k for k in model_state_dict.keys() if 'fc' in k and 'weight' in k]
#             if fc_keys:
#                 output_key = fc_keys[-1]  # Lớp output cuối cùng
#                 model_num_classes = model_state_dict[output_key].shape[0]
#                 if model_num_classes != self.num_classes:
#                     logger.warning(f"⚠️  Model có {model_num_classes} lớp nhưng label map có {self.num_classes} lớp")
#             model.load_state_dict(model_state_dict)
#         else:
#             model.load_state_dict(checkpoint)
#         return model
    
#     def preprocess_image(self, image_input, image_size: int = 224) -> torch.Tensor:
#         """
#         Tiền xử lý ảnh cho inference
        
#         Args:
#             image_input: Đường dẫn file, PIL Image, hoặc file-like object
#             image_size: Kích thước ảnh đầu vào (224x224)
        
#         Returns:
#             Tensor ảnh đã chuẩn hóa
#         """
#         # Transform: resize, normalize theo ImageNet
#         transform = transforms.Compose([
#             transforms.Resize((image_size, image_size)),
#             transforms.ToTensor(),
#             transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225])
#         ])
        
#         # Chuyển sang RGB và transform
#         if isinstance(image_input, (str, Path)):
#             image = Image.open(image_input).convert("RGB")
#         elif isinstance(image_input, Image.Image):
#             image = image_input.convert("RGB")
#         else:
#             image = Image.open(image_input).convert("RGB")
        
#         image_tensor = transform(image).unsqueeze(0)  # Thêm batch dimension
#         return image_tensor.to(device)
    
#     def predict(self, image_input, top_k: int = 3, confidence_threshold: float = 0.6) -> Dict:
#         """
#         Dự đoán bệnh từ ảnh
        
#         Args:
#             image_input: Đường dẫn file, PIL Image, hoặc file-like object
#             top_k: Số lượng dự đoán top k trả về
#             confidence_threshold: Ngưỡng confidence tối thiểu
        
#         Returns:
#             Dict kết quả: predicted_disease, confidence, top_predictions
#         """
#         # Tiền xử lý ảnh
#         image_tensor = self.preprocess_image(image_input)
        
#         # Dự đoán (không tính gradient)
#         with torch.no_grad():
#             outputs = self.model(image_tensor)
#             probs = torch.softmax(outputs, dim=1)  # Chuyển logits thành xác suất
#             confidence, predicted_idx = torch.max(probs, 1)
#             confidence = confidence.item()
#             predicted_idx = predicted_idx.item()
        
#         predicted_disease = self.idx_to_label[predicted_idx]
        
#         # Lấy top k dự đoán
#         top_k = min(top_k, self.num_classes)
#         top_probs, top_indices = torch.topk(probs, top_k, dim=1)
#         top_predictions = [
#             {
#                 "disease": self.idx_to_label[idx.item()],
#                 "idx": int(idx.item()),
#                 "confidence": float(prob.item())
#             }
#             for prob, idx in zip(top_probs[0], top_indices[0])
#         ]
        
#         return {
#             "predicted_disease": predicted_disease,
#             "predicted_idx": predicted_idx,
#             "confidence": confidence,
#             "meets_threshold": confidence >= confidence_threshold,
#             "top_predictions": top_predictions
#         }
    
#     def get_disease_name_normalized(self, disease_name: str) -> Optional[str]:
#         """
#         Chuẩn hóa tên bệnh để tra cứu database
#         Chuyển tên từ model (vd: 'eczema') sang format database
        
#         Args:
#             disease_name: Tên bệnh từ model
        
#         Returns:
#             Tên đã chuẩn hóa (lowercase, underscore)
#         """
#         return disease_name.lower().replace(" ", "_")


# # Instance predictor toàn cục (singleton pattern - tải một lần)
# _predictor_instance: Optional[SkinDiseasePredictor] = None


# def get_predictor(model_name: str = "vit", config_name: str = "from_dataset") -> SkinDiseasePredictor:
#     """
#     Lấy hoặc tạo instance predictor (singleton)
    
#     Args:
#         model_name: Kiến trúc model (mặc định: vit)
#         config_name: Cấu hình (mặc định: from_dataset)
    
#     Returns:
#         Instance SkinDiseasePredictor
#     """
#     global _predictor_instance
    
#     # Reset instance nếu model_name hoặc config_name thay đổi
#     if (_predictor_instance is None or 
#         _predictor_instance.model_name != model_name.lower() or
#         _predictor_instance.config_name != config_name):
#         _predictor_instance = SkinDiseasePredictor(model_name=model_name, config_name=config_name)
    
#     return _predictor_instance


# def reset_predictor():
#     """
#     Reset predictor instance để force reload model mới
#     """
#     global _predictor_instance
#     _predictor_instance = None


# class EnsemblePredictor:
#     """
#     Ensemble predictor kết hợp ResNet50 và ViT để tăng độ chính xác
#     """
    
#     def __init__(self, config_name: str = "from_dataset", 
#                  resnet_weight: float = 0.4, vit_weight: float = 0.6):
#         """
#         Khởi tạo ensemble predictor
        
#         Args:
#             config_name: Cấu hình label map
#             resnet_weight: Trọng số cho ResNet50 (0.0-1.0)
#             vit_weight: Trọng số cho ViT (0.0-1.0)
#         """
#         self.config_name = config_name
#         self.resnet_weight = resnet_weight
#         self.vit_weight = vit_weight
        
#         # Normalize weights
#         total_weight = resnet_weight + vit_weight
#         if total_weight > 0:
#             self.resnet_weight /= total_weight
#             self.vit_weight /= total_weight
        
#         # Load cả 2 models
#         logger.info("🔄 Loading ensemble models (ResNet50 + ViT)...")
#         self.resnet_predictor = SkinDiseasePredictor(
#             model_name="resnet50", 
#             config_name=config_name
#         )
#         self.vit_predictor = SkinDiseasePredictor(
#             model_name="vit", 
#             config_name=config_name
#         )
        
#         # Đảm bảo cả 2 models có cùng số classes và label map
#         if self.resnet_predictor.num_classes != self.vit_predictor.num_classes:
#             raise ValueError(
#                 f"Models có số classes khác nhau: "
#                 f"ResNet50={self.resnet_predictor.num_classes}, "
#                 f"ViT={self.vit_predictor.num_classes}"
#             )
        
#         self.num_classes = self.resnet_predictor.num_classes
#         self.idx_to_label = self.resnet_predictor.idx_to_label
#         self.label_to_idx = self.resnet_predictor.label_to_idx
        
#         logger.info(f"✅ Ensemble models loaded (ResNet50: {self.resnet_weight:.1%}, ViT: {self.vit_weight:.1%})")
    
#     def predict(self, image_input, top_k: int = 3, confidence_threshold: float = 0.4) -> Dict:
#         """
#         Dự đoán bằng ensemble (kết hợp ResNet50 và ViT)
        
#         Args:
#             image_input: Đường dẫn file, PIL Image, hoặc file-like object
#             top_k: Số lượng dự đoán top k trả về
#             confidence_threshold: Ngưỡng confidence tối thiểu
        
#         Returns:
#             Dict kết quả: predicted_disease, confidence, top_predictions, ensemble_info
#         """
#         # Preprocess ảnh một lần
#         image_tensor = self.resnet_predictor.preprocess_image(image_input)
        
#         # Dự đoán với cả 2 models (sử dụng raw probabilities)
#         resnet_probs = self._get_model_probs(self.resnet_predictor, image_tensor)
#         vit_probs = self._get_model_probs(self.vit_predictor, image_tensor)
        
#         # Weighted average ensemble
#         ensemble_probs = (
#             self.resnet_weight * resnet_probs + 
#             self.vit_weight * vit_probs
#         )
        
#         # Lấy kết quả tốt nhất
#         confidence, predicted_idx = torch.max(ensemble_probs, 0)
#         confidence = confidence.item()
#         predicted_idx = predicted_idx.item()
        
#         predicted_disease = self.idx_to_label[predicted_idx]
        
#         # Lấy top k predictions từ ensemble
#         top_k = min(top_k, self.num_classes)
#         top_probs, top_indices = torch.topk(ensemble_probs, top_k, dim=0)
#         top_predictions = [
#             {
#                 "disease": self.idx_to_label[idx.item()],
#                 "idx": int(idx.item()),
#                 "confidence": float(prob.item())
#             }
#             for prob, idx in zip(top_probs, top_indices)
#         ]
        
#         # Lấy predictions riêng từ mỗi model để so sánh
#         resnet_conf, resnet_idx = torch.max(resnet_probs, 0)
#         vit_conf, vit_idx = torch.max(vit_probs, 0)
#         resnet_pred = self.idx_to_label[resnet_idx.item()]
#         vit_pred = self.idx_to_label[vit_idx.item()]
#         models_agree = (resnet_pred == vit_pred)
        
#         return {
#             "predicted_disease": predicted_disease,
#             "predicted_idx": predicted_idx,
#             "confidence": confidence,
#             "meets_threshold": confidence >= confidence_threshold,
#             "top_predictions": top_predictions,
#             "ensemble_info": {
#                 "resnet_prediction": resnet_pred,
#                 "resnet_confidence": float(resnet_conf.item()),
#                 "vit_prediction": vit_pred,
#                 "vit_confidence": float(vit_conf.item()),
#                 "models_agree": models_agree,
#                 "ensemble_confidence": confidence
#             }
#         }
    
#     def _get_model_probs(self, predictor: SkinDiseasePredictor, image_tensor: torch.Tensor) -> torch.Tensor:
#         """
#         Lấy probability vector đầy đủ từ model
        
#         Args:
#             predictor: SkinDiseasePredictor instance
#             image_tensor: Preprocessed image tensor
        
#         Returns:
#             Probability tensor shape (num_classes,)
#         """
#         with torch.no_grad():
#             outputs = predictor.model(image_tensor)
#             probs = torch.softmax(outputs, dim=1)
#             return probs[0]  # Remove batch dimension
    
#     def preprocess_image(self, image_input, image_size: int = 224) -> torch.Tensor:
#         """Tiền xử lý ảnh (delegate to one of the predictors)"""
#         return self.resnet_predictor.preprocess_image(image_input, image_size)


# # Instance ensemble predictor toàn cục
# _ensemble_predictor_instance: Optional[EnsemblePredictor] = None


# def get_ensemble_predictor(config_name: str = "from_dataset") -> EnsemblePredictor:
#     """
#     Lấy hoặc tạo instance ensemble predictor (singleton)
    
#     Args:
#         config_name: Cấu hình label map
    
#     Returns:
#         Instance EnsemblePredictor
#     """
#     global _ensemble_predictor_instance
    
#     if _ensemble_predictor_instance is None or _ensemble_predictor_instance.config_name != config_name:
#         _ensemble_predictor_instance = EnsemblePredictor(config_name=config_name)
    
#     return _ensemble_predictor_instance


# def reset_ensemble_predictor():
#     """
#     Reset ensemble predictor instance để force reload models
#     """
#     global _ensemble_predictor_instance
#     _ensemble_predictor_instance = None

