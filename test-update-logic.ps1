# Test script for the auto-update workflow
# This script tests the core functions without making any changes

Write-Host "=== Testing Auto-Update Workflow Logic ===" -ForegroundColor Magenta

# Test function to get latest version from Fluent Bit packages site
function Test-GetLatestFluentBitVersion {
    Write-Host "`n1. Testing Get-LatestFluentBitVersion..." -ForegroundColor Cyan
    try {
        $response = Invoke-WebRequest -Uri "https://packages.fluentbit.io/windows/" -UseBasicParsing
        $content = $response.Content
        
        # Look for fluent-bit-X.Y.Z-win64.exe pattern
        $versionPattern = 'fluent-bit-(\d+\.\d+\.\d+)-win64\.exe'
        $versionMatches = [regex]::Matches($content, $versionPattern)
        
        if ($versionMatches.Count -eq 0) {
            Write-Error "❌ No version found in packages site"
            return $null
        }
        
        # Get all versions and find the latest
        $versions = $versionMatches | ForEach-Object { $_.Groups[1].Value } | Sort-Object { [version]$_ } -Descending
        Write-Host "✅ Found versions: $($versions -join ', ')" -ForegroundColor Green
        Write-Host "✅ Latest version: $($versions[0])" -ForegroundColor Green
        return $versions[0]
    }
    catch {
        Write-Error "❌ Failed to fetch latest version: $_"
        return $null
    }
}

# Test function to get current Chocolatey package version
function Test-GetCurrentChocolateyVersion {
    Write-Host "`n2. Testing Get-CurrentChocolateyVersion..." -ForegroundColor Cyan
    try {
        # First try Chocolatey page
        try {
            $response = Invoke-WebRequest -Uri "https://community.chocolatey.org/packages/fluent-bit/" -UseBasicParsing
            $content = $response.Content
            
            # Look for version in the page
            $versionPattern = '<h3>fluent-bit (\d+\.\d+\.\d+)</h3>'
            $versionMatch = [regex]::Match($content, $versionPattern)
            
            if ($versionMatch.Success) {
                Write-Host "✅ Found version on Chocolatey page: $($versionMatch.Groups[1].Value)" -ForegroundColor Green
                return $versionMatch.Groups[1].Value
            }
        }
        catch {
            Write-Warning "⚠️ Could not access Chocolatey page, trying fallback method"
        }
        
        # Fallback to reading from nuspec file
        if (Test-Path "fluent-bit.nuspec") {
            $nuspecContent = Get-Content -Path "fluent-bit.nuspec" -Raw
            $nuspecMatch = [regex]::Match($nuspecContent, '<version>(\d+\.\d+\.\d+)</version>')
            if ($nuspecMatch.Success) {
                Write-Host "✅ Found version in local nuspec: $($nuspecMatch.Groups[1].Value)" -ForegroundColor Green
                return $nuspecMatch.Groups[1].Value
            }
        }
        
        Write-Error "❌ Could not determine current version"
        return $null
    }
    catch {
        Write-Error "❌ Failed to get current Chocolatey version: $_"
        return $null
    }
}

# Test URL accessibility
function Test-UrlAccessibility {
    param([string]$Version)
    
    Write-Host "`n3. Testing URL accessibility for version $Version..." -ForegroundColor Cyan
    
    $url32 = "https://packages.fluentbit.io/windows/fluent-bit-$Version-win32.exe"
    $url64 = "https://packages.fluentbit.io/windows/fluent-bit-$Version-win64.exe"
    
    # Test 32-bit URL
    try {
        $response = Invoke-WebRequest -Uri $url32 -Method Head -UseBasicParsing
        if ($response.StatusCode -eq 200) {
            Write-Host "✅ 32-bit URL accessible: $url32" -ForegroundColor Green
        }
    }
    catch {
        Write-Error "❌ 32-bit URL not accessible: $url32"
    }
    
    # Test 64-bit URL
    try {
        $response = Invoke-WebRequest -Uri $url64 -Method Head -UseBasicParsing
        if ($response.StatusCode -eq 200) {
            Write-Host "✅ 64-bit URL accessible: $url64" -ForegroundColor Green
        }
    }
    catch {
        Write-Error "❌ 64-bit URL not accessible: $url64"
    }
}

# Main test execution
try {
    # Test getting latest version
    $latestVersion = Test-GetLatestFluentBitVersion
    
    # Test getting current version
    $currentVersion = Test-GetCurrentChocolateyVersion
    
    if ($latestVersion -and $currentVersion) {
        Write-Host "`n=== Version Comparison ===" -ForegroundColor Yellow
        Write-Host "Current version: $currentVersion" -ForegroundColor White
        Write-Host "Latest version:  $latestVersion" -ForegroundColor White
        
        $needsUpdate = [version]$latestVersion -gt [version]$currentVersion
        Write-Host "Needs update:    $needsUpdate" -ForegroundColor $(if($needsUpdate) { "Green" } else { "Blue" })
        
        # Test URL accessibility for latest version
        Test-UrlAccessibility -Version $latestVersion
        
        Write-Host "`n✅ All tests completed successfully!" -ForegroundColor Green
    }
    else {
        Write-Error "❌ Could not complete tests due to version detection failures"
    }
}
catch {
    Write-Error "❌ Test execution failed: $_"
}

Write-Host "`n=== Test Summary ===" -ForegroundColor Magenta
Write-Host "This test validates the core logic that will be used in the GitHub workflow."
Write-Host "If all tests pass, the automated workflow should function correctly."