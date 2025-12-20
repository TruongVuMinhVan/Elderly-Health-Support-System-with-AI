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
        """
        💊 **Hướng dẫn uống thuốc an toàn:**
        
        **⏰ Thời gian:**
        • Uống đúng giờ theo chỉ định bác sĩ
        • Đặt báo thức nhắc nhở
        • Nếu quên 1 liều: uống ngay khi nhớ (trừ khi gần giờ uống liều tiếp theo)
        
        **📋 Lưu ý quan trọng:**
        • Không tự ý tăng/giảm liều
        • Không ngừng thuốc đột ngột
        • Uống với nước lọc, tránh rượu bia
        • Bảo quản thuốc nơi khô ráo, thoáng mát
        
        **🔍 Theo dõi:**
        • Ghi nhật ký uống thuốc
        • Theo dõi tác dụng phụ
        • Mang danh sách thuốc khi đi khám
        
        **⚠️ Báo bác sĩ ngay nếu:**
        • Có phản ứng dị ứng (ngứa, phát ban, khó thở)
        • Tác dụng phụ nghiêm trọng
        • Thuốc không có hiệu quả
        
        Tuân thủ uống thuốc = Kiểm soát bệnh tốt hơn! 💙
        """,
        
        """
        💊 **Quản lý thuốc thông minh:**
        
        **📦 Sắp xếp thuốc:**
        • Dùng hộp chia thuốc theo ngày/giờ
        • Để thuốc ở nơi dễ thấy (không phải tủ lạnh)
        • Kiểm tra hạn sử dụng định kỳ
        
        **📱 Công nghệ hỗ trợ:**
        • App nhắc uống thuốc
        • Báo thức điện thoại
        • Lịch ghi chú trên tường
        
        **👨‍⚕️ Tương tác thuốc:**
        • Thông báo bác sĩ tất cả thuốc đang dùng
        • Bao gồm thuốc không kê đơn, thảo dược
        • Hỏi dược sĩ về tương tác thuốc
        
        **🍽️ Uống thuốc với thức ăn:**
        • Trước ăn: 30-60 phút trước bữa ăn
        • Sau ăn: 1-2 giờ sau bữa ăn
        • Cùng bữa ăn: trong lúc ăn hoặc ngay sau ăn
        
        Thuốc là bạn đồng hành chăm sóc sức khỏe! 💙
        """,
        
        """
        💊 **An toàn thuốc cho người cao tuổi:**
        
        **🎯 Nguyên tắc vàng:**
        • "Đúng người, đúng thuốc, đúng liều, đúng cách, đúng thời gian"
        • Luôn đọc nhãn thuốc trước khi uống
        • Không chia sẻ thuốc với người khác
        
        **📝 Danh sách thuốc:**
        • Ghi tên thuốc, liều lượng, tần suất
        • Cập nhật khi có thay đổi
        • Mang theo khi đi du lịch, cấp cứu
        
        **🔄 Tái khám định kỳ:**
        • Đánh giá hiệu quả điều trị
        • Điều chỉnh liều nếu cần
        • Kiểm tra tác dụng phụ
        • Cân nhắc ngừng thuốc không cần thiết
        
        **💡 Mẹo nhỏ:**
        • Uống thuốc cùng thói quen hàng ngày (đánh răng, ăn sáng)
        • Chuẩn bị thuốc cho cả tuần vào Chủ nhật
        • Nhờ người thân nhắc nhở nếu cần
        
        Sức khỏe là tài sản quý giá nhất! 💙
        """
    ]
    
    GENERAL_HEALTH_TIPS = [
        """
        🌟 **Lời khuyên sức khỏe tổng quát cho người cao tuổi:**
        
        💧 **Nước uống:** 
        • Uống 6-8 ly nước/ngày (khoảng 1.5-2 lít)
        • Uống từ từ, chia đều trong ngày
        • Tránh uống quá nhiều nước trước khi ngủ
        
        🥗 **Dinh dưỡng:**
        • Ăn nhiều rau xanh, trái cây tươi (5 phần/ngày)
        • Protein: cá, thịt nạc, trứng, đậu
        • Canxi: sữa, phô mai, rau xanh đậm màu
        • Hạn chế muối (<5g/ngày), đường, dầu mỡ
        
        🏃‍♂️ **Vận động:**
        • Đi bộ 30 phút/ngày (có thể chia 3 lần 10 phút)
        • Tập thể dục nhẹ: yoga, thái cực quyền
        • Tập cơ: nâng tạ nhẹ 2-3 lần/tuần
        
        😴 **Giấc ngủ:** 7-8 tiếng/đêm, ngủ đúng giờ
        
        🏥 **Khám định kỳ:** 3-6 tháng/lần tùy tình trạng sức khỏe
        """,
        
        """
        🎯 **Duy trì sức khỏe toàn diện:**
        
        ⚖️ **Cân nặng:**
        • BMI lý tưởng: 18.5-24.9
        • Cân nặng mỗi tuần cùng giờ
        • Giảm cân từ từ (0.5-1kg/tháng)
        
        🚭 **Tránh có hại:**
        • Không hút thuốc (bỏ thuốc bất cứ lúc nào cũng có lợi)
        • Hạn chế rượu bia (<1 ly/ngày nữ, <2 ly/ngày nam)
        • Tránh thuốc không rõ nguồn gốc
        
        🧠 **Sức khỏe tinh thần:**
        • Quản lý stress: thiền, nghe nhạc, làm vườn
        • Duy trì mối quan hệ xã hội
        • Học hỏi điều mới: đọc sách, học ngoại ngữ
        • Tham gia hoạt động cộng đồng
        
        💡 **Mẹo nhỏ:** Viết nhật ký sức khỏe để theo dõi tiến bộ!
        """,
        
        """
        🏠 **Chăm sóc sức khỏe tại nhà:**
        
        📊 **Theo dõi chỉ số:**
        • Huyết áp: đo cùng giờ mỗi ngày
        • Đường huyết: theo chỉ định bác sĩ
        • Cân nặng: 1 lần/tuần
        • Ghi chép vào sổ theo dõi
        
        🧼 **Vệ sinh cá nhân:**
        • Rửa tay thường xuyên (20 giây với xà phòng)
        • Vệ sinh răng miệng 2 lần/ngày
        • Tắm gội đều đặn
        • Cắt móng tay chân sạch sẽ
        
        🏡 **An toàn tại nhà:**
        • Đèn chiếu sáng đủ, tránh trơn trượt
        • Tay vịn cầu thang, nhà tắm
        • Sắp xếp đồ dùng tầm với
        • Số điện thoại khẩn cấp dễ thấy
        
        💊 **Thuốc cấp cứu cơ bản:**
        • Thuốc hạ sốt, giảm đau
        • Băng gạc, cồn sát trùng
        • Thuốc dị ứng (nếu có tiền sử)
        • Kiểm tra hạn sử dụng định kỳ
        """
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
