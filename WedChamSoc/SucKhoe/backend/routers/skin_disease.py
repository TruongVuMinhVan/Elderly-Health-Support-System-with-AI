
from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File, Form
from sqlalchemy.orm import Session
from typing import List, Optional
from pydantic import BaseModel
from datetime import datetime
import logging
import os
import uuid
from pathlib import Path

from database import get_database
from auth_simple import get_current_user
from models.user import User
from models.skin_disease import SkinDisease, SkinDiseasePrediction
from ml.predictor import get_predictor, get_ensemble_predictor

# Logging setup
logger = logging.getLogger(__name__)

# Create router
router = APIRouter(prefix="/api/skin-disease", tags=["skin-disease"])

# Configuration
UPLOAD_DIR = Path("uploads/skin_disease")
UPLOAD_DIR.mkdir(parents=True, exist_ok=True)
ALLOWED_EXTENSIONS = {".jpg", ".jpeg", ".png", ".bmp"}
MAX_FILE_SIZE = 10 * 1024 * 1024  # 10MB

# Pydantic models
class SkinDiseaseResponse(BaseModel):
    id: int
    name: str
    name_vi: Optional[str]
    description: Optional[str]
    symptoms: List[str]
    causes: Optional[str]
    treatment: Optional[str]
    prevention: Optional[str]
    severity: Optional[str]
    is_common: bool

class TopPrediction(BaseModel):
    disease_name: str
    disease: Optional[SkinDiseaseResponse] = None
    confidence: float
    rank: int

class PredictionResponse(BaseModel):
    id: int
    user_id: Optional[int] = None  # Optional for quick scan
    image_path: Optional[str] = None  # Optional for quick scan
    predicted_disease: Optional[SkinDiseaseResponse]  # Full disease info from database
    predicted_disease_name: Optional[str] = None  # Original name from model prediction
    confidence: Optional[float]
    created_at: Optional[str] = None  # Optional for quick scan
    top_predictions: Optional[List[TopPrediction]] = None
    severity: Optional[str] = None  # For quick scan
    requires_login: Optional[bool] = False  # Flag for quick scan

class PredictionRequest(BaseModel):

    actual_disease_id: Optional[int] = None
    user_feedback: Optional[str] = None
    is_confirmed: bool = False

# Helper functions
def allowed_file(filename: str) -> bool:
    return Path(filename).suffix.lower() in ALLOWED_EXTENSIONS

def match_disease_name(db: Session, disease_name: str) -> Optional[SkinDisease]:
    """
    Match disease name from model prediction to database
    
    Args:
        db: Database session
        disease_name: Disease name from model (e.g., 'basal_cell_carcinoma')
    
    Returns:
        SkinDisease object if found, None otherwise
    """
    # Normalize predicted name for matching
    predicted_name_normalized = disease_name.lower().strip()
    
    # Try exact match first
    disease = db.query(SkinDisease).filter(
        SkinDisease.name.ilike(predicted_name_normalized)
    ).first()
    
    # If not found, try variations
    if not disease:
        name_with_spaces = predicted_name_normalized.replace("_", " ")
        disease = db.query(SkinDisease).filter(
            SkinDisease.name.ilike(name_with_spaces)
        ).first()
    
    if not disease:
        name_with_hyphens = predicted_name_normalized.replace("_", "-")
        disease = db.query(SkinDisease).filter(
            SkinDisease.name.ilike(name_with_hyphens)
        ).first()
    
    if not disease:
        disease = db.query(SkinDisease).filter(
            SkinDisease.name.ilike(f"%{predicted_name_normalized}%")
        ).first()
    
    return disease

def save_uploaded_file(file: UploadFile, user_id: int) -> str:

    if not allowed_file(file.filename):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"File type not allowed. Allowed types: {', '.join(ALLOWED_EXTENSIONS)}"
        )
    
    # Generate unique filename
    file_ext = Path(file.filename).suffix
    unique_filename = f"{user_id}_{uuid.uuid4()}{file_ext}"
    file_path = UPLOAD_DIR / unique_filename
    
    # Save file
    try:
        with open(file_path, "wb") as f:
            content = file.file.read()
            if len(content) > MAX_FILE_SIZE:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"File too large. Maximum size: {MAX_FILE_SIZE / 1024 / 1024}MB"
                )
            f.write(content)
        
        # Return relative path for database
        return f"uploads/skin_disease/{unique_filename}"
    except Exception as e:
        logger.error(f"Error saving file: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to save uploaded file"
        )

# API Endpoints

@router.get("/diseases", response_model=List[SkinDiseaseResponse])
async def get_all_diseases(
    db: Session = Depends(get_database)
):

    try:
        diseases = db.query(SkinDisease).all()
        return [disease.to_dict() for disease in diseases]
    except Exception as e:
        logger.error(f"Error fetching diseases: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to fetch diseases"
        )

