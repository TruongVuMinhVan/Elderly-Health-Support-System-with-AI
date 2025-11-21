"""
Simple Authentication API routes (supporting TOTP & Email OTP)
"""

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from pydantic import BaseModel, EmailStr, validator
from datetime import timedelta
import logging
import json

from database import get_database
from auth_simple import AuthManager, validate_email, validate_password, rate_limiter, get_current_user
from models.user import User
from temp_token import TempTokenManager
from two_factor_auth import TwoFactorAuth, two_factor_rate_limit
from email_service import email_otp_service  # ✅ import thêm để gửi OTP email
from typing import Optional

# Logging setup
logger = logging.getLogger(__name__)

# Create router
router = APIRouter(tags=["authentication"])

# -----------------------------
# Pydantic Models
# -----------------------------
class UserRegister(BaseModel):
    email: EmailStr
    password: str
    full_name: str
    phone: str = None
    
    @validator('password')
    def validate_password_strength(cls, v):
        if not validate_password(v):
            raise ValueError('Password must be at least 6 characters long')
        return v

class UserLogin(BaseModel):
    email: EmailStr
    password: str

class Token(BaseModel):
    access_token: str
    token_type: str
    user: dict

class TwoFactorRequired(BaseModel):
    status: str = "2fa_required"
    temp_token: str
    message: str
    method: str  # "totp" or "email"

class TwoFactorVerify(BaseModel):
    temp_token: str
    code: str

class EmailOTPVerifyRequest(BaseModel):
    temp_token: str
    email: str
    otp: str

class UserResponse(BaseModel):
    id: int
    email: str
    full_name: str
    is_active: bool
    email_verified: bool
    two_factor_enabled: bool
    email_otp_enabled: bool
    preferred_2fa_method: Optional[str] = None

# -----------------------------
# Register
# -----------------------------
@router.post("/register", response_model=Token, status_code=status.HTTP_201_CREATED)
def register(user_data: UserRegister, db: Session = Depends(get_database)):
    """
    Register a new user
    """
    try:
        existing_user = db.query(User).filter(User.email == user_data.email).first()
        if existing_user:
            raise HTTPException(status_code=400, detail="Email already registered")
        
        password_hash = AuthManager.get_password_hash(user_data.password)
        new_user = User(
            email=user_data.email,
            password_hash=password_hash,
            full_name=user_data.full_name,
            phone=user_data.phone,
            email_verified=True
        )
        db.add(new_user)
        db.commit()
        db.refresh(new_user)

        access_token = AuthManager.create_access_token(
            data={"sub": str(new_user.id), "email": new_user.email},
            expires_delta=timedelta(minutes=30)
        )

        logger.info(f"✅ User registered successfully: {new_user.email}")
        return {"access_token": access_token, "token_type": "bearer", "user": new_user.to_dict()}

    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        logger.error(f"❌ Error registering user: {e}")
        raise HTTPException(status_code=500, detail="Failed to register user")

