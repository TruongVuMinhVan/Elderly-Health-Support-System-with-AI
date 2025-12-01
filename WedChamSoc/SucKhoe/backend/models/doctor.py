"""
Doctor model for finding nearby doctors
"""

from typing import Optional
from sqlalchemy import Column, Integer, String, Text, DECIMAL, Boolean, TIMESTAMP, func
from database import Base

class Doctor(Base):
    """
    Doctor/Clinic information model
    """
    __tablename__ = "doctors"
    
    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    name = Column(String(255), nullable=False)
    specialty = Column(String(255), nullable=True)  # Chuyên khoa
    clinic_name = Column(String(255), nullable=True)  # Tên phòng khám
    address = Column(Text, nullable=False)
    phone = Column(String(20), nullable=True)
    email = Column(String(255), nullable=True)
    website = Column(String(255), nullable=True)
    
    # Location (for GPS/nearby search)
    latitude = Column(DECIMAL(10, 8), nullable=True)  # Vĩ độ
    longitude = Column(DECIMAL(11, 8), nullable=True)  # Kinh độ
    
    # Additional info
    rating = Column(DECIMAL(3, 2), nullable=True, default=0.0)  # Đánh giá 0-5
    review_count = Column(Integer, default=0)  # Số lượt đánh giá
    price_range = Column(String(50), nullable=True)  # Mức giá (ví dụ: "100k-500k")
    opening_hours = Column(Text, nullable=True)  # Giờ mở cửa (JSON)
    
    # Status
    is_active = Column(Boolean, default=True)
    created_at = Column(TIMESTAMP, server_default=func.current_timestamp())
    updated_at = Column(TIMESTAMP, server_default=func.current_timestamp(), onupdate=func.current_timestamp())
    
    def __repr__(self):
        return f"<Doctor(id={self.id}, name='{self.name}', clinic='{self.clinic_name}')>"
    
    def to_dict(self):
        """Convert doctor object to dictionary"""
        import json
        return {
            "id": self.id,
            "name": self.name,
            "specialty": self.specialty,
            "clinic_name": self.clinic_name,
            "address": self.address,
            "phone": self.phone,
            "email": self.email,
            "website": self.website,
            "latitude": float(self.latitude) if self.latitude else None,
            "longitude": float(self.longitude) if self.longitude else None,
            "rating": float(self.rating) if self.rating else 0.0,
            "review_count": self.review_count,
            "price_range": self.price_range,
            "opening_hours": json.loads(self.opening_hours) if self.opening_hours else None,
            "is_active": self.is_active
        }
    
    def calculate_distance(self, lat: float, lon: float) -> Optional[float]:
        """
        Calculate distance in kilometers using Haversine formula
        Returns None if coordinates are not available
        """
        if not self.latitude or not self.longitude:
            return None
        
        from math import radians, sin, cos, sqrt, atan2
        
        # Convert to radians
        lat1 = radians(float(self.latitude))
        lon1 = radians(float(self.longitude))
        lat2 = radians(lat)
        lon2 = radians(lon)
        
        # Haversine formula
        dlat = lat2 - lat1
        dlon = lon2 - lon1
        
        a = sin(dlat/2)**2 + cos(lat1) * cos(lat2) * sin(dlon/2)**2
        c = 2 * atan2(sqrt(a), sqrt(1-a))
        
        # Earth radius in kilometers
        R = 6371.0
        
        distance = R * c
        return distance

