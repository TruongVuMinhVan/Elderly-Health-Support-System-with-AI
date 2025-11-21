"""
Email OTP verification for login 2FA
"""

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from pydantic import BaseModel
from datetime import timedelta
import logging

from database import get_database
from auth_simple import AuthManager
from models.user import User
from email_service import email_otp_service
from temp_token import TempTokenManager
# Logging setup
logger = logging.getLogger(__name__)

# Create router
router = APIRouter(prefix="/auth", tags=["Email 2FA Login"])


# Pydantic models
class EmailOTPVerifyRequest(BaseModel):
    temp_token: str
    email: str
    otp: str


class Token(BaseModel):
    access_token: str
    token_type: str
    user: dict


@router.post("/verify-email-2fa", response_model=Token)
async def verify_email_2fa(
    request: EmailOTPVerifyRequest,
    db: Session = Depends(get_database),
):
    """
    Verify email OTP and complete login (Email-based 2FA)
    """
    try:
        logger.info(f"📩 Verifying email OTP for {request.email}")

        temp_payload = TempTokenManager.verify_temp_token(request.temp_token)
        if not temp_payload:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid or expired temporary token",
            )

        user_id = int(temp_payload.get("sub"))
        user_email = temp_payload.get("email")

        if not user_id or not user_email:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid token payload",
            )

        user = db.query(User).filter(User.id == user_id).first()
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found",
            )

        if user.email.lower() != request.email.lower():
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Email mismatch",
            )

        if not user.email_otp_enabled:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Email OTP is not enabled for this user",
            )

        is_valid = email_otp_service.verify_otp(request.email, request.otp)
        if not is_valid:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid or expired OTP",
            )

        access_token_expires = timedelta(minutes=30)
        access_token = AuthManager.create_access_token(
            data={"sub": str(user.id), "email": user.email},
            expires_delta=access_token_expires,
        )

        logger.info(f"✅ Email OTP verified successfully for user: {user.email}")

        return Token(
            access_token=access_token,
            token_type="bearer",
            user=user.to_dict(),
        )

    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        logger.error(f"❌ Error verifying email OTP: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to verify email OTP",
        )
