# Compatibility shim: older launchers (0.1.x) restart this file after an update. The launcher is KH2Coop.exe now.
Start-Process -FilePath (Join-Path $PSScriptRoot 'KH2Coop.exe') -WorkingDirectory $PSScriptRoot
