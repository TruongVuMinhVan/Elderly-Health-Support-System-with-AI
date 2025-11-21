@echo off
title SucKhoe Development Server
color 0A

echo.
echo  ========================================
echo  🚀 SucKhoe Development Environment
echo  ========================================
echo.

REM Check if directories exist
if not exist "backend" (
    echo ❌ Backend directory not found!
    pause
    exit /b 1
)

if not exist "frontend" (
    echo ❌ Frontend directory not found!
    pause
    exit /b 1
)

echo 📦 Starting Backend (FastAPI)...
start "Backend Server" cmd /k "cd backend && uvicorn main:app --reload --port 8000 --host 0.0.0.0"

timeout /t 2 /nobreak >nul

echo 📦 Starting Frontend (Next.js)...
start "Frontend Server" cmd /k "cd frontend && npm run dev"

echo.
echo ✅ Both servers are starting...
echo.
echo 🌐 Backend API: http://localhost:8000
echo 🌐 Frontend App: http://localhost:3000
echo 📚 API Docs: http://localhost:8000/docs
echo.
echo 💡 Close the terminal windows to stop servers
echo.

pause
