# Manual Update Helper Script for Fluent Bit Chocolatey Package
# This script can be used to manually check for updates and test the update process

param(
    [switch]$CheckOnly,
    [switch]$Force,
    [string]$Version
)

# Function to get latest version from Fluent Bit packages site
function Get-LatestFluentBitVersion {
    try {
        Write-Host "Checking latest version from https://packages.fluentbit.io/windows/" -ForegroundColor Cyan
        $response = Invoke-WebRequest -Uri "https://packages.fluentbit.io/windows/" -UseBasicParsing
        $content = $response.Content
        
        # Look for fluent-bit-X.Y.Z-win64.exe pattern
        $versionPattern = 'fluent-bit-(\d+\.\d+\.\d+)-win64\.exe'
        $versionMatches = [regex]::Matches($content, $versionPattern)
        
        if ($versionMatches.Count -eq 0) {
            Write-Error "No version found in packages site"
            return $null
        }
        
        # Get all versions and find the latest
        $versions = $versionMatches | ForEach-Object { $_.Groups[1].Value } | Sort-Object { [version]$_ } -Descending
        Write-Host "Available versions found: $($versions -join ', ')" -ForegroundColor Gray
        return $versions[0]
    }
    catch {
        Write-Error "Failed to fetch latest version: $_"
        return $null
    }
}

# Function to get current package version from nuspec
function Get-CurrentPackageVersion {
    try {
        $nuspecPath = "fluent-bit.nuspec"
        if (-not (Test-Path $nuspecPath)) {
            Write-Error "fluent-bit.nuspec not found. Make sure you're running this from the package root directory."
            return $null
        }
        
        $nuspecContent = Get-Content -Path $nuspecPath -Raw
        $versionMatch = [regex]::Match($nuspecContent, '<version>(\d+\.\d+\.\d+)</version>')
        
        if ($versionMatch.Success) {
            return $versionMatch.Groups[1].Value
        }
        else {
            Write-Error "Could not find version in nuspec file"
            return $null
        }
    }
    catch {
        Write-Error "Failed to read current package version: $_"
        return $null
    }
}

# Function to download and calculate checksums
function Get-Checksums {
    param([string]$Version)
    
    $url32 = "https://packages.fluentbit.io/windows/fluent-bit-$Version-win32.exe"
    $url64 = "https://packages.fluentbit.io/windows/fluent-bit-$Version-win64.exe"
    
    Write-Host "Downloading and calculating checksums for version $Version..." -ForegroundColor Cyan
    
    $checksums = @{}
    
    # Download and checksum 32-bit version
    try {
        Write-Host "  Downloading 32-bit version..." -ForegroundColor Gray
        Invoke-WebRequest -Uri $url32 -OutFile "temp-win32.exe" -UseBasicParsing
        $checksums.checksum32 = (Get-FileHash -Path "temp-win32.exe" -Algorithm SHA256).Hash
        Remove-Item "temp-win32.exe" -ErrorAction SilentlyContinue
        Write-Host "  32-bit SHA256: $($checksums.checksum32)" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to download 32-bit version: $_"
        return $null
    }
    
    # Download and checksum 64-bit version
    try {
        Write-Host "  Downloading 64-bit version..." -ForegroundColor Gray
        Invoke-WebRequest -Uri $url64 -OutFile "temp-win64.exe" -UseBasicParsing
        $checksums.checksum64 = (Get-FileHash -Path "temp-win64.exe" -Algorithm SHA256).Hash
        Remove-Item "temp-win64.exe" -ErrorAction SilentlyContinue
        Write-Host "  64-bit SHA256: $($checksums.checksum64)" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to download 64-bit version: $_"
        return $null
    }
    
    return $checksums
}

