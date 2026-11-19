@echo off
rem ITC Desk launcher: double-click to open ITC Desk. It also starts the Tally link in the background,
rem so Auto mode can read from TallyPrime on this computer. The link only reads: it refuses anything
rem that would change Tally. Stop it from ITC Desk (Auto > Stop link) or restart the PC.
setlocal
title ITC Desk
cd /d "%~dp0"
rem "ITC Desk.bat link" (used when Windows starts) only starts the Tally link, without opening the page
set "LINKONLY="
if /i "%~1"=="link" set "LINKONLY=1"
echo.
echo  ITC Desk launcher
echo  Folder: %~dp0
echo.

rem 1. Find ITC Desk in this folder: the newest of ITC_Desk.html, ITC_Desk (1).html, ITC-Desk.html (GitHub), ITC Desk.html, index.html
set "PAGE="
set "LDIR=%~dp0"
for /f "usebackq delims=" %%F in (`powershell -NoProfile -Command "Get-ChildItem -LiteralPath $env:LDIR -File | Where-Object { $_.Name -match '^(itc[ _-]?desk.*|index)\.html?$' } | Sort-Object LastWriteTime -Descending | Select-Object -First 1 -ExpandProperty Name"`) do if not defined PAGE set "PAGE=%%F"
set "ONLINE=https://g-avinash21.github.io/ITC-Desk/"

rem 2. Start the Tally link, unless it is already running
set "BATFILE=%~f0"
set "LINKPS=%TEMP%\ITC Desk link.ps1"
set "LINKLOG=%TEMP%\ITC Desk link.log"
rem Ask the link itself (/ping). A link that holds the port but does not answer (stuck, or an older copy started
rem with Windows) is stopped and started fresh. Another program on port 9800 is named, not stopped.
powershell -NoProfile -Command "try { $r = Invoke-WebRequest -UseBasicParsing -TimeoutSec 3 'http://127.0.0.1:9800/ping'; if ($r.Content -match 'ITC Tally link') { exit 0 } } catch { }; $h = @(Get-NetTCPConnection -LocalPort 9800 -State Listen -ErrorAction SilentlyContinue); if (-not $h.Count) { exit 1 }; foreach ($c in $h) { $p = Get-Process -Id $c.OwningProcess -ErrorAction SilentlyContinue; if ($p -and $p.ProcessName -match '^(powershell|pwsh)$') { Stop-Process -Id $p.Id -Force } else { Write-Host ('  Port 9800 is used by another program: ' + $p.ProcessName); exit 3 } }; Start-Sleep -Milliseconds 800; exit 2"
if errorlevel 3 goto portbusy
if not errorlevel 1 goto linkok
if errorlevel 2 echo  An older Tally link was not answering: it was stopped.
echo  Starting the Tally link in the background...
powershell -NoProfile -Command "$s = [IO.File]::ReadAllText($env:BATFILE); [IO.File]::WriteAllText($env:LINKPS, $s.Substring($s.LastIndexOf('#' + 'PS-START')))"
start "" /min powershell -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -Command "& $env:LINKPS *> $env:LINKLOG"
powershell -NoProfile -Command "for ($i = 0; $i -lt 24; $i++) { try { $r = Invoke-WebRequest -UseBasicParsing -TimeoutSec 2 'http://127.0.0.1:9800/ping'; if ($r.Content -match 'ITC Tally link') { exit 0 } } catch { Start-Sleep -Milliseconds 500 } }; exit 1"
if errorlevel 1 goto linkvisible
:linkok
echo  The Tally link is running.
if defined LINKONLY exit /b

rem 3. Offer once to start the link with Windows, so it is always running
set "STARTUP=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\ITC Desk link.bat"
set "ASKED=%APPDATA%\ITC Desk startup asked.txt"
if exist "%STARTUP%" goto openpage
if exist "%ASKED%" goto openpage
echo.
echo  Start the Tally link by itself whenever this computer starts?
echo  Then Auto mode always finds it, even if ITC Desk is opened directly. (Y = yes, N = no; no answer in 20 seconds = no)
choice /C YN /T 20 /D N /N
if errorlevel 2 goto declined
> "%STARTUP%" echo @start "" /min "%~f0" link
echo  Done. It will start with Windows. To undo, delete "ITC Desk link.bat" from the Startup folder.
goto openpage
:declined
> "%ASKED%" echo asked
echo  Not added. You will not be asked again.
:openpage