# -----------------------------
# Login
# -----------------------------
@router.post("/login")
async def login(
    user_credentials: UserLogin,
    db: Session = Depends(get_database)
):
    """
    Login user - supports both TOTP and Email OTP

    Behavior:
    - Rate limit login attempts.
    - Verify email/password and account active state.
    - If either TOTP or Email-OTP is enabled, create a temporary token and:
        - If preferred method is email (and email OTP is enabled) => SEND OTP to email and return 2fa_required (method="email")
        - Otherwise => return 2fa_required (method="totp")
    - If no 2FA => create and return access token immediately.
    """
    try:
        logger.info(f"🔑 Login attempt for email: {user_credentials.email}")

        # Rate limiting
        if not rate_limiter.is_allowed(user_credentials.email):
            logger.warning(f"🔒 Too many login attempts for {user_credentials.email}")
            raise HTTPException(
                status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                detail="Too many login attempts. Please try again later."
            )

        # Lookup user
        user = db.query(User).filter(User.email == user_credentials.email).first()
        if not user:
            logger.warning(f"❌ Login failed — user not found: {user_credentials.email}")
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid email or password"
            )

        # Verify password
        if not AuthManager.verify_password(user_credentials.password, user.password_hash):
            logger.warning(f"❌ Login failed — invalid password for: {user_credentials.email}")
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid email or password"
            )

        # Account active?
        if not user.is_active:
            logger.warning(f"❌ Login failed — account deactivated: {user_credentials.email}")
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Account is deactivated"
            )

        # Successful credential check -> reset rate limiter
        rate_limiter.reset_attempts(user_credentials.email)

        # If any 2FA mechanism is enabled, start 2FA flow
        if user.two_factor_enabled or user.email_otp_enabled:
            # Create a short-lived temp token used only for 2FA verification step
            temp_token = TempTokenManager.create_temp_token(user.id, user.email)

            # Determine method: prefer user's preferred_2fa_method if available
            method = None
            pref = (user.preferred_2fa_method or "").lower() if getattr(user, "preferred_2fa_method", None) else None

            if user.email_otp_enabled and pref == "email":
                method = "email"
            elif user.two_factor_enabled and pref == "totp":
                method = "totp"
            else:
                # fallback priority: email if enabled, otherwise totp
                if user.email_otp_enabled:
                    method = "email"
                else:
                    method = "totp"

            # If email method, send OTP now (await) so frontend can immediately prompt user
            if method == "email":
                logger.info(f"📧 Email OTP 2FA required for user: {user.email} (preferred={pref})")
                try:
                    # send_otp_email is async in your service; await it so we ensure OTP sent
                    await email_otp_service.send_otp_email(user.email, user.full_name or user.email)
                    logger.info(f"📧 Email OTP sent to {user.email}")
                except Exception as e:
                    # If sending email fails, do NOT return 2fa_required (user won't receive code).
                    logger.error(f"❌ Failed to send Email OTP to {user.email}: {e}", exc_info=True)
                    raise HTTPException(
                        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                        detail="Failed to send OTP email. Please try again later."
                    )

                return TwoFactorRequired(
                    temp_token=temp_token,
                    message="Please check your email for the verification code",
                    method="email"
                )

            # Otherwise TOTP flow (no email sending here)
            logger.info(f"🔐 TOTP 2FA required for user: {user.email} (preferred={pref})")
            return TwoFactorRequired(
                temp_token=temp_token,
                message="Please enter your 2FA code from the authenticator app",
                method="totp"
            )

        # No 2FA — create access token and return normal login response
        access_token = AuthManager.create_access_token(
            data={"sub": str(user.id), "email": user.email},
            expires_delta=timedelta(minutes=30)
        )

        logger.info(f"✅ User logged in successfully: {user.email}")
        return Token(
            access_token=access_token,
            token_type="bearer",
            user=user.to_dict()
        )

    except HTTPException:
        # re-raise known HTTPExceptions so FastAPI handles them properly
        raise
    except Exception as e:
        logger.error(f"❌ Error logging in user: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to login"
        )

# -----------------------------
# Verify TOTP 2FA
# -----------------------------
@router.post("/verify-2fa", response_model=Token)
async def verify_2fa(request: TwoFactorVerify, db: Session = Depends(get_database)):
    """
    Verify TOTP 2FA and complete login
    """
    try:
        temp_payload = TempTokenManager.verify_temp_token(request.temp_token)
        if not temp_payload:
            raise HTTPException(401, "Invalid or expired temporary token")

        user_id = int(temp_payload.get("sub"))
        user = db.query(User).filter(User.id == user_id).first()
        if not user:
            raise HTTPException(404, "User not found")

        if not two_factor_rate_limit.is_allowed(str(user_id)):
            raise HTTPException(429, "Too many 2FA attempts. Please try again later.")

        success = False
        is_backup = False

        if user.two_factor_secret and TwoFactorAuth.verify_totp(user.two_factor_secret, request.code):
            success = True
        elif user.backup_codes_hashed:
            backup_codes_hashed = json.loads(user.backup_codes_hashed)
            idx = TwoFactorAuth.verify_backup_code(backup_codes_hashed, request.code)
            if idx is not None:
                success = True
                is_backup = True
                backup_codes_hashed = TwoFactorAuth.remove_backup_code(backup_codes_hashed, idx)
                user.backup_codes_hashed = json.dumps(backup_codes_hashed)
                db.commit()

        two_factor_rate_limit.record_attempt(str(user_id), success)
        if not success:
            raise HTTPException(400, "Invalid 2FA code")

        access_token = AuthManager.create_access_token(
            data={"sub": str(user.id), "email": user.email},
            expires_delta=timedelta(minutes=30)
        )

        logger.info(f"✅ 2FA verified for {user.email} (backup: {is_backup})")
        return Token(access_token=access_token, token_type="bearer", user=user.to_dict())

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Error verifying 2FA: {e}")
        db.rollback()
        raise HTTPException(500, "Failed to verify 2FA")

