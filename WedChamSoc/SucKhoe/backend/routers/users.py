"""
User management API routes for Elderly Health Support System
"""

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List, Optional
from pydantic import BaseModel, EmailStr, validator
from datetime import date, datetime
import logging

from database import get_database
from auth_simple import get_current_user, get_user_id
from models.user import User, UserSetting, GenderEnum
from models.health import HealthProfile, BloodTypeEnum

# Logging setup
logger = logging.getLogger(__name__)

# Create router
router = APIRouter(prefix="/api/users", tags=["users"])

# Pydantic models for request/response
class UserCreate(BaseModel):
    email: EmailStr
    phone: Optional[str] = None
    full_name: str
    date_of_birth: Optional[date] = None
    gender: Optional[str] = None
    address: Optional[str] = None
    emergency_contact_name: Optional[str] = None
    emergency_contact_phone: Optional[str] = None
    
    @validator('gender')
    def validate_gender(cls, v):
        if v and v not in ['male', 'female', 'other']:
            raise ValueError('Gender must be male, female, or other')
        return v

class UserUpdate(BaseModel):
    phone: Optional[str] = None
    full_name: Optional[str] = None
    date_of_birth: Optional[date] = None
    gender: Optional[str] = None
    address: Optional[str] = None
    emergency_contact_name: Optional[str] = None
    emergency_contact_phone: Optional[str] = None
    
    @validator('gender')
    def validate_gender(cls, v):
        if v and v not in ['male', 'female', 'other']:
            raise ValueError('Gender must be male, female, or other')
        return v

class HealthProfileCreate(BaseModel):
    height: Optional[float] = None
    blood_type: Optional[str] = None
    chronic_diseases: Optional[List[str]] = []
    allergies: Optional[List[str]] = []
    current_medications: Optional[List[str]] = []
    medical_notes: Optional[str] = None
    doctor_name: Optional[str] = None
    doctor_phone: Optional[str] = None
    insurance_info: Optional[str] = None
    
    @validator('blood_type')
    def validate_blood_type(cls, v):
        if v and v not in ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-']:
            raise ValueError('Invalid blood type')
        return v

class HealthProfileUpdate(HealthProfileCreate):
    pass

class UserResponse(BaseModel):
    id: int
    email: str
    phone: Optional[str]
    full_name: str
    date_of_birth: Optional[date]
    gender: Optional[str]
    address: Optional[str]
    emergency_contact_name: Optional[str]
    emergency_contact_phone: Optional[str]
    created_at: datetime
    updated_at: datetime
    is_active: bool
    age: Optional[int] = None

class UserSettingCreate(BaseModel):
    setting_key: str
    setting_value: str

class UserSettingUpdate(BaseModel):
    setting_value: str

@router.put("/me", response_model=UserResponse)
async def update_current_user_profile(
    user_data: UserUpdate,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_database)
):
    """
    Update current user's profile
    """
    try:
        user_id = current_user.get("sub")

        user = db.query(User).filter(User.id == user_id).first()
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found"
            )

        # Update user fields
        update_data = user_data.model_dump(exclude_unset=True)
        for field, value in update_data.items():
            if field == 'gender' and value:
                setattr(user, field, GenderEnum(value))
            else:
                setattr(user, field, value)

        db.commit()
        db.refresh(user)

        logger.info(f"User updated successfully: {user.id}")

        user_dict = user.to_dict()
        user_dict['age'] = user.age
        return UserResponse(**user_dict)

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error updating user profile: {e}")
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to update user profile"
        )

@router.get("/me", response_model=UserResponse)
async def get_current_user_profile(
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_database)
):
    """
    Get current user's profile
    """
    try:
        user_id = current_user.get("sub")
        # Convert to int if it's a string
        if isinstance(user_id, str):
            user_id = int(user_id)

        user = db.query(User).filter(User.id == user_id).first()
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found"
            )

        user_dict = user.to_dict()
        user_dict['age'] = user.age
        return UserResponse(**user_dict)

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting user profile: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to get user profile"
        )

@router.put("/me", response_model=UserResponse)
async def update_current_user_profile(
    user_data: UserUpdate,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_database)
):
    """
    Update current user's profile
    """
    try:
        user_id = current_user.get("sub")
        # Convert to int if it's a string
        if isinstance(user_id, str):
            user_id = int(user_id)

        user = db.query(User).filter(User.id == user_id).first()
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found"
            )
        
        # Update user fields
        update_data = user_data.dict(exclude_unset=True)
        for field, value in update_data.items():
            if field == 'gender' and value:
                setattr(user, field, GenderEnum(value))
            else:
                setattr(user, field, value)
        
        db.commit()
        db.refresh(user)
        
        logger.info(f"User updated successfully: {user.id}")
        
        user_dict = user.to_dict()
        user_dict['age'] = user.age
        return UserResponse(**user_dict)
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error updating user profile: {e}")
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to update user profile"
        )

