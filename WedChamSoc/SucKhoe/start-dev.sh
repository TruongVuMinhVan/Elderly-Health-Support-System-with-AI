#!/bin/bash
# Bash script to start both backend and frontend
# Usage: ./start-dev.sh

echo "🚀 Starting SucKhoe Development Environment..."
echo ""

# Check if we're in the right directory
if [ ! -d "backend" ] || [ ! -d "frontend" ]; then
    echo "❌ Error: Please run this script from the SucKhoe root directory"
    echo "   Expected structure: SucKhoe/backend and SucKhoe/frontend"
    exit 1
fi

# Function to check if port is in use
check_port() {
    local port=$1
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
        return 0  # Port is in use
    else
        return 1  # Port is free
    fi
}

# Check if ports are available
if check_port 8000; then
    echo "⚠️  Warning: Port 8000 is already in use"
    echo "   Backend might already be running"
fi

if check_port 3000; then
    echo "⚠️  Warning: Port 3000 is already in use"
    echo "   Frontend might already be running"
fi

echo ""
echo "📦 Starting Backend (FastAPI) on port 8000..."
echo "📦 Starting Frontend (Next.js) on port 3000..."
echo ""

# Function to cleanup background processes
cleanup() {
    echo ""
    echo "🛑 Stopping servers..."
    kill $BACKEND_PID $FRONTEND_PID 2>/dev/null
    wait $BACKEND_PID $FRONTEND_PID 2>/dev/null
    echo "✅ Servers stopped"
    exit 0
}

# Set up signal handlers
trap cleanup SIGINT SIGTERM

# Start backend in background
cd backend
uvicorn main:app --reload --port 8000 --host 0.0.0.0 &
BACKEND_PID=$!
cd ..

# Start frontend in background
cd frontend
npm run dev &
FRONTEND_PID=$!
cd ..

echo "✅ Both servers are starting..."
echo ""
echo "🌐 Backend API: http://localhost:8000"
echo "🌐 Frontend App: http://localhost:3000"
echo "📚 API Docs: http://localhost:8000/docs"
echo ""
echo "Press Ctrl+C to stop both servers"
echo ""

# Wait for both processes
wait $BACKEND_PID $FRONTEND_PID
