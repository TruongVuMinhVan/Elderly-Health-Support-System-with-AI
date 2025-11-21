"""
Schedules and reminders API routes for Elderly Health Support System
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
from models.medication import Schedule, Reminder, ScheduleTypeEnum, ReminderTypeEnum

# Logging setup
logger = logging.getLogger(__name__)

# Create router
router = APIRouter(prefix="/api/schedules", tags=["schedules"])

# Pydantic models
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

class ReminderCreate(BaseModel):
    schedule_id: Optional[int] = None
    reminder_type: str
    title: str
    message: Optional[str] = None
    remind_datetime: datetime
    
    @validator('reminder_type')
    def validate_reminder_type(cls, v):
        if v not in ['medication', 'appointment', 'checkup', 'custom']:
            raise ValueError('Invalid reminder type')
        return v

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

# Schedule endpoints
@router.post("", response_model=ScheduleResponse, status_code=status.HTTP_201_CREATED)
async def create_schedule(
    schedule_data: ScheduleCreate,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_database)
):
    """
    Create a new schedule
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
        
        schedule = Schedule(
            user_id=user.id,
            schedule_type=ScheduleTypeEnum(schedule_data.schedule_type),
            title=schedule_data.title,
            description=schedule_data.description,
            scheduled_datetime=schedule_data.scheduled_datetime,
            location=schedule_data.location,
            doctor_name=schedule_data.doctor_name,
            medication_id=schedule_data.medication_id,
            is_recurring=schedule_data.is_recurring,
            recurrence_pattern=schedule_data.recurrence_pattern
        )
        
        db.add(schedule)
        db.commit()
        db.refresh(schedule)
        
        # Create automatic reminder (30 minutes before)
        reminder_datetime = schedule_data.scheduled_datetime - timedelta(minutes=30)
        if reminder_datetime > datetime.now():
            reminder = Reminder(
                user_id=user.id,
                schedule_id=schedule.id,
                reminder_type=ReminderTypeEnum(schedule_data.schedule_type),
                title=f"Nhắc nhở: {schedule_data.title}",
                message=f"Bạn có {schedule_data.title} vào lúc {schedule_data.scheduled_datetime.strftime('%H:%M')}",
                remind_datetime=reminder_datetime
            )
            db.add(reminder)
            db.commit()
        
        logger.info(f"Schedule created: {schedule.id} for user {user.id}")
        
        schedule_dict = schedule.to_dict()
        schedule_dict['is_upcoming'] = schedule.is_upcoming()
        schedule_dict['is_overdue'] = schedule.is_overdue()
        
        return ScheduleResponse(**schedule_dict)
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error creating schedule: {e}")
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to create schedule"
        )

@router.get("", response_model=List[ScheduleResponse])
async def get_schedules(
    schedule_type: Optional[str] = Query(None, description="Filter by schedule type"),
    upcoming_only: bool = Query(False, description="Get only upcoming schedules"),
    start_date: Optional[date] = Query(None, description="Start date filter"),
    end_date: Optional[date] = Query(None, description="End date filter"),
    limit: int = Query(50, ge=1, le=100, description="Number of schedules to return"),
    offset: int = Query(0, ge=0, description="Number of schedules to skip"),
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_database)
):
    """
    Get user's schedules with filtering and pagination
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
        
        query = db.query(Schedule).filter(Schedule.user_id == user.id)
        
        # Apply filters
        if schedule_type:
            query = query.filter(Schedule.schedule_type == ScheduleTypeEnum(schedule_type))
        
        if upcoming_only:
            query = query.filter(
                and_(
                    Schedule.scheduled_datetime > datetime.now(),
                    Schedule.is_completed == False
                )
            )
        
        if start_date:
            query = query.filter(Schedule.scheduled_datetime >= start_date)
        
        if end_date:
            query = query.filter(Schedule.scheduled_datetime <= end_date)
        
        # Order by scheduled_datetime
        query = query.order_by(Schedule.scheduled_datetime)
        
        # Apply pagination
        schedules = query.offset(offset).limit(limit).all()
        
        response_schedules = []
        for schedule in schedules:
            schedule_dict = schedule.to_dict()
            schedule_dict['is_upcoming'] = schedule.is_upcoming()
            schedule_dict['is_overdue'] = schedule.is_overdue()
            response_schedules.append(ScheduleResponse(**schedule_dict))
        
        return response_schedules
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting schedules: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to get schedules"
        )

@router.get("/today", response_model=List[ScheduleResponse])
async def get_today_schedules(
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_database)
):
    """
    Get today's schedules
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
        
        today = date.today()
        tomorrow = today + timedelta(days=1)
        
        schedules = db.query(Schedule).filter(
            and_(
                Schedule.user_id == user.id,
                Schedule.scheduled_datetime >= today,
                Schedule.scheduled_datetime < tomorrow
            )
        ).order_by(Schedule.scheduled_datetime).all()
        
        response_schedules = []
        for schedule in schedules:
            schedule_dict = schedule.to_dict()
            schedule_dict['is_upcoming'] = schedule.is_upcoming()
            schedule_dict['is_overdue'] = schedule.is_overdue()
            response_schedules.append(ScheduleResponse(**schedule_dict))
        
        return response_schedules
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting today's schedules: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to get today's schedules"
        )

@router.get("/{schedule_id}", response_model=ScheduleResponse)
async def get_schedule(
    schedule_id: int,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_database)
):
    """
    Get a specific schedule
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
        
        schedule = db.query(Schedule).filter(
            Schedule.id == schedule_id,
            Schedule.user_id == user.id
        ).first()
        
        if not schedule:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Schedule not found"
            )
        
        schedule_dict = schedule.to_dict()
        schedule_dict['is_upcoming'] = schedule.is_upcoming()
        schedule_dict['is_overdue'] = schedule.is_overdue()
        
        return ScheduleResponse(**schedule_dict)
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting schedule: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to get schedule"
        )

@router.put("/{schedule_id}", response_model=ScheduleResponse)
async def update_schedule(
    schedule_id: int,
    schedule_data: ScheduleUpdate,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_database)
):
    """
    Update a schedule
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
        
        schedule = db.query(Schedule).filter(
            Schedule.id == schedule_id,
            Schedule.user_id == user.id
        ).first()
        
        if not schedule:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Schedule not found"
            )
        
        # Update schedule fields
        update_data = schedule_data.model_dump(exclude_unset=True)
        for field, value in update_data.items():
            setattr(schedule, field, value)
        
        db.commit()
        db.refresh(schedule)
        
        logger.info(f"Schedule updated: {schedule.id} for user {user.id}")
        
        schedule_dict = schedule.to_dict()
        schedule_dict['is_upcoming'] = schedule.is_upcoming()
        schedule_dict['is_overdue'] = schedule.is_overdue()
        
        return ScheduleResponse(**schedule_dict)
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error updating schedule: {e}")
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to update schedule"
        )

@router.delete("/{schedule_id}")
async def delete_schedule(
    schedule_id: int,
    db: Session = Depends(get_database),
    current_user: dict = Depends(get_current_user)
):
    """
    Delete a schedule
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

        # Get the schedule
        schedule = db.query(Schedule).filter(
            Schedule.id == schedule_id,
            Schedule.user_id == user.id
        ).first()

        if not schedule:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Schedule not found"
            )

        # Delete the schedule
        db.delete(schedule)
        db.commit()

        return {"message": "Schedule deleted successfully"}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error deleting schedule: {str(e)}")
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to delete schedule"
        )
