$ErrorActionPreference = 'Stop'

$process = Get-Process "fluent-bit*" -ea 0

if ($process) {
  $processPath = $process | Where-Object { $_.Path } | Select-Object -First 1 -ExpandProperty Path
  Write-Host "Found Running instance of fluent-bit. Stopping processes..."
  $process | Stop-Process
}

$toolsDir   = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
$url        = 'https://packages.fluentbit.io/windows/fluent-bit-4.0.4-win32.exe'
$url64      = 'https://packages.fluentbit.io/windows/fluent-bit-4.0.4-win64.exe'

$packageArgs = @{
  packageName   = $env:ChocolateyPackageName
  unzipLocation = $toolsDir
  fileType      = 'exe'
  url           = $url
  url64bit      = $url64
  softwareName  = 'fluent-bit*'
  checksum      = 'E4C6FA0555E793342DAAD954F5EDEA5801D0D44904E31E2F8778FEC5B0FFCFD2'
  checksumType  = 'sha256'
  checksum64    = '3B51C5FE30859CA1D6959F90C37B3C7B23AEC1641CA7068C458F900FE8B0A8E9'
  checksumType64= 'sha256'
  silentArgs    = "/S"
  validExitCodes= @(0, 3010, 1641)
}

Install-ChocolateyPackage @packageArgs

# Get the installation directory from the registry
if (Test-Path "HKLM:\SOFTWARE\WOW6432Node\Chronosphere Inc.\fluent-bit") {
  Write-Debug "64-bit version installed"
  $regKey = Get-ItemProperty "HKLM:\SOFTWARE\WOW6432Node\Chronosphere Inc.\fluent-bit"
  $regKeySelector = $regKey | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | Select-Object -First 1
  $installDir = $regKey.$regKeySelector
  Write-Host "Fluentbit is installed at: $installDir"
} elseif (Test-Path "HKLM:\SOFTWARE\Chronosphere Inc.\fluent-bit") {
  Write-Debug "32-bit version installed"
  $regKey = Get-ItemProperty "HKLM:\SOFTWARE\Chronosphere Inc.\fluent-bit"
  $regKeySelector = $regKey | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | Select-Object -First 1
  $installDir = $regKey.$regKeySelector
  Write-Host "Fluentbit is installed at: $installDir"
} else {
  Write-Error "Fluentbit installation directory not found in registry."
  exit 1
}

$ServiceName = "fluent-bit"
$ExecutablePath = Join-Path -Path $installDir -ChildPath "bin\fluent-bit.exe"
$ConfigPath = Join-Path -Path $installDir -ChildPath "conf\fluent-bit.conf"

Write-Host "Executable Path: $ExecutablePath"
Write-Host "Config Path: $ConfigPath"

New-Service $ServiceName -BinaryPathName "`"$ExecutablePath`" -c `"$ConfigPath`"" -StartupType Automatic -Description "This service runs Fluent Bit, a log collector that enables real-time processing and delivery of log data to centralized logging systems."
Start-Service -Name $ServiceName

Write-Host "Fluent Bit service created successfully." -ForegroundColor Green