"""
Email service for sending OTP and notifications
"""

import secrets
from datetime import datetime, timedelta
from typing import Optional
from fastapi_mail import FastMail, MessageSchema, ConnectionConfig
import logging
import os
from dotenv import load_dotenv

# Load environment variables from .env file
env_path = os.path.join(os.path.dirname(__file__), ".env")
if os.path.exists(env_path):
    load_dotenv(env_path)

logger = logging.getLogger(__name__)

# ================================
# Email Configuration
# ================================
MAIL_USERNAME = os.getenv("MAIL_USERNAME")
MAIL_PASSWORD = os.getenv("MAIL_PASSWORD")
MAIL_FROM = os.getenv("MAIL_FROM", "noreply@suckhoe.com")
MAIL_PORT = int(os.getenv("MAIL_PORT", "587"))
MAIL_SERVER = os.getenv("MAIL_SERVER", "smtp.gmail.com")
MAIL_STARTTLS = os.getenv("MAIL_STARTTLS", "True").lower() == "true"
MAIL_SSL_TLS = os.getenv("MAIL_SSL_TLS", "False").lower() == "true"

EMAIL_CONFIGURED = bool(MAIL_USERNAME and MAIL_PASSWORD)

# Debug info (1 lần duy nhất khi khởi động)
print("🔍 Email Config Debug:")
print(f"   MAIL_USERNAME: {MAIL_USERNAME}")
print(f"   MAIL_PASSWORD: {'***' if MAIL_PASSWORD else 'None'}")
print(f"   EMAIL_CONFIGURED: {EMAIL_CONFIGURED}")

conf = (
    ConnectionConfig(
        MAIL_USERNAME=MAIL_USERNAME,
        MAIL_PASSWORD=MAIL_PASSWORD,
        MAIL_FROM=MAIL_FROM,
        MAIL_PORT=MAIL_PORT,
        MAIL_SERVER=MAIL_SERVER,
        USE_CREDENTIALS=True,
        VALIDATE_CERTS=False,
        MAIL_STARTTLS=MAIL_STARTTLS,
        MAIL_SSL_TLS=MAIL_SSL_TLS,
    )
    if EMAIL_CONFIGURED
    else None
)


