@echo off
chcp 65001 >nul

:: 檢查管理員權限
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [ERROR] 請右鍵點擊「以管理員身分執行」！
    pause
    exit /b
)

:: 將所有邏輯與中文輸出交給 PowerShell 處理
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$ErrorActionPreference = 'Stop';" ^
    "try {" ^
    "  Write-Host '==========================================' -ForegroundColor Cyan;" ^
    "  Write-Host '    Gemini CLI 自動化安裝程式' -ForegroundColor Cyan;" ^
    "  Write-Host '==========================================' -ForegroundColor Cyan;" ^
    "  Write-Host '1. 檢查 Chocolatey...' -ForegroundColor Cyan;" ^
    "  if (!(Get-Command choco -ErrorAction SilentlyContinue)) {" ^
    "    Write-Host '   - 正在安裝 Chocolatey...' -ForegroundColor Yellow;" ^
    "    Set-ExecutionPolicy Bypass -Scope Process -Force;" ^
    "    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072;" ^
    "    iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'));" ^
    "    $env:Path = [System.Environment]::GetEnvironmentVariable('Path','Machine') + ';' + [System.Environment]::GetEnvironmentVariable('Path','User');" ^
    "  } else { Write-Host '   - Chocolatey 已存在。' -ForegroundColor Green };" ^
    "  Write-Host '2. 檢查 Node.js...' -ForegroundColor Cyan;" ^
    "  if (!(Get-Command node -ErrorAction SilentlyContinue)) {" ^
    "    Write-Host '   - 正在安裝 Node.js...' -ForegroundColor Yellow;" ^
    "    cmd.exe /c 'choco install nodejs -y';" ^
    "    if ($LASTEXITCODE -ne 0) { throw 'Node.js 安裝失敗' };" ^
    "    $env:Path = [System.Environment]::GetEnvironmentVariable('Path','Machine') + ';' + [System.Environment]::GetEnvironmentVariable('Path','User');" ^
    "  } else { Write-Host '   - Node.js 已存在。' -ForegroundColor Green };" ^
    "  Write-Host '3. 安裝 @google/gemini-cli...' -ForegroundColor Cyan;" ^
    "  $npmCmd = Get-Command npm -ErrorAction SilentlyContinue;" ^
    "  if (!$npmCmd) { $env:Path = [System.Environment]::GetEnvironmentVariable('Path','Machine') + ';' + [System.Environment]::GetEnvironmentVariable('Path','User') };" ^
    "  cmd.exe /c 'npm install -g @google/gemini-cli';" ^
    "  if ($LASTEXITCODE -ne 0) { throw 'npm 安裝失敗！請檢查網路連線。' };" ^
    "  Write-Host '--- 所有軟體安裝完成 ---' -ForegroundColor Green;" ^
    "  Write-Host '`n==========================================' -ForegroundColor Cyan;" ^
    "  Write-Host '           API KEY 設定 (可選)' -ForegroundColor Cyan;" ^
    "  Write-Host '==========================================' -ForegroundColor Cyan;" ^
    "  Write-Host '請至 https://aistudio.google.com/ 取得 API Key' -ForegroundColor Yellow;" ^
    "  $apiKey = Read-Host '請貼上您的 Gemini API Key (若想稍後設定請直接按 Enter)';" ^
    "  if (![string]::IsNullOrWhiteSpace($apiKey)) {" ^
    "    [System.Environment]::SetEnvironmentVariable('GEMINI_API_KEY', $apiKey, 'User');" ^
    "    Write-Host '[OK] API Key 已寫入環境變數。' -ForegroundColor Green;" ^
    "  }" ^
    "  Write-Host '`n------------------------------------------' -ForegroundColor Green;" ^
    "  Write-Host '【恭喜】環境已架設完成！' -ForegroundColor Green;" ^
    "  Write-Host '請重新啟動終端機。' -ForegroundColor Yellow;" ^
    "  Write-Host '------------------------------------------' -ForegroundColor Green;" ^
    "} catch {" ^
    "  Write-Host '`n!!! [發生錯誤，安裝已中斷] !!!' -ForegroundColor Red;" ^
    "  Write-Host $_.Exception.Message -ForegroundColor Red;" ^
    "  exit 1;" ^
    "}"

pause