$adb = "adb"
if (!(Get-Command $adb -ErrorAction SilentlyContinue)) {
    $adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
}

if (!(Test-Path $adb) -and !(Get-Command $adb -ErrorAction SilentlyContinue)) {
    Write-Host "ADB not found. Please ensure Android SDK is installed and adb is in your PATH." -ForegroundColor Red
    exit
}

Write-Host "Detecting devices..." -ForegroundColor Cyan
$devices = & $adb devices | Select-String -Pattern "\tdevice$"
if ($devices.Count -eq 0) {
    Write-Host "No devices found. Please connect your phone or start an emulator." -ForegroundColor Red
    exit
}

$deviceId = $devices[0].ToString().Split("`t")[0]
Write-Host "Using device: $deviceId" -ForegroundColor Green

$apkPath = "build/app/outputs/flutter-apk/app-release.apk"

if (!(Test-Path $apkPath)) {
    Write-Host "APK not found at $apkPath." -ForegroundColor Red
    Write-Host "Please run 'flutter build apk --release' first." -ForegroundColor Yellow
    exit
}

Write-Host "Pushing and installing $(Split-Path $apkPath -Leaf)..." -ForegroundColor Cyan
& $adb -s $deviceId install -r $apkPath

if ($LASTEXITCODE -eq 0) {
    Write-Host "`nSuccessfully installed Resistance APK!" -ForegroundColor Green
} else {
    Write-Host "`nFailed to install APK. Check the error message above." -ForegroundColor Red
}
