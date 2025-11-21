"""
Email OTP 2FA API routes
"""

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from pydantic import BaseModel
from typing import Optional
import logging

from database import get_database
from auth_simple import get_current_user
from models.user import User
from email_service import email_otp_service

# Logging setup
logger = logging.getLogger(__name__)

# Create router
router = APIRouter(prefix="/auth/2fa/email", tags=["Email 2FA"])

# Pydantic models
class EmailOTPSendRequest(BaseModel):
    email: str

class EmailOTPVerifyRequest(BaseModel):
    email: str
    otp: str

class EmailOTPEnableRequest(BaseModel):
    otp: str

class EmailOTPStatusResponse(BaseModel):
    email_otp_enabled: bool
    preferred_2fa_method: str

@router.post("/send-otp")
async def send_email_otp(
    request: EmailOTPSendRequest,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_database)
):
    """
    Send OTP via email for 2FA (SECURED)
    - Only allow sending OTP to the authenticated user's email (prevent abuse).
    - Useful for setup (enable) and 'resend' flows from frontend.
    """
    try:
        user_id = current_user.get("sub")
        if isinstance(user_id, str):
            user_id = int(user_id)

        user = db.query(User).filter(User.id == user_id).first()
        if not user:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")

        # Security: only allow sending OTP to the authenticated user's registered email.
        if request.email.lower().strip() != user.email.lower().strip():
            logger.warning(f"Attempt to send OTP to a different email: requested={request.email} user={user.email}")
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Cannot send OTP to that email address"
            )

        # Send OTP email (await so we know if it succeeded)
        await email_otp_service.send_otp_email(
            email=user.email,
            user_name=user.full_name or user.email
        )

        logger.info(f"Email OTP sent to {user.email} for user_id={user.id}")
        return {"message": "OTP đã được gửi đến email của bạn", "email": user.email}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error sending email OTP: {e}", exc_info=True)
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Failed to send email OTP")

@router.post("/verify-otp")
async def verify_email_otp(
    request: EmailOTPVerifyRequest,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_database)
):
    """
    Verify email OTP for 2FA
    """
    try:
        user_id = current_user.get("sub")
        if isinstance(user_id, str):
            user_id = int(user_id)

        user = db.query(User).filter(User.id == user_id).first()
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found"
            )

        # Check if email OTP is enabled
        if not user.email_otp_enabled:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Email OTP is not enabled for this user"
            )

        # Verify OTP
        is_valid = email_otp_service.verify_otp(request.email, request.otp)
        
        if not is_valid:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid or expired OTP"
            )

        logger.info(f"Email OTP verified for user {user.email}")

        return {
            "message": "OTP verified successfully",
            "verified": True
        }

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error verifying email OTP: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to verify email OTP"
        )

@router.post("/enable")
async def enable_email_otp(
    request: EmailOTPEnableRequest,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_database)
):
    """
    Enable Email OTP 2FA for the current user.
    Verify OTP, then set flags and send confirmation.
    """
    try:
        user_id = int(current_user.get("sub"))
        user = db.query(User).filter(User.id == user_id).first()

        if not user:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")

        if user.email_otp_enabled:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Email OTP is already enabled")

        if not email_otp_service.verify_otp(user.email, request.otp):
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid or expired OTP code")

        user.email_otp_enabled = True
        user.preferred_2fa_method = "email"
        db.commit()
        db.refresh(user)

        try:
            await email_otp_service.send_2fa_setup_email(email=user.email, user_name=user.full_name)
        except Exception as e:
            logger.warning(f"⚠️ Failed to send 2FA confirmation email to {user.email}: {e}")

        logger.info(f"✅ Email OTP 2FA enabled for {user.email}")

        return {
            "message": "Email OTP 2FA đã được bật thành công",
            "email_otp_enabled": True,
            "preferred_2fa_method": "email"
        }

    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        logger.error(f"❌ Error enabling email OTP: {e}", exc_info=True)
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Failed to enable email OTP")


@router.post("/disable")
async def disable_email_otp(
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_database)
):
    """
    Disable email OTP 2FA
    - Turn off email_otp_enabled.
    - Update preferred_2fa_method: if TOTP is available keep 'totp', otherwise set to None (or empty).
    - Commit and return the new status.
    - NOTE: consider requiring confirmation (password/otp) for stronger security.
    """
    try:
        user_id = current_user.get("sub")
        if isinstance(user_id, str):
            user_id = int(user_id)

        user = db.query(User).filter(User.id == user_id).first()
        if not user:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")

        if not user.email_otp_enabled:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Email OTP is not enabled")

        # Disable email OTP
        user.email_otp_enabled = False

        # Decide preferred method:
        # - if TOTP is enabled -> prefer totp
        # - else -> clear preferred method (None or '')
        if getattr(user, "two_factor_enabled", False):
            user.preferred_2fa_method = 'totp'
        else:
            # No other 2FA available -> clear preference
            user.preferred_2fa_method = None

        db.commit()
        # refresh to get updated model state
        db.refresh(user)

        logger.info(f"Email OTP disabled for user_id={user.id} (email={user.email})")

        return {
            "message": "Email OTP 2FA đã được tắt",
            "email_otp_enabled": user.email_otp_enabled,
            "preferred_2fa_method": user.preferred_2fa_method
        }

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error disabling email OTP: {e}", exc_info=True)
        db.rollback()
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Failed to disable email OTP")

@router.get("/status", response_model=EmailOTPStatusResponse)
async def get_email_otp_status(
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_database)
):
    """
    Get email OTP status
    """
    try:
        user_id = current_user.get("sub")
        if isinstance(user_id, str):
            user_id = int(user_id)

        user = db.query(User).filter(User.id == user_id).first()
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found"
            )

        return EmailOTPStatusResponse(
            email_otp_enabled=user.email_otp_enabled,
            preferred_2fa_method=user.preferred_2fa_method
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting email OTP status: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to get email OTP status"
        )