# Function to update package files
function Update-PackageFiles {
    param(
        [string]$Version,
        [string]$Checksum32,
        [string]$Checksum64
    )
    
    Write-Host "Updating package files to version $Version..." -ForegroundColor Cyan
    
    # Backup original files
    $backupDir = "backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
    Copy-Item "fluent-bit.nuspec" "$backupDir\" -Force
    Copy-Item "tools\chocolateyinstall.ps1" "$backupDir\" -Force
    Write-Host "  Backup created in: $backupDir" -ForegroundColor Gray
    
    try {
        # Update nuspec file
        Write-Host "  Updating fluent-bit.nuspec..." -ForegroundColor Gray
        $nuspecPath = "fluent-bit.nuspec"
        $nuspecContent = Get-Content -Path $nuspecPath -Raw
        
        # Update version
        $nuspecContent = $nuspecContent -replace '<version>\d+\.\d+\.\d+</version>', "<version>$Version</version>"
        
        # Update release notes URL
        $nuspecContent = $nuspecContent -replace 'https://fluentbit\.io/announcements/v\d+\.\d+\.\d+/', "https://fluentbit.io/announcements/v$Version/"
        
        Set-Content -Path $nuspecPath -Value $nuspecContent -Encoding UTF8BOM
        
        # Update chocolateyinstall.ps1
        Write-Host "  Updating chocolateyinstall.ps1..." -ForegroundColor Gray
        $installPath = "tools\chocolateyinstall.ps1"
        $installContent = Get-Content -Path $installPath -Raw
        
        # Update URLs
        $installContent = $installContent -replace "fluent-bit-\d+\.\d+\.\d+-win32\.exe", "fluent-bit-$Version-win32.exe"
        $installContent = $installContent -replace "fluent-bit-\d+\.\d+\.\d+-win64\.exe", "fluent-bit-$Version-win64.exe"
        
        # Update checksums - more specific regex patterns
        $installContent = $installContent -replace "checksum\s*=\s*'[A-Fa-f0-9]+'", "checksum      = '$Checksum32'"
        $installContent = $installContent -replace "checksum64\s*=\s*'[A-Fa-f0-9]+'", "checksum64    = '$Checksum64'"
        
        Set-Content -Path $installPath -Value $installContent -Encoding UTF8BOM
        
        Write-Host "  Package files updated successfully!" -ForegroundColor Green
        Write-Host "  To restore backup: Copy-Item $backupDir\* .\ -Force" -ForegroundColor Yellow
    }
    catch {
        Write-Error "Failed to update package files: $_"
        Write-Host "Restoring backup..." -ForegroundColor Yellow
        Copy-Item "$backupDir\*" ".\" -Force
        Remove-Item $backupDir -Recurse -Force
        return $false
    }
    
    return $true
}

# Main execution
Write-Host "=== Fluent Bit Package Update Helper ===" -ForegroundColor Magenta
Write-Host ""

# Get current version
$currentVersion = Get-CurrentPackageVersion
if (-not $currentVersion) {
    Write-Error "Could not determine current version. Exiting."
    exit 1
}

Write-Host "Current package version: $currentVersion" -ForegroundColor Yellow

# Determine target version
if ($Version) {
    $targetVersion = $Version
    Write-Host "Target version (specified): $targetVersion" -ForegroundColor Yellow
}
else {
    $latestVersion = Get-LatestFluentBitVersion
    if (-not $latestVersion) {
        Write-Error "Could not determine latest version. Exiting."
        exit 1
    }
    $targetVersion = $latestVersion
    Write-Host "Latest available version: $targetVersion" -ForegroundColor Yellow
}

# Check if update is needed
$needsUpdate = [version]$targetVersion -gt [version]$currentVersion

Write-Host ""
if ($needsUpdate -or $Force) {
    if ($Force) {
        Write-Host "🔄 Forcing update to version $targetVersion" -ForegroundColor Cyan
    }
    else {
        Write-Host "✅ Update needed: $currentVersion → $targetVersion" -ForegroundColor Green
    }
    
    if ($CheckOnly) {
        Write-Host "ℹ️ Check-only mode enabled. Exiting without making changes." -ForegroundColor Blue
        exit 0
    }
    
    # Get checksums
    $checksums = Get-Checksums -Version $targetVersion
    if (-not $checksums) {
        Write-Error "Failed to get checksums. Exiting."
        exit 1
    }
    
    # Update files
    $success = Update-PackageFiles -Version $targetVersion -Checksum32 $checksums.checksum32 -Checksum64 $checksums.checksum64
    
    if ($success) {
        Write-Host ""
        Write-Host "🎉 Package successfully updated to version $targetVersion!" -ForegroundColor Green
        Write-Host ""
        Write-Host "Next steps:" -ForegroundColor Cyan
        Write-Host "  1. Test the package: choco pack && choco install fluent-bit --source ./ -y" -ForegroundColor White
        Write-Host "  2. Review changes: git diff" -ForegroundColor White
        Write-Host "  3. Commit and push: git add -A && git commit -m 'Update to v$targetVersion' && git push" -ForegroundColor White
    }
    else {
        Write-Error "Failed to update package files."
        exit 1
    }
}
else {
    Write-Host "ℹ️ No update needed. Package is already at the latest version." -ForegroundColor Blue
}

Write-Host ""