@router.get("/diseases/{disease_id}", response_model=SkinDiseaseResponse)
async def get_disease(
    disease_id: int,
    db: Session = Depends(get_database)
):

    disease = db.query(SkinDisease).filter(SkinDisease.id == disease_id).first()
    if not disease:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Disease not found"
        )
    return disease.to_dict()

@router.post("/quick-scan", response_model=PredictionResponse)
async def quick_scan(
    image: UploadFile = File(...),
    db: Session = Depends(get_database)
):
    """
    Quick Scan - Chẩn đoán nhanh KHÔNG CẦN ĐĂNG NHẬP
    
    - Người dùng chụp/tải ảnh lên
    - AI phân tích ngay lập tức
    - Hiển thị kết quả: tên bệnh, mức độ nghiêm trọng, gợi ý
    - KHÔNG lưu ảnh hoặc kết quả vào database
    - Có nút "Lưu kết quả" → yêu cầu đăng nhập
    """
    try:
        import tempfile
        import os
        
        # Validate file
        if not image.filename:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="No file provided"
            )
        
        # Save to temporary file (will be deleted after processing)
        temp_file_path = None
        try:
            # Create temp directory if not exists
            temp_dir = Path(tempfile.gettempdir()) / "quick_scan"
            temp_dir.mkdir(parents=True, exist_ok=True)
            
            # Create temp file
            file_ext = Path(image.filename).suffix
            temp_file = tempfile.NamedTemporaryFile(
                delete=False,
                suffix=file_ext,
                dir=str(temp_dir)
            )
            temp_file_path = Path(temp_file.name)
            
            # Write uploaded file to temp
            content = await image.read()
            temp_file.write(content)
            temp_file.close()
            
            # Load predictor (sử dụng ViT model)
            try:
                predictor = get_predictor(model_name="vit", config_name="from_dataset")
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
                    confidence_threshold=0.4  # Giảm threshold cho ViT để tăng độ nhạy
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
            
            # Get severity
            severity = None
            if disease and disease.severity:
                severity = disease.severity.value if hasattr(disease.severity, 'value') else str(disease.severity)
            else:
                # Default severity based on disease type
                high_severity_diseases = ["melanoma", "basal_cell_carcinoma", "squamous_cell_carcinoma"]
                if any(d in predicted_disease_name.lower() for d in high_severity_diseases):
                    severity = "severe" if confidence > 0.7 else "moderate"
                else:
                    severity = "mild"
            
            # Process top predictions
            top_predictions = []
            if "top_predictions" in prediction_result:
                for rank, top_pred in enumerate(prediction_result["top_predictions"], 1):
                    top_disease_name = top_pred["disease"]
                    top_confidence = top_pred["confidence"]
                    top_disease = match_disease_name(db, top_disease_name)
                    
                    top_predictions.append({
                        "disease_name": top_disease_name,
                        "disease": top_disease.to_dict() if top_disease else None,
                        "confidence": float(top_confidence),
                        "rank": rank
                    })
            
            logger.info(f"✅ Quick scan completed: {predicted_disease_name} (confidence: {confidence:.2%})")
            
            # Return response (similar to PredictionResponse but without saving to DB)
            return {
                "id": 0,  # No ID since not saved
                "user_id": None,  # No user since no login
                "image_path": None,  # Not saved
                "predicted_disease": predicted_disease,
                "predicted_disease_name": predicted_disease_name,
                "confidence": float(confidence),
                "created_at": None,
                "top_predictions": top_predictions,
                "severity": severity,
                "requires_login": True  # Flag to show "Save result" button
            }
            
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

