"""
Database configuration and connection setup for Elderly Health Support System
"""

import os
import time
from sqlalchemy import create_engine, MetaData, text
from sqlalchemy.exc import OperationalError, SQLAlchemyError
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from decouple import config
import logging
from datetime import datetime

# Logging setup
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Database URL from environment variables
DATABASE_URL = str(config(
    'DATABASE_URL',
    default='mysql+pymysql://root:123456@localhost:3306/elderly_health_db'
))

# Create SQLAlchemy engine
try:
    debug_mode = bool(config('DEBUG', default=False, cast=bool))
    
    # Check if using SQLite
    is_sqlite = DATABASE_URL.startswith('sqlite')
    
    # Configure engine with appropriate settings
    if is_sqlite:
        from sqlalchemy.pool import NullPool
        engine = create_engine(
            DATABASE_URL,
            connect_args={"check_same_thread": False},
            poolclass=NullPool,
            echo=debug_mode
        )
    else:
        engine = create_engine(
            DATABASE_URL,
            pool_size=int(config('DB_POOL_SIZE', default=5)),
            max_overflow=int(config('DB_MAX_OVERFLOW', default=10)),
            pool_pre_ping=True,
            pool_recycle=300,
            pool_timeout=30,
            echo=debug_mode
        )
    logger.info(f"Database engine created successfully using {DATABASE_URL.split('://')[0]}")
except Exception as e:
    logger.error(f"Failed to create database engine: {e}")
    raise

# Create SessionLocal class
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# Create Base class for models
Base = declarative_base()

# Metadata for database operations
metadata = MetaData()

def get_database():
    """
    Dependency function to get database session
    """
    db = SessionLocal()
    try:
        yield db
    except Exception as e:
        # Don't log HTTPException (404, etc.) as errors - they're expected business logic
        from fastapi import HTTPException
        if isinstance(e, HTTPException):
            # HTTPExceptions are handled by the exception handler, just rollback and re-raise
            db.rollback()
            raise
        # Log actual database errors
        logger.error(f"Database session error: {e}")
        db.rollback()
        raise
    finally:
        # Only close the session, don't rollback unless there was an error
        db.close()

def init_database():
    """
    Initialize database tables
    """
    try:
        # Try to connect with retry logic first
        if not connect_with_retry():
            logger.error("Could not establish database connection for initialization")
            return False
            
        Base.metadata.create_all(bind=engine)
        logger.info("Database tables created successfully")
        return True
    except Exception as e:
        logger.error(f"Failed to create database tables: {e}")
        raise

def check_database_connection():
    """
    Check if database connection is working
    """
    try:
        with engine.connect() as connection:
            connection.execute(text("SELECT 1"))
            logger.info("Database connection successful")
            return True
    except Exception as e:
        logger.error(f"Database connection failed: {e}")
        return False

def connect_with_retry(max_retries=3, retry_delay=2):
    """
    Attempt to connect to database with retry logic
    """
    retries = 0
    last_exception = None
    
    while retries < max_retries:
        try:
            with engine.connect() as connection:
                connection.execute(text("SELECT 1"))
                logger.info(f"Database connection successful after {retries} retries")
                return True
        except (OperationalError, SQLAlchemyError) as e:
            last_exception = e
            retries += 1
            logger.warning(f"Database connection attempt {retries} failed: {e}")
            time.sleep(retry_delay)
    
    logger.error(f"Failed to connect to database after {max_retries} attempts: {last_exception}")
    return False

# Database utility functions
class DatabaseManager:
    """
    Database manager class for common operations
    """
    @staticmethod
    def get_session():
        """Get a new database session"""
        return SessionLocal()
    
    @staticmethod
    def execute_query(query: str, params: dict[str, object] | None = None) -> list:
        """Execute a raw SQL query"""
        try:
            with engine.connect() as connection:
                if params:
                    result = connection.execute(text(query), params)
                else:
                    result = connection.execute(text(query))
                return result.fetchall()
        except Exception as e:
            logger.error(f"Query execution failed: {e}")
            raise

    @staticmethod
    def execute_procedure(procedure_name: str, params: list[object] | None = None) -> list:
        """Execute a stored procedure"""
        try:
            with engine.connect() as connection:
                if params:
                    placeholders = ','.join(['%s'] * len(params))
                    sql = text(f"CALL {procedure_name}({placeholders})")
                    result = connection.execute(sql, params)
                else:
                    sql = text(f"CALL {procedure_name}()")
                    result = connection.execute(sql)
                return result.fetchall()
        except Exception as e:
            logger.error(f"Procedure execution failed: {e}")
            raise

# Health check function
def health_check():
    """
    Perform database health check
    """
    try:
        db = SessionLocal()
        db.execute(text("SELECT 1"))
        db.close()
        return {"status": "healthy", "database": "connected"}
    except Exception as e:
        logger.error(f"Health check failed: {e}")
        return {"status": "unhealthy", "database": "disconnected", "error": str(e)}

# Connection pool monitoring
def get_pool_status():
    """
    Get connection pool status
    """
    try:
        pool = engine.pool
        pool_status = {}
        for attr in ["size", "checkedin", "checkedout", "overflow", "invalid"]:
            pool_status[attr] = getattr(pool, attr, None)
        return pool_status
    except Exception as e:
        logger.error(f"Failed to get pool status: {e}")
        return {"error": str(e)}

# Database backup utilities
def backup_database(backup_path: str = None):
    """
    Create database backup (MySQL dump)
    """
    if not backup_path:
        backup_path = f"backup_{datetime.now().strftime('%Y%m%d_%H%M%S')}.sql"
    
    try:
        import subprocess
        
        # Extract database info from URL
        db_info = DATABASE_URL.split('/')
        db_name = db_info[-1]
        host_info = db_info[2].split('@')[-1].split(':')
        host = host_info[0]
        port = host_info[1] if len(host_info) > 1 else '3306'
        
        user_info = DATABASE_URL.split('//')[1].split('@')[0].split(':')
        username = user_info[0]
        password = user_info[1]
        
        # Create mysqldump command
        cmd = [
            'mysqldump',
            f'--host={host}',
            f'--port={port}',
            f'--user={username}',
            f'--password={password}',
            '--single-transaction',
            '--routines',
            '--triggers',
            db_name
        ]
        
        with open(backup_path, 'w') as backup_file:
            subprocess.run(cmd, stdout=backup_file, check=True)
        
        logger.info(f"Database backup created: {backup_path}")
        return backup_path
    except Exception as e:
        logger.error(f"Database backup failed: {e}")
        raise

# Initialize database on import
if __name__ == "__main__":
    # Test database connection
    if check_database_connection():
        print("✅ Database connection successful")
        init_database()
        print("✅ Database initialized")
    else:
        print("❌ Database connection failed")



