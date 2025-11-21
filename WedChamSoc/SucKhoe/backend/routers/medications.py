"""
Medications and schedules API routes for Elderly Health Support System
"""

from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from sqlalchemy import desc, and_, or_
from typing import List, Optional
from pydantic import BaseModel, validator
from datetime import datetime, date, timedelta
import logging

from database import get_database
from auth_simple import get_current_user
from models.user import User
from models.medication import Medication, Schedule, Reminder, ScheduleTypeEnum, ReminderTypeEnum

# Logging setup
logger = logging.getLogger(__name__)

# Create router
router = APIRouter(prefix="/api/medications", tags=["medications"])

# Pydantic models
class MedicationCreate(BaseModel):
    medication_name: str
    dosage: Optional[str] = None
    frequency: Optional[str] = None
    instructions: Optional[str] = None
    start_date: Optional[date] = None
    end_date: Optional[date] = None

class MedicationUpdate(BaseModel):
    medication_name: Optional[str] = None
    dosage: Optional[str] = None
    frequency: Optional[str] = None
    instructions: Optional[str] = None
    start_date: Optional[date] = None
    end_date: Optional[date] = None
    is_active: Optional[bool] = None

class MedicationResponse(BaseModel):
    id: int
    user_id: int
    medication_name: str
    dosage: Optional[str]
    frequency: Optional[str]
    instructions: Optional[str]
    start_date: Optional[date]
    end_date: Optional[date]
    is_active: bool
    created_at: datetime
    updated_at: datetime
    is_current: bool

class ScheduleCreate(BaseModel):
    schedule_type: str
    title: str
    description: Optional[str] = None
    scheduled_datetime: datetime
    location: Optional[str] = None
    doctor_name: Optional[str] = None
    medication_id: Optional[int] = None
    is_recurring: bool = False
    recurrence_pattern: Optional[str] = None
    
    @validator('schedule_type')
    def validate_schedule_type(cls, v):
        if v not in ['medication', 'appointment', 'checkup']:
            raise ValueError('Invalid schedule type')
        return v

class ScheduleUpdate(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    scheduled_datetime: Optional[datetime] = None
    location: Optional[str] = None
    doctor_name: Optional[str] = None
    is_completed: Optional[bool] = None
    is_recurring: Optional[bool] = None
    recurrence_pattern: Optional[str] = None

class ScheduleResponse(BaseModel):
    id: int
    user_id: int
    schedule_type: str
    title: str
    description: Optional[str]
    scheduled_datetime: datetime
    location: Optional[str]
    doctor_name: Optional[str]
    medication_id: Optional[int]
    is_completed: bool
    is_recurring: bool
    recurrence_pattern: Optional[str]
    created_at: datetime
    updated_at: datetime
    is_upcoming: bool
    is_overdue: bool

class ReminderResponse(BaseModel):
    id: int
    user_id: int
    schedule_id: Optional[int]
    reminder_type: str
    title: str
    message: Optional[str]
    remind_datetime: datetime
    is_sent: bool
    is_read: bool
    created_at: datetime

# Medication endpoints
@router.post("", response_model=MedicationResponse, status_code=status.HTTP_201_CREATED)
async def create_medication(
    medication_data: MedicationCreate,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_database)
):
    """
    Create a new medication
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
        
        medication = Medication(
            user_id=user.id,
            medication_name=medication_data.medication_name,
            dosage=medication_data.dosage,
            frequency=medication_data.frequency,
            instructions=medication_data.instructions,
            start_date=medication_data.start_date,
            end_date=medication_data.end_date
        )
        
        db.add(medication)
        db.commit()
        db.refresh(medication)
        
        logger.info(f"Medication created: {medication.id} for user {user.id}")
        
        medication_dict = medication.to_dict()
        medication_dict['is_current'] = medication.is_current()
        
        return MedicationResponse(**medication_dict)
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error creating medication: {e}")
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to create medication"
        )

@router.get("", response_model=List[MedicationResponse])
async def get_medications(
    active_only: bool = Query(True, description="Get only active medications"),
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_database)
):
    """
    Get user's medications
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
        
        query = db.query(Medication).filter(Medication.user_id == user.id)
        
        if active_only:
            query = query.filter(Medication.is_active == True)
        
        medications = query.order_by(desc(Medication.created_at)).all()
        
        response_medications = []
        for medication in medications:
            medication_dict = medication.to_dict()
            medication_dict['is_current'] = medication.is_current()
            response_medications.append(MedicationResponse(**medication_dict))
        
        return response_medications
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting medications: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to get medications"
        )

@router.get("/{medication_id}", response_model=MedicationResponse)
async def get_medication(
    medication_id: int,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_database)
):
    """
    Get a specific medication
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
        
        medication = db.query(Medication).filter(
            Medication.id == medication_id,
            Medication.user_id == user.id
        ).first()
        
        if not medication:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Medication not found"
            )
        
        medication_dict = medication.to_dict()
        medication_dict['is_current'] = medication.is_current()
        
        return MedicationResponse(**medication_dict)
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting medication: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to get medication"
        )

@router.put("/{medication_id}", response_model=MedicationResponse)
async def update_medication(
    medication_id: int,
    medication_data: MedicationUpdate,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_database)
):
    """
    Update a medication
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
        
        medication = db.query(Medication).filter(
            Medication.id == medication_id,
            Medication.user_id == user.id
        ).first()
        
        if not medication:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Medication not found"
            )
        
        # Update medication fields
        update_data = medication_data.model_dump(exclude_unset=True)
        for field, value in update_data.items():
            setattr(medication, field, value)
        
        db.commit()
        db.refresh(medication)
        
        logger.info(f"Medication updated: {medication.id} for user {user.id}")
        
        medication_dict = medication.to_dict()
        medication_dict['is_current'] = medication.is_current()
        
        return MedicationResponse(**medication_dict)
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error updating medication: {e}")
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to update medication"
        )

@router.delete("/{medication_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_medication(
    medication_id: int,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_database)
):
    """
    Delete a medication
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
        
        medication = db.query(Medication).filter(
            Medication.id == medication_id,
            Medication.user_id == user.id
        ).first()
        
        if not medication:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Medication not found"
            )
        
        db.delete(medication)
        db.commit()
        
        logger.info(f"Medication deleted: {medication_id} for user {user.id}")
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error deleting medication: {e}")
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to delete medication"
        )
