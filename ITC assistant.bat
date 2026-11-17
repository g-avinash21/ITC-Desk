@echo off
setlocal
title ITC Desk assistant
set "BASE=%~dp0"
echo.
echo  ITC Desk assistant
echo  Runs a small AI model on this computer. No client data leaves it.
echo.
call :find
if not defined EXE (
  where winget >nul 2>nul
  if errorlevel 1 (
    echo  winget is missing. Install "App Installer" from the Microsoft Store, then run this file again.
    pause
    exit /b 1
  )
  echo  Installing llama.cpp. This happens only once.
  winget install llama.cpp --accept-source-agreements --accept-package-agreements
  call :find
)
if not defined EXE (
  echo.
  echo  llama.cpp is installed, but llama-server.exe could not be found.
  echo  Download the Windows CPU zip from github.com/ggml-org/llama.cpp/releases,
  echo  unzip it into the folder that holds this file, and double-click this file again.
  pause
  exit /b 1
)
echo  Using %EXE% %SUB%
set "CFG=%BASE%ITC assistant model.txt"
if exist "%CFG%" (
  choice /c CK /t 4 /d K /n /m "  Press C to change the model, or wait 4 seconds: "
  if not errorlevel 2 del "%CFG%"
)
if not exist "%CFG%" (
  echo.
  echo  Which model?
  echo    S  Qwen3 4B Instruct     2.5 GB  best answers, slowest
  echo    M  LFM2.5 1.2B Instruct  0.7 GB  good balance for 8 GB RAM
  echo    L  Qwen2.5 1.5B Instruct 1.0 GB  light
  echo    T  LFM2 350M             0.2 GB  fastest, weakest; for old PCs
  choice /c SMLT /n /m "  Type S, M, L or T: "
  if errorlevel 4 (echo LiquidAI/LFM2-350M-GGUF:Q4_K_M> "%CFG%") else if errorlevel 3 (echo Qwen/Qwen2.5-1.5B-Instruct-GGUF:Q4_K_M> "%CFG%") else if errorlevel 2 (echo LiquidAI/LFM2.5-1.2B-Instruct-GGUF:Q4_K_M> "%CFG%") else (echo unsloth/Qwen3-4B-Instruct-2507-GGUF:Q4_K_M> "%CFG%")
)
set /p MODEL=<"%CFG%"
echo.
echo  Starting the assistant with %MODEL%
echo  The first start downloads the model from Hugging Face. Later starts work offline.
echo  When you see "listening on http://127.0.0.1:8080", go back to ITC Desk and click Test. Keep this window open.
echo.
"%EXE%" %SUB% -hf %MODEL% -c 8192 --host 127.0.0.1 --port 8080
echo.
echo  The assistant stopped. To change the model, run this file again and press C.
pause
exit /b 0

:find
set "EXE="
set "SUB="
for /f "delims=" %%F in ('where llama-server 2^>nul') do if not defined EXE set "EXE=%%F"
if defined EXE exit /b 0
for %%R in ("%BASE%" "%LOCALAPPDATA%\Microsoft\WinGet\Links" "%LOCALAPPDATA%\Microsoft\WinGet\Packages" "%ProgramFiles%\WinGet\Packages" "%ProgramFiles%\llama.cpp") do (
  if not defined EXE for /f "delims=" %%F in ('dir /s /b "%%~R\llama-server.exe" 2^>nul') do if not defined EXE set "EXE=%%F"
)
if defined EXE exit /b 0
for /f "delims=" %%F in ('where llama 2^>nul') do if not defined EXE (
  set "EXE=%%F"
  set "SUB=serve"
)
exit /b 0
