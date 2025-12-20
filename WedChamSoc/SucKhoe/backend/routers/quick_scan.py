"""
Quick Scan API - Chẩn đoán nhanh không cần đăng nhập
"""

from fastapi import APIRouter, HTTPException, status, UploadFile, File, Depends
from sqlalchemy.orm import Session
from typing import Optional
from pydantic import BaseModel
import logging
import tempfile
import os
from pathlib import Path

from database import get_database
from ml.predictor import get_predictor, get_ensemble_predictor
from models.skin_disease import SkinDisease
from routers.skin_disease import match_disease_name
from auth_simple import get_current_user

# Logging setup
logger = logging.getLogger(__name__)

# Create router
router = APIRouter(prefix="/api/quick-scan", tags=["quick-scan"])

# Pydantic models
class QuickScanResponse(BaseModel):
    predicted_disease_name: str
    predicted_disease: Optional[dict] = None
    confidence: float
    severity: Optional[str] = None
    recommendation: str
    top_predictions: list = []
    requires_login: bool = True  # Cần đăng nhập để lưu kết quả

class QuickScanRequest(BaseModel):
    save_result: bool = False
    user_id: Optional[int] = None

# Temporary directory for quick scan (auto-cleanup)
TEMP_DIR = Path(tempfile.gettempdir()) / "quick_scan"
TEMP_DIR.mkdir(exist_ok=True)

def get_severity_level(disease_name: str, confidence: float, db: Session) -> str:
    """Determine severity level based on disease and confidence"""
    disease = match_disease_name(db, disease_name)
    
    if disease and disease.severity:
        return disease.severity.value if hasattr(disease.severity, 'value') else str(disease.severity)
    
    # Default severity based on disease type
    high_severity_diseases = ["melanoma", "basal_cell_carcinoma", "squamous_cell_carcinoma"]
    if any(d in disease_name.lower() for d in high_severity_diseases):
        return "severe" if confidence > 0.7 else "moderate"
    
    return "mild"

def get_recommendation(disease_name: str, confidence: float, severity: str, db: Session) -> str:
    """Generate recommendation based on prediction"""
    disease = match_disease_name(db, disease_name)
    
    if severity == "severe" or confidence > 0.8:
        return "⚠️ Khuyến nghị: Nên đi khám bác sĩ da liễu ngay để được chẩn đoán chính xác và điều trị kịp thời."
    elif severity == "moderate" or confidence > 0.6:
        return "💡 Khuyến nghị: Nên theo dõi và đi khám bác sĩ trong vòng 1-2 tuần nếu tình trạng không cải thiện."
    else:
        return "✅ Khuyến nghị: Có thể theo dõi tại nhà. Nếu có thay đổi hoặc lo ngại, nên tham khảo ý kiến bác sĩ."

@router.post("/scan", response_model=QuickScanResponse)
async def quick_scan(
    image: UploadFile = File(...),
    db: Session = Depends(get_database)
):
    """
    Quick scan - Chẩn đoán nhanh không cần đăng nhập
    
    - Không lưu ảnh hoặc kết quả vào database
    - Trả về kết quả ngay lập tức
    - Có nút "Lưu kết quả" yêu cầu đăng nhập
    """
    try:
        # Validate file
        if not image.filename:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="No file provided"
            )
        
        # Save to temporary file (will be deleted after processing)
        temp_file_path = None
        try:
            # Create temp file
            file_ext = Path(image.filename).suffix
            temp_file = tempfile.NamedTemporaryFile(
                delete=False,
                suffix=file_ext,
                dir=TEMP_DIR
            )
            temp_file_path = Path(temp_file.name)
            
            # Write uploaded file to temp
            content = await image.read()
            temp_file.write(content)
            temp_file.close()
            
            # Load ensemble predictor (kết hợp ResNet50 + ViT)
            try:
                predictor = get_ensemble_predictor(config_name="from_dataset")
            except FileNotFoundError as e:
                logger.error(f"Model not found: {e}")
                raise HTTPException(
                    status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                    detail="AI model not available. Please ensure model is trained."
                )
            except Exception as e:
                logger.error(f"Error loading model: {e}")
                raise HTTPException(
                    status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                    detail=f"Failed to load AI model: {str(e)}"
                )
            
            # Perform prediction
            try:
                prediction_result = predictor.predict(
                    temp_file_path, 
                    top_k=3, 
                    confidence_threshold=0.5
                )
            except Exception as e:
                logger.error(f"Error during prediction: {e}")
                raise HTTPException(
                    status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                    detail=f"Prediction failed: {str(e)}"
                )
            
            # Get prediction details
            predicted_disease_name = prediction_result["predicted_disease"]
            confidence = prediction_result["confidence"]
            
            # Match disease in database
            disease = match_disease_name(db, predicted_disease_name)
            predicted_disease = disease.to_dict() if disease else None
            
            # Get severity and recommendation
            severity = get_severity_level(predicted_disease_name, confidence, db)
            recommendation = get_recommendation(predicted_disease_name, confidence, severity, db)
            
            # Process top predictions
            top_predictions = []
            if "top_predictions" in prediction_result:
                for top_pred in prediction_result["top_predictions"]:
                    top_disease_name = top_pred["disease"]
                    top_confidence = top_pred["confidence"]
                    top_disease = match_disease_name(db, top_disease_name)
                    
                    top_predictions.append({
                        "disease_name": top_disease_name,
                        "disease": top_disease.to_dict() if top_disease else None,
                        "confidence": float(top_confidence),
                        "rank": len(top_predictions) + 1
                    })
            
            logger.info(f"✅ Quick scan completed: {predicted_disease_name} (confidence: {confidence:.2%})")
            
            return QuickScanResponse(
                predicted_disease_name=predicted_disease_name,
                predicted_disease=predicted_disease,
                confidence=float(confidence),
                severity=severity,
                recommendation=recommendation,
                top_predictions=top_predictions,
                requires_login=True
            )
            
        finally:
            # Clean up temp file
            if temp_file_path and temp_file_path.exists():
                try:
                    os.unlink(temp_file_path)
                except Exception as e:
                    logger.warning(f"Failed to delete temp file {temp_file_path}: {e}")
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error in quick scan: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Quick scan failed: {str(e)}"
        )

@router.post("/save-result")
async def save_quick_scan_result(
    request: QuickScanRequest,
    current_user: dict = Depends(get_current_user),
    db: Session = get_database()
):
    """
    Lưu kết quả quick scan vào database (cần đăng nhập)
    """
    # This endpoint requires authentication
    # Implementation will be added when user wants to save result
    pass

