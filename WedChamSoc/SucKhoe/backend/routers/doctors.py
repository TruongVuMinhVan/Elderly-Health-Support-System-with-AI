"""
Find Nearby Doctors API - Không cần đăng nhập
"""

from fastapi import APIRouter, HTTPException, status, Query, Depends
from sqlalchemy.orm import Session
from typing import List, Optional
from pydantic import BaseModel
import logging
from math import radians, sin, cos, sqrt, atan2

from database import get_database
from models.doctor import Doctor

# Logging setup
logger = logging.getLogger(__name__)

# Create router
router = APIRouter(prefix="/api/doctors", tags=["doctors"])

# Pydantic models
class DoctorResponse(BaseModel):
    id: int
    name: str
    specialty: Optional[str] = None
    clinic_name: Optional[str] = None
    address: str
    phone: Optional[str] = None
    email: Optional[str] = None
    website: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    rating: float = 0.0
    review_count: int = 0
    price_range: Optional[str] = None
    opening_hours: Optional[dict] = None
    distance_km: Optional[float] = None  # Distance from user location

class NearbyDoctorsRequest(BaseModel):
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    address: Optional[str] = None
    specialty: Optional[str] = None
    max_distance_km: Optional[float] = 10.0  # Default 10km
    limit: int = 20

def calculate_distance(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    """Calculate distance in kilometers using Haversine formula"""
    # Convert to radians
    lat1_rad = radians(lat1)
    lon1_rad = radians(lon1)
    lat2_rad = radians(lat2)
    lon2_rad = radians(lon2)
    
    # Haversine formula
    dlat = lat2_rad - lat1_rad
    dlon = lon2_rad - lon1_rad
    
    a = sin(dlat/2)**2 + cos(lat1_rad) * cos(lat2_rad) * sin(dlon/2)**2
    c = 2 * atan2(sqrt(a), sqrt(1-a))
    
    # Earth radius in kilometers
    R = 6371.0
    
    return R * c

@router.get("/nearby", response_model=List[DoctorResponse])
async def find_nearby_doctors(
    latitude: Optional[float] = Query(None, description="Vĩ độ (GPS)"),
    longitude: Optional[float] = Query(None, description="Kinh độ (GPS)"),
    address: Optional[str] = Query(None, description="Địa chỉ (nếu không có GPS)"),
    specialty: Optional[str] = Query(None, description="Chuyên khoa (ví dụ: da liễu)"),
    max_distance_km: float = Query(10.0, description="Khoảng cách tối đa (km)"),
    limit: int = Query(20, description="Số lượng kết quả tối đa"),
    db: Session = Depends(get_database)
):
    """
    Tìm bác sĩ/phòng khám gần nhất
    
    - Nhập địa chỉ hoặc dùng GPS
    - Hiển thị danh sách phòng khám
    - Xem đánh giá, địa chỉ, số điện thoại
    - Tính khoảng cách
    - Không cần đăng nhập
    """
    try:
        # Query active doctors
        query = db.query(Doctor).filter(Doctor.is_active == True)
        
        # Filter by specialty if provided
        if specialty:
            query = query.filter(Doctor.specialty.ilike(f"%{specialty}%"))
        
        doctors = query.all()
        
        # If GPS coordinates provided, calculate distances and sort
        if latitude and longitude:
            doctors_with_distance = []
            for doctor in doctors:
                if doctor.latitude and doctor.longitude:
                    distance = calculate_distance(
                        latitude, longitude,
                        float(doctor.latitude), float(doctor.longitude)
                    )
                    if distance <= max_distance_km:
                        doctor_dict = doctor.to_dict()
                        doctor_dict["distance_km"] = round(distance, 2)
                        doctors_with_distance.append((doctor_dict, distance))
            
            # Sort by distance
            doctors_with_distance.sort(key=lambda x: x[1])
            result = [doc[0] for doc in doctors_with_distance[:limit]]
            
        else:
            # No GPS, just return all (sorted by rating)
            result = []
            for doctor in doctors:
                doctor_dict = doctor.to_dict()
                result.append(doctor_dict)
            
            # Sort by rating (highest first)
            result.sort(key=lambda x: x.get("rating", 0), reverse=True)
            result = result[:limit]
        
        logger.info(f"✅ Found {len(result)} doctors nearby")
        
        return result
        
    except Exception as e:
        logger.error(f"Error finding nearby doctors: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to find doctors: {str(e)}"
        )

@router.get("/search", response_model=List[DoctorResponse])
async def search_doctors(
    q: str = Query(..., description="Từ khóa tìm kiếm (tên, địa chỉ, chuyên khoa)"),
    limit: int = Query(20, description="Số lượng kết quả tối đa"),
    db: Session = Depends(get_database)
):
    """
    Tìm kiếm bác sĩ theo từ khóa
    """
    try:
        search_term = f"%{q}%"
        
        doctors = db.query(Doctor).filter(
            Doctor.is_active == True,
            (
                Doctor.name.ilike(search_term) |
                Doctor.clinic_name.ilike(search_term) |
                Doctor.address.ilike(search_term) |
                Doctor.specialty.ilike(search_term)
            )
        ).limit(limit).all()
        
        result = [doctor.to_dict() for doctor in doctors]
        
        logger.info(f"✅ Found {len(result)} doctors matching '{q}'")
        
        return result
        
    except Exception as e:
        logger.error(f"Error searching doctors: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to search doctors: {str(e)}"
        )

@router.get("/{doctor_id}", response_model=DoctorResponse)
async def get_doctor(
    doctor_id: int,
    db: Session = Depends(get_database)
):
    """
    Lấy thông tin chi tiết của bác sĩ/phòng khám
    """
    try:
        doctor = db.query(Doctor).filter(
            Doctor.id == doctor_id,
            Doctor.is_active == True
        ).first()
        
        if not doctor:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Doctor not found"
            )
        
        return doctor.to_dict()
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting doctor: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get doctor: {str(e)}"
        )

