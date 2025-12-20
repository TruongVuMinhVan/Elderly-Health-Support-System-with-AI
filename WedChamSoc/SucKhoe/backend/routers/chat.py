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
GEMINI_API_KEY = config('GEMINI_API_KEY', default='')
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

# Models for public chatbot consult (no login required)
class ConsultMessage(BaseModel):
    content: str
    session_id: Optional[str] = None

class ConsultResponse(BaseModel):
    message: str
    suggested_diseases: List[dict] = []
    recommendation: str
    should_see_doctor: bool = False
    session_id: str

class HealthAdviceService:
    """
    Service for generating health advice responses
    """
    
    @staticmethod
    def get_system_prompt():
        """Get system prompt for health AI assistant"""
        return """
        Bạn là một trợ lý AI chuyên về sức khỏe cho người cao tuổi tại Việt Nam, có kiến thức sâu rộng về y học, dinh dưỡng, và chăm sóc sức khỏe.

        🎯 NHIỆM VỤ CHÍNH:
        1. **Phân tích triệu chứng chi tiết:** Đặt câu hỏi sâu về vị trí, mức độ, thời gian, yếu tố làm tăng/giảm, triệu chứng kèm theo
        2. **Đưa ra các khả năng:** Liệt kê 2-4 nguyên nhân có thể, giải thích tại sao (dựa trên triệu chứng)
        3. **Hướng dẫn xử lý tạm thời:** Các biện pháp an toàn tại nhà (nghỉ ngơi, chườm, uống nước, tư thế...)
        4. **Tư vấn dinh dưỡng:** Thực phẩm nên ăn/tránh, chế độ ăn phù hợp
        5. **Lời khuyên lối sống:** Vận động, giấc ngủ, quản lý stress
        6. **Khuyến nghị y tế:** Khi nào cần đi khám, mức độ khẩn cấp

        ⚠️ QUY TẮC QUAN TRỌNG:
        - KHÔNG chẩn đoán bệnh chính xác (chỉ nói "có thể là", "khả năng")
        - KHÔNG kê đơn thuốc cụ thể (chỉ gợi ý loại thuốc chung như "thuốc giảm đau", "thuốc hạ sốt")
        - LUÔN khuyên đi khám bác sĩ cho các vấn đề nghiêm trọng hoặc kéo dài >3 ngày
        - Với triệu chứng khẩn cấp: hướng dẫn gọi 115 hoặc đến bệnh viện NGAY
        - Sử dụng ngôn ngữ đơn giản, thân thiện, gọi "bác" hoặc "cô/chú"

        🚨 DẤU HIỆU KHẨN CẤP (yêu cầu đi bệnh viện ngay):
        - Đau ngực dữ dội, tức ngực, khó thở
        - Đau đầu dữ dội đột ngột (như búa bổ)
        - Yếu liệt một bên người, méo miệng, nói khó
        - Sốt cao >39°C không hạ
        - Chảy máu nhiều không cầm được
        - Đau bụng dữ dội, cứng bụng
        - Co giật, ngất xỉu
        - Nôn ra máu, đi cầu phân đen

        📋 CẤU TRÚC TRẢ LỜI CHI TIẾT:

        **1. CHÀO HỎI & THẤU HIỂU (1-2 câu)**
        "Chào bác/cô! Tôi hiểu bác/cô đang gặp vấn đề về [triệu chứng]. Tôi sẽ cố gắng hỗ trợ bác/cô."

        **2. HỎI THÊM THÔNG TIN (nếu câu hỏi ngắn gọn)**
        "Để tư vấn chính xác hơn, bác/cô có thể cho biết thêm:"
        • Vị trí cụ thể: [ví dụ: đau ở đâu trong bụng?]
        • Mức độ: [nhẹ/vừa/dữ dội, thang điểm 1-10]
        • Thời gian: [khi nào bắt đầu? kéo dài bao lâu?]
        • Đặc điểm: [đau liên tục hay từng cơn? tăng khi nào?]
        • Triệu chứng kèm theo: [sốt? buồn nôn? tiêu chảy?...]
        • Tiền sử: [có bệnh nền? đang uống thuốc gì?]

        **3. PHÂN TÍCH & CÁC KHẢ NĂNG (2-4 khả năng)**
        "Dựa trên triệu chứng bác/cô mô tả, có thể là:"

        **🔹 Khả năng 1: [Tên bệnh/tình trạng]**
        • Triệu chứng điển hình: [liệt kê]
        • Nguyên nhân: [giải thích ngắn gọn]
        • Mức độ: [nhẹ/vừa/nghiêm trọng]

        **🔹 Khả năng 2: [Tên bệnh/tình trạng]**
        • Triệu chứng điển hình: [liệt kê]
        • Nguyên nhân: [giải thích ngắn gọn]
        • Mức độ: [nhẹ/vừa/nghiêm trọng]

        [Thêm khả năng 3, 4 nếu cần]

        **4. XỬ LÝ TẠM THỜI TẠI NHÀ**
        "Trong lúc chờ khám bác sĩ, bác/cô có thể:"

        **✅ Nên làm:**
        • [Hướng dẫn cụ thể 1]
        • [Hướng dẫn cụ thể 2]
        • [Hướng dẫn cụ thể 3]

        **❌ Tránh:**
        • [Điều cần tránh 1]
        • [Điều cần tránh 2]

        **5. DINH DƯỠNG & CHĂM SÓC**
        **🍎 Thực phẩm nên ăn:**
        • [Thực phẩm 1 + lý do]
        • [Thực phẩm 2 + lý do]

        **🚫 Thực phẩm nên tránh:**
        • [Thực phẩm 1 + lý do]
        • [Thực phẩm 2 + lý do]

        **6. KHUYẾN NGHỊ Y TẾ**
        **🏥 Nên đi khám bác sĩ nếu:**
        • [Dấu hiệu 1]
        • [Dấu hiệu 2]
        • [Dấu hiệu 3]

        **⏰ Thời gian:** [Ngay/Trong 24h/Trong 2-3 ngày/Theo dõi]

        **🚨 ĐI CẤP CỨU NGAY nếu:** [Liệt kê dấu hiệu nguy hiểm]

        **7. LỜI KHUYÊN THÊM**
        • [Lời khuyên về lối sống]
        • [Phòng ngừa]
        • [Theo dõi]

        **8. KẾT THÚC**
        "Chúc bác/cô sớm khỏe lại! Nếu có thêm câu hỏi, cứ hỏi tôi nhé. 💙"

        🎨 PHONG CÁCH VIẾT:
        - Thân thiện, ấm áp, dễ hiểu
        - Sử dụng emoji phù hợp: 💡⚠️🏥💊🍎🏃‍♂️😴🤒💙✅❌🔹
        - Chia thành các mục rõ ràng với bullet points
        - Giải thích thuật ngữ y khoa nếu dùng
        - Đưa ra ví dụ cụ thể, dễ hình dung
        - Độ dài: 300-500 từ (chi tiết nhưng không dài dòng)

        💬 ĐỐI VỚI CÂU HỎI CHUNG (không phải triệu chứng):
        - Trả lời chi tiết, có cấu trúc
        - Đưa ra nhiều thông tin hữu ích
        - Có ví dụ thực tế
        - Kết thúc bằng lời khuyên thêm

        Trả lời bằng tiếng Việt, CHI TIẾT, CÓ CẤU TRÚC, THỰC TẾ. KHÔNG trả lời hời hợt, chung chung, hoặc quá ngắn gọn.
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
            
            # Enhance user context with symptom analysis for short messages
            message_lower = user_message.lower().strip()
            
            # Detect if message is too short/vague about symptoms
            symptom_keywords = ["đau", "nhức", "khó chịu", "mệt", "sốt", "buồn nôn", "nôn", "tiêu chảy", "táo bón"]
            has_symptom = any(keyword in message_lower for keyword in symptom_keywords)
            
            # If message is short and mentions symptoms, enhance context to ask for more details
            if has_symptom and len(user_message.split()) <= 5:
                if user_context is None:
                    user_context = {}
                user_context['needs_more_info'] = True
                user_context['symptom_type'] = HealthAdviceService._detect_symptom_type(message_lower)
            
            # Use Gemini if API key is available and valid
            if GEMINI_API_KEY and GEMINI_API_KEY != '' and not GEMINI_API_KEY.startswith('YOUR_'):
                try:
                    response = await HealthAdviceService._get_gemini_response(user_message, user_context)
                    logger.info(f"✅ Gemini API response generated successfully")
                    return response
                except Exception as e:
                    logger.error(f"❌ Gemini API failed, falling back to template: {e}")
                    # Fallback to template but ensure symptom-based response if symptoms detected
                    return HealthAdviceService._get_template_response(user_message)
            else:
                logger.warning("⚠️ Gemini API key not configured properly, using template response")
                # Fallback to template responses
                return HealthAdviceService._get_template_response(user_message)
                
        except Exception as e:
            logger.error(f"Error generating chat response: {e}")
            return "Xin lỗi, tôi đang gặp sự cố kỹ thuật. Vui lòng thử lại sau hoặc liên hệ bác sĩ nếu cần hỗ trợ khẩn cấp."
    
    @staticmethod
    def _detect_symptom_type(message: str) -> str:
        """Detect the type of symptom from message"""
        message_lower = message.lower()
        
        if any(word in message_lower for word in ["đau bụng", "đau dạ dày", "đau bao tử"]):
            return "đau_bụng"
        elif any(word in message_lower for word in ["đau đầu", "nhức đầu"]):
            return "đau_đầu"
        elif any(word in message_lower for word in ["đau lưng", "nhức lưng"]):
            return "đau_lưng"
        elif any(word in message_lower for word in ["đau ngực", "tức ngực"]):
            return "đau_ngực"
        elif any(word in message_lower for word in ["sốt", "nóng sốt"]):
            return "sốt"
        elif any(word in message_lower for word in ["ho", "ho khan", "ho có đờm"]):
            return "ho"
        else:
            return "khác"
    
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

            # Add conversation history if available
            if user_context and 'symptoms' in user_context:
                full_prompt += f"""