# -----------------------------
# Verify Email OTP 2FA (Login)
# -----------------------------
@router.post("/verify-email-2fa", response_model=Token)
async def verify_email_2fa(request: EmailOTPVerifyRequest, db: Session = Depends(get_database)):
    """
    Verify email OTP and complete login
    """
    try:
        temp_payload = TempTokenManager.verify_temp_token(request.temp_token)
        if not temp_payload:
            raise HTTPException(401, "Invalid or expired temporary token")

        user_id = int(temp_payload.get("sub"))
        user = db.query(User).filter(User.id == user_id).first()
        if not user:
            raise HTTPException(404, "User not found")

        if not email_otp_service.verify_otp(request.email, request.otp):
            raise HTTPException(400, "Invalid or expired OTP")

        access_token = AuthManager.create_access_token(
            data={"sub": str(user.id), "email": user.email},
            expires_delta=timedelta(minutes=30)
        )

        logger.info(f"✅ Email OTP verified successfully for {user.email}")
        return Token(access_token=access_token, token_type="bearer", user=user.to_dict())

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Error verifying email OTP: {e}")
        db.rollback()
        raise HTTPException(500, "Failed to verify email OTP")

# -----------------------------
# Get current user info
# -----------------------------
@router.get("/me", response_model=UserResponse)
async def get_current_user_info(
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_database)
):
    """
    Get current user information
    """
    try:
        user_id = current_user.get("sub")
        if isinstance(user_id, str):
            user_id = int(user_id)

        user = db.query(User).filter(User.id == user_id).first()
        if not user:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")

        # Ensure user.to_dict() returns the exact keys expected by UserResponse:
        # id, email, full_name, is_active, email_verified, two_factor_enabled,
        # email_otp_enabled, preferred_2fa_method
        user_dict = user.to_dict()

        # Guard: if some keys missing, fill defaults to avoid pydantic validation error
        user_dict.setdefault("two_factor_enabled", False)
        user_dict.setdefault("email_otp_enabled", False)
        user_dict.setdefault("preferred_2fa_method", None)

        return UserResponse(**user_dict)

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Error getting user info: {e}", exc_info=True)
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Failed to get user information")

# -----------------------------
# Change Password
# -----------------------------
@router.post("/change-password")
async def change_password(old_password: str, new_password: str, current_user: dict = Depends(get_current_user), db: Session = Depends(get_database)):
    """
    Change user password
    """
    try:
        if not validate_password(new_password):
            raise HTTPException(400, "New password must be at least 6 characters long")

        user_id = int(current_user.get("sub"))
        user = db.query(User).filter(User.id == user_id).first()
        if not user:
            raise HTTPException(404, "User not found")

        if not AuthManager.verify_password(old_password, user.password_hash):
            raise HTTPException(400, "Current password is incorrect")

        user.password_hash = AuthManager.get_password_hash(new_password)
        db.commit()

        logger.info(f"🔑 Password changed for {user.email}")
        return {"message": "Password changed successfully"}

    except Exception as e:
        db.rollback()
        logger.error(f"❌ Error changing password: {e}")
        raise HTTPException(500, "Failed to change password")

# -----------------------------
# Logout & Health
# -----------------------------
@router.post("/logout")
async def logout():
    """Logout user (client should remove token)"""
    return {"message": "Logged out successfully"}

@router.get("/health")
async def auth_health():
    """Authentication system health check"""
    from auth_simple import auth_health_check
    return auth_health_check()
