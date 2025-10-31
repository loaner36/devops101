$ErrorActionPreference='Stop'
$base = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $base
& "$base\sysdiag.ps1" | Out-Null
$latest = Get-ChildItem -File "$base\win_sysdiag_*.txt" | Sort-Object LastWriteTime -desc | Select-Object -First 1
if(-not $latest){ throw "未找到 win_sysdiag_*.txt" }
$ts = Get-Date -Format 'yyyyMMdd_HHmmss'
$zip= "win_sysdiag_bundle_$ts.zip"
if(Test-Path $zip){ Remove-Item $zip -Force }
Compress-Archive -Path "$base\sysdiag.ps1", $latest.FullName -DestinationPath $zip
Write-Host "打包完成：$zip（包含：sysdiag.ps1 + $($latest.Name)）"
