"""
AI Chat API routes for Elderly Health Support System
"""

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List, Optional
from pydantic import BaseModel
from datetime import datetime
import logging
import uuid
import requests
import json
from decouple import config

from database import get_database
from auth_simple import get_current_user
from models.user import User
from models.chat import ChatSession, ChatMessage, MessageTypeEnum, HealthChatTemplates

# Logging setup
logger = logging.getLogger(__name__)

# Create router
router = APIRouter(prefix="/api/chat", tags=["chat"])

# Gemini configuration
GEMINI_API_KEY = config('GEMINI_API_KEY', default='AIzaSyCc2yejWFMfUhg9ro2gQ_SQ6CcaL69Y7Ts')
GEMINI_MODEL = config('GEMINI_MODEL', default='gemini-2.0-flash')
GEMINI_API_URL = f"https://generativelanguage.googleapis.com/v1beta/models/{GEMINI_MODEL}:generateContent"

# Pydantic models
class ChatMessageCreate(BaseModel):
    content: str

class ChatMessageResponse(BaseModel):
    id: int
    session_id: int
    message_type: str
    content: str
    timestamp: datetime

class ChatSessionResponse(BaseModel):
    id: int
    user_id: int
    session_id: str
    started_at: datetime
    ended_at: Optional[datetime]
    is_active: bool
    messages: List[ChatMessageResponse] = []

class ChatResponse(BaseModel):
    message: ChatMessageResponse
    session: ChatSessionResponse

