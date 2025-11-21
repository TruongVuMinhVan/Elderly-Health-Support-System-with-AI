"""
Chat models for AI chatbot functionality in Elderly Health Support System
"""

from sqlalchemy import Column, Integer, String, Text, Boolean, TIMESTAMP, func, ForeignKey, Enum
from sqlalchemy.orm import relationship
from database import Base
import enum

class MessageTypeEnum(enum.Enum):
    user = "user"
    assistant = "assistant"

class ChatSession(Base):
    """
    Chat session model for storing AI chat sessions
    """
    __tablename__ = "chat_sessions"
    
    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    session_id = Column(String(255), nullable=False, index=True)
    started_at = Column(TIMESTAMP, server_default=func.current_timestamp())
    ended_at = Column(TIMESTAMP, nullable=True)
    is_active = Column(Boolean, default=True)
    
    # Relationships - temporarily disabled to avoid import issues
    # user = relationship("User", back_populates="chat_sessions")
    messages = relationship("ChatMessage", back_populates="session", cascade="all, delete-orphan")
    
    def __repr__(self):
        return f"<ChatSession(id={self.id}, session_id='{self.session_id}', user_id={self.user_id})>"
    
    def to_dict(self):
        """Convert chat session object to dictionary"""
        return {
            "id": self.id,
            "user_id": self.user_id,
            "session_id": self.session_id,
            "started_at": self.started_at.isoformat() if self.started_at else None,
            "ended_at": self.ended_at.isoformat() if self.ended_at else None,
            "is_active": self.is_active
        }
    
    def end_session(self):
        """End the chat session"""
        from datetime import datetime
        self.ended_at = datetime.now()
        self.is_active = False
    
    def get_messages_count(self, db_session=None):
        """Get total number of messages in this session"""
        if db_session:
            from models.chat import ChatMessage
            return db_session.query(ChatMessage).filter(ChatMessage.session_id == self.id).count()
        return 0  # Return 0 if no database session provided
    
    def get_last_message(self, db_session=None):
        """Get the last message in this session"""
        if db_session:
            from models.chat import ChatMessage
            last_message = db_session.query(ChatMessage).filter(
                ChatMessage.session_id == self.id
            ).order_by(ChatMessage.timestamp.desc()).first()
            return last_message
        return None  # Return None if no database session provided

class ChatMessage(Base):
    """
    Chat message model for storing individual chat messages
    """
    __tablename__ = "chat_messages"
    
    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    session_id = Column(Integer, ForeignKey("chat_sessions.id", ondelete="CASCADE"), nullable=False, index=True)
    message_type = Column(Enum(MessageTypeEnum), nullable=False)
    content = Column(Text, nullable=False)
    timestamp = Column(TIMESTAMP, server_default=func.current_timestamp(), index=True)
    
    # Relationships
    session = relationship("ChatSession", back_populates="messages")
    
    def __repr__(self):
        return f"<ChatMessage(id={self.id}, type='{self.message_type}', session_id={self.session_id})>"
    
    def to_dict(self):
        """Convert chat message object to dictionary"""
        return {
            "id": self.id,
            "session_id": self.session_id,
            "message_type": self.message_type.value,
            "content": self.content,
            "timestamp": self.timestamp.isoformat() if self.timestamp else None
        }
    
    def is_from_user(self):
        """Check if message is from user"""
        return self.message_type == MessageTypeEnum.user
    
    def is_from_assistant(self):
        """Check if message is from assistant"""
        return self.message_type == MessageTypeEnum.assistant
    
    def get_preview(self, max_length=100):
        """Get a preview of the message content"""
        if len(self.content) <= max_length:
            return self.content
        return self.content[:max_length] + "..."