# ================================
# Email OTP Service
# ================================
class EmailOTPService:
    """Service for managing email OTP"""

    def __init__(self):
        self.fastmail = FastMail(conf) if conf else None
        self.otp_storage = {}  # In production, use Redis or database

    def generate_otp(self, length: int = 6) -> str:
        """Generate a random OTP"""
        return "".join([str(secrets.randbelow(10)) for _ in range(length)])

    def store_otp(self, email: str, otp: str, expires_in_minutes: int = 5):
        """Store OTP with expiration"""
        expires_at = datetime.utcnow() + timedelta(minutes=expires_in_minutes)
        self.otp_storage[email] = {
            "otp": otp,
            "expires_at": expires_at,
            "attempts": 0,
        }

    def verify_otp(self, email: str, provided_otp: str) -> bool:
        """Verify OTP with expiration and attempt limit"""
        logger.info(f"🔍 Verifying OTP for email: {email}")
        logger.info(f"📦 Current OTP storage keys: {list(self.otp_storage.keys())}")
        
        record = self.otp_storage.get(email)
        if not record:
            logger.warning(f"❌ No OTP record found for email: {email}")
            return False

        logger.info(f"📝 OTP record found - Expires at: {record['expires_at']}, Attempts: {record['attempts']}")
        
        # Expired
        if datetime.utcnow() > record["expires_at"]:
            logger.warning(f"⏰ OTP expired for {email}")
            del self.otp_storage[email]
            return False

        # Too many attempts
        if record["attempts"] >= 3:
            logger.warning(f"🚫 Too many attempts for {email}")
            del self.otp_storage[email]
            return False

        # Match check
        logger.info(f"🔑 Comparing OTP - Stored: {record['otp']}, Provided: {provided_otp}")
        if record["otp"] == provided_otp:
            logger.info(f"✅ OTP verified successfully for {email}")
            del self.otp_storage[email]
            return True

        logger.warning(f"❌ OTP mismatch for {email}")
        record["attempts"] += 1
        return False

    async def send_otp_email(self, email: str, user_name: str = "Người dùng") -> str:
        """Send OTP via email"""
        if not EMAIL_CONFIGURED or self.fastmail is None:
            logger.error("Email service not configured properly.")
            raise Exception(
                "Email service not configured. Please set MAIL_USERNAME and MAIL_PASSWORD in .env"
            )

        try:
            otp = self.generate_otp()
            self.store_otp(email, otp)

            subject = "Mã xác thực 2 bước - SucKhoe"

            html_content = f"""
            <!DOCTYPE html>
            <html>
            <head>
                <meta charset="utf-8">
                <title>Mã xác thực 2 bước</title>
                <style>
                    body {{ font-family: Arial, sans-serif; line-height: 1.6; color: #333; }}
                    .container {{ max-width: 600px; margin: 0 auto; padding: 20px; }}
                    .header {{ background: #4F46E5; color: white; padding: 20px; text-align: center; border-radius: 8px 8px 0 0; }}
                    .content {{ background: #f9f9f9; padding: 30px; border-radius: 0 0 8px 8px; }}
                    .otp-code {{ background: #4F46E5; color: white; font-size: 32px; font-weight: bold; text-align: center; padding: 20px; border-radius: 8px; letter-spacing: 8px; margin: 20px 0; }}
                    .warning {{ background: #FEF3C7; border: 1px solid #F59E0B; padding: 15px; border-radius: 8px; margin: 20px 0; }}
                    .footer {{ text-align: center; margin-top: 30px; color: #666; font-size: 14px; }}
                </style>
            </head>
            <body>
                <div class="container">
                    <div class="header">
                        <h1>🔐 Mã xác thực 2 bước</h1>
                    </div>
                    <div class="content">
                        <p>Xin chào <strong>{user_name}</strong>,</p>
                        <p>Bạn đang thực hiện đăng nhập vào hệ thống SucKhoe. Vui lòng sử dụng mã xác thực bên dưới:</p>
                        <div class="otp-code">{otp}</div>
                        <div class="warning">
                            <strong>⚠️ Lưu ý quan trọng:</strong>
                            <ul>
                                <li>Mã này chỉ có hiệu lực trong <strong>5 phút</strong></li>
                                <li>Không chia sẻ mã này với bất kỳ ai</li>
                                <li>Nếu bạn không thực hiện đăng nhập, vui lòng bỏ qua email này</li>
                            </ul>
                        </div>
                        <p>Trân trọng,<br>Đội ngũ SucKhoe</p>
                    </div>
                    <div class="footer">
                        <p>Email này được gửi tự động, vui lòng không trả lời.</p>
                    </div>
                </div>
            </body>
            </html>
            """

            message = MessageSchema(
                subject=subject, recipients=[email], body=html_content, subtype="html"
            )
            await self.fastmail.send_message(message)

            logger.info(f"✅ OTP email sent to {email}")
            return otp

        except Exception as e:
            logger.error(f"❌ Failed to send OTP email to {email}: {e}")
            raise Exception("Không thể gửi email xác thực")

    async def send_2fa_setup_email(self, email: str, user_name: str = "Người dùng") -> bool:
        """Send 2FA setup confirmation email"""
        if not EMAIL_CONFIGURED or self.fastmail is None:
            logger.error("Email service not configured properly.")
            return False

        try:
            subject = "Bảo mật 2 bước đã được bật - SucKhoe"
            html_content = f"""
            <!DOCTYPE html>
            <html>
            <head>
                <meta charset="utf-8">
                <title>Bảo mật 2 bước đã được bật</title>
                <style>
                    body {{ font-family: Arial, sans-serif; line-height: 1.6; color: #333; }}
                    .container {{ max-width: 600px; margin: 0 auto; padding: 20px; }}
                    .header {{ background: #10B981; color: white; padding: 20px; text-align: center; border-radius: 8px 8px 0 0; }}
                    .content {{ background: #f9f9f9; padding: 30px; border-radius: 0 0 8px 8px; }}
                    .success {{ background: #D1FAE5; border: 1px solid #10B981; padding: 15px; border-radius: 8px; margin: 20px 0; }}
                    .footer {{ text-align: center; margin-top: 30px; color: #666; font-size: 14px; }}
                </style>
            </head>
            <body>
                <div class="container">
                    <div class="header">
                        <h1>✅ Bảo mật 2 bước đã được bật</h1>
                    </div>
                    <div class="content">
                        <p>Xin chào <strong>{user_name}</strong>,</p>
                        <div class="success">
                            <strong>🎉 Chúc mừng!</strong> Bảo mật 2 bước qua email đã được bật thành công cho tài khoản của bạn.
                        </div>
                        <p>Từ giờ, mỗi khi đăng nhập, bạn sẽ nhận được mã xác thực qua email để bảo vệ tài khoản.</p>
                        <p>Nếu bạn không thực hiện thay đổi này, vui lòng liên hệ với chúng tôi ngay lập tức. </p>
                        <p> Trân trọng,<br>Đội ngũ SucKhoe</p>
                    </div>
                    <div class="footer">
                        <p>Email này được gửi tự động, vui lòng không trả lời.</p>
                    </div>
                </div>
            </body>
            </html>
            """

            message = MessageSchema(
                subject=subject, recipients=[email], body=html_content, subtype="html"
            )
            await self.fastmail.send_message(message)

            logger.info(f"📩 2FA setup email sent to {email}")
            return True

        except Exception as e:
            logger.error(f"❌ Failed to send 2FA setup email to {email}: {e}")
            return False


# Global email service instance
email_otp_service = EmailOTPService()