class HealthAdviceService:
    """
    Service for generating health advice responses
    """
    
    @staticmethod
    def get_system_prompt():
        """Get system prompt for health AI assistant"""
        return """
        Bạn là một trợ lý AI chuyên về sức khỏe cho người cao tuổi tại Việt Nam.

        NHIỆM VỤ:
        1. Tư vấn sức khỏe cơ bản, an toàn và phù hợp với người cao tuổi
        2. Nhắc nhở về việc uống thuốc và khám bệnh định kỳ
        3. Đưa ra lời khuyên về lối sống lành mạnh
        4. Hướng dẫn theo dõi các chỉ số sức khỏe
        5. Khuyến khích tìm kiếm sự chăm sóc y tế chuyên nghiệp khi cần thiết

        QUY TẮC QUAN TRỌNG:
        - KHÔNG chẩn đoán bệnh hoặc kê đơn thuốc cụ thể
        - LUÔN khuyên người dùng tham khảo ý kiến bác sĩ cho các vấn đề nghiêm trọng
        - Sử dụng ngôn ngữ đơn giản, thân thiện, gọi "bác" hoặc "cô"
        - Đưa ra thông tin chính xác và cập nhật
        - Trong trường hợp khẩn cấp, hướng dẫn gọi 115 hoặc đến bệnh viện

        PHONG CÁCH TRẢ LỜI:
        - Bắt đầu bằng lời chào thân thiện
        - Sử dụng emoji phù hợp (💡, ⚠️, 🏥, 💊, 🍎, 🏃‍♂️)
        - Chia thông tin thành các mục rõ ràng
        - Kết thúc bằng lời chúc sức khỏe

        Trả lời bằng tiếng Việt, có cấu trúc rõ ràng và thực tế.
        """
    
    @staticmethod
    async def generate_response(user_message: str, user_context: dict = None) -> str:
        """
        Generate AI response for user message
        """
        try:
            # Check for emergency keywords
            if HealthChatTemplates.check_emergency_keywords(user_message):
                return HealthChatTemplates.EMERGENCY_RESPONSE
            
            # Check for greeting
            greeting_keywords = ["xin chào", "chào", "hello", "hi", "bạn khỏe không"]
            if any(keyword in user_message.lower() for keyword in greeting_keywords):
                import random
                return random.choice(HealthChatTemplates.GREETING_RESPONSES)
            
            # Use Gemini if API key is available
            if GEMINI_API_KEY and GEMINI_API_KEY != '':
                return await HealthAdviceService._get_gemini_response(user_message, user_context)
            else:
                # Fallback to template responses
                return HealthAdviceService._get_template_response(user_message)
                
        except Exception as e:
            logger.error(f"Error generating chat response: {e}")
            return "Xin lỗi, tôi đang gặp sự cố kỹ thuật. Vui lòng thử lại sau hoặc liên hệ bác sĩ nếu cần hỗ trợ khẩn cấp."
    
    @staticmethod
    async def _get_gemini_response(user_message: str, user_context: dict = None) -> str:
        """
        Get response from Gemini API
        """
        try:
            # Prepare the prompt
            system_prompt = HealthAdviceService.get_system_prompt()
            full_prompt = f"{system_prompt}\n\n"

            # Add user context if available
            if user_context:
                full_prompt += f"""
THÔNG TIN NGƯỜI DÙNG:
- Tên: {user_context.get('name', 'Không có')}
- Tuổi: {user_context.get('age', 'Không có')} tuổi
- Giới tính: {user_context.get('gender', 'Không xác định')}
- Tình trạng sức khỏe: {user_context.get('health_conditions', 'Chưa có thông tin')}

"""

            full_prompt += f"CÂU HỎI: {user_message}\n\nTRẢ LỜI:"

            # Prepare request data
            request_data = {
                "contents": [
                    {
                        "parts": [
                            {
                                "text": full_prompt
                            }
                        ]
                    }
                ]
            }

            # Make API request
            response = requests.post(
                f"{GEMINI_API_URL}?key={GEMINI_API_KEY}",
                headers={'Content-Type': 'application/json'},
                json=request_data,
                timeout=30
            )

            if response.status_code == 200:
                result = response.json()
                if 'candidates' in result and len(result['candidates']) > 0:
                    content = result['candidates'][0]['content']['parts'][0]['text']
                    return content.strip()
                else:
                    logger.error("No candidates in Gemini response")
                    return HealthAdviceService._get_template_response(user_message)
            else:
                logger.error(f"Gemini API error: {response.status_code} - {response.text}")
                return HealthAdviceService._get_template_response(user_message)

        except Exception as e:
            logger.error(f"Gemini API error: {e}")
            return HealthAdviceService._get_template_response(user_message)
    
    @staticmethod
    def _get_template_response(user_message: str) -> str:
        """
        Get template response based on keywords
        """
        message_lower = user_message.lower()
        
        # Blood pressure related
        if any(keyword in message_lower for keyword in ["huyết áp", "blood pressure", "cao huyết áp"]):
            return """
            Về huyết áp, bạn cần lưu ý:
            
            📊 Chỉ số bình thường: < 120/80 mmHg
            ⚠️ Cao huyết áp: ≥ 140/90 mmHg
            
            💡 Lời khuyên:
            • Đo huyết áp đều đặn cùng giờ mỗi ngày
            • Giảm muối trong ăn uống (< 5g/ngày)
            • Tập thể dục nhẹ nhàng 30 phút/ngày
            • Uống thuốc đúng giờ theo chỉ định bác sĩ
            • Tái khám định kỳ theo lịch hẹn
            
            Nếu huyết áp > 180/110, hãy đến bệnh viện ngay!
            """
        
        # Medication related
        elif any(keyword in message_lower for keyword in ["thuốc", "uống thuốc", "medication"]):
            import random
            return random.choice(HealthChatTemplates.MEDICATION_REMINDERS)
        
        # Exercise related
        elif any(keyword in message_lower for keyword in ["tập thể dục", "vận động", "exercise"]):
            return """
            🏃‍♂️ Thể dục cho người cao tuổi:
            
            ✅ Nên tập:
            • Đi bộ 30 phút/ngày
            • Bơi lội hoặc tập trong nước
            • Yoga, thái cực quyền
            • Tập thở sâu
            
            ❌ Tránh:
            • Vận động quá mạnh
            • Tập khi đói hoặc no quá
            • Tập khi không khỏe
            
            💡 Lưu ý: Khởi động 5-10 phút trước khi tập!
            """
        
        # Diet related
        elif any(keyword in message_lower for keyword in ["ăn uống", "chế độ ăn", "diet", "dinh dưỡng"]):
            return """
            🍎 Chế độ ăn lành mạnh cho người cao tuổi:
            
            ✅ Nên ăn:
            • Rau xanh, trái cây tươi
            • Cá, thịt nạc, trứng
            • Ngũ cốc nguyên hạt
            • Sữa, sản phẩm từ sữa
            • Uống đủ nước (6-8 ly/ngày)
            
            ❌ Hạn chế:
            • Muối, đường, dầu mỡ
            • Thức ăn chế biến sẵn
            • Rượu bia, thuốc lá
            
            🕐 Ăn đều đặn 3 bữa chính + 2 bữa phụ
            """
        
        # General health
        else:
            import random
            return random.choice(HealthChatTemplates.GENERAL_HEALTH_TIPS)

