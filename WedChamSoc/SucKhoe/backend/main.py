"""
Main FastAPI application for Elderly Health Support System
"""

from fastapi import FastAPI, HTTPException, Depends, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.trustedhost import TrustedHostMiddleware
from fastapi.responses import JSONResponse
from fastapi.openapi.docs import get_swagger_ui_html
from fastapi.openapi.utils import get_openapi
from contextlib import asynccontextmanager
import logging
import time
from decouple import config

# Import database and auth
# Note: When running with uvicorn backend.main:app, backend/ is in sys.path
# So we can import directly from database (which is backend/database.py)
import sys
from pathlib import Path

# Ensure backend directory is in path for imports
backend_dir = Path(__file__).parent
if str(backend_dir) not in sys.path:
    sys.path.insert(0, str(backend_dir))

from database import init_database, check_database_connection, health_check
from auth_simple import auth_health_check

# Import all models to ensure they are registered with SQLAlchemy before init_database()
# This ensures all tables are created when init_database() is called
from models import User, HealthProfile, HealthRecord, Medication, ChatSession, ChatMessage, SkinDisease, SkinDiseasePrediction, Doctor

# Import routers
from routers import auth, users, health, medications, schedules, chat, two_factor, email_2fa, email_verify_2fa, skin_disease, doctors

# Logging configuration
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Application configuration
APP_NAME = "Elderly Health Support System API"
APP_VERSION = "1.0.0"
APP_DESCRIPTION = """
Hệ thống API hỗ trợ theo dõi & chăm sóc sức khỏe người cao tuổi

## Tính năng chính

* **Quản lý người dùng**: Đăng ký, đăng nhập, quản lý hồ sơ
* **Theo dõi sức khỏe**: Ghi nhận và theo dõi các chỉ số sức khỏe
* **Quản lý thuốc**: Thông tin thuốc và lịch uống thuốc
* **Lịch hẹn**: Đặt lịch khám bệnh và nhắc nhở
* **AI Chatbot**: Tư vấn sức khỏe thông minh

## Bảo mật

API sử dụng Auth0 JWT tokens để xác thực người dùng.
"""

# Environment configuration
DEBUG = config('DEBUG', default=False, cast=bool)
ALLOWED_ORIGINS = config('ALLOWED_ORIGINS', default='http://localhost:3000').split(',')

@asynccontextmanager
async def lifespan(app: FastAPI):
    """
    Application lifespan events
    """
    # Startup
    logger.info("Starting Elderly Health Support System API...")
    
    # Initialize database (non-blocking)
    try:
        if check_database_connection():
            init_database()
            logger.info("✅ Database initialized successfully")
        else:
            logger.warning("⚠️ Database connection failed - API will continue but some features may not work")
    except Exception as e:
        logger.warning(f"⚠️ Database initialization error: {e} - API will continue")
    
    # Check Auth0 connection (non-blocking)
    try:
        auth_status = auth_health_check()
        if auth_status["status"] == "healthy":
            logger.info("✅ Auth0 connection healthy")
        else:
            logger.warning(f"⚠️ Auth0 connection issue: {auth_status}")
    except Exception as e:
        logger.warning(f"⚠️ Auth0 check error: {e} - API will continue")
    
    logger.info("🚀 Application startup complete")
    
    try:
        yield
    except Exception as e:
        logger.error(f"Error during application lifetime: {e}")
    finally:
        # Shutdown
        logger.info("🛑 Shutting down Elderly Health Support System API...")

# Create FastAPI application
app = FastAPI(
    title=APP_NAME,
    version=APP_VERSION,
    description=APP_DESCRIPTION,
    lifespan=lifespan,
    docs_url="/docs" if DEBUG else None,
    redoc_url="/redoc" if DEBUG else None,
    openapi_url="/openapi.json" if DEBUG else None
)

# Add middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000", "http://localhost:3001", "http://127.0.0.1:3000", "http://127.0.0.1:3001"] if not DEBUG else ["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.add_middleware(
    TrustedHostMiddleware,
    allowed_hosts=["*"] if DEBUG else ["localhost", "127.0.0.1"]
)

# Request logging middleware
@app.middleware("http")
async def log_requests(request: Request, call_next):
    """
    Log all HTTP requests
    """
    start_time = time.time()
    
    # Log request
    logger.info(f"📥 {request.method} {request.url}")
    
    # Process request
    response = await call_next(request)
    
    # Log response
    process_time = time.time() - start_time
    logger.info(f"📤 {request.method} {request.url} - {response.status_code} - {process_time:.3f}s")
    
    return response

