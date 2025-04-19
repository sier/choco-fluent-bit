$ErrorActionPreference = 'Stop'
# Stop and delete the service if it exists
sc.exe stop fluent-bit
sc.exe delete fluent-bit