TRIỆU CHỨNG ĐÃ MÔ TẢ TRƯỚC ĐÓ: {', '.join(user_context.get('symptoms', []))}
"""
            
            # Add specific guidance based on symptom type
            symptom_guidance = ""
            if user_context and user_context.get('needs_more_info'):
                symptom_type = user_context.get('symptom_type', 'khác')
                
                if symptom_type == 'đau_bụng':
                    symptom_guidance = """
QUAN TRỌNG: Câu hỏi quá ngắn gọn về đau bụng. BẮT BUỘC phải hỏi thêm:
1. Vị trí đau: Ở đâu trong bụng? (trên rốn, dưới rốn, bên trái, bên phải, giữa bụng)
2. Mức độ đau: Đau như thế nào? (nhẹ, vừa, dữ dội, quặn thắt)
3. Thời gian: Đau từ khi nào? Kéo dài bao lâu? (vài phút, vài giờ, vài ngày)
4. Triệu chứng kèm theo: Có sốt không? Buồn nôn? Nôn? Tiêu chảy? Táo bón? Chướng bụng?
5. Hoàn cảnh: Ăn gì trước đó? Có uống thuốc gì không?
6. Cải thiện/tệ hơn: Đau tăng khi làm gì? (ăn, uống, vận động) Có tư thế nào giảm đau không?

