"""
User models for Elderly Health Support System
"""

from sqlalchemy import Column, Integer, String, Date, Enum, Text, Boolean, TIMESTAMP, func, ForeignKey, UniqueConstraint, Index
from sqlalchemy.orm import relationship
from database import Base
import enum


class GenderEnum(enum.Enum):
    male = "male"
    female = "female"
    other = "other"


class User(Base):
    """
    User model representing elderly users in the system
    """
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    email = Column(String(255), unique=True, nullable=False, index=True)
    password_hash = Column(String(255), nullable=False)
    phone = Column(String(20), nullable=True)
    full_name = Column(String(255), nullable=False)
    date_of_birth = Column(Date, nullable=True)
    gender = Column(Enum(GenderEnum), default=GenderEnum.other)
    address = Column(Text, nullable=True)
    emergency_contact_name = Column(String(255), nullable=True)
    emergency_contact_phone = Column(String(20), nullable=True)
    created_at = Column(TIMESTAMP, server_default=func.current_timestamp())
    updated_at = Column(TIMESTAMP, server_default=func.current_timestamp(
    ), onupdate=func.current_timestamp())
    is_active = Column(Boolean, default=True)
    email_verified = Column(Boolean, default=False)

    # Two-Factor Authentication (2FA)
    two_factor_enabled = Column(Boolean, default=False)
    # Base32 secret for TOTP (never expose via API). Nullable until user enables 2FA
    two_factor_secret = Column(String(64), nullable=True)
    # JSON-encoded list of hashed backup codes (bcrypt hashes), nullable
    backup_codes_hashed = Column(Text, nullable=True)

    # Email OTP 2FA
    email_otp_enabled = Column(Boolean, default=False)
    # Preferred 2FA method: 'totp' or 'email'
    preferred_2fa_method = Column(String(10), default='totp')

    # Relationships - temporarily disabled to avoid import issues
    # health_profile = relationship("HealthProfile", back_populates="user", uselist=False)
    # health_records = relationship("HealthRecord", back_populates="user")
    # medications = relationship("Medication", back_populates="user")
    # schedules = relationship("Schedule", back_populates="user")
    # reminders = relationship("Reminder", back_populates="user")
    # chat_sessions = relationship("ChatSession", back_populates="user")
    # user_settings = relationship("UserSetting", back_populates="user")  # Temporarily disabled

    def __repr__(self):
        return f"<User(id={self.id}, email='{self.email}', full_name='{self.full_name}')>"

    def to_dict(self):
        """Convert user object to dictionary"""
        return {
            "id": self.id,
            "email": self.email,
            "phone": self.phone,
            "full_name": self.full_name,
            "date_of_birth": self.date_of_birth.isoformat() if self.date_of_birth else None,
            "gender": self.gender.value if self.gender else None,
            "address": self.address,
            "emergency_contact_name": self.emergency_contact_name,
            "emergency_contact_phone": self.emergency_contact_phone,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None,
            "is_active": self.is_active,
            "email_verified": self.email_verified,
            # Only expose whether 2FA is enabled; never expose secrets or backup codes
            "two_factor_enabled": self.two_factor_enabled,
            "email_otp_enabled": self.email_otp_enabled,
            "preferred_2fa_method": self.preferred_2fa_method
        }

    @property
    def age(self):
        """Calculate user's age"""
        if self.date_of_birth:
            from datetime import date
            today = date.today()
            return today.year - self.date_of_birth.year - ((today.month, today.day) < (self.date_of_birth.month, self.date_of_birth.day))
        return None

    def get_full_profile(self):
        """Get user with health profile"""
        profile_data = self.to_dict()
        # Check if health_profile relationship exists and is accessible
        try:
            if hasattr(self, 'health_profile') and self.health_profile:
                profile_data["health_profile"] = self.health_profile.to_dict()
        except AttributeError:
            # Relationship not configured, skip health profile
            pass
        return profile_data


class UserSetting(Base):
    """
    User settings model for storing user preferences
    Each user can have multiple settings, but each setting_key should be unique per user
    """
    __tablename__ = "user_settings"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    user_id = Column(Integer, ForeignKey(
        "users.id", ondelete="CASCADE"), nullable=False, index=True)
    setting_key = Column(String(100), nullable=False)
    setting_value = Column(Text, nullable=True)
    created_at = Column(TIMESTAMP, server_default=func.current_timestamp())
    updated_at = Column(TIMESTAMP, server_default=func.current_timestamp(
    ), onupdate=func.current_timestamp())
    
    # Add unique constraint on (user_id, setting_key) to prevent duplicates
    __table_args__ = (
        UniqueConstraint('user_id', 'setting_key', name='uq_user_setting'),
        Index('idx_user_setting_key', 'user_id', 'setting_key'),
    )

    # Relationships
    # user = relationship("User", back_populates="user_settings")  # Temporarily disabled

    def __repr__(self):
        return f"<UserSetting(user_id={self.user_id}, key='{self.setting_key}', value='{self.setting_value}')>"

    def to_dict(self):
        """Convert user setting object to dictionary"""
        return {
            "id": self.id,
            "user_id": self.user_id,
            "setting_key": self.setting_key,
            "setting_value": self.setting_value,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None
        }