# Include routers
app.include_router(users.router)
app.include_router(health.router)
app.include_router(medications.router)
app.include_router(schedules.router)
app.include_router(chat.router)
app.include_router(skin_disease.router)
app.include_router(doctors.router)
app.include_router(auth.router, prefix="/api/auth")
app.include_router(two_factor.router, prefix="/api")
app.include_router(email_2fa.router, prefix="/api")
app.include_router(email_verify_2fa.router, prefix="/api")

# Root endpoint
@app.get("/", tags=["root"])
async def root():
    """
    Root endpoint with API information
    """
    return {
        "message": "Elderly Health Support System API",
        "version": APP_VERSION,
        "status": "healthy",
        "docs": "/docs" if DEBUG else "Documentation disabled in production",
        "endpoints": {
            "users": "/api/users",
            "health": "/api/health",
            "medications": "/api/medications",
            "schedules": "/api/schedules",
            "chat": "/api/chat",
            "skin_disease": "/api/skin-disease"
        }
    }

# Health check endpoint
@app.get("/health", tags=["health"])
async def health_check_endpoint():
    """
    Health check endpoint for monitoring
    """
    try:
        # Check database
        db_health = health_check()
        
        # Check Auth0
        auth_health = auth_health_check()
        
        # Overall status
        overall_status = "healthy" if (
            db_health["status"] == "healthy" and 
            auth_health["status"] == "healthy"
        ) else "unhealthy"
        
        return {
            "status": overall_status,
            "timestamp": time.time(),
            "version": APP_VERSION,
            "services": {
                "database": db_health,
                "auth": auth_health
            }
        }
    except Exception as e:
        logger.error(f"Health check error: {e}")
        return JSONResponse(
            status_code=503,
            content={
                "status": "unhealthy",
                "error": str(e),
                "timestamp": time.time()
            }
        )

# API Info endpoint
@app.get("/api/info", tags=["info"])
async def api_info():
    """
    API information and statistics
    """
    return {
        "name": APP_NAME,
        "version": APP_VERSION,
        "description": "API for elderly health support system",
        "features": [
            "User management with Auth0",
            "Health records tracking",
            "Medication management",
            "Schedule and reminders",
            "AI health chatbot"
        ],
        "supported_health_metrics": [
            "blood_pressure",
            "heart_rate", 
            "blood_sugar",
            "weight",
            "temperature"
        ],
        "supported_schedule_types": [
            "medication",
            "appointment",
            "checkup"
        ]
    }

# Custom exception handlers
@app.exception_handler(HTTPException)
async def http_exception_handler(request: Request, exc: HTTPException):
    """
    Custom HTTP exception handler
    """
    # Log 404 as INFO (expected cases like health profile not found)
    # Log other client errors (4xx) as WARNING
    # Log server errors (5xx) as ERROR
    if exc.status_code == 404:
        logger.info(f"HTTP {exc.status_code}: {exc.detail} - {request.method} {request.url}")
    elif 400 <= exc.status_code < 500:
        logger.warning(f"HTTP {exc.status_code}: {exc.detail} - {request.method} {request.url}")
    else:
        logger.error(f"HTTP {exc.status_code}: {exc.detail} - {request.method} {request.url}")
    
    return JSONResponse(
        status_code=exc.status_code,
        content={
            "error": True,
            "status_code": exc.status_code,
            "message": exc.detail,
            "timestamp": time.time()
        }
    )

@app.exception_handler(Exception)
async def general_exception_handler(request: Request, exc: Exception):
    """
    General exception handler
    """
    logger.error(f"Unhandled exception: {exc} - {request.method} {request.url}")
    
    return JSONResponse(
        status_code=500,
        content={
            "error": True,
            "status_code": 500,
            "message": "Internal server error" if not DEBUG else str(exc),
            "timestamp": time.time()
        }
    )

# Custom OpenAPI schema
def custom_openapi():
    """
    Custom OpenAPI schema with additional information
    """
    if app.openapi_schema:
        return app.openapi_schema
    
    openapi_schema = get_openapi(
        title=APP_NAME,
        version=APP_VERSION,
        description=APP_DESCRIPTION,
        routes=app.routes,
    )
    
    # Add security scheme
    openapi_schema["components"]["securitySchemes"] = {
        "Auth0Bearer": {
            "type": "http",
            "scheme": "bearer",
            "bearerFormat": "JWT",
            "description": "Auth0 JWT token"
        }
    }
    
    # Add global security
    openapi_schema["security"] = [{"Auth0Bearer": []}]
    
    app.openapi_schema = openapi_schema
    return app.openapi_schema

app.openapi = custom_openapi

# Development server
if __name__ == "__main__":
    import uvicorn
    
    logger.info("🔧 Starting development server...")
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8001,
        reload=DEBUG,
        log_level="info"
    )
