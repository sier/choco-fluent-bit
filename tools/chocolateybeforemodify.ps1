$ErrorActionPreference = 'Stop'
# Stop and delete the service if it exists
Start-ChocolateyProcessAsAdmin -Statements "sc.exe stop fluent-bit; sc.exe delete fluent-bit"