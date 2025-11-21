"""
Health-related models for Elderly Health Support System
"""

from sqlalchemy import Column, Integer, String, Text, Boolean, TIMESTAMP, func, ForeignKey, Enum, DECIMAL, Date
from sqlalchemy.orm import relationship
from database import Base
import enum
import json

class BloodTypeEnum(enum.Enum):
    A_POSITIVE = "A+"
    A_NEGATIVE = "A-"
    B_POSITIVE = "B+"
    B_NEGATIVE = "B-"
    AB_POSITIVE = "AB+"
    AB_NEGATIVE = "AB-"
    O_POSITIVE = "O+"
    O_NEGATIVE = "O-"

class RecordTypeEnum(enum.Enum):
    blood_pressure = "blood_pressure"
    heart_rate = "heart_rate"
    blood_sugar = "blood_sugar"
    weight = "weight"
    temperature = "temperature"

class HealthProfile(Base):
    """
    Health profile model for storing user's medical information
    """
    __tablename__ = "health_profiles"
    
    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    height = Column(DECIMAL(5, 2), nullable=True)  # cm
    blood_type = Column(Enum(BloodTypeEnum), nullable=True)
    chronic_diseases = Column(Text, nullable=True)  # JSON array
    allergies = Column(Text, nullable=True)  # JSON array
    current_medications = Column(Text, nullable=True)  # JSON array
    medical_notes = Column(Text, nullable=True)
    doctor_name = Column(String(255), nullable=True)
    doctor_phone = Column(String(20), nullable=True)
    insurance_info = Column(Text, nullable=True)
    created_at = Column(TIMESTAMP, server_default=func.current_timestamp())
    updated_at = Column(TIMESTAMP, server_default=func.current_timestamp(), onupdate=func.current_timestamp())
    
    # Relationships - temporarily disabled to avoid import issues
    # user = relationship("User", back_populates="health_profile")
    
    def __repr__(self):
        return f"<HealthProfile(user_id={self.user_id}, blood_type='{self.blood_type}')>"
    
    def to_dict(self):
        """Convert health profile object to dictionary"""
        return {
            "id": self.id,
            "user_id": self.user_id,
            "height": float(self.height) if self.height else None,
            "blood_type": self.blood_type.value if self.blood_type else None,
            "chronic_diseases": json.loads(self.chronic_diseases) if self.chronic_diseases else [],
            "allergies": json.loads(self.allergies) if self.allergies else [],
            "current_medications": json.loads(self.current_medications) if self.current_medications else [],
            "medical_notes": self.medical_notes,
            "doctor_name": self.doctor_name,
            "doctor_phone": self.doctor_phone,
            "insurance_info": self.insurance_info,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None
        }
    
    def set_chronic_diseases(self, diseases: list):
        """Set chronic diseases as JSON"""
        self.chronic_diseases = json.dumps(diseases, ensure_ascii=False)
    
    def set_allergies(self, allergies: list):
        """Set allergies as JSON"""
        self.allergies = json.dumps(allergies, ensure_ascii=False)
    
    def set_current_medications(self, medications: list):
        """Set current medications as JSON"""
        self.current_medications = json.dumps(medications, ensure_ascii=False)

class HealthRecord(Base):
    """
    Health record model for storing health measurements
    """
    __tablename__ = "health_records"
    
    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    record_type = Column(Enum(RecordTypeEnum), nullable=False, index=True)
    systolic_pressure = Column(Integer, nullable=True)  # for blood pressure
    diastolic_pressure = Column(Integer, nullable=True)  # for blood pressure
    heart_rate = Column(Integer, nullable=True)  # beats per minute
    blood_sugar = Column(DECIMAL(5, 2), nullable=True)  # mg/dL
    weight = Column(DECIMAL(5, 2), nullable=True)  # kg
    temperature = Column(DECIMAL(4, 2), nullable=True)  # celsius
    notes = Column(Text, nullable=True)
    recorded_at = Column(TIMESTAMP, server_default=func.current_timestamp())
    created_at = Column(TIMESTAMP, server_default=func.current_timestamp())
    
    # Relationships - temporarily disabled to avoid import issues
    # user = relationship("User", back_populates="health_records")
    
    def __repr__(self):
        return f"<HealthRecord(user_id={self.user_id}, type='{self.record_type}', recorded_at='{self.recorded_at}')>"
    
    def to_dict(self):
        """Convert health record object to dictionary"""
        return {
            "id": self.id,
            "user_id": self.user_id,
            "record_type": self.record_type.value,
            "systolic_pressure": self.systolic_pressure,
            "diastolic_pressure": self.diastolic_pressure,
            "heart_rate": self.heart_rate,
            "blood_sugar": float(self.blood_sugar) if self.blood_sugar else None,
            "weight": float(self.weight) if self.weight else None,
            "temperature": float(self.temperature) if self.temperature else None,
            "notes": self.notes,
            "recorded_at": self.recorded_at.isoformat() if self.recorded_at else None,
            "created_at": self.created_at.isoformat() if self.created_at else None
        }
    
    def get_display_value(self):
        """Get the main value for display based on record type"""
        if self.record_type == RecordTypeEnum.blood_pressure:
            return f"{self.systolic_pressure}/{self.diastolic_pressure}"
        elif self.record_type == RecordTypeEnum.heart_rate:
            return f"{self.heart_rate} bpm"
        elif self.record_type == RecordTypeEnum.blood_sugar:
            return f"{self.blood_sugar} mg/dL"
        elif self.record_type == RecordTypeEnum.weight:
            return f"{self.weight} kg"
        elif self.record_type == RecordTypeEnum.temperature:
            return f"{self.temperature}°C"
        return "N/A"
    
    def is_normal_range(self):
        """Check if the value is in normal range"""
        try:
            if self.record_type == RecordTypeEnum.blood_pressure:
                # Normal: <120/80, High: ≥140/90
                if self.systolic_pressure is None or self.diastolic_pressure is None:
                    return True
                return self.systolic_pressure < 140 and self.diastolic_pressure < 90
            elif self.record_type == RecordTypeEnum.heart_rate:
                # Normal: 60-100 bpm for adults
                if self.heart_rate is None:
                    return True
                return 60 <= self.heart_rate <= 100
            elif self.record_type == RecordTypeEnum.blood_sugar:
                # Normal fasting: 70-100 mg/dL
                if self.blood_sugar is None:
                    return True
                return 70 <= self.blood_sugar <= 140  # More lenient for elderly
            elif self.record_type == RecordTypeEnum.temperature:
                # Normal: 36.1-37.2°C
                if self.temperature is None:
                    return True
                return 36.1 <= self.temperature <= 37.2
            return True  # Weight doesn't have a universal normal range
        except (TypeError, ValueError):
            return True
