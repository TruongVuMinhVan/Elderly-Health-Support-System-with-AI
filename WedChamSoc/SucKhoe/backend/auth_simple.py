"""
Simple authentication module without Auth0 - using JWT tokens
"""

import jwt
from datetime import datetime, timedelta
from fastapi import HTTPException, Security, Depends, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from passlib.context import CryptContext
from decouple import config
import logging
from typing import Optional, Dict, Any
from sqlalchemy.orm import Session

# Logging setup
logger = logging.getLogger(__name__)

# Configuration
SECRET_KEY = config('SECRET_KEY', default='your-super-secret-key-change-in-production')
ALGORITHM = config('ALGORITHM', default='HS256')
ACCESS_TOKEN_EXPIRE_MINUTES = config('ACCESS_TOKEN_EXPIRE_MINUTES', default=30, cast=int)

# Password hashing
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

# Security scheme
security = HTTPBearer()

class AuthManager:
    """
    Simple authentication manager
    """
    
    @staticmethod
    def verify_password(plain_password: str, hashed_password: str) -> bool:
        """Verify a password against its hash"""
        return pwd_context.verify(plain_password, hashed_password)
    
    @staticmethod
    def get_password_hash(password: str) -> str:
        """Hash a password"""
        return pwd_context.hash(password)
    
    @staticmethod
    def create_access_token(data: dict, expires_delta: Optional[timedelta] = None) -> str:
        """Create JWT access token"""
        to_encode = data.copy()
        if expires_delta:
            expire = datetime.utcnow() + expires_delta
        else:
            expire = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
        
        to_encode.update({"exp": expire})
        encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
        return encoded_jwt
    
    @staticmethod
    def verify_token(token: str) -> Dict[str, Any]:
        """Verify JWT token and return payload"""
        try:
            logger.info(f"🔍 Verifying token with SECRET_KEY: {SECRET_KEY[:10]}...")
            logger.info(f"🔍 Using algorithm: {ALGORITHM}")
            logger.info(f"🔍 Token to verify: {token[:50]}...")

            payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
            logger.info(f"✅ Token decoded successfully: {payload}")

            user_id_str = payload.get("sub")
            if user_id_str is None:
                logger.error("❌ No 'sub' field in token payload")
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail="Invalid authentication credentials",
                    headers={"WWW-Authenticate": "Bearer"},
                )

            # Validate user_id format but keep original format in payload
            try:
                # Just validate it can be converted to int, but don't change payload
                int(user_id_str) if isinstance(user_id_str, str) else user_id_str
            except (ValueError, TypeError):
                logger.error(f"❌ Invalid user ID format: {user_id_str}")
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail="Invalid authentication credentials",
                    headers={"WWW-Authenticate": "Bearer"},
                )

            return payload
        except jwt.ExpiredSignatureError as e:
            logger.error(f"❌ Token expired: {str(e)}")
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Token has expired",
                headers={"WWW-Authenticate": "Bearer"},
            )
        except jwt.InvalidTokenError as e:
            logger.error(f"❌ Invalid token: {str(e)}")
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid authentication credentials",
                headers={"WWW-Authenticate": "Bearer"},
            )

def get_current_user(credentials: HTTPAuthorizationCredentials = Security(security)) -> Dict[str, Any]:
    """
    Dependency to get current authenticated user
    """
    logger.info(f"🔑 Auth check - credentials: {credentials is not None}")

    if not credentials:
        logger.warning("❌ No authorization header provided")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Authorization header is required",
            headers={"WWW-Authenticate": "Bearer"},
        )

    token = credentials.credentials
    logger.info(f"🔑 Token received: {token[:20] if token else 'EMPTY'}...")

    try:
        result = AuthManager.verify_token(token)
        logger.info(f"✅ Token verified for user: {result.get('sub')}")
        return result
    except Exception as e:
        logger.error(f"❌ Token verification failed: {str(e)}")
        logger.error(f"❌ Token verification error type: {type(e).__name__}")
        import traceback
        logger.error(f"❌ Full traceback: {traceback.format_exc()}")
        raise

def get_current_user_optional(credentials: Optional[HTTPAuthorizationCredentials] = Security(security)) -> Optional[Dict[str, Any]]:
    """
    Optional dependency to get current authenticated user
    """
    if not credentials:
        return None
    
    try:
        token = credentials.credentials
        return AuthManager.verify_token(token)
    except HTTPException:
        return None

def get_user_id(current_user: Dict[str, Any] = Depends(get_current_user)) -> int:
    """
    Extract user ID from token
    """
    return current_user.get("sub")

def get_user_email(current_user: Dict[str, Any] = Depends(get_current_user)) -> str:
    """
    Extract user email from token
    """
    return current_user.get("email", "")

# Validation functions
def validate_email(email: str) -> bool:
    """Validate email format"""
    import re
    pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
    return bool(re.match(pattern, email))

def validate_password(password: str) -> bool:
    """Validate password strength"""
    # At least 6 characters
    if len(password) < 6:
        return False
    return True

def validate_phone_number(phone: str) -> bool:
    """Validate Vietnamese phone number"""
    import re
    pattern = r'^(\+84|84|0)(3[2-9]|5[6|8|9]|7[0|6-9]|8[1-6|8|9]|9[0-4|6-9])[0-9]{7}$'
    return bool(re.match(pattern, phone.replace(' ', '')))

# Rate limiting (simple implementation)
class RateLimiter:
    """Simple rate limiter for login attempts"""
    
    def __init__(self):
        self.attempts = {}
    
    def is_allowed(self, identifier: str, max_attempts: int = 5, window_minutes: int = 15) -> bool:
        """Check if login attempt is allowed"""
        import time
        current_time = time.time()
        window_seconds = window_minutes * 60
        
        if identifier not in self.attempts:
            self.attempts[identifier] = []
        
        # Clean old attempts
        self.attempts[identifier] = [
            attempt_time for attempt_time in self.attempts[identifier]
            if current_time - attempt_time < window_seconds
        ]
        
        # Check if under limit
        if len(self.attempts[identifier]) >= max_attempts:
            return False
        
        # Add current attempt
        self.attempts[identifier].append(current_time)
        return True
    
    def reset_attempts(self, identifier: str):
        """Reset attempts for identifier"""
        if identifier in self.attempts:
            del self.attempts[identifier]

# Global rate limiter instance
rate_limiter = RateLimiter()

# Health check function
def auth_health_check() -> Dict[str, Any]:
    """
    Check authentication system health
    """
    try:
        # Test token creation and verification
        test_data = {"sub": "1", "email": "test@example.com"}
        token = AuthManager.create_access_token(test_data)
        decoded = AuthManager.verify_token(token)
        
        return {
            "status": "healthy",
            "auth_type": "simple_jwt",
            "timestamp": datetime.utcnow().isoformat()
        }
    except Exception as e:
        return {
            "status": "unhealthy",
            "error": str(e),
            "timestamp": datetime.utcnow().isoformat()
        }