@router.post("/predict", response_model=PredictionResponse)
async def predict_skin_disease(
    image: UploadFile = File(...),
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_database)
):

    try:
        # Lưu file ảnh đã upload
        image_path = save_uploaded_file(image, current_user["id"])
        full_image_path = Path(image_path)
        
        # Tải ensemble predictor (kết hợp ResNet50 + ViT)
        try:
            predictor = get_ensemble_predictor(config_name="from_dataset")
        except FileNotFoundError as e:
            logger.error(f"Không tìm thấy model: {e}")
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail="Model AI không khả dụng. Vui lòng đảm bảo model đã được train."
            )
        except Exception as e:
            logger.error(f"Lỗi tải model: {e}")
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Không thể tải model AI: {str(e)}"
            )
        
        # Thực hiện dự đoán
        try:
            prediction_result = predictor.predict(full_image_path, top_k=3, confidence_threshold=0.4)  # ViT model
        except Exception as e:
            logger.error(f"Lỗi khi dự đoán: {e}")
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Dự đoán thất bại: {str(e)}"
            )
        
        # Ánh xạ tên bệnh từ model sang database
        predicted_disease_name = prediction_result["predicted_disease"]
        confidence = prediction_result["confidence"]
        predicted_name_normalized = predicted_disease_name.lower().strip()
        
        # Tìm bệnh trong database (thử nhiều cách: exact, underscore, space, hyphen, partial)
        disease = db.query(SkinDisease).filter(
            SkinDisease.name.ilike(predicted_name_normalized)
        ).first()
        
        if not disease:
            disease = db.query(SkinDisease).filter(
                SkinDisease.name.ilike(predicted_name_normalized.replace("_", " "))
            ).first()
        if not disease:
            disease = db.query(SkinDisease).filter(
                SkinDisease.name.ilike(predicted_name_normalized.replace("_", "-"))
            ).first()
        if not disease:
            disease = db.query(SkinDisease).filter(
                SkinDisease.name.ilike(f"%{predicted_name_normalized}%")
            ).first()
        
        predicted_disease_id = disease.id if disease else None
        
        # Lưu kết quả dự đoán vào database
        prediction = SkinDiseasePrediction(
            user_id=current_user["id"],
            image_path=image_path,
            predicted_disease_id=predicted_disease_id,
            confidence=float(confidence)
        )
        db.add(prediction)
        db.commit()
        db.refresh(prediction)
        
        # Lấy thông tin bệnh từ database
        predicted_disease = None
        if disease:
            predicted_disease = disease.to_dict()
            logger.info(f"✅ Đã khớp bệnh: {disease.name} (ID: {disease.id})")
        elif predicted_disease_id:
            disease_obj = db.query(SkinDisease).filter(SkinDisease.id == predicted_disease_id).first()
            if disease_obj:
                predicted_disease = disease_obj.to_dict()
        
        if predicted_disease:
            logger.info(f"✅ Dự đoán hoàn tất: {predicted_disease.get('name', predicted_disease_name)} (confidence: {confidence:.2%})")
        else:
            logger.warning(f"⚠️ Dự đoán hoàn tất nhưng không tìm thấy bệnh trong database: {predicted_disease_name}")
        
        # Trả về kết quả với đầy đủ thông tin bệnh
        return {
            "id": prediction.id,
            "user_id": prediction.user_id,
            "image_path": prediction.image_path,
            "predicted_disease": predicted_disease,
            "predicted_disease_name": predicted_disease_name,
            "confidence": float(prediction.confidence) if prediction.confidence else None,
            "created_at": prediction.created_at.isoformat() if prediction.created_at else None
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error in prediction: {e}", exc_info=True)
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Prediction failed: {str(e)}"
        )

@router.get("/predictions", response_model=List[PredictionResponse])
async def get_user_predictions(
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_database),
    limit: int = 20
):
    try:
        predictions = db.query(SkinDiseasePrediction).filter(
            SkinDiseasePrediction.user_id == current_user["id"]
        ).order_by(SkinDiseasePrediction.created_at.desc()).limit(limit).all()
        
        result = []
        for pred in predictions:
            predicted_disease = None
            if pred.predicted_disease_id:
                disease = db.query(SkinDisease).filter(
                    SkinDisease.id == pred.predicted_disease_id
                ).first()
                if disease:
                    predicted_disease = disease.to_dict()
            
            result.append({
                "id": pred.id,
                "user_id": pred.user_id,
                "image_path": pred.image_path,
                "predicted_disease": predicted_disease,
                "confidence": float(pred.confidence) if pred.confidence else None,
                "created_at": pred.created_at.isoformat() if pred.created_at else None
            })
        
        return result
    except Exception as e:
        logger.error(f"Error fetching predictions: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to fetch predictions"
        )

