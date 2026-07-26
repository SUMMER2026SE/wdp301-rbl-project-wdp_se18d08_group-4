# Backend in a separate window - Ctrl+C here only stops Flutter.
$ErrorActionPreference = "Stop"
$root = Split-Path $PSScriptRoot -Parent
$backendDir = Join-Path $root "backend"
$appDir = Join-Path $root "mobile\customer_app"
$apiConfig = Join-Path $appDir "lib\core\config\api_config.dart"

function Get-LanIp {
    $addrs = Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue |
        Where-Object {
            $_.IPAddress -notlike '127.*' -and
            $_.IPAddress -notlike '169.254.*' -and
            $_.PrefixOrigin -ne 'WellKnown'
        } |
        Select-Object -ExpandProperty IPAddress
    if ($addrs) { return $addrs[0] }
    return $null
}

function Test-PortOpen {
    param([int]$Port)
    $conn = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue
    return $null -ne $conn
}

$backendPort = 3000
$lanIp = Get-LanIp
if ($lanIp) {
    Write-Host "==> PC LAN IP: $lanIp (api_config.dart lanHost)" -ForegroundColor Yellow
} else {
    Write-Host "==> Khong tim thay IP LAN. Chay ipconfig va sua lanHost trong api_config.dart" -ForegroundColor Yellow
}

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
    Write-Host "==> Backend already running (localhost:3000)" -ForegroundColor Green
}

$adb = Get-Command adb -ErrorAction SilentlyContinue
if ($adb) {
    $devices = & adb devices 2>$null | Select-String "device$"
    if ($devices) {
        & adb reverse tcp:3000 tcp:3000 2>$null | Out-Null
        Write-Host "==> adb reverse tcp:3000 tcp:3000 OK (USB)" -ForegroundColor Green
        Write-Host "    App se goi http://127.0.0.1:3000/api" -ForegroundColor DarkGray
    } else {
        Write-Host "==> CANH BAO: Khong thay dien thoai USB (adb devices trong)" -ForegroundColor Red
        Write-Host "    Bat USB debugging, cap USB, chap nhan 'Allow USB debugging' tren dien thoai" -ForegroundColor Yellow
        Write-Host "    Hoac chay thu cong: adb reverse tcp:3000 tcp:3000" -ForegroundColor Yellow
    }
} else {
    Write-Host "==> CANH BAO: Khong tim thay adb trong PATH" -ForegroundColor Red
    Write-Host "    Cai Android SDK platform-tools hoac them adb vao PATH" -ForegroundColor Yellow
}

Write-Host "==> API URL trong app: xem lib/core/config/api_config.dart" -ForegroundColor DarkGray
if (Test-Path $apiConfig) {
    Select-String -Path $apiConfig -Pattern "useLanHost|useAdbReverse|lanHost" | ForEach-Object { Write-Host "    $($_.Line.Trim())" -ForegroundColor DarkGray }
}

Set-Location $appDir
Write-Host "==> Flutter customer (Ctrl+C stops app only; backend keeps running)" -ForegroundColor Cyan
Write-Host "    Hot reload: r | Hot restart: R | Quit: q" -ForegroundColor DarkGray

if ($args.Count -gt 0) {
    flutter run @args
} else {
    flutter run
}
