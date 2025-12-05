"""
Health records API routes for Elderly Health Support System
"""

from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from sqlalchemy import desc, func
from typing import List, Optional, Dict
from pydantic import BaseModel, validator
from datetime import datetime, date, timedelta
import logging

from database import get_database
from auth_simple import get_current_user
from models.user import User
from models.health import HealthRecord, RecordTypeEnum

# Logging setup
logger = logging.getLogger(__name__)

# Create router
router = APIRouter(prefix="/api/health", tags=["health"])

# Pydantic models
class HealthRecordCreate(BaseModel):
    record_type: str
    systolic_pressure: Optional[int] = None
    diastolic_pressure: Optional[int] = None
    heart_rate: Optional[int] = None
    blood_sugar: Optional[float] = None
    weight: Optional[float] = None
    temperature: Optional[float] = None
    notes: Optional[str] = None
    recorded_at: Optional[datetime] = None
    
    @validator('record_type')
    def validate_record_type(cls, v):
        if v not in ['blood_pressure', 'heart_rate', 'blood_sugar', 'weight', 'temperature']:
            raise ValueError('Invalid record type')
        return v
    
    @validator('systolic_pressure', 'diastolic_pressure')
    def validate_blood_pressure(cls, v, values):
        if values.get('record_type') == 'blood_pressure' and v is None:
            raise ValueError('Blood pressure values are required for blood pressure records')
        if v is not None and (v < 50 or v > 300):
            raise ValueError('Blood pressure value out of valid range')
        return v
    
    @validator('heart_rate')
    def validate_heart_rate(cls, v, values):
        if values.get('record_type') == 'heart_rate' and v is None:
            raise ValueError('Heart rate is required for heart rate records')
        if v is not None and (v < 30 or v > 200):
            raise ValueError('Heart rate value out of valid range')
        return v
    
    @validator('blood_sugar')
    def validate_blood_sugar(cls, v, values):
        if values.get('record_type') == 'blood_sugar' and v is None:
            raise ValueError('Blood sugar is required for blood sugar records')
        if v is not None and (v < 20 or v > 600):
            raise ValueError('Blood sugar value out of valid range')
        return v
    
    @validator('weight')
    def validate_weight(cls, v, values):
        if values.get('record_type') == 'weight' and v is None:
            raise ValueError('Weight is required for weight records')
        if v is not None and (v < 20 or v > 300):
            raise ValueError('Weight value out of valid range')
        return v
    
    @validator('temperature')
    def validate_temperature(cls, v, values):
        if values.get('record_type') == 'temperature' and v is None:
            raise ValueError('Temperature is required for temperature records')
        if v is not None and (v < 30 or v > 45):
            raise ValueError('Temperature value out of valid range')
        return v

class HealthRecordResponse(BaseModel):
    id: int
    user_id: int
    record_type: str
    systolic_pressure: Optional[int]
    diastolic_pressure: Optional[int]
    heart_rate: Optional[int]
    blood_sugar: Optional[float]
    weight: Optional[float]
    temperature: Optional[float]
    notes: Optional[str]
    recorded_at: datetime
    created_at: datetime
    display_value: str
    is_normal: bool

class HealthStatsResponse(BaseModel):
    record_type: str
    total_records: int
    latest_value: Optional[str]
    latest_date: Optional[datetime]
    average_last_7_days: Optional[float]
    average_last_30_days: Optional[float]
    trend: str  # "improving", "stable", "declining"