Sau đó đưa ra các khả năng có thể (viêm dạ dày, rối loạn tiêu hóa, đau bụng kinh, sỏi mật, viêm ruột thừa...) và hướng dẫn xử lý.
"""
                elif symptom_type == 'đau_đầu':
                    symptom_guidance = """
QUAN TRỌNG: Câu hỏi quá ngắn gọn về đau đầu. BẮT BUỘC phải hỏi thêm:
1. Vị trí đau: Đau ở đâu? (trán, sau gáy, một bên, cả đầu)
2. Mức độ: Đau như thế nào? (nhẹ, vừa, dữ dội, như búa bổ)
3. Thời gian: Đau từ khi nào? Kéo dài bao lâu?
4. Triệu chứng kèm theo: Có buồn nôn? Nhạy cảm với ánh sáng/tiếng động? Chóng mặt?
5. Hoàn cảnh: Có chấn thương đầu không? Có thay đổi thời tiết không?
"""
                else:
                    symptom_guidance = """
QUAN TRỌNG: Câu hỏi quá ngắn gọn về triệu chứng. BẮT BUỘC phải hỏi thêm:
1. Mô tả chi tiết: Triệu chứng cụ thể như thế nào?
2. Vị trí: Ở đâu? (nếu có thể xác định)
3. Mức độ: Nhẹ, vừa, hay nghiêm trọng?
4. Thời gian: Khi nào bắt đầu? Kéo dài bao lâu?
5. Triệu chứng kèm theo: Có triệu chứng khác không?
6. Hoàn cảnh: Có điều gì gây ra hoặc làm tăng/giảm triệu chứng không?
"""
            
            full_prompt += f"""
CÂU HỎI/TRIỆU CHỨNG CỦA NGƯỜI DÙNG: {user_message}
{symptom_guidance}
YÊU CẦU:
- Phân tích chi tiết triệu chứng này
- Nếu câu hỏi quá ngắn gọn, HÃY HỎI THÊM các câu hỏi cụ thể (theo hướng dẫn trên)
- Đưa ra các khả năng có thể dựa trên triệu chứng
- Hướng dẫn xử lý tạm thời an toàn tại nhà
- Khuyến nghị có nên đi khám không và khi nào nên đi khám