rem 4. Open ITC Desk
if not defined PAGE goto nopage
echo  Opening %PAGE% in your browser...
start "" "%~dp0%PAGE%"
echo.
echo  Done. This window closes by itself; the link keeps running in the background.
timeout /t 5 >nul
exit /b

:linkvisible
echo.
echo  The Tally link could not start in the background (antivirus or PowerShell settings may block it).
if exist "%LINKLOG%" type "%LINKLOG%"
echo  Running it in this window instead. KEEP THIS WINDOW OPEN while you use Auto mode.
echo.
if defined PAGE start "" "%~dp0%PAGE%"
if not defined PAGE echo  No ITC Desk file in this folder: opening the online copy.
if not defined PAGE start "" "%ONLINE%"
powershell -NoProfile -ExecutionPolicy Bypass -File "%LINKPS%"
pause
exit /b

:portbusy
echo.
echo  The Tally link cannot start: another program is using port 9800 (named above).
echo  Close that program, or restart the computer, then double-click this file again.
echo.
pause
exit /b

:nopage
echo.
echo  No ITC Desk file in this folder, so the online copy is opening:
echo  %ONLINE%
echo  The Tally link is running, so Auto mode works there too.
echo  (To work offline, keep ITC_Desk.html in this folder.)
start "" "%ONLINE%"
timeout /t 8 >nul
exit /b

#PS-START
$ErrorActionPreference = 'Stop'
$Port = 9800
# Pages allowed to use the link: ITC Desk opened from a file, or its published page
$Allowed = @('null', 'https://g-avinash21.github.io')
$listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Loopback, $Port)
try { $listener.Start() } catch { Write-Host " Port $Port is in use: the Tally link may already be running."; return }
Write-Host " Running on http://127.0.0.1:$Port  (only this computer can reach it)"
Write-Host ""

function Send($stream, [int]$code, [string]$origin, [byte[]]$body, [string]$type) {
  $reason = @{200='OK';204='No Content';400='Bad Request';403='Forbidden';404='Not Found';502='Bad Gateway'}[$code]
  $h = "HTTP/1.1 $code $reason`r`n"
  if ($origin) { $h += "Access-Control-Allow-Origin: $origin`r`nVary: Origin`r`n" }
  $h += "Access-Control-Allow-Methods: GET, POST, OPTIONS`r`nAccess-Control-Allow-Headers: Content-Type`r`nAccess-Control-Allow-Private-Network: true`r`n"
  if (-not $body) { $body = [byte[]]@() }
  if ($type) { $h += "Content-Type: $type`r`n" }
  $h += "Content-Length: $($body.Length)`r`nConnection: close`r`n`r`n"
  $hb = [Text.Encoding]::ASCII.GetBytes($h)
  $stream.Write($hb, 0, $hb.Length)
  if ($body.Length) { $stream.Write($body, 0, $body.Length) }
}
function Json($o) { [Text.Encoding]::UTF8.GetBytes(($o | ConvertTo-Json -Compress -Depth 5)) }

