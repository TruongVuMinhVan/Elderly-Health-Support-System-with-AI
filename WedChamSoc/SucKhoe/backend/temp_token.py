"""
Temporary token system for 2FA flow
"""

import jwt
from datetime import datetime, timedelta
from typing import Optional, Dict, Any
import logging

logger = logging.getLogger(__name__)

# JWT configuration
from decouple import config
SECRET_KEY = config('SECRET_KEY', default='your-super-secret-key-change-in-production')
ALGORITHM = config('ALGORITHM', default='HS256')
TEMP_TOKEN_EXPIRE_MINUTES = 5  # 5 minutes for temp tokens

class TempTokenManager:
    """
    Manages temporary tokens for 2FA flow
    """
    
    @staticmethod
    def create_temp_token(user_id: int, email: str) -> str:
        """
        Create a temporary token for 2FA verification
        """
        try:
            expire = datetime.utcnow() + timedelta(minutes=TEMP_TOKEN_EXPIRE_MINUTES)
            payload = {
                "sub": str(user_id),
                "email": email,
                "type": "temp_2fa",
                "exp": expire,
                "iat": datetime.utcnow()
            }
            
            token = jwt.encode(payload, SECRET_KEY, algorithm=ALGORITHM)
            logger.info(f"Temp token created for user: {email}")
            return token
            
        except Exception as e:
            logger.error(f"Error creating temp token: {e}")
            raise
    
    @staticmethod
    def verify_temp_token(token: str) -> Optional[Dict[str, Any]]:
        """
        Verify and decode temporary token
        """
        try:
            payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
            
            # Check if it's a temp token
            if payload.get("type") != "temp_2fa":
                logger.warning("Invalid token type")
                return None
            
            logger.info(f"Temp token verified for user: {payload.get('email')}")
            return payload
            
        except jwt.ExpiredSignatureError:
            logger.warning("Temp token expired")
            return None
        except jwt.InvalidTokenError as e:
            logger.warning(f"Invalid temp token: {e}")
            return None
        except Exception as e:
            logger.error(f"Error verifying temp token: {e}")
            return None
    
    @staticmethod
    def is_temp_token_valid(token: str) -> bool:
        """
        Check if temp token is valid without decoding
        """
        try:
            payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
            return payload.get("type") == "temp_2fa"
        except:
            return False