@router.post("/records", response_model=HealthRecordResponse, status_code=status.HTTP_201_CREATED)
async def create_health_record(
    record_data: HealthRecordCreate,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_database)
):
    """
    Create a new health record
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
        
        # Create health record
        health_record = HealthRecord(
            user_id=user.id,
            record_type=RecordTypeEnum(record_data.record_type),
            systolic_pressure=record_data.systolic_pressure,
            diastolic_pressure=record_data.diastolic_pressure,
            heart_rate=record_data.heart_rate,
            blood_sugar=record_data.blood_sugar,
            weight=record_data.weight,
            temperature=record_data.temperature,
            notes=record_data.notes,
            recorded_at=record_data.recorded_at or datetime.now()
        )
        
        db.add(health_record)
        db.commit()
        db.refresh(health_record)
        
        logger.info(f"Health record created: {health_record.id} for user {user.id}")
        
        # Prepare response
        record_dict = health_record.to_dict()
        record_dict['display_value'] = health_record.get_display_value()
        record_dict['is_normal'] = health_record.is_normal_range()
        
        return HealthRecordResponse(**record_dict)
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error creating health record: {e}")
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to create health record"
        )

@router.get("/records", response_model=List[HealthRecordResponse])
async def get_health_records(
    record_type: Optional[str] = Query(None, description="Filter by record type"),
    limit: int = Query(50, ge=1, le=100, description="Number of records to return"),
    offset: int = Query(0, ge=0, description="Number of records to skip"),
    start_date: Optional[date] = Query(None, description="Start date filter"),
    end_date: Optional[date] = Query(None, description="End date filter"),
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_database)
):
    """
    Get user's health records with filtering and pagination
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
        
        # Build query
        query = db.query(HealthRecord).filter(HealthRecord.user_id == user.id)
        
        # Apply filters
        if record_type:
            query = query.filter(HealthRecord.record_type == RecordTypeEnum(record_type))
        
        if start_date:
            query = query.filter(HealthRecord.recorded_at >= start_date)
        
        if end_date:
            query = query.filter(HealthRecord.recorded_at <= end_date)
        
        # Order by recorded_at descending
        query = query.order_by(desc(HealthRecord.recorded_at))
        
        # Apply pagination
        records = query.offset(offset).limit(limit).all()
        
        # Prepare response
        response_records = []
        for record in records:
            record_dict = record.to_dict()
            record_dict['display_value'] = record.get_display_value()
            record_dict['is_normal'] = record.is_normal_range()
            response_records.append(HealthRecordResponse(**record_dict))
        
        return response_records
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting health records: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to get health records"
        )

@router.get("/records/{record_id}", response_model=HealthRecordResponse)
async def get_health_record(
    record_id: int,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_database)
):
    """
    Get a specific health record
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
        
        record = db.query(HealthRecord).filter(
            HealthRecord.id == record_id,
            HealthRecord.user_id == user.id
        ).first()
        
        if not record:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Health record not found"
            )
        
        record_dict = record.to_dict()
        record_dict['display_value'] = record.get_display_value()
        record_dict['is_normal'] = record.is_normal_range()
        
        return HealthRecordResponse(**record_dict)
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting health record: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to get health record"
        )

@router.delete("/records/{record_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_health_record(
    record_id: int,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_database)
):
    """
    Delete a health record
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
        
        record = db.query(HealthRecord).filter(
            HealthRecord.id == record_id,
            HealthRecord.user_id == user.id
        ).first()
        
        if not record:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Health record not found"
            )
        
        db.delete(record)
        db.commit()
        
        logger.info(f"Health record deleted: {record_id} for user {user.id}")

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error deleting health record: {e}")
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to delete health record"
        )

