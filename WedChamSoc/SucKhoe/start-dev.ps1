# PowerShell script to start both backend and frontend
# Usage: .\start-dev.ps1

Write-Host "🚀 Starting SucKhoe Development Environment..." -ForegroundColor Green
Write-Host ""

# Check if we're in the right directory
if (-not (Test-Path "backend") -or -not (Test-Path "frontend")) {
    Write-Host "❌ Error: Please run this script from the SucKhoe root directory" -ForegroundColor Red
    Write-Host "   Expected structure: SucKhoe/backend and SucKhoe/frontend" -ForegroundColor Yellow
    exit 1
}

# Function to check if port is in use
function Test-Port {
    param([int]$Port)
    try {
        $connection = New-Object System.Net.Sockets.TcpClient
        $connection.Connect("localhost", $Port)
        $connection.Close()
        return $true
    }
    catch {
        return $false
    }
}

# Check if ports are available
if (Test-Port 8000) {
    Write-Host "⚠️  Warning: Port 8000 is already in use" -ForegroundColor Yellow
    Write-Host "   Backend might already be running" -ForegroundColor Yellow
}

if (Test-Port 3000) {
    Write-Host "⚠️  Warning: Port 3000 is already in use" -ForegroundColor Yellow
    Write-Host "   Frontend might already be running" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "📦 Starting Backend (FastAPI) on port 8000..." -ForegroundColor Cyan
Write-Host "📦 Starting Frontend (Next.js) on port 3000..." -ForegroundColor Cyan
Write-Host ""

# Start backend in background
$backendJob = Start-Job -ScriptBlock {
    Set-Location $using:PWD
    Set-Location "backend"
    Write-Host "[BACKEND] Starting FastAPI server..." -ForegroundColor Blue
    uvicorn main:app --reload --port 8000 --host 0.0.0.0
}

# Start frontend in background  
$frontendJob = Start-Job -ScriptBlock {
    Set-Location $using:PWD
    Set-Location "frontend"
    Write-Host "[FRONTEND] Starting Next.js development server..." -ForegroundColor Magenta
    npm run dev
}

# Function to display logs
function Show-Logs {
    param($Job, $Color)
    $output = Receive-Job -Job $Job
    if ($output) {
        foreach ($line in $output) {
            Write-Host "[$Color] $line" -ForegroundColor $Color
        }
    }
}

Write-Host "✅ Both servers are starting..." -ForegroundColor Green
Write-Host ""
Write-Host "🌐 Backend API: http://localhost:8000" -ForegroundColor Cyan
Write-Host "🌐 Frontend App: http://localhost:3000" -ForegroundColor Cyan
Write-Host "📚 API Docs: http://localhost:8000/docs" -ForegroundColor Cyan
Write-Host ""
Write-Host "Press Ctrl+C to stop both servers" -ForegroundColor Yellow
Write-Host ""

# Monitor jobs and display output
try {
    while ($backendJob.State -eq "Running" -or $frontendJob.State -eq "Running") {
        # Show backend logs
        Show-Logs -Job $backendJob -Color "Blue"
        
        # Show frontend logs  
        Show-Logs -Job $frontendJob -Color "Magenta"
        
        Start-Sleep -Milliseconds 500
    }
}
catch {
    Write-Host ""
    Write-Host "🛑 Stopping servers..." -ForegroundColor Yellow
}
finally {
    # Clean up jobs
    if ($backendJob.State -eq "Running") {
        Stop-Job -Job $backendJob
        Remove-Job -Job $backendJob
    }
    if ($frontendJob.State -eq "Running") {
        Stop-Job -Job $frontendJob  
        Remove-Job -Job $frontendJob
    }
    Write-Host "✅ Servers stopped" -ForegroundColor Green
}
