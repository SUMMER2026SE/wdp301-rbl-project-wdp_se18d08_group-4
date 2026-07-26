$ErrorActionPreference = "Stop"
$root = Split-Path $PSScriptRoot -Parent
$backendDir = Join-Path $root "backend"
$appDir = Join-Path $root "mobile\provider_app"

function Test-PortOpen {
    param([int]$Port)
    $conn = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue
    return $null -ne $conn
}

$backendPort = 3000

$beUp = $false
try {
    $h = Invoke-RestMethod -Uri "http://localhost:3000/api/health" -TimeoutSec 2
    $beUp = $h.success -eq $true
} catch { }

if (-not $beUp) {
    if (Test-PortOpen -Port $backendPort) {
        Write-Host "==> Port $backendPort đang được sử dụng nhưng backend chưa trả health." -ForegroundColor Yellow
        Write-Host "    Kiểm tra process khác đang chạy trên port $backendPort, hoặc đổi PORT trong .env và NEXT_PUBLIC_API_URL cho khớp." -ForegroundColor Yellow
        exit 1
    }
    Write-Host "==> Starting backend (new window)..." -ForegroundColor Cyan
    $beCmd = "Set-Location '$backendDir'; Write-Host 'UniMove API - Ctrl+C here stops backend only' -ForegroundColor Green; npm run dev"
    Start-Process powershell -ArgumentList @("-NoExit", "-Command", $beCmd)
    Start-Sleep -Seconds 4
} else {
    Write-Host "==> Backend already running (localhost:3000) - reuse, skip second instance" -ForegroundColor Green
}

Set-Location $appDir
Write-Host "==> Flutter provider (Ctrl+C stops app only)" -ForegroundColor Cyan
flutter run @args