@router.post("/predict/test", response_model=PredictionResponse)
async def predict_skin_disease_test(
    image: UploadFile = File(...),
    db: Session = Depends(get_database)
):
    """
    Test endpoint for prediction (no authentication required)
    For testing purposes only
    """
    try:
        # Find or create a test user
        # First, try to find any existing user
        test_user = db.query(User).first()
        
        if not test_user:
            # Create a test user if none exists
            from datetime import datetime
            from werkzeug.security import generate_password_hash
            from models.user import GenderEnum
            
            test_user = User(
                email="test@example.com",
                password_hash=generate_password_hash("test123"),
                full_name="Test User",
                date_of_birth=datetime(1950, 1, 1),
                gender=GenderEnum.other,
                phone="0000000000",
                created_at=datetime.now(),
                updated_at=datetime.now()
            )
            db.add(test_user)
            db.commit()
            db.refresh(test_user)
            logger.info(f"✅ Created test user with ID: {test_user.id}")
        
        test_user_id = test_user.id
        logger.info(f"✅ Using test user ID: {test_user_id}")
        
        # Save uploaded file
        image_path = save_uploaded_file(image, test_user_id)
        full_image_path = Path(image_path)
        
        # Load predictor (uses from_dataset config to match quick-scan)
        try:
            predictor = get_predictor(model_name="resnet50", config_name="from_dataset")
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
            prediction_result = predictor.predict(full_image_path, top_k=3, confidence_threshold=0.4)  # ViT model
        except Exception as e:
            logger.error(f"Error during prediction: {e}")
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Prediction failed: {str(e)}"
            )
        
        # Map predicted disease name to database
        predicted_disease_name = prediction_result["predicted_disease"]
        confidence = prediction_result["confidence"]
        
        # Match disease using helper function
        disease = match_disease_name(db, predicted_disease_name)
        predicted_disease_id = disease.id if disease else None
        
        # Save prediction to database
        prediction = SkinDiseasePrediction(
            user_id=test_user_id,
            image_path=image_path,
            predicted_disease_id=predicted_disease_id,
            confidence=float(confidence)
        )
        db.add(prediction)
        db.commit()
        db.refresh(prediction)
        
        # Get disease info from database
        predicted_disease = None
        if disease:
            predicted_disease = disease.to_dict()
            logger.info(f"✅ Disease matched: {disease.name} (ID: {disease.id})")
        
        # Process top predictions
        top_predictions = []
        if "top_predictions" in prediction_result:
            for rank, top_pred in enumerate(prediction_result["top_predictions"], 1):
                top_disease_name = top_pred["disease"]
                top_confidence = top_pred["confidence"]
                
                # Match to database
                top_disease_obj = match_disease_name(db, top_disease_name)
                top_disease_dict = top_disease_obj.to_dict() if top_disease_obj else None
                
                top_predictions.append({
                    "disease_name": top_disease_name,
                    "disease": top_disease_dict,
                    "confidence": float(top_confidence),
                    "rank": rank
                })
        
        logger.info(f"✅ Test prediction completed: {predicted_disease_name} (confidence: {confidence:.2%})")
        
        return {
            "id": prediction.id,
            "user_id": prediction.user_id,
            "image_path": prediction.image_path,
            "predicted_disease": predicted_disease,
            "predicted_disease_name": predicted_disease_name,
            "confidence": float(prediction.confidence) if prediction.confidence else None,
            "created_at": prediction.created_at.isoformat() if prediction.created_at else None,
            "top_predictions": top_predictions
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error in test prediction: {e}", exc_info=True)
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Prediction failed: {str(e)}"
        )

@router.get("/predictions/all", response_model=List[PredictionResponse])
async def get_all_predictions(
    db: Session = Depends(get_database),
    limit: int = 100,
    user_id: Optional[int] = None
):

    try:
        query = db.query(SkinDiseasePrediction)
        
        if user_id:
            query = query.filter(SkinDiseasePrediction.user_id == user_id)
        
        predictions = query.order_by(
            SkinDiseasePrediction.created_at.desc()
        ).limit(limit).all()
        
        result = []
        for pred in predictions:
            predicted_disease = None
            if pred.predicted_disease_id:
                disease = db.query(SkinDisease).filter(
                    SkinDisease.id == pred.predicted_disease_id
                ).first()
                if disease:
                    predicted_disease = disease.to_dict()
            
            result.append({
                "id": pred.id,
                "user_id": pred.user_id,
                "image_path": pred.image_path,
                "predicted_disease": predicted_disease,
                "confidence": float(pred.confidence) if pred.confidence else None,
                "created_at": pred.created_at.isoformat() if pred.created_at else None
            })
        
        return result
    except Exception as e:
        logger.error(f"Error fetching all predictions: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to fetch predictions"
        )

@router.put("/predictions/{prediction_id}/confirm")
async def confirm_prediction(
    prediction_id: int,
    request: PredictionRequest,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_database)
):
    """
    Confirm or update prediction with user feedback
    """
    try:
        prediction = db.query(SkinDiseasePrediction).filter(
            SkinDiseasePrediction.id == prediction_id,
            SkinDiseasePrediction.user_id == current_user["id"]
        ).first()
        
        if not prediction:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Prediction not found"
            )
        
        # Update prediction
        if request.actual_disease_id is not None:
            prediction.actual_disease_id = request.actual_disease_id
        if request.user_feedback is not None:
            prediction.user_feedback = request.user_feedback
        prediction.is_confirmed = request.is_confirmed
        
        db.commit()
        db.refresh(prediction)
        
        return {
            "status": "success",
            "message": "Prediction confirmed",
            "prediction": prediction.to_dict()
        }
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error confirming prediction: {e}")
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to confirm prediction"
        )

