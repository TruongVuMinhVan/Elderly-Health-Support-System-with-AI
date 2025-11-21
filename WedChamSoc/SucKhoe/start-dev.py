#!/usr/bin/env python3
"""
Cross-platform script to start both backend and frontend
Usage: python start-dev.py
"""

import os
import sys
import subprocess
import signal
import time
import threading
from pathlib import Path

def print_colored(text, color="white"):
    """Print colored text (works on most terminals)"""
    colors = {
        "red": "\033[91m",
        "green": "\033[92m", 
        "yellow": "\033[93m",
        "blue": "\033[94m",
        "magenta": "\033[95m",
        "cyan": "\033[96m",
        "white": "\033[97m",
        "reset": "\033[0m"
    }
    print(f"{colors.get(color, '')}{text}{colors['reset']}")

def check_port(port):
    """Check if port is in use"""
    import socket
    try:
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
            s.bind(('localhost', port))
            return False  # Port is free
    except OSError:
        return True  # Port is in use

def run_backend():
    """Run backend server"""
    os.chdir("backend")
    print_colored("[BACKEND] Starting FastAPI server...", "blue")
    try:
        subprocess.run([
            sys.executable, "-m", "uvicorn", 
            "main:app", "--reload", "--port", "8000", "--host", "0.0.0.0"
        ], check=True)
    except KeyboardInterrupt:
        pass
    except subprocess.CalledProcessError as e:
        print_colored(f"[BACKEND] Error: {e}", "red")

def run_frontend():
    """Run frontend server"""
    os.chdir("frontend")
    print_colored("[FRONTEND] Starting Next.js development server...", "magenta")
    try:
        subprocess.run(["npm", "run", "dev"], check=True)
    except KeyboardInterrupt:
        pass
    except subprocess.CalledProcessError as e:
        print_colored(f"[FRONTEND] Error: {e}", "red")

def main():
    """Main function"""
    print_colored("🚀 Starting SucKhoe Development Environment...", "green")
    print()
    
    # Check if we're in the right directory
    if not Path("backend").exists() or not Path("frontend").exists():
        print_colored("❌ Error: Please run this script from the SucKhoe root directory", "red")
        print_colored("   Expected structure: SucKhoe/backend and SucKhoe/frontend", "yellow")
        sys.exit(1)
    
    # Check if ports are available
    if check_port(8000):
        print_colored("⚠️  Warning: Port 8000 is already in use", "yellow")
        print_colored("   Backend might already be running", "yellow")
    
    if check_port(3000):
        print_colored("⚠️  Warning: Port 3000 is already in use", "yellow")
        print_colored("   Frontend might already be running", "yellow")
    
    print()
    print_colored("📦 Starting Backend (FastAPI) on port 8000...", "cyan")
    print_colored("📦 Starting Frontend (Next.js) on port 3000...", "cyan")
    print()
    
    # Store original directory
    original_dir = os.getcwd()
    
    # Global variables for cleanup
    backend_process = None
    frontend_process = None
    
    def cleanup():
        """Cleanup function"""
        print()
        print_colored("🛑 Stopping servers...", "yellow")
        if backend_process:
            backend_process.terminate()
        if frontend_process:
            frontend_process.terminate()
        print_colored("✅ Servers stopped", "green")
        sys.exit(0)
    
    # Set up signal handlers
    signal.signal(signal.SIGINT, lambda s, f: cleanup())
    signal.signal(signal.SIGTERM, lambda s, f: cleanup())
    
    try:
        # Start backend in a separate thread
        backend_thread = threading.Thread(target=run_backend)
        backend_thread.daemon = True
        backend_thread.start()
        
        # Start frontend in a separate thread
        frontend_thread = threading.Thread(target=run_frontend)
        frontend_thread.daemon = True
        frontend_thread.start()
        
        print_colored("✅ Both servers are starting...", "green")
        print()
        print_colored("🌐 Backend API: http://localhost:8000", "cyan")
        print_colored("🌐 Frontend App: http://localhost:3000", "cyan")
        print_colored("📚 API Docs: http://localhost:8000/docs", "cyan")
        print()
        print_colored("Press Ctrl+C to stop both servers", "yellow")
        print()
        
        # Keep the main thread alive
        while True:
            time.sleep(1)
            
    except KeyboardInterrupt:
        cleanup()
    except Exception as e:
        print_colored(f"❌ Error: {e}", "red")
        cleanup()

if __name__ == "__main__":
    main()
