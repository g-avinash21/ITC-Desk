@echo off
title ITC Tally link
echo.
echo  ITC Tally link
echo  Lets ITC Desk read from TallyPrime on this computer. Read-only: it refuses
echo  any request that would create, alter or delete anything in Tally.
echo  Keep this window open while you use Auto mode; close it when done.
echo.
powershell -NoProfile -ExecutionPolicy Bypass -Command "$s=[IO.File]::ReadAllText('%~f0'); iex ($s.Substring($s.LastIndexOf('#'+'PS-START')))"
echo.
pause
exit /b

#PS-START
$ErrorActionPreference = 'Stop'
$Port = 9800
# Pages allowed to use the link: ITC Desk opened from a file, or its published page
$Allowed = @('null', 'https://g-avinash21.github.io')
$listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Loopback, $Port)
try { $listener.Start() } catch { Write-Host " Port $Port is in use. ITC Tally link may already be running in another window."; return }
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
