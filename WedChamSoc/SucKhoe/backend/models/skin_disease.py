"""
Skin Disease models for AI prediction system
"""

from sqlalchemy import Column, Integer, String, Text, Boolean, TIMESTAMP, func, ForeignKey, Enum, DECIMAL
from sqlalchemy.orm import relationship
from database import Base
import enum
import json

class SeverityEnum(enum.Enum):
    mild = "mild"
    moderate = "moderate"
    severe = "severe"

class SkinDisease(Base):
    """
    Skin disease information model
    """
    __tablename__ = "skin_diseases"
    
    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    name = Column(String(255), nullable=False, index=True)  # English name
    name_vi = Column(String(255), nullable=True)  # Vietnamese name
    description = Column(Text, nullable=True)
    symptoms = Column(Text, nullable=True)  # JSON array
    causes = Column(Text, nullable=True)
    treatment = Column(Text, nullable=True)
    prevention = Column(Text, nullable=True)
    severity = Column(Enum(SeverityEnum), nullable=True)
    is_common = Column(Boolean, default=False)
    created_at = Column(TIMESTAMP, server_default=func.current_timestamp())
    updated_at = Column(TIMESTAMP, server_default=func.current_timestamp(), onupdate=func.current_timestamp())
    
    # Relationships
    # predictions = relationship("SkinDiseasePrediction", back_populates="predicted_disease")
    
    def __repr__(self):
        return f"<SkinDisease(id={self.id}, name='{self.name}')>"
    
    def to_dict(self):
        """Convert skin disease object to dictionary"""
        return {
            "id": self.id,
            "name": self.name,
            "name_vi": self.name_vi,
            "description": self.description,
            "symptoms": json.loads(self.symptoms) if self.symptoms else [],
            "causes": self.causes,
            "treatment": self.treatment,
            "prevention": self.prevention,
            "severity": self.severity.value if self.severity else None,
            "is_common": self.is_common,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None
        }
    
    def set_symptoms(self, symptoms: list):
        """Set symptoms as JSON"""
        self.symptoms = json.dumps(symptoms, ensure_ascii=False)

class SkinDiseasePrediction(Base):
    """
    Skin disease prediction history model
    """
    __tablename__ = "skin_disease_predictions"
    
    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    image_path = Column(String(500), nullable=False)
    predicted_disease_id = Column(Integer, ForeignKey("skin_diseases.id"), nullable=True, index=True)
    confidence = Column(DECIMAL(5, 4), nullable=True)  # 0.0000 to 1.0000
    actual_disease_id = Column(Integer, ForeignKey("skin_diseases.id"), nullable=True)  # User confirmed
    user_feedback = Column(Text, nullable=True)
    is_confirmed = Column(Boolean, default=False)
    created_at = Column(TIMESTAMP, server_default=func.current_timestamp())
    
    # Relationships
    # user = relationship("User", back_populates="skin_disease_predictions")
    # predicted_disease = relationship("SkinDisease", foreign_keys=[predicted_disease_id], back_populates="predictions")
    # actual_disease = relationship("SkinDisease", foreign_keys=[actual_disease_id])
    
    def __repr__(self):
        return f"<SkinDiseasePrediction(id={self.id}, user_id={self.user_id}, confidence={self.confidence})>"
    
    def to_dict(self):
        """Convert prediction object to dictionary"""
        return {
            "id": self.id,
            "user_id": self.user_id,
            "image_path": self.image_path,
            "predicted_disease_id": self.predicted_disease_id,
            "confidence": float(self.confidence) if self.confidence else None,
            "actual_disease_id": self.actual_disease_id,
            "user_feedback": self.user_feedback,
            "is_confirmed": self.is_confirmed,
            "created_at": self.created_at.isoformat() if self.created_at else None
        }

