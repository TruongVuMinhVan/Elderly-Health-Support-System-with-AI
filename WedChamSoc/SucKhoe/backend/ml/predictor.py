"""
ML Model Predictor for Skin Disease Classification
Handles model loading and prediction
"""

import torch
import torch.nn as nn
from torchvision import transforms
from torchvision.models import resnet50, ResNet50_Weights, efficientnet_b6, EfficientNet_B6_Weights
import timm
from PIL import Image
import json
from pathlib import Path
from typing import Dict, List, Optional, Tuple
import logging

logger = logging.getLogger(__name__)

# Device configuration
device = torch.device("cuda" if torch.cuda.is_available() else "cpu")


class SkinDiseasePredictor:
    """Predictor class for skin disease classification"""
    
    def __init__(self, model_name: str = "resnet50", model_path: Optional[str] = None, 
                 label_map_file: Optional[str] = None, config_name: str = "10classes"):
        """
        Initialize predictor
        
        Args:
            model_name: Model architecture (resnet50, efficientnet_b6, vit)
            model_path: Path to trained model weights (.pth file)
            label_map_file: Path to label map JSON file
            config_name: Configuration preset (default, 10classes)
        """
        self.model_name = model_name.lower()
        self.config_name = config_name
        
        # Set default paths based on config
        # Try multiple path resolution strategies
        current_file = Path(__file__).resolve()
        backend_dir = current_file.parent.parent  # backend/ml -> backend
        project_root = backend_dir.parent  # backend -> project root
        
        # Try paths in order: relative to backend, relative to project root, absolute
        def resolve_path(path_str: str, default_relative: Path) -> Path:
            path = Path(path_str)
            if path.is_absolute():
                return path
            # Try relative to backend directory first (when running from backend/)
            backend_path = backend_dir / path
            if backend_path.exists():
                return backend_path
            # Try relative to project root (when running from project root)
            root_path = project_root / path
            if root_path.exists():
                return root_path
            # Return the path as-is (will raise error if doesn't exist)
            return path
        
        if label_map_file is None:
            if config_name == "10classes":
                label_map_file = "models/label_map_10classes.json"
            else:
                label_map_file = "models/label_map.json"
        
        if model_path is None:
            model_path = f"models/{model_name}_best.pth"
        
        # Resolve paths
        self.label_map_file = resolve_path(label_map_file, backend_dir)
        self.model_path = resolve_path(model_path, backend_dir)
        
        # Load label map
        if not self.label_map_file.exists():
            raise FileNotFoundError(
                f"Label map not found: {self.label_map_file}\n"
                f"Tried: {backend_dir / label_map_file}, {project_root / label_map_file}"
            )
        
        with open(self.label_map_file, "r", encoding="utf-8") as f:
            self.label_data = json.load(f)
        
        self.num_classes = self.label_data["num_classes"]
        self.idx_to_label = {int(k): v for k, v in self.label_data["idx_to_label"].items()}
        self.label_to_idx = {v: k for k, v in self.idx_to_label.items()}
        
        # Load model
        if not self.model_path.exists():
            raise FileNotFoundError(f"Model not found: {self.model_path}")
        
        self.model = self._create_model()
        self.model.eval()
        self.model.to(device)
        
        logger.info(f"✅ Loaded {model_name} model from {self.model_path}")
        logger.info(f"   Classes: {self.num_classes}, Device: {device}")
    
    def _create_model(self) -> nn.Module:
        """Create and load model architecture"""
        
        if self.model_name == "resnet50":
            model = resnet50(weights=None)
            model.fc = nn.Sequential(
                nn.Linear(model.fc.in_features, 512),
                nn.ReLU(),
                nn.Dropout(0.5),
                nn.Linear(512, self.num_classes)
            )
        
        elif self.model_name == "efficientnet_b6":
            model = efficientnet_b6(weights=None)
            in_features = model.classifier[1].in_features
            model.classifier = nn.Sequential(
                nn.Linear(in_features, 512),
                nn.ReLU(),
                nn.Dropout(0.5),
                nn.Linear(512, self.num_classes)
            )
        
        elif self.model_name == "vit":
            model = timm.create_model('vit_base_patch16_224', pretrained=False)
            model.head = nn.Sequential(
                nn.Linear(model.head.in_features, 512),
                nn.ReLU(),
                nn.Dropout(0.5),
                nn.Linear(512, self.num_classes)
            )
        
        else:
            raise ValueError(f"Unknown model: {self.model_name}")
        
        # Load weights
        model.load_state_dict(torch.load(self.model_path, map_location=device))
        return model
    
    def preprocess_image(self, image_input, image_size: int = 224) -> torch.Tensor:
        """
        Preprocess image for inference
        
        Args:
            image_input: Path to image file, PIL Image, or file-like object
            image_size: Target image size
        
        Returns:
            Preprocessed image tensor
        """
        transform = transforms.Compose([
            transforms.Resize((image_size, image_size)),
            transforms.ToTensor(),
            transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225])
        ])
        
        # Handle different input types
        if isinstance(image_input, (str, Path)):
            image = Image.open(image_input).convert("RGB")
        elif isinstance(image_input, Image.Image):
            image = image_input.convert("RGB")
        else:
            # Assume file-like object
            image = Image.open(image_input).convert("RGB")
        
        image_tensor = transform(image).unsqueeze(0)  # Add batch dimension
        return image_tensor.to(device)
    
    def predict(self, image_input, top_k: int = 3, confidence_threshold: float = 0.6) -> Dict:
        """
        Predict disease from image
        
        Args:
            image_input: Path to image file, PIL Image, or file-like object
            top_k: Number of top predictions to return
            confidence_threshold: Minimum confidence for prediction
        
        Returns:
            Dictionary with prediction results:
            {
                "predicted_disease": str,
                "predicted_idx": int,
                "confidence": float,
                "meets_threshold": bool,
                "top_predictions": List[Dict]
            }
        """
        # Preprocess image
        image_tensor = self.preprocess_image(image_input)
        
        # Predict
        with torch.no_grad():
            outputs = self.model(image_tensor)
            probs = torch.softmax(outputs, dim=1)
            confidence, predicted_idx = torch.max(probs, 1)
            confidence = confidence.item()
            predicted_idx = predicted_idx.item()
        
        predicted_disease = self.idx_to_label[predicted_idx]
        
        # Get top k predictions
        top_k = min(top_k, self.num_classes)
        top_probs, top_indices = torch.topk(probs, top_k, dim=1)
        top_predictions = [
            {
                "disease": self.idx_to_label[idx.item()],
                "idx": int(idx.item()),
                "confidence": float(prob.item())
            }
            for prob, idx in zip(top_probs[0], top_indices[0])
        ]
        
        result = {
            "predicted_disease": predicted_disease,
            "predicted_idx": predicted_idx,
            "confidence": confidence,
            "meets_threshold": confidence >= confidence_threshold,
            "top_predictions": top_predictions
        }
        
        return result
    
    def get_disease_name_normalized(self, disease_name: str) -> Optional[str]:
        """
        Get normalized disease name for database lookup
        Converts model output (e.g., 'eczema') to database name format
        
        Args:
            disease_name: Disease name from model prediction
        
        Returns:
            Normalized disease name or None if not found
        """
        # Model outputs are already normalized (lowercase, underscores)
        return disease_name.lower().replace(" ", "_")


# Global predictor instance (lazy loading)
_predictor_instance: Optional[SkinDiseasePredictor] = None


def get_predictor(model_name: str = "resnet50", config_name: str = "10classes") -> SkinDiseasePredictor:
    """
    Get or create global predictor instance (singleton pattern)
    
    Args:
        model_name: Model architecture
        config_name: Configuration preset
    
    Returns:
        SkinDiseasePredictor instance
    """
    global _predictor_instance
    
    if _predictor_instance is None or _predictor_instance.model_name != model_name.lower():
        _predictor_instance = SkinDiseasePredictor(
            model_name=model_name,
            config_name=config_name
        )
    
    return _predictor_instance

