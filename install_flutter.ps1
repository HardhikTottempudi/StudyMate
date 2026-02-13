# Flutter Installation Script for Windows
# Run this script after freeing up disk space (need at least 3GB free)

Write-Host "Flutter Installation Script" -ForegroundColor Cyan
Write-Host "=========================" -ForegroundColor Cyan
Write-Host ""

# Check available disk space
$drive = (Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Root -eq (Split-Path $env:LOCALAPPDATA -Qualifier) }).Root
$freeSpace = (Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Root -eq $drive }).Free
$freeSpaceGB = [math]::Round($freeSpace / 1GB, 2)

Write-Host "Available disk space: $freeSpaceGB GB" -ForegroundColor Yellow

if ($freeSpaceGB -lt 3) {
    Write-Host "WARNING: You need at least 3GB of free space. Current: $freeSpaceGB GB" -ForegroundColor Red
    Write-Host "Please free up some space and run this script again." -ForegroundColor Red
    exit 1
}

# Flutter installation path
$flutterPath = "$env:LOCALAPPDATA\flutter"
$flutterBinPath = "$flutterPath\flutter\bin"

Write-Host "Installing Flutter to: $flutterPath" -ForegroundColor Green
Write-Host ""

# Download Flutter SDK
$flutterUrl = "https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.24.5-stable.zip"
$downloadPath = "$env:USERPROFILE\Downloads\flutter.zip"

Write-Host "Downloading Flutter SDK (this may take a few minutes)..." -ForegroundColor Yellow
$ProgressPreference = 'SilentlyContinue'
try {
    Invoke-WebRequest -Uri $flutterUrl -OutFile $downloadPath -UseBasicParsing
    Write-Host "Download complete!" -ForegroundColor Green
} catch {
    Write-Host "Error downloading Flutter: $_" -ForegroundColor Red
    exit 1
}

# Extract Flutter SDK
Write-Host "Extracting Flutter SDK..." -ForegroundColor Yellow
try {
    if (Test-Path $flutterPath) {
        Remove-Item $flutterPath -Recurse -Force
    }
    Expand-Archive -Path $downloadPath -DestinationPath $flutterPath -Force
    Write-Host "Extraction complete!" -ForegroundColor Green
} catch {
    Write-Host "Error extracting Flutter: $_" -ForegroundColor Red
    Write-Host "This might be due to insufficient disk space." -ForegroundColor Yellow
    exit 1
}

# Add Flutter to PATH for current session
$env:Path += ";$flutterBinPath"

# Verify installation
Write-Host ""
Write-Host "Verifying installation..." -ForegroundColor Yellow
& "$flutterBinPath\flutter.bat" --version

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "Flutter installed successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "To make Flutter available permanently, add this to your PATH:" -ForegroundColor Cyan
    Write-Host $flutterBinPath -ForegroundColor White
    Write-Host ""
    Write-Host "Or run this command to add it to your user PATH:" -ForegroundColor Cyan
    Write-Host "[Environment]::SetEnvironmentVariable('Path', [Environment]::GetEnvironmentVariable('Path', 'User') + ';$flutterBinPath', 'User')" -ForegroundColor White
    Write-Host ""
    Write-Host "After adding to PATH, restart your terminal and run: flutter doctor" -ForegroundColor Yellow
} else {
    Write-Host "Flutter installation verification failed." -ForegroundColor Red
    exit 1
}

# Clean up download
if (Test-Path $downloadPath) {
    Write-Host "Cleaning up download file..." -ForegroundColor Yellow
    Remove-Item $downloadPath -Force
}
