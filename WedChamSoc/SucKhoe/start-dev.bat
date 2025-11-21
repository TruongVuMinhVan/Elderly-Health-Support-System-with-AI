@echo off
REM Windows batch script to start both backend and frontend
REM Usage: start-dev.bat

echo 🚀 Starting SucKhoe Development Environment...
echo.

REM Check if we're in the right directory
if not exist "backend" (
    echo ❌ Error: backend directory not found
    echo    Please run this script from the SucKhoe root directory
    pause
    exit /b 1
)

if not exist "frontend" (
    echo ❌ Error: frontend directory not found
    echo    Please run this script from the SucKhoe root directory
    pause
    exit /b 1
)

echo 📦 Starting Backend (FastAPI) on port 8000...
echo 📦 Starting Frontend (Next.js) on port 3000...
echo.

echo ✅ Both servers are starting...
echo.
echo 🌐 Backend API: http://localhost:8000
echo 🌐 Frontend App: http://localhost:3000
echo 📚 API Docs: http://localhost:8000/docs
echo.
echo Press Ctrl+C to stop both servers
echo.

REM Start backend in new window
start "SucKhoe Backend" cmd /k "cd backend && uvicorn main:app --reload --port 8000 --host 0.0.0.0"

REM Start frontend in new window
start "SucKhoe Frontend" cmd /k "cd frontend && npm run dev"

echo ✅ Both servers started in separate windows
echo    Close the terminal windows to stop the servers
pause