@router.get("/stats/all")
async def get_all_health_stats(
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_database)
):
    """
    Get health statistics for all record types in a single query (optimized)
    """
    try:
        user_id = current_user.get("sub")
        if isinstance(user_id, str):
            user_id = int(user_id)

        user = db.query(User).filter(User.id == user_id).first()
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found"
            )

        # Optimized: Only load records needed for stats (last 30 days + latest record per type)
        # This significantly reduces memory usage and query time
        now = datetime.now()
        week_ago = now - timedelta(days=7)
        month_ago = now - timedelta(days=30)
        
        # Get latest record for each type (for latest_value and latest_date)
        # And all records from last 30 days (for averages) - limit to 500 per type
        all_types = ['blood_pressure', 'heart_rate', 'blood_sugar', 'weight', 'temperature']
        records_by_type = {}
        total_counts = {}
        
        for record_type_str in all_types:
            record_type_enum = RecordTypeEnum(record_type_str)
            
            # Get total count (lightweight)
            total_counts[record_type_str] = db.query(HealthRecord).filter(
                HealthRecord.user_id == user.id,
                HealthRecord.record_type == record_type_enum
            ).count()
            
            # Get latest record for this type
            latest_record = db.query(HealthRecord).filter(
                HealthRecord.user_id == user.id,
                HealthRecord.record_type == record_type_enum
            ).order_by(desc(HealthRecord.recorded_at)).first()
            
            # Get records from last 30 days for this type (limit to 500 to avoid memory issues)
            recent_records = db.query(HealthRecord).filter(
                HealthRecord.user_id == user.id,
                HealthRecord.record_type == record_type_enum,
                HealthRecord.recorded_at >= month_ago
            ).order_by(desc(HealthRecord.recorded_at)).limit(500).all()
            
            # Combine: latest + recent records (avoid duplicates)
            records = []
            if latest_record:
                records.append(latest_record)
            # Add recent records that are not the latest
            for rec in recent_records:
                if not latest_record or rec.id != latest_record.id:
                    records.append(rec)
            
            records_by_type[record_type_str] = records

        # Calculate stats for each type
        result = {}

        def get_numeric_value(record):
            """Extract numeric value from record for averaging"""
            try:
                if record.record_type == RecordTypeEnum.blood_pressure:
                    return float(record.systolic_pressure) if record.systolic_pressure else None
                elif record.record_type == RecordTypeEnum.blood_sugar:
                    return float(record.blood_sugar) if record.blood_sugar else None
                elif record.record_type == RecordTypeEnum.weight:
                    return float(record.weight) if record.weight else None
                elif record.record_type == RecordTypeEnum.heart_rate:
                    return float(record.heart_rate) if record.heart_rate else None
                elif record.record_type == RecordTypeEnum.temperature:
                    return float(record.temperature) if record.temperature else None
                return None
            except (ValueError, TypeError):
                return None

        for record_type, records in records_by_type.items():
            if not records:
                result[record_type] = {
                    "record_type": record_type,
                    "total_records": 0,
                    "latest_value": None,
                    "latest_date": None,
                    "average_last_7_days": None,
                    "average_last_30_days": None,
                    "trend": "stable"
                }
                continue

            latest_record = records[0]
            latest_value = latest_record.get_display_value()
            latest_date = latest_record.recorded_at

            recent_records_7d = [r for r in records if r.recorded_at >= week_ago]
            recent_records_30d = [r for r in records if r.recorded_at >= month_ago]

            numeric_values_7d = [get_numeric_value(r) for r in recent_records_7d]
            numeric_values_7d = [v for v in numeric_values_7d if v is not None]
            avg_7d = sum(numeric_values_7d) / len(numeric_values_7d) if numeric_values_7d else None

            numeric_values_30d = [get_numeric_value(r) for r in recent_records_30d]
            numeric_values_30d = [v for v in numeric_values_30d if v is not None]
            avg_30d = sum(numeric_values_30d) / len(numeric_values_30d) if numeric_values_30d else None

            trend = "stable"
            if len(recent_records_7d) >= 2 and avg_7d and avg_30d:
                if avg_7d > avg_30d * 1.05:
                    trend = "improving" if record_type == "weight" else "declining"
                elif avg_7d < avg_30d * 0.95:
                    trend = "declining" if record_type == "weight" else "improving"

            result[record_type] = {
                "record_type": record_type,
                "total_records": total_counts.get(record_type, 0),  # Use count from database
                "latest_value": latest_value,
                "latest_date": latest_date.isoformat() if latest_date else None,
                "average_last_7_days": avg_7d,
                "average_last_30_days": avg_30d,
                "trend": trend
            }

        # Add empty stats for types that don't have records
        all_types = ['blood_pressure', 'heart_rate', 'blood_sugar', 'weight', 'temperature']
        for record_type in all_types:
            if record_type not in result:
                result[record_type] = {
                    "record_type": record_type,
                    "total_records": 0,
                    "latest_value": None,
                    "latest_date": None,
                    "average_last_7_days": None,
                    "average_last_30_days": None,
                    "trend": "stable"
                }

        return result

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting all health stats: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to get health statistics"
        )

