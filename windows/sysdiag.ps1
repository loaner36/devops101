# 作用：收集 Windows 关键诊断信息到 txt（UTF-8 无 BOM）
$ErrorActionPreference='Stop'
$ts   = Get-Date -Format 'yyyyMMdd_HHmmss'
$out  = "win_sysdiag_$ts.txt"
$utf8 = [System.Text.UTF8Encoding]::new($false)

function W([string]$title,[scriptblock]$action){
  "[=== $title ===]`n" | Out-File -FilePath $out -Encoding $utf8 -Append
  try { & $action | Out-String | Out-File $out -Encoding $utf8 -Append }
  catch { "[$title] 失败：$($_.Exception.Message)`n" | Out-File $out -Encoding $utf8 -Append }
  "" | Out-File $out -Encoding $utf8 -Append
}

W 'BASIC / OS' {
  $os=Get-CimInstance Win32_OperatingSystem
  [pscustomobject]@{
    ComputerName=$env:COMPUTERNAME; Caption=$os.Caption; Version=$os.Version
    Architecture=(Get-CimInstance Win32_Processor|Select-Object -First 1 -Expand AddressWidth)
    LastBoot=$os.LastBootUpTime; PSVersion=$PSVersionTable.PSVersion
  }
}
W 'UPTIME & CPU' {
  $os=Get-CimInstance Win32_OperatingSystem
  $u=(Get-Date)-$os.LastBootUpTime
  $cpu=Get-CimInstance Win32_Processor|Select-Object -First 1
  [pscustomobject]@{Uptime=("{0:%d}d {0:%hh}h {0:%mm}m" -f $u); CPU=$cpu.Name;
    Cores=$cpu.NumberOfCores; Threads=$cpu.NumberOfLogicalProcessors; MaxMHz=$cpu.MaxClockSpeed}
}
W 'MEMORY(MB)' {
  $os=Get-CimInstance Win32_OperatingSystem
  $t=[math]::Round($os.TotalVisibleMemorySize/1024,0)
  $f=[math]::Round($os.FreePhysicalMemory/1024,0)
  [pscustomobject]@{TotalMB=$t; UsedMB=$t-$f; FreeMB=$f}
}
W 'DISKS' {
  Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" |
    Select-Object DeviceID,@{n='SizeGB';e={[math]::Round($_.Size/1GB,2)}},
      @{n='FreeGB';e={[math]::Round($_.FreeSpace/1GB,2)}},
      @{n='Used%';e={if($_.Size){[math]::Round(100*(1-($_.FreeSpace/$_.Size)),1)}else{0}}}
}
W 'TOP PROCESSES' { Get-Process|Sort-Object CPU -desc|Select-Object -First 10 Id,ProcessName,CPU,PM,WS }
W 'NETWORK CONFIG' { Get-NetIPConfiguration|Format-List * }
W 'ROUTES (IPv4)'  { Get-NetRoute -AddressFamily IPv4|Sort-Object RouteMetric|Select-Object -First 30|Format-Table -AutoSize }
W 'LISTEN PORTS' {
  $tcp=Get-NetTCPConnection -State Listen|Select LocalAddress,LocalPort,OwningProcess
  $udp=Get-NetUDPEndpoint|Select LocalAddress,LocalPort,OwningProcess
  $all=$tcp|ForEach-Object{ $p=(Get-Process -Id $_.OwningProcess -ea SilentlyContinue).ProcessName
    [pscustomobject]@{Proto='TCP';Local="$($_.LocalAddress):$($_.LocalPort)";PID=$_.OwningProcess;Proc=$p} }
  $all+=$udp|ForEach-Object{ $p=(Get-Process -Id $_.OwningProcess -ea SilentlyContinue).ProcessName
    [pscustomobject]@{Proto='UDP';Local="$($_.LocalAddress):$($_.LocalPort)";PID=$_.OwningProcess;Proc=$p} }
  $all|Select-Object -First 50|Format-Table -AutoSize
}
W 'DNS' { Get-DnsClientServerAddress -AddressFamily IPv4|Select InterfaceAlias,ServerAddresses }
W 'CONNECTIVITY' { '1.1.1.1','8.8.8.8','www.microsoft.com'|%{ try{Test-Connection -Count 2 -Quiet $_|Out-String}catch{"Ping $_ 失败"} } }
W 'EVENT ERRORS (24h)' {
  $since=(Get-Date).AddDays(-1)
  $sys=Get-WinEvent -FilterHashtable @{LogName='System';Level=2;StartTime=$since} -MaxEvents 60 -ea SilentlyContinue
  $app=Get-WinEvent -FilterHashtable @{LogName='Application';Level=2;StartTime=$since} -MaxEvents 40 -ea SilentlyContinue
  $sys+$app|Select TimeCreated,ProviderName,Id,LevelDisplayName,Message|Sort-Object TimeCreated -desc|Format-List
}
"已保存诊断结果到：$out"|Out-File -FilePath $out -Encoding $utf8 -Append
Write-Host "Saved to $out"
