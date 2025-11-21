"""
Two-Factor Authentication (2FA) API routes
"""

from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.responses import StreamingResponse
from sqlalchemy.orm import Session
from pydantic import BaseModel
from typing import List, Optional
import json
import logging
import io

from database import get_database
from auth_simple import AuthManager, get_current_user
from models.user import User
from two_factor_auth import TwoFactorAuth, TwoFactorManager, two_factor_rate_limit

# Logging setup
logger = logging.getLogger(__name__)

# Create router
router = APIRouter(prefix="/auth/2fa", tags=["2FA"])

# Pydantic models
class TwoFactorSetupResponse(BaseModel):
    otpauth_uri: str
    secret: str

class TwoFactorEnableRequest(BaseModel):
    code: str

class TwoFactorEnableResponse(BaseModel):
    backup_codes: List[str]

class TwoFactorVerifyRequest(BaseModel):
    code: str

class TwoFactorRecoverRequest(BaseModel):
    backup_code: str

class TwoFactorStatusResponse(BaseModel):
    two_factor_enabled: bool

@router.post("/setup-start", response_model=TwoFactorSetupResponse)
async def start_2fa_setup(
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_database)
):
    """
    Start 2FA setup process - generates secret and otpauth URI
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

        if user.two_factor_enabled:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="2FA is already enabled"
            )

        # Generate secret and otpauth URI
        secret, otpauth_uri = TwoFactorManager.setup_2fa_start(user.email)
        
        # Store secret temporarily (not enabled yet)
        user.two_factor_secret = secret
        db.commit()

        logger.info(f"2FA setup started for user: {user.email}")

        return TwoFactorSetupResponse(
            otpauth_uri=otpauth_uri,
            secret=secret
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error starting 2FA setup: {e}")
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to start 2FA setup"
        )

@router.get("/qr")
async def get_2fa_qr_code(
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_database)
):
    """
    Get QR code image for 2FA setup
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

        if not user.two_factor_secret:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="No 2FA secret found. Start setup first."
            )

        # Generate otpauth URI and QR code
        otpauth_uri = TwoFactorAuth.build_otpauth_uri(user.two_factor_secret, user.email)
        qr_code_bytes = TwoFactorAuth.generate_qr_code(otpauth_uri)

        return StreamingResponse(
            io.BytesIO(qr_code_bytes),
            media_type="image/png",
            headers={"Content-Disposition": "inline; filename=2fa-qr.png"}
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error generating QR code: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to generate QR code"
        )

@router.post("/enable", response_model=TwoFactorEnableResponse)
async def enable_2fa(
    request: TwoFactorEnableRequest,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_database)
):
    """
    Enable 2FA after verification
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

        if user.two_factor_enabled:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="2FA is already enabled"
            )

        if not user.two_factor_secret:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="No 2FA secret found. Start setup first."
            )

        # Verify the code
        if not TwoFactorAuth.verify_totp(user.two_factor_secret, request.code):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid verification code"
            )

        # Generate backup codes
        backup_codes = TwoFactorAuth.generate_backup_codes()
        backup_codes_hashed = TwoFactorAuth.hash_backup_codes(backup_codes)

        # Enable 2FA
        user.two_factor_enabled = True
        user.backup_codes_hashed = json.dumps(backup_codes_hashed)
        db.commit()

        logger.info(f"2FA enabled for user: {user.email}")

        return TwoFactorEnableResponse(backup_codes=backup_codes)

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error enabling 2FA: {e}")
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to enable 2FA"
        )

@router.post("/disable")
async def disable_2fa(
    request: TwoFactorVerifyRequest,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_database)
):
    """
    Disable 2FA
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

        if not user.two_factor_enabled:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="2FA is not enabled"
            )

        # Verify the code before disabling
        if not TwoFactorAuth.verify_totp(user.two_factor_secret, request.code):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid verification code"
            )

        # Disable 2FA
        user.two_factor_enabled = False
        user.two_factor_secret = None
        user.backup_codes_hashed = None
        db.commit()

        logger.info(f"2FA disabled for user: {user.email}")

        return {"message": "2FA disabled successfully"}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error disabling 2FA: {e}")
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to disable 2FA"
        )

@router.get("/status")
async def get_2fa_status(
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_database)
):
    """
    Return combined 2FA status for the authenticated user:
    { two_factor_enabled, email_otp_enabled, preferred_2fa_method }
    """
    try:
        user_id = current_user.get("sub")
        if isinstance(user_id, str):
            user_id = int(user_id)

        user = db.query(User).filter(User.id == user_id).first()
        if not user:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")

        return {
            "two_factor_enabled": bool(user.two_factor_enabled),
            "email_otp_enabled": bool(user.email_otp_enabled),
            "preferred_2fa_method": user.preferred_2fa_method or None
        }

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Error getting 2FA status: {e}", exc_info=True)
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Failed to get 2FA status")

@router.post("/recover")
async def recover_with_backup_code(
    request: TwoFactorRecoverRequest,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_database)
):
    """
    Use backup code to recover 2FA access
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

        if not user.two_factor_enabled:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="2FA is not enabled"
            )

        if not user.backup_codes_hashed:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="No backup codes available"
            )

        # Parse backup codes
        backup_codes_hashed = json.loads(user.backup_codes_hashed)
        
        # Verify backup code
        backup_index = TwoFactorAuth.verify_backup_code(backup_codes_hashed, request.backup_code)
        if backup_index is None:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid backup code"
            )

        # Remove used backup code
        backup_codes_hashed = TwoFactorAuth.remove_backup_code(backup_codes_hashed, backup_index)
        user.backup_codes_hashed = json.dumps(backup_codes_hashed) if backup_codes_hashed else None
        db.commit()

        logger.info(f"Backup code used for user: {user.email}")

        return {"message": "Backup code accepted"}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error using backup code: {e}")
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to use backup code"
        )