@router.get("/stats/{record_type}", response_model=HealthStatsResponse)
async def get_health_stats(
    record_type: str,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_database)
):
    """
    Get health statistics for a specific record type
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

        # Get all records for this type - limit to recent records to reduce memory usage
        records = db.query(HealthRecord).filter(
            HealthRecord.user_id == user.id,
            HealthRecord.record_type == RecordTypeEnum(record_type)
        ).order_by(desc(HealthRecord.recorded_at)).limit(1000).all()  # Limit to 1000 most recent to reduce RAM usage

        if not records:
            return HealthStatsResponse(
                record_type=record_type,
                total_records=0,
                latest_value=None,
                latest_date=None,
                average_last_7_days=None,
                average_last_30_days=None,
                trend="stable"
            )

        # Calculate statistics
        total_records = len(records)
        latest_record = records[0]
        latest_value = latest_record.get_display_value()
        latest_date = latest_record.recorded_at

        # Calculate averages for numeric values
        now = datetime.now()
        week_ago = now - timedelta(days=7)
        month_ago = now - timedelta(days=30)

        recent_records_7d = [r for r in records if r.recorded_at >= week_ago]
        recent_records_30d = [r for r in records if r.recorded_at >= month_ago]

        def get_numeric_value(record):
            """Extract numeric value from record for averaging"""
            try:
                if record.record_type == RecordTypeEnum.blood_pressure:
                    # For blood pressure, use systolic value
                    return float(record.systolic_pressure) if record.systolic_pressure else None
                elif record.record_type == RecordTypeEnum.blood_sugar:
                    return float(record.blood_sugar) if record.blood_sugar else None
                elif record.record_type == RecordTypeEnum.weight:
                    return float(record.weight) if record.weight else None
                elif record.record_type == RecordTypeEnum.heart_rate:
                    return float(record.heart_rate) if record.heart_rate else None
                elif record.record_type == RecordTypeEnum.temperature:
                    return float(record.temperature) if record.temperature else None
                else:
                    return None
            except (ValueError, TypeError):
                return None

        # Calculate averages
        avg_7d = None
        avg_30d = None

        numeric_values_7d = [get_numeric_value(r) for r in recent_records_7d]
        numeric_values_7d = [v for v in numeric_values_7d if v is not None]
        if numeric_values_7d:
            avg_7d = sum(numeric_values_7d) / len(numeric_values_7d)

        numeric_values_30d = [get_numeric_value(r) for r in recent_records_30d]
        numeric_values_30d = [v for v in numeric_values_30d if v is not None]
        if numeric_values_30d:
            avg_30d = sum(numeric_values_30d) / len(numeric_values_30d)

        # Calculate trend
        trend = "stable"
        if len(recent_records_7d) >= 2 and avg_7d and avg_30d:
            if avg_7d > avg_30d * 1.05:  # 5% increase
                trend = "improving" if record_type == "weight" else "declining"
            elif avg_7d < avg_30d * 0.95:  # 5% decrease
                trend = "declining" if record_type == "weight" else "improving"

        return HealthStatsResponse(
            record_type=record_type,
            total_records=total_records,
            latest_value=latest_value,
            latest_date=latest_date,
            average_last_7_days=avg_7d,
            average_last_30_days=avg_30d,
            trend=trend
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting health stats: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to get health statistics"
        )
