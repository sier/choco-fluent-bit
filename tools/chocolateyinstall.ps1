

$ErrorActionPreference = 'Stop'

$process = Get-Process "fluent-bit*" -ea 0

if ($process) {
  $processPath = $process | Where-Object { $_.Path } | Select-Object -First 1 -ExpandProperty Path
  Write-Host "Found Running instance of fluent-bit. Stopping processes..."
  $process | Stop-Process
}

$toolsDir   = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
$url        = 'https://packages.fluentbit.io/windows/fluent-bit-4.0.0-win32.exe'
$url64      = 'https://packages.fluentbit.io/windows/fluent-bit-4.0.0-win64.exe'

$packageArgs = @{
  packageName   = $env:ChocolateyPackageName
  unzipLocation = $toolsDir
  fileType      = 'exe'
  url           = $url
  url64bit      = $url64
  softwareName  = 'fluent-bit*'
  checksum      = '2676f127b2b71d44f494027fbac4a20bc8be2257fe8a201b28b9780056bde24f'
  checksumType  = 'sha256'
  checksum64    = 'c4173fe51f81dc3108d6036687d8d0b715f619ffcfb04223ab1c31ef4284ff92'
  checksumType64= 'sha256'
  silentArgs    = "/S"
  validExitCodes= @(0, 3010, 1641)
}

Install-ChocolateyPackage @packageArgs


$ServiceName = "fluent-bit"
$ExecutablePath = "C:\Program Files\fluent-bit\bin\fluent-bit.exe"
$ConfigPath = "C:\Program Files\fluent-bit\conf\fluent-bit.conf"

$cmdFilePath = "$toolsdir\fluent-bit.cmd"
    $cmdFileContent = @"
sc.exe create $ServiceName binpath= "\"$ExecutablePath\" -c \"$ConfigPath\"" start= auto
sc.exe description $ServiceName "This service runs Fluent Bit, a log collector that enables real-time processing and delivery of log data to centralized logging systems."
sc.exe start $ServiceName
"@
    Set-Content -Path $cmdFilePath -Value $cmdFileContent -Force

try {
    Start-Process -FilePath $cmdFilePath -Wait
}
catch {
    Write-Error $_.Exception.Message
    exit 1
}
Write-Host "Fluent Bit service created successfully." -ForegroundColor Green