TRẢ LỜI (chi tiết, không hời hợt, có cấu trúc rõ ràng):"""

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
                    logger.info(f"✅ Gemini API returned response (length: {len(content)})")
                    return content.strip()
                else:
                    logger.error(f"❌ No candidates in Gemini response: {result}")
                    # Raise exception to trigger fallback
                    raise Exception("No candidates in Gemini response")
            else:
                error_text = response.text[:500] if response.text else "No error message"
                logger.error(f"❌ Gemini API HTTP error {response.status_code}: {error_text}")
                # Raise exception to trigger fallback
                raise Exception(f"Gemini API HTTP {response.status_code}: {error_text}")

        except requests.exceptions.RequestException as e:
            logger.error(f"❌ Gemini API request exception: {e}")
            raise  # Re-raise to trigger fallback
        except Exception as e:
            logger.error(f"❌ Gemini API error: {e}", exc_info=True)
            raise  # Re-raise to trigger fallback
    
    @staticmethod
    def _get_template_response(user_message: str) -> str:
        """
        Get detailed template response based on keywords
        Priority: Symptoms > Specific topics > Medication reminders > General
        """
        message_lower = user_message.lower()
        
        # PRIORITY 1: Check for symptoms FIRST (before medication keyword)
        symptom_keywords = [
            "đau bụng", "đau dạ dày", "đau bao tử", "đau đầu", "nhức đầu",
            "đau lưng", "nhức lưng", "đau ngực", "tức ngực", "sốt", "nóng sốt",
            "ho", "ho khan", "ho có đờm", "buồn nôn", "nôn", "tiêu chảy", 
            "táo bón", "chướng bụng", "đầy hơi", "khó tiêu", "đau", "nhức",
            "mệt mỏi", "chóng mặt", "choáng váng", "khó thở", "tức thở"
        ]
        has_symptom = any(keyword in message_lower for keyword in symptom_keywords)
        
        if has_symptom:
            # Detect specific symptom type for more targeted response
            if any(word in message_lower for word in ["đau bụng", "đau dạ dày", "đau bao tử"]):
                return """
                🤒 **Chào bác/cô! Tôi hiểu bác/cô đang gặp vấn đề về đau bụng.**

                **🔍 Để tư vấn chính xác hơn, bác/cô có thể cho biết thêm:**
                • **Vị trí:** Đau ở đâu trong bụng? (trên rốn, dưới rốn, bên trái/phải, giữa bụng)
                • **Mức độ:** Đau như thế nào? (nhẹ, vừa, dữ dội, quặn thắt) - thang điểm 1-10?
                • **Thời gian:** Đau từ khi nào? Kéo dài bao lâu? (vài phút, vài giờ, vài ngày)
                • **Đặc điểm:** Đau liên tục hay từng cơn? Tăng khi ăn/uống/vận động?
                • **Triệu chứng kèm theo:** Có sốt không? Buồn nôn? Nôn? Tiêu chảy? Táo bón? Chướng bụng?
                • **Hoàn cảnh:** Ăn gì trước đó? Có uống thuốc gì không? Có căng thẳng không?

                **🔹 Các khả năng có thể:**
                • **Rối loạn tiêu hóa:** Do ăn uống không hợp lý, căng thẳng
                • **Viêm dạ dày:** Đau thượng vị, buồn nôn, ợ hơi
                • **Hội chứng ruột kích thích:** Đau bụng + rối loạn đại tiện
                • **Táo bón:** Đau bụng dưới, khó đi cầu

                **✅ Xử lý tạm thời:**
                • Nghỉ ngơi, nằm co chân lên bụng
                • Chườm ấm vùng bụng (không quá nóng)
                • Uống nước ấm từng ngụm nhỏ
                • Ăn nhẹ: cháo loãng, bánh quy giòn

                **🏥 Đi khám ngay nếu:**
                • Đau dữ dội, cứng bụng
                • Sốt cao >38.5°C
                • Nôn ra máu, đi cầu phân đen
                • Đau kéo dài >24h không giảm

                Chúc bác/cô sớm khỏe lại! 💙
                """
            
            elif any(word in message_lower for word in ["đau đầu", "nhức đầu"]):
                return """
                🤒 **Chào bác/cô! Tôi hiểu bác/cô đang bị đau đầu.**

                **🔍 Để tư vấn chính xác hơn, bác/cô có thể cho biết thêm:**
                • **Vị trí:** Đau ở đâu? (trán, thái dương, sau gáy, một bên, cả đầu)
                • **Mức độ:** Đau như thế nào? (nhẹ, vừa, dữ dội, như búa bổ) - thang điểm 1-10?
                • **Thời gian:** Đau từ khi nào? Kéo dài bao lâu?
                • **Đặc điểm:** Đau liên tục hay từng cơn? Đập thình thịch?
                • **Triệu chứng kèm theo:** Buồn nôn? Nhạy cảm ánh sáng/tiếng động? Chóng mặt? Sốt?
                • **Hoàn cảnh:** Có căng thẳng? Thay đổi thời tiết? Ít ngủ? Đói?

                **🔹 Các khả năng có thể:**
                • **Đau đầu căng thẳng:** Do stress, mệt mỏi, tư thế xấu
                • **Đau nửa đầu (migraine):** Đau một bên, buồn nôn, sợ ánh sáng
                • **Đau đầu do huyết áp:** Kèm chóng mặt, ù tai
                • **Đau đầu do mất nước:** Khi ít uống nước, trời nóng

                **✅ Xử lý tạm thời:**
                • Nghỉ ngơi trong phòng tối, yên tĩnh
                • Chườm lạnh trán hoặc chườm ấm gáy
                • Massage nhẹ thái dương, gáy
                • Uống đủ nước, ăn nhẹ nếu đói
                • Thuốc giảm đau (paracetamol) theo hướng dẫn

                **🏥 Đi khám ngay nếu:**
                • Đau đầu dữ dội đột ngột (như búa bổ)
                • Kèm sốt cao, cứng gáy
                • Yếu liệt tay chân, nói khó
                • Đau đầu thay đổi đột ngột so với bình thường

                Chúc bác/cô sớm khỏe lại! 💙
                """
            
            else:
                # General symptom response
                return """
                🤒 **Chào bác/cô! Tôi hiểu bác/cô đang gặp vấn đề về sức khỏe.**
                
                **🔍 Để tư vấn tốt hơn, bác/cô có thể cho biết thêm:**
                • **Triệu chứng cụ thể:** Mô tả chi tiết hơn về cảm giác
                • **Vị trí:** Ở đâu trên cơ thể? (nếu có thể xác định)
                • **Mức độ:** Nhẹ, vừa, hay nghiêm trọng? (thang điểm 1-10)
                • **Thời gian:** Khi nào bắt đầu? Kéo dài bao lâu?
                • **Triệu chứng kèm theo:** Có triệu chứng khác không?
                • **Hoàn cảnh:** Có điều gì gây ra hoặc làm tăng/giảm triệu chứng?
                • **Tiền sử:** Có bệnh nền? Đang uống thuốc gì?

                **💡 Nguyên tắc chung:**
                • Nghỉ ngơi đầy đủ
                • Uống đủ nước (6-8 ly/ngày)
                • Ăn nhẹ, dễ tiêu
                • Theo dõi triệu chứng

                **⚠️ Lưu ý quan trọng:**
                Tôi không thể chẩn đoán bệnh chính xác. Nếu triệu chứng nghiêm trọng hoặc kéo dài >3 ngày, bác/cô nên đi khám bác sĩ.

                **🚨 Đi cấp cứu ngay nếu:**
                • Đau dữ dội, sốt cao >39°C
                • Khó thở, đau ngực
                • Yếu liệt, méo miệng, nói khó
                • Chảy máu nhiều, ngất xỉu

                Hãy gọi 115 hoặc đến bệnh viện gần nhất!

                Chúc bác/cô sớm khỏe lại! 💙
                """
        
        # PRIORITY 2: Blood pressure related
        elif any(keyword in message_lower for keyword in ["huyết áp", "blood pressure", "cao huyết áp", "tăng huyết áp"]):
            return """
            📊 **Hướng dẫn về Huyết áp cho người cao tuổi:**

            **🎯 Chỉ số chuẩn:**
            • **Bình thường:** <120/80 mmHg
            • **Hơi cao:** 120-139/80-89 mmHg  
            • **Cao huyết áp độ 1:** 140-159/90-99 mmHg
            • **Cao huyết áp độ 2:** ≥160/100 mmHg
            • **Khẩn cấp:** >180/110 mmHg

            **📏 Cách đo đúng:**
            • Ngồi yên 5 phút trước khi đo
            • Đo cùng giờ mỗi ngày (sáng và tối)
            • Không uống cà phê, hút thuốc trước 30 phút
            • Băng quấn vừa khít, ngang tim
            • Đo 2-3 lần, cách nhau 1-2 phút

            **✅ Kiểm soát huyết áp:**
            
            **🍎 Chế độ ăn DASH:**
            • Nhiều rau xanh, trái cây (5-9 phần/ngày)
            • Ngũ cốc nguyên hạt, đậu, hạt
            • Cá, thịt nạc, sữa ít béo
            • Giảm muối <5g/ngày (1 thìa cà phê)
            • Hạn chế đường, dầu mỡ

            **🏃‍♂️ Vận động:**
            • Đi bộ nhanh 30 phút/ngày, 5 ngày/tuần
            • Bơi lội, đạp xe, yoga
            • Tập thở sâu, thiền
            • Tránh vận động quá mạnh

            **💊 Uống thuốc:**
            • Đúng giờ, đúng liều theo bác sĩ
            • Không tự ý ngừng thuốc
            • Ghi nhật ký huyết áp
            • Tái khám định kỳ 1-3 tháng

            **🚨 Đi cấp cứu ngay nếu:**
            • Huyết áp >180/110 mmHg
            • Đau đầu dữ dội, chóng mặt
            • Đau ngực, khó thở
            • Nôn mửa, nhìn mờ

            **💡 Mẹo nhỏ:**
            • Giảm cân nếu thừa cân (mỗi kg giảm = huyết áp giảm 1mmHg)
            • Ngủ đủ 7-8 tiếng
            • Quản lý stress
            • Hạn chế rượu bia

            Chúc bác/cô kiểm soát huyết áp tốt! 💙
            """
        
        # PRIORITY 3: Exercise related
        elif any(keyword in message_lower for keyword in ["tập thể dục", "vận động", "exercise", "thể thao"]):
            return """
            🏃‍♂️ **Hướng dẫn Thể dục cho người cao tuổi:**

            **🎯 Lợi ích:**
            • Tăng cường sức khỏe tim mạch
            • Cải thiện cân bằng, giảm ngã
            • Tăng mật độ xương
            • Cải thiện tâm trạng, giấc ngủ
            • Kiểm soát cân nặng, đường huyết

            **✅ Các bài tập nên tập:**

            **🚶‍♂️ Aerobic (150 phút/tuần):**
            • Đi bộ nhanh: 30 phút/ngày, 5 ngày/tuần
            • Bơi lội: nhẹ nhàng, tốt cho khớp
            • Đạp xe đạp: trong nhà hoặc ngoài trời
            • Khiêu vũ: vui vẻ, tăng cường xã hội

            **💪 Tập cơ (2-3 lần/tuần):**
            • Nâng tạ nhẹ (0.5-2kg)
            • Dùng dây kháng lực
            • Tập với trọng lượng cơ thể: đứng ngồi ghế
            • Tập 8-12 lần/bài, 2-3 hiệp

            **🧘‍♀️ Cân bằng & Dẻo dai:**
            • Yoga: cải thiện dẻo dai, cân bằng
            • Thái cực quyền: nhẹ nhàng, an toàn
            • Đứng một chân: 10-30 giây
            • Duỗi cơ: giữ 15-30 giây

            **⚠️ Lưu ý an toàn:**
            • Khởi động 5-10 phút (đi bộ chậm, xoay khớp)
            • Tăng cường độ từ từ
            • Ngừng nếu đau ngực, khó thở, chóng mặt
            • Mặc giày thể thao phù hợp
            • Uống nước đủ trước, trong, sau tập

            **❌ Tránh:**
            • Tập khi đói hoặc no quá
            • Vận động quá mạnh, đột ngột
            • Tập khi sốt, không khỏe
            • Nhịn thở khi tập cơ

            **📅 Lịch tập mẫu:**
            • **Thứ 2, 4, 6:** Đi bộ + Tập cơ
            • **Thứ 3, 5:** Yoga/Thái cực quyền
            • **Thứ 7:** Bơi lội hoặc đạp xe
            • **Chủ nhật:** Nghỉ ngơi hoặc đi bộ nhẹ

            **💡 Bắt đầu từ từ:** 10-15 phút/ngày, tăng dần 5 phút/tuần

            Chúc bác/cô tập luyện vui khỏe! 💙
            """
        
        # PRIORITY 4: Diet related
        elif any(keyword in message_lower for keyword in ["ăn uống", "chế độ ăn", "diet", "dinh dưỡng", "thực phẩm"]):
            return """
            🍎 **Chế độ ăn lành mạnh cho người cao tuổi:**

            **🎯 Nguyên tắc cơ bản:**
            • Ăn đa dạng, cân bằng dinh dưỡng
            • Chia nhỏ bữa: 3 bữa chính + 2-3 bữa phụ
            • Ăn chậm, nhai kỹ
            • Uống đủ nước: 6-8 ly/ngày

            **✅ Thực phẩm nên ăn:**

            **🥬 Rau xanh (3-5 phần/ngày):**
            • Rau lá xanh đậm: cải bó xôi, cải xoăn
            • Rau họ cải: bông cải xanh, súp lơ
            • Cà chua, cà rốt, bí đỏ (giàu vitamin A)

            **🍓 Trái cây (2-4 phần/ngày):**
            • Cam, chanh (vitamin C)
            • Chuối (kali, tốt cho tim)
            • Táo, lê (chất xơ)
            • Quả mọng: việt quất, dâu (chống oxy hóa)

            **🐟 Protein (2-3 phần/ngày):**
            • Cá biển: cá hồi, cá thu (omega-3)
            • Thịt nạc: thịt gà, thịt bò nạc
            • Trứng: 1 quả/ngày
            • Đậu, hạt: đậu phụ, hạt óc chó

            **🥛 Canxi (2-3 phần/ngày):**
            • Sữa ít béo, sữa chua
            • Phô mai ít muối
            • Rau xanh đậm màu
            • Cá có xương: cá cơm, cá sardin

            **🌾 Ngũ cốc nguyên hạt:**
            • Gạo lứt, yến mạch
            • Bánh mì nguyên cám
            • Quinoa, lúa mạch

            **❌ Hạn chế:**
            • **Muối:** <5g/ngày (1 thìa cà phê)
            • **Đường:** <25g/ngày (6 thìa cà phê)
            • **Chất béo bão hòa:** <10% tổng calo
            • Thức ăn chế biến sẵn, đồ hộp
            • Rượu bia: <1 ly/ngày (nữ), <2 ly/ngày (nam)

            **🕐 Thời gian ăn:**
            • **Sáng (7-8h):** Đầy đủ dinh dưỡng, có protein
            • **Trưa (11-12h):** Bữa chính, nhiều rau
            • **Tối (17-18h):** Nhẹ nhàng, ít dầu mỡ
            • **Bữa phụ:** Trái cây, sữa chua, hạt

            **💡 Mẹo nấu ăn:**
            • Hấp, luộc, nướng thay vì chiên
            • Dùng gia vị tự nhiên: gừng, tỏi, thảo mộc
            • Nấu chín kỹ, dễ tiêu hóa
            • Cắt nhỏ nếu khó nhai

            **🚫 Thực phẩm cần tránh:**
            • Thức ăn ôi thiu, hết hạn
            • Đồ sống: sushi, tiết canh
            • Đồ ngọt quá nhiều
            • Thức ăn nhanh, đồ chiên

            Chúc bác/cô ăn ngon miệng, khỏe mạnh! 💙
            """
        
        # PRIORITY 5: Sleep related
        elif any(keyword in message_lower for keyword in ["ngủ", "mất ngủ", "khó ngủ", "sleep", "insomnia"]):
            return """
            😴 **Hướng dẫn giấc ngủ chất lượng cho người cao tuổi:**

            **🎯 Nhu cầu giấc ngủ:**
            • Người cao tuổi: 7-8 tiếng/đêm
            • Có thể ngủ trưa 20-30 phút (trước 15h)
            • Chất lượng quan trọng hơn số lượng

            **✅ Thói quen ngủ tốt:**
            
            **🕘 Lịch trình đều đặn:**
            • Đi ngủ và thức dậy cùng giờ mỗi ngày
            • Kể cả cuối tuần và ngày lễ
            • Tránh ngủ nướng quá 1 tiếng

            **🛏️ Môi trường ngủ:**
            • Phòng tối, yên tĩnh, mát mẻ (18-22°C)
            • Nệm và gối thoải mái
            • Tránh ánh sáng xanh từ điện thoại, TV

            **🌙 Chuẩn bị trước khi ngủ:**
            • Tắm nước ấm 1-2 tiếng trước ngủ
            • Đọc sách, nghe nhạc nhẹ
            • Thở sâu, thiền 10-15 phút
            • Tránh caffeine sau 14h

            **❌ Tránh:**
            • Ăn no, uống nhiều nước trước ngủ 2-3 tiếng
            • Tập thể dục mạnh tối muộn
            • Căng thẳng, lo lắng
            • Ngủ trưa quá lâu hoặc quá muộn

            **🌿 Phương pháp tự nhiên:**
            • Trà hoa cúc, trà hoa oải hương
            • Tinh dầu lavender
            • Yoga nhẹ, duỗi cơ
            • Nghe nhạc thiền, âm thanh tự nhiên

            **🏥 Khi nào cần gặp bác sĩ:**
            • Mất ngủ >3 tuần
            • Ngáy to, ngưng thở khi ngủ
            • Buồn ngủ quá mức ban ngày
            • Giật chân khi ngủ

            Chúc bác/cô ngủ ngon, khỏe mạnh! 💙
            """

        # PRIORITY 6: Mental health/stress
        elif any(keyword in message_lower for keyword in ["stress", "căng thẳng", "lo lắng", "buồn", "trầm cảm", "tâm lý"]):
            return """
            🧠 **Chăm sóc sức khỏe tinh thần cho người cao tuổi:**

            **💡 Hiểu về stress:**
            • Stress là phản ứng tự nhiên của cơ thể
            • Có thể do thay đổi cuộc sống, bệnh tật, mất mát
            • Ảnh hưởng đến sức khỏe thể chất và tinh thần

            **🔍 Dấu hiệu cần chú ý:**
            • Buồn bã kéo dài >2 tuần
            • Mất hứng thú với hoạt động yêu thích
            • Thay đổi cảm xúc đột ngột
            • Khó tập trung, quyết định
            • Rối loạn ăn uống, ngủ

            **✅ Cách quản lý stress:**

            **🧘‍♀️ Thư giãn:**
            • Thở sâu: hít vào 4 giây, giữ 4 giây, thở ra 6 giây
            • Thiền chánh niệm 10-20 phút/ngày
            • Yoga, thái cực quyền
            • Nghe nhạc, đọc sách

            **🤝 Kết nối xã hội:**
            • Duy trì liên lạc với gia đình, bạn bè
            • Tham gia hoạt động cộng đồng
            • Tình nguyện, giúp đỡ người khác
            • Nuôi thú cưng nếu có thể

            **🎨 Hoạt động sáng tạo:**
            • Vẽ, viết nhật ký
            • Làm vườn, nấu ăn
            • Học kỹ năng mới
            • Chơi trò chơi trí tuệ

            **🏃‍♂️ Vận động:**
            • Đi bộ ngoài trời 30 phút/ngày
            • Tiếp xúc ánh sáng mặt trời
            • Tập thể dục nhẹ nhàng
            • Khiêu vũ, bơi lội

            **💭 Tư duy tích cực:**
            • Ghi nhật ký biết ơn
            • Tập trung vào điều tích cực
            • Chấp nhận những gì không thể thay đổi
            • Đặt mục tiêu nhỏ, thực tế

            **🏥 Khi nào cần hỗ trợ chuyên nghiệp:**
            • Cảm giác tuyệt vọng, vô ích
            • Có ý định tự làm hại bản thân
            • Không thể thực hiện hoạt động hàng ngày
            • Triệu chứng kéo dài >1 tháng

            **📞 Đường dây nóng hỗ trợ tâm lý:**
            • 1900 0167 (24/7)
            • 028 38 333 333

            Sức khỏe tinh thần cũng quan trọng như sức khỏe thể chất! 💙
            """

        # PRIORITY 7: Diabetes
        elif any(keyword in message_lower for keyword in ["tiểu đường", "đường huyết", "diabetes", "glucose"]):
            return """
            🩺 **Quản lý Tiểu đường cho người cao tuổi:**

            **📊 Chỉ số đường huyết:**
            • **Bình thường:** <100 mg/dL (lúc đói)
            • **Tiền tiểu đường:** 100-125 mg/dL
            • **Tiểu đường:** ≥126 mg/dL (2 lần khác nhau)
            • **Sau ăn 2h:** <140 mg/dL (bình thường)

            **🎯 Mục tiêu kiểm soát:**
            • HbA1c: <7% (người cao tuổi khỏe mạnh)
            • HbA1c: 7-8% (có bệnh kèm theo)
            • Đường huyết lúc đói: 80-130 mg/dL
            • Đường huyết sau ăn: <180 mg/dL

            **🍽️ Chế độ ăn cho người tiểu đường:**

            **✅ Nên ăn:**
            • Rau xanh không hạn chế
            • Protein nạc: cá, gà, đậu phụ
            • Ngũ cốc nguyên hạt: gạo lứt, yến mạch
            • Trái cây ít đường: táo, lê, quả mọng
            • Chất béo tốt: dầu ô liu, hạt óc chó

            **❌ Hạn chế:**
            • Đường, kẹo, bánh ngọt
            • Nước ngọt, nước trái cây
            • Gạo trắng, bánh mì trắng
            • Thức ăn chiên, đồ chế biến

            **⏰ Thời gian ăn:**
            • Ăn đều đặn 3 bữa chính + 2-3 bữa phụ
            • Không bỏ bữa
            • Ăn bữa phụ nếu uống thuốc hạ đường huyết

            **💊 Quản lý thuốc:**
            • Uống đúng giờ, đúng liều
            • Không tự ý thay đổi liều
            • Mang theo kẹo/đường phòng hạ đường huyết
            • Kiểm tra chân, mắt định kỳ

            **🏃‍♂️ Vận động:**
            • 150 phút/tuần vận động vừa phải
            • Đi bộ sau ăn 15-30 phút
            • Tập cơ 2-3 lần/tuần
            • Kiểm tra đường huyết trước/sau tập

            **⚠️ Dấu hiệu nguy hiểm:**

            **📈 Đường huyết cao:**
            • Khát nước nhiều, tiểu nhiều
            • Mệt mỏi, nhìn mờ
            • Thở có mùi trái cây

            **📉 Đường huyết thấp:**
            • Run tay, đổ mồ hôi
            • Chóng mặt, lú lẫn
            • Đói bụng, tim đập nhanh

            **🚨 Cấp cứu ngay nếu:**
            • Đường huyết <70 hoặc >400 mg/dL
            • Bất tỉnh, co giật
            • Nôn mửa không ngừng

            **💡 Mẹo quản lý:**
            • Ghi nhật ký đường huyết
            • Mang thẻ bệnh nhân tiểu đường
            • Khám mắt, thận định kỳ
            • Chăm sóc chân cẩn thận

            Kiểm soát tốt tiểu đường = Sống khỏe mạnh! 💙
            """

        # PRIORITY 8: Medication reminders (ONLY if no symptoms mentioned)
        elif any(keyword in message_lower for keyword in ["thuốc", "uống thuốc", "medication"]):
            import random
            return random.choice(HealthChatTemplates.MEDICATION_REMINDERS)
        
        # PRIORITY 9: General health
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

# In-memory conversation storage for public consult (không lưu vào database)
_public_conversations = {}

def _extract_symptoms(user_message: str) -> List[str]:
    """Extract symptoms from user message"""
    symptom_keywords = {
        "ngứa": "ngứa",
        "đỏ": "đỏ da",
        "sưng": "sưng",
        "đau": "đau",
        "nóng": "nóng rát",
        "mụn": "mụn",
        "vết thương": "vết thương",
        "phát ban": "phát ban",
        "bong tróc": "bong tróc da",
        "mẩn đỏ": "mẩn đỏ"
    }
    
    symptoms = []
    user_lower = user_message.lower()
    for keyword, symptom in symptom_keywords.items():
        if keyword in user_lower:
            symptoms.append(symptom)
    
    return symptoms

def _suggest_diseases_from_symptoms(symptoms: List[str]) -> List[dict]:
    """Suggest possible diseases based on symptoms"""
    disease_symptoms_map = {
        "eczema": ["ngứa", "đỏ", "bong tróc"],
        "melanoma": ["đổi màu", "nốt ruồi", "bất thường"],
        "basal_cell_carcinoma": ["vết thương", "không lành", "chảy máu"],
        "dermatitis": ["ngứa", "đỏ", "phát ban"],
        "psoriasis": ["bong tróc", "đỏ", "dày da"],
        "healthy": []
    }
    
    suggested = []
    for disease, disease_symptoms in disease_symptoms_map.items():
        matches = sum(1 for s in symptoms if any(ds in s.lower() for ds in disease_symptoms))
        if matches > 0:
            suggested.append({
                "disease_name": disease,
                "match_score": matches / len(disease_symptoms) if disease_symptoms else 0,
                "matched_symptoms": [s for s in symptoms if any(ds in s.lower() for ds in disease_symptoms)]
            })
    
    suggested.sort(key=lambda x: x["match_score"], reverse=True)
    return suggested[:3]

def _determine_should_see_doctor(symptoms: List[str], suggested_diseases: List[dict]) -> bool:
    """Determine if user should see a doctor"""
    urgent_symptoms = ["chảy máu", "đau nhiều", "nhiễm trùng", "sốt", "khó thở"]
    
    if any(urgent in " ".join(symptoms).lower() for urgent in urgent_symptoms):
        return True
    
    high_risk_diseases = ["melanoma", "basal_cell_carcinoma", "squamous_cell_carcinoma"]
    if any(d["disease_name"] in high_risk_diseases for d in suggested_diseases):
        return True
    
    return False

@router.post("/consult", response_model=ConsultResponse)
async def chatbot_consult_public(
    message: ConsultMessage
):
    """
    Chatbot tư vấn sơ bộ - KHÔNG CẦN ĐĂNG NHẬP
    
    - Mô tả triệu chứng bằng text
    - Chatbot hỏi thêm câu hỏi
    - Gợi ý bệnh có thể
    - Khuyến nghị có nên đi khám không
    - KHÔNG lưu lịch sử chat vào database
    """
    try:
        import uuid
        from datetime import datetime
        
        # Generate conversation ID if not provided
        if not message.session_id:
            session_id = str(uuid.uuid4())
        else:
            session_id = message.session_id
        
        # Initialize conversation if new
        if session_id not in _public_conversations:
            _public_conversations[session_id] = {
                "messages": [],
                "symptoms": []
            }
        
        conversation = _public_conversations[session_id]
        
        # Extract symptoms from message
        symptoms = _extract_symptoms(message.content)
        conversation["symptoms"].extend(symptoms)
        conversation["symptoms"] = list(set(conversation["symptoms"]))  # Remove duplicates
        
        # Add user message to conversation
        conversation["messages"].append({
            "role": "user",
            "content": message.content,
            "timestamp": str(datetime.now())
        })
        
        # Generate AI response with symptom context
        user_context = {
            "symptoms": conversation["symptoms"],
            "message_count": len(conversation["messages"])
        }
        
        ai_response = await HealthAdviceService.generate_response(
            message.content,
            user_context
        )
        
        # Add AI response to conversation
        conversation["messages"].append({
            "role": "assistant",
            "content": ai_response,
            "timestamp": str(datetime.now())
        })
        
        # Suggest diseases based on symptoms
        suggested_diseases = _suggest_diseases_from_symptoms(conversation["symptoms"])
        
        # Determine if should see doctor
        should_see_doctor = _determine_should_see_doctor(conversation["symptoms"], suggested_diseases)
        
        # Generate recommendation
        if should_see_doctor:
            recommendation = "⚠️ Dựa trên các triệu chứng bạn mô tả, chúng tôi khuyến nghị bạn nên đi khám bác sĩ da liễu để được chẩn đoán chính xác và điều trị kịp thời."
        elif suggested_diseases:
            recommendation = "💡 Các triệu chứng bạn mô tả có thể liên quan đến một số bệnh da liễu. Nên theo dõi và đi khám nếu tình trạng không cải thiện."
        else:
            recommendation = "✅ Hãy tiếp tục mô tả thêm về các triệu chứng để chúng tôi có thể tư vấn tốt hơn."
        
        logger.info(f"✅ Public chatbot consult completed for session {session_id}")
        
        return ConsultResponse(
            message=ai_response,
            suggested_diseases=suggested_diseases,
            recommendation=recommendation,
            should_see_doctor=should_see_doctor,
            session_id=session_id
        )
        
    except Exception as e:
        logger.error(f"Error in public chatbot consult: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Chatbot consult failed: {str(e)}"
        )

@router.delete("/consult/{session_id}")
async def clear_public_conversation(session_id: str):
    """Clear public conversation (privacy - user can clear their session)"""
    if session_id in _public_conversations:
        del _public_conversations[session_id]
    return {"status": "cleared", "message": "Conversation cleared"}