while ($true) {
  $client = $listener.AcceptTcpClient()
  try {
    $s = $client.GetStream(); $s.ReadTimeout = 20000
    $ms = New-Object IO.MemoryStream; $buf = New-Object byte[] 65536; $hEnd = -1
    while ($hEnd -lt 0) {
      $n = $s.Read($buf, 0, $buf.Length); if ($n -le 0) { break }
      $ms.Write($buf, 0, $n)
      $hEnd = [Text.Encoding]::ASCII.GetString($ms.ToArray()).IndexOf("`r`n`r`n")
    }
    if ($hEnd -lt 0) { continue }
    $all = $ms.ToArray()
    $head = [Text.Encoding]::ASCII.GetString($all, 0, $hEnd)
    $lines = $head -split "`r`n"
    $parts = $lines[0] -split ' '
    $method = $parts[0]; $path = $parts[1]
    $hdr = @{}
    foreach ($l in $lines[1..($lines.Length - 1)]) { $i = $l.IndexOf(':'); if ($i -gt 0) { $hdr[$l.Substring(0, $i).Trim().ToLower()] = $l.Substring($i + 1).Trim() } }
    $origin = $hdr['origin']
    $len = 0; if ($hdr['content-length']) { $len = [int]$hdr['content-length'] }
    $body = New-Object IO.MemoryStream
    $have = $all.Length - ($hEnd + 4)
    if ($have -gt 0) { $body.Write($all, $hEnd + 4, $have) }
    while ($body.Length -lt $len) { $n = $s.Read($buf, 0, $buf.Length); if ($n -le 0) { break }; $body.Write($buf, 0, $n) }
    $bodyBytes = $body.ToArray()

    if ($origin -and ($Allowed -notcontains $origin)) { Send $s 403 $null (Json @{ error = "This page is not allowed to read Tally: $origin" }) 'application/json'; Write-Host " Refused a request from $origin"; continue }
    $ao = $origin
    if ($method -eq 'OPTIONS') { Send $s 204 $ao $null $null; continue }

    $q = @{}
    if ($path.Contains('?')) { foreach ($kv in $path.Split('?')[1].Split('&')) { $p = $kv.Split('='); if ($p.Length -eq 2) { $q[$p[0]] = [Uri]::UnescapeDataString($p[1]) } } }
    $route = $path.Split('?')[0]

    if ($route -eq '/quit') { Send $s 200 $ao (Json @{ ok = $true; stopped = $true }) 'application/json'; $client.Close(); $listener.Stop(); return }
    if ($route -eq '/ping') { Send $s 200 $ao (Json @{ ok = $true; name = 'ITC Tally link'; version = 1 }) 'application/json'; continue }

    if ($route -eq '/scan') {
      $from = 9000; $to = 9010
      if ($q['from']) { $from = [int]$q['from'] }; if ($q['to']) { $to = [int]$q['to'] }
      if ($to - $from -gt 40) { $to = $from + 40 }
      $found = @()
      foreach ($p in $from..$to) {
        $tc = New-Object System.Net.Sockets.TcpClient
        $ar = $tc.BeginConnect('127.0.0.1', $p, $null, $null)
        $ok = $ar.AsyncWaitHandle.WaitOne(250)
        if ($ok -and $tc.Connected) {
          $tc.Close()
          $txt = ''
          try {
            $r = [System.Net.HttpWebRequest]::Create("http://127.0.0.1:$p/"); $r.Proxy = $null; $r.Timeout = 3000
            $resp = $r.GetResponse(); $sr = New-Object IO.StreamReader($resp.GetResponseStream()); $txt = $sr.ReadToEnd(); $resp.Close()
          } catch { $txt = '' }
          if ($txt.Length -gt 200) { $txt = $txt.Substring(0, 200) }
          $found += @{ port = $p; reply = $txt }
        } else { $tc.Close() }
      }
      Send $s 200 $ao (Json @{ ports = @($found) }) 'application/json'; continue
    }

    if ($route -eq '/tally' -and $method -eq 'POST') {
      $tp = 9000; if ($q['port']) { $tp = [int]$q['port'] }
      $xml = [Text.Encoding]::UTF8.GetString($bodyBytes)
      # Read-only: only Export requests; nothing that imports, creates, alters or deletes
      if ($xml -notmatch '<TALLYREQUEST>\s*Export' -or $xml -match '<TALLYREQUEST>\s*Import' -or $xml -match 'ACTION\s*=\s*"(Create|Alter|Delete|Cancel)"') {
        Send $s 403 $ao (Json @{ error = 'Refused: ITC Tally link only reads from Tally.' }) 'application/json'; Write-Host ' Refused a request that was not read-only'; continue
      }
      try {
        $r = [System.Net.HttpWebRequest]::Create("http://127.0.0.1:$tp/"); $r.Proxy = $null
        $r.Method = 'POST'; $r.ContentType = 'text/xml;charset=utf-8'; $r.Timeout = 300000; $r.ReadWriteTimeout = 300000
        $rs = $r.GetRequestStream(); $rs.Write($bodyBytes, 0, $bodyBytes.Length); $rs.Close()
        $resp = $r.GetResponse(); $out = New-Object IO.MemoryStream; $resp.GetResponseStream().CopyTo($out); $resp.Close()
        Send $s 200 $ao $out.ToArray() 'application/octet-stream'
        Write-Host (" Read from Tally on port {0}: {1:N0} bytes" -f $tp, $out.Length)
      } catch {
        Send $s 502 $ao (Json @{ error = "Tally on port $tp did not answer: $($_.Exception.Message)" }) 'application/json'
      }
      continue
    }
    Send $s 404 $ao (Json @{ error = 'Not found' }) 'application/json'
  } catch {
    Write-Host " Error: $($_.Exception.Message)"
  } finally { $client.Close() }
}