@router.post("/sessions", response_model=ChatSessionResponse, status_code=status.HTTP_201_CREATED)
async def create_chat_session(
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_database)
):
    """
    Create a new chat session
    """
    try:
        user_id = current_user.get("sub")

        user = db.query(User).filter(User.id == user_id).first()
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found"
            )
        
        # End any active sessions
        active_sessions = db.query(ChatSession).filter(
            ChatSession.user_id == user.id,
            ChatSession.is_active == True
        ).all()
        
        for session in active_sessions:
            session.end_session()
        
        # Create new session
        session_id = str(uuid.uuid4())
        chat_session = ChatSession(
            user_id=user.id,
            session_id=session_id
        )
        
        db.add(chat_session)
        db.commit()
        db.refresh(chat_session)
        
        logger.info(f"Chat session created: {chat_session.id} for user {user.id}")
        
        return ChatSessionResponse(**chat_session.to_dict())
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error creating chat session: {e}")
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to create chat session"
        )

@router.get("/sessions/active", response_model=Optional[ChatSessionResponse])
async def get_active_session(
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_database)
):
    """
    Get user's active chat session
    """
    logger.info(f"🔍 Getting active session for user: {current_user.get('sub')}")
    try:
        user_id = current_user.get("sub")

        user = db.query(User).filter(User.id == user_id).first()
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found"
            )
        
        session = db.query(ChatSession).filter(
            ChatSession.user_id == user.id,
            ChatSession.is_active == True
        ).first()
        
        if not session:
            return None
        
        # Get session with messages
        messages = db.query(ChatMessage).filter(
            ChatMessage.session_id == session.id
        ).order_by(ChatMessage.timestamp).all()
        
        session_dict = session.to_dict()
        session_dict['messages'] = [
            ChatMessageResponse(**msg.to_dict()) for msg in messages
        ]
        
        return ChatSessionResponse(**session_dict)
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting active session: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to get active session"
        )

@router.post("/sessions/{session_id}/messages", response_model=ChatResponse)
async def send_message(
    session_id: int,
    message_data: ChatMessageCreate,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_database)
):
    """
    Send a message in a chat session
    """
    try:
        user_id = current_user.get("sub")

        user = db.query(User).filter(User.id == user_id).first()
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found"
            )
        
        session = db.query(ChatSession).filter(
            ChatSession.id == session_id,
            ChatSession.user_id == user.id,
            ChatSession.is_active == True
        ).first()
        
        if not session:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Chat session not found or inactive"
            )
        
        # Save user message
        user_message = ChatMessage(
            session_id=session.id,
            message_type=MessageTypeEnum.user,
            content=message_data.content
        )
        
        db.add(user_message)
        db.commit()
        db.refresh(user_message)
        
        # Generate AI response with user context
        user_context = {
            "name": user.full_name,
            "age": user.age,
            "gender": user.gender.value if user.gender else "không xác định",
            "email": user.email,
            "health_conditions": "Chưa có thông tin"  # Could be enhanced with health profile data
        }
        
        ai_response_content = await HealthAdviceService.generate_response(
            message_data.content, 
            user_context
        )
        
        # Save AI response
        ai_message = ChatMessage(
            session_id=session.id,
            message_type=MessageTypeEnum.assistant,
            content=ai_response_content
        )
        
        db.add(ai_message)
        db.commit()
        db.refresh(ai_message)
        
        logger.info(f"Chat message exchanged in session {session.id}")
        
        # Prepare response
        session_dict = session.to_dict()
        return ChatResponse(
            message=ChatMessageResponse(**ai_message.to_dict()),
            session=ChatSessionResponse(**session_dict)
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error sending message: {e}")
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to send message"
        )
