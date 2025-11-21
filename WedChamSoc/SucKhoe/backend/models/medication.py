"""
Medication and schedule models for Elderly Health Support System
"""

from sqlalchemy import Column, Integer, String, Text, Boolean, TIMESTAMP, func, ForeignKey, Enum, Date, DateTime
from sqlalchemy.orm import relationship
from database import Base
import enum

class ScheduleTypeEnum(enum.Enum):
    medication = "medication"
    appointment = "appointment"
    checkup = "checkup"

class ReminderTypeEnum(enum.Enum):
    medication = "medication"
    appointment = "appointment"
    checkup = "checkup"
    custom = "custom"

class Medication(Base):
    """
    Medication model for storing user's medication information
    """
    __tablename__ = "medications"
    
    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    medication_name = Column(String(255), nullable=False)
    dosage = Column(String(100), nullable=True)
    frequency = Column(String(100), nullable=True)  # e.g., "2 times daily", "every 8 hours"
    instructions = Column(Text, nullable=True)
    start_date = Column(Date, nullable=True)
    end_date = Column(Date, nullable=True)
    is_active = Column(Boolean, default=True)
    created_at = Column(TIMESTAMP, server_default=func.current_timestamp())
    updated_at = Column(TIMESTAMP, server_default=func.current_timestamp(), onupdate=func.current_timestamp())
    
    # Relationships - temporarily disabled to avoid import issues
    # user = relationship("User", back_populates="medications")
    schedules = relationship("Schedule", back_populates="medication")
    
    def __repr__(self):
        return f"<Medication(id={self.id}, name='{self.medication_name}', user_id={self.user_id})>"
    
    def to_dict(self):
        """Convert medication object to dictionary"""
        return {
            "id": self.id,
            "user_id": self.user_id,
            "medication_name": self.medication_name,
            "dosage": self.dosage,
            "frequency": self.frequency,
            "instructions": self.instructions,
            "start_date": self.start_date.isoformat() if self.start_date else None,
            "end_date": self.end_date.isoformat() if self.end_date else None,
            "is_active": self.is_active,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None
        }
    
    def is_current(self):
        """Check if medication is currently active"""
        from datetime import date
        today = date.today()
        
        if not self.is_active:
            return False
        
        if self.start_date and self.start_date > today:
            return False
        
        if self.end_date and self.end_date < today:
            return False
        
        return True

class Schedule(Base):
    """
    Schedule model for storing appointments and medication schedules
    """
    __tablename__ = "schedules"
    
    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    schedule_type = Column(Enum(ScheduleTypeEnum), nullable=False)
    title = Column(String(255), nullable=False)
    description = Column(Text, nullable=True)
    scheduled_datetime = Column(DateTime, nullable=False, index=True)
    location = Column(String(255), nullable=True)  # for appointments
    doctor_name = Column(String(255), nullable=True)  # for appointments
    medication_id = Column(Integer, ForeignKey("medications.id", ondelete="SET NULL"), nullable=True)
    is_completed = Column(Boolean, default=False)
    is_recurring = Column(Boolean, default=False)
    recurrence_pattern = Column(String(100), nullable=True)  # e.g., "daily", "weekly", "monthly"
    created_at = Column(TIMESTAMP, server_default=func.current_timestamp())
    updated_at = Column(TIMESTAMP, server_default=func.current_timestamp(), onupdate=func.current_timestamp())
    
    # Relationships - temporarily disabled to avoid import issues
    # user = relationship("User", back_populates="schedules")
    medication = relationship("Medication", back_populates="schedules")
    reminders = relationship("Reminder", back_populates="schedule")
    
    def __repr__(self):
        return f"<Schedule(id={self.id}, title='{self.title}', type='{self.schedule_type}', user_id={self.user_id})>"
    
    def to_dict(self):
        """Convert schedule object to dictionary"""
        return {
            "id": self.id,
            "user_id": self.user_id,
            "schedule_type": self.schedule_type.value,
            "title": self.title,
            "description": self.description,
            "scheduled_datetime": self.scheduled_datetime.isoformat() if self.scheduled_datetime else None,
            "location": self.location,
            "doctor_name": self.doctor_name,
            "medication_id": self.medication_id,
            "is_completed": self.is_completed,
            "is_recurring": self.is_recurring,
            "recurrence_pattern": self.recurrence_pattern,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None
        }
    
    def is_upcoming(self):
        """Check if schedule is upcoming"""
        from datetime import datetime
        return self.scheduled_datetime > datetime.now() and not self.is_completed
    
    def is_overdue(self):
        """Check if schedule is overdue"""
        from datetime import datetime
        return self.scheduled_datetime < datetime.now() and not self.is_completed

class Reminder(Base):
    """
    Reminder model for storing user reminders
    """
    __tablename__ = "reminders"
    
    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    schedule_id = Column(Integer, ForeignKey("schedules.id", ondelete="CASCADE"), nullable=True)
    reminder_type = Column(Enum(ReminderTypeEnum), nullable=False)
    title = Column(String(255), nullable=False)
    message = Column(Text, nullable=True)
    remind_datetime = Column(DateTime, nullable=False, index=True)
    is_sent = Column(Boolean, default=False, index=True)
    is_read = Column(Boolean, default=False)
    created_at = Column(TIMESTAMP, server_default=func.current_timestamp())
    
    # Relationships - temporarily disabled to avoid import issues
    # user = relationship("User", back_populates="reminders")
    schedule = relationship("Schedule", back_populates="reminders")
    
    def __repr__(self):
        return f"<Reminder(id={self.id}, title='{self.title}', type='{self.reminder_type}', user_id={self.user_id})>"
    
    def to_dict(self):
        """Convert reminder object to dictionary"""
        return {
            "id": self.id,
            "user_id": self.user_id,
            "schedule_id": self.schedule_id,
            "reminder_type": self.reminder_type.value,
            "title": self.title,
            "message": self.message,
            "remind_datetime": self.remind_datetime.isoformat() if self.remind_datetime else None,
            "is_sent": self.is_sent,
            "is_read": self.is_read,
            "created_at": self.created_at.isoformat() if self.created_at else None
        }
    
    def is_due(self):
        """Check if reminder is due"""
        from datetime import datetime
        return self.remind_datetime <= datetime.now() and not self.is_sent
    
    def mark_as_sent(self):
        """Mark reminder as sent"""
        self.is_sent = True
    
    def mark_as_read(self):
        """Mark reminder as read"""
        self.is_read = True