@router.post("/me/health-profile")
async def create_health_profile(
    profile_data: HealthProfileCreate,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_database)
):
    """
    Create health profile for current user
    """
    try:
        user_id = current_user.get("sub")
        # Convert to int if it's a string
        if isinstance(user_id, str):
            user_id = int(user_id)

        user = db.query(User).filter(User.id == user_id).first()
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found"
            )
        
        # Check if health profile already exists
        existing_profile = db.query(HealthProfile).filter(HealthProfile.user_id == user.id).first()
        if existing_profile:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Health profile already exists"
            )
        
        # Create health profile
        health_profile = HealthProfile(
            user_id=user.id,
            height=profile_data.height,
            blood_type=BloodTypeEnum(profile_data.blood_type) if profile_data.blood_type else None,
            medical_notes=profile_data.medical_notes,
            doctor_name=profile_data.doctor_name,
            doctor_phone=profile_data.doctor_phone,
            insurance_info=profile_data.insurance_info
        )
        
        # Set JSON fields
        if profile_data.chronic_diseases:
            health_profile.set_chronic_diseases(profile_data.chronic_diseases)
        if profile_data.allergies:
            health_profile.set_allergies(profile_data.allergies)
        if profile_data.current_medications:
            health_profile.set_current_medications(profile_data.current_medications)
        
        db.add(health_profile)
        db.commit()
        db.refresh(health_profile)
        
        logger.info(f"Health profile created for user: {user.id}")
        return health_profile.to_dict()
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error creating health profile: {e}")
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to create health profile"
        )

@router.get("/me/health-profile")
async def get_health_profile(
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_database)
):
    """
    Get current user's health profile
    """
    try:
        user_id = current_user.get("sub")
        # Convert to int if it's a string
        if isinstance(user_id, str):
            user_id = int(user_id)

        user = db.query(User).filter(User.id == user_id).first()
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found"
            )
        
        health_profile = db.query(HealthProfile).filter(HealthProfile.user_id == user.id).first()
        if not health_profile:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Health profile not found"
            )
        
        return health_profile.to_dict()
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting health profile: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to get health profile"
        )

@router.put("/me/health-profile")
async def update_health_profile(
    profile_data: HealthProfileUpdate,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_database)
):
    """
    Update current user's health profile
    """
    try:
        user_id = current_user.get("sub")
        # Convert to int if it's a string
        if isinstance(user_id, str):
            user_id = int(user_id)

        user = db.query(User).filter(User.id == user_id).first()
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found"
            )
        
        health_profile = db.query(HealthProfile).filter(HealthProfile.user_id == user.id).first()
        if not health_profile:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Health profile not found"
            )
        
        # Update health profile fields
        update_data = profile_data.dict(exclude_unset=True)
        for field, value in update_data.items():
            if field == 'blood_type' and value:
                setattr(health_profile, field, BloodTypeEnum(value))
            elif field in ['chronic_diseases', 'allergies', 'current_medications']:
                if field == 'chronic_diseases':
                    health_profile.set_chronic_diseases(value)
                elif field == 'allergies':
                    health_profile.set_allergies(value)
                elif field == 'current_medications':
                    health_profile.set_current_medications(value)
            else:
                setattr(health_profile, field, value)
        
        db.commit()
        db.refresh(health_profile)
        
        logger.info(f"Health profile updated for user: {user.id}")
        return health_profile.to_dict()
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error updating health profile: {e}")
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to update health profile"
        )

@router.get("/me/settings")
async def get_user_settings(
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_database)
):
    """
    Get current user's settings
    """
    try:
        user_id = current_user.get("sub")
        # Convert to int if it's a string
        if isinstance(user_id, str):
            user_id = int(user_id)

        user = db.query(User).filter(User.id == user_id).first()
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found"
            )

        settings = db.query(UserSetting).filter(UserSetting.user_id == user.id).all()
        return [setting.to_dict() for setting in settings]

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting user settings: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to get user settings"
        )

@router.post("/me/settings")
async def create_user_setting(
    setting_data: UserSettingCreate,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_database)
):
    """
    Create or update user setting
    """
    try:
        user_id = current_user.get("sub")
        # Convert to int if it's a string
        if isinstance(user_id, str):
            user_id = int(user_id)

        user = db.query(User).filter(User.id == user_id).first()
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found"
            )

        # Check if setting exists
        existing_setting = db.query(UserSetting).filter(
            UserSetting.user_id == user.id,
            UserSetting.setting_key == setting_data.setting_key
        ).first()

        if existing_setting:
            # Update existing setting
            existing_setting.setting_value = setting_data.setting_value
            db.commit()
            db.refresh(existing_setting)
            return existing_setting.to_dict()
        else:
            # Create new setting
            new_setting = UserSetting(
                user_id=user.id,
                setting_key=setting_data.setting_key,
                setting_value=setting_data.setting_value
            )
            db.add(new_setting)
            db.commit()
            db.refresh(new_setting)
            return new_setting.to_dict()

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error creating user setting: {e}")
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to create user setting"
        )
