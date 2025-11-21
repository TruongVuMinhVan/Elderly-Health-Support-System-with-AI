"""
Two-Factor Authentication (2FA) utilities
Handles TOTP generation, verification, and backup codes
"""

import pyotp
import secrets
import json
import base64
import io
from typing import List, Optional, Tuple
from passlib.hash import bcrypt
import qrcode
from qrcode.image.pil import PilImage

class TwoFactorAuth:
    """
    Two-Factor Authentication helper class
    """
    
    # App configuration
    APP_NAME = "SucKhoe"
    ISSUER = "SucKhoe"
    
    @staticmethod
    def generate_totp_secret() -> str:
        return pyotp.random_base32()
    
    @staticmethod
    def build_otpauth_uri(secret: str, username: str) -> str:
        totp = pyotp.TOTP(secret)
        return totp.provisioning_uri(
            name=username,
            issuer_name=TwoFactorAuth.ISSUER
        )
    
    @staticmethod
    def verify_totp(secret: str, code: str, valid_window: int = 1) -> bool:
        if not secret or not code:
            return False
        
        try:
            totp = pyotp.TOTP(secret)
            return totp.verify(code, valid_window=valid_window)
        except Exception:
            return False
    
    @staticmethod
    def generate_backup_codes(count: int = 8) -> List[str]:
        return [secrets.token_hex(4) for _ in range(count)]
    
    @staticmethod
    def hash_backup_codes(codes: List[str]) -> List[str]:
        return [bcrypt.hash(code) for code in codes]
    
    @staticmethod
    def verify_backup_code(hashed_codes: List[str], code: str) -> Optional[int]:
        if not hashed_codes or not code:
            return None
        
        for idx, hashed_code in enumerate(hashed_codes):
            if bcrypt.verify(code, hashed_code):
                return idx
        return None
    
    @staticmethod
    def remove_backup_code(hashed_codes: List[str], index: int) -> List[str]:
        if 0 <= index < len(hashed_codes):
            return hashed_codes[:index] + hashed_codes[index + 1:]
        return hashed_codes
    
    @staticmethod
    def generate_qr_code(otpauth_uri: str) -> bytes:
        qr = qrcode.QRCode(
            version=1,
            error_correction=qrcode.constants.ERROR_CORRECT_L,
            box_size=10,
            border=4,
        )
        qr.add_data(otpauth_uri)
        qr.make(fit=True)
        
        img = qr.make_image(fill_color="black", back_color="white")
        
        # Convert to bytes
        img_bytes = io.BytesIO()
        img.save(img_bytes, format='PNG')
        img_bytes.seek(0)
        return img_bytes.getvalue()
    
    @staticmethod
    def get_current_totp_code(secret: str) -> str:
        if not secret:
            return ""
        
        try:
            totp = pyotp.TOTP(secret)
            return totp.now()
        except Exception:
            return ""
    
    @staticmethod
    def validate_totp_code(code: str) -> bool:
        return code.isdigit() and len(code) == 6
    
    @staticmethod
    def validate_backup_code(code: str) -> bool:
        return len(code) == 8 and all(c in '0123456789abcdefABCDEF' for c in code)


class TwoFactorManager:
    @staticmethod
    def setup_2fa_start(user_email: str) -> Tuple[str, str]:
        secret = TwoFactorAuth.generate_totp_secret()
        otpauth_uri = TwoFactorAuth.build_otpauth_uri(secret, user_email)
        return secret, otpauth_uri
    
    @staticmethod
    def enable_2fa(secret: str, verification_code: str) -> Tuple[bool, List[str]]:

        if not TwoFactorAuth.verify_totp(secret, verification_code):
            return False, []
        
        backup_codes = TwoFactorAuth.generate_backup_codes()
        return True, backup_codes
    
    @staticmethod
    def verify_2fa_code(secret: str, code: str, backup_codes_hashed: List[str] = None) -> Tuple[bool, bool]:
        # Try TOTP first
        if TwoFactorAuth.verify_totp(secret, code):
            return True, False
        
        # Try backup codes if provided
        if backup_codes_hashed:
            backup_index = TwoFactorAuth.verify_backup_code(backup_codes_hashed, code)
            if backup_index is not None:
                return True, True
        
        return False, False
    
    @staticmethod
    def disable_2fa() -> bool:
        # This would be called when user wants to disable 2FA
        # The actual clearing would be done in the database
        return True


# Rate limiting for 2FA attempts
class TwoFactorRateLimit:
    def __init__(self):
        self.attempts = {}
        self.max_attempts = 5
        self.lockout_duration = 300  # 5 minutes
    
    def is_allowed(self, user_id: str) -> bool:
        import time
        current_time = time.time()
        
        if user_id not in self.attempts:
            self.attempts[user_id] = []
        
        # Clean old attempts
        self.attempts[user_id] = [
            attempt_time for attempt_time in self.attempts[user_id]
            if current_time - attempt_time < self.lockout_duration
        ]
        
        return len(self.attempts[user_id]) < self.max_attempts
    
    def record_attempt(self, user_id: str, success: bool):
        import time
        current_time = time.time()
        
        if user_id not in self.attempts:
            self.attempts[user_id] = []
        
        if not success:
            self.attempts[user_id].append(current_time)
        else:
            # Reset attempts on success
            self.attempts[user_id] = []
    
    def get_remaining_attempts(self, user_id: str) -> int:
        if user_id not in self.attempts:
            return self.max_attempts
        
        import time
        current_time = time.time()
        
        # Clean old attempts
        self.attempts[user_id] = [
            attempt_time for attempt_time in self.attempts[user_id]
            if current_time - attempt_time < self.lockout_duration
        ]
        
        return max(0, self.max_attempts - len(self.attempts[user_id]))


# Global rate limiter instance
two_factor_rate_limit = TwoFactorRateLimit()