# Health-related chat templates and responses
class HealthChatTemplates:
    """
    Templates for health-related chat responses
    """
    
    GREETING_RESPONSES = [
        "Xin chào! Tôi là trợ lý AI sức khỏe của bạn. Tôi có thể giúp bạn tư vấn về các vấn đề sức khỏe cơ bản. Bạn cần hỗ trợ gì hôm nay?",
        "Chào bạn! Tôi ở đây để hỗ trợ bạn về các câu hỏi sức khỏe. Hãy cho tôi biết bạn muốn tìm hiểu về điều gì?",
        "Xin chào! Tôi có thể giúp bạn tư vấn về sức khỏe, thuốc men, và chế độ sinh hoạt. Bạn có câu hỏi gì không?"
    ]
    
    BLOOD_PRESSURE_ADVICE = {
        "normal": "Huyết áp của bạn trong mức bình thường. Hãy duy trì lối sống lành mạnh với chế độ ăn ít muối, tập thể dục đều đặn và kiểm tra định kỳ.",
        "elevated": "Huyết áp của bạn hơi cao. Bạn nên: 1) Giảm muối trong ăn uống, 2) Tăng cường vận động, 3) Kiểm soát cân nặng, 4) Theo dõi huyết áp thường xuyên.",
        "high": "Huyết áp của bạn cao. Bạn cần: 1) Uống thuốc đúng giờ theo chỉ định bác sĩ, 2) Chế độ ăn DASH (ít muối, nhiều rau quả), 3) Tập thể dục nhẹ nhàng, 4) Tái khám theo lịch hẹn."
    }
    
    MEDICATION_REMINDERS = [
        "Đừng quên uống thuốc đúng giờ nhé! Việc tuân thủ đúng liều lượng và thời gian rất quan trọng cho sức khỏe.",
        "Hãy nhớ uống thuốc theo đúng chỉ định của bác sĩ. Nếu quên một liều, hãy uống ngay khi nhớ ra (trừ khi gần giờ uống liều tiếp theo).",
        "Việc uống thuốc đều đặn sẽ giúp kiểm soát bệnh tốt hơn. Bạn có thể đặt báo thức để nhắc nhở."
    ]
    
    GENERAL_HEALTH_TIPS = [
        "Một số lời khuyên sức khỏe cho người cao tuổi: 1) Uống đủ nước (6-8 ly/ngày), 2) Ăn nhiều rau xanh và trái cây, 3) Tập thể dục nhẹ nhàng hàng ngày, 4) Ngủ đủ 7-8 tiếng, 5) Khám sức khỏe định kỳ.",
        "Để duy trì sức khỏe tốt: 1) Duy trì cân nặng hợp lý, 2) Không hút thuốc, hạn chế rượu bia, 3) Quản lý stress, 4) Duy trì mối quan hệ xã hội tích cực, 5) Kích thích trí não bằng đọc sách, giải đố.",
        "Chăm sóc sức khỏe tại nhà: 1) Theo dõi các chỉ số sức khỏe (huyết áp, đường huyết), 2) Giữ gìn vệ sinh cá nhân, 3) Tạo môi trường sống an toàn, 4) Chuẩn bị thuốc cấp cứu cơ bản."
    ]
    
    EMERGENCY_KEYWORDS = [
        "cấp cứu", "khẩn cấp", "đau ngực", "khó thở", "choáng váng", "ngất xỉu", 
        "đau đầu dữ dội", "nôn mửa", "sốt cao", "co giật", "tai nạn"
    ]
    
    EMERGENCY_RESPONSE = """
    🚨 TÌNH HUỐNG KHẨN CẤP 🚨
    
    Nếu bạn đang gặp tình huống khẩn cấp, hãy:
    1. GỌI NGAY 115 (Cấp cứu) hoặc 113 (Công an)
    2. Liên hệ người thân gần nhất
    3. Nếu có thể, đến bệnh viện gần nhất
    
    Tôi chỉ là trợ lý AI và không thể thay thế cho việc chăm sóc y tế khẩn cấp.
    """
    
    @classmethod
    def get_blood_pressure_advice(cls, systolic, diastolic):
        """Get blood pressure advice based on readings"""
        if systolic < 120 and diastolic < 80:
            return cls.BLOOD_PRESSURE_ADVICE["normal"]
        elif systolic < 140 or diastolic < 90:
            return cls.BLOOD_PRESSURE_ADVICE["elevated"]
        else:
            return cls.BLOOD_PRESSURE_ADVICE["high"]
    
    @classmethod
    def check_emergency_keywords(cls, message):
        """Check if message contains emergency keywords"""
        message_lower = message.lower()
        return any(keyword in message_lower for keyword in cls.EMERGENCY_KEYWORDS)
