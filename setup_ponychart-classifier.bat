@echo off
:: 切換編碼至 UTF-8 以避免中文亂碼
chcp 65001 >nul
setlocal EnableDelayedExpansion

echo [1/5] 檢查並安裝 uv...
where uv >nul 2>nul
if !errorlevel! neq 0 (
    echo 系統中找不到 uv，開始自動安裝...
    powershell -ExecutionPolicy ByPass -c "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-RestMethod -Uri https://astral.sh/uv/install.ps1 | Invoke-Expression"
    
    if exist "%USERPROFILE%\.local\bin\uv.exe" (
        set "UV_EXE=%USERPROFILE%\.local\bin\uv.exe"
    ) else if exist "%USERPROFILE%\.cargo\bin\uv.exe" (
        set "UV_EXE=%USERPROFILE%\.cargo\bin\uv.exe"
    ) else if exist "%LOCALAPPDATA%\Programs\uv\uv.exe" (
        set "UV_EXE=%LOCALAPPDATA%\Programs\uv\uv.exe"
    ) else (
        echo [錯誤] 找不到 uv.exe，請確認安裝過程是否被網路或防毒阻擋。
        goto :error
    )
) else (
    echo uv 已安裝，跳過此步驟。
    set "UV_EXE=uv"
)

echo.
echo [2/5] 在當前目錄建立新資料夾 (pony_env) 並初始化 Python 3.11 環境...
set "ENV_DIR=%CD%\pony_env"
if not exist "!ENV_DIR!" mkdir "!ENV_DIR!"
"!UV_EXE!" venv --python 3.11 "!ENV_DIR!"
if !errorlevel! neq 0 (
    echo [錯誤] 建立虛擬環境失敗！
    goto :error
)

echo.
echo [3/5] 安裝 ponychart-classifier...
"!UV_EXE!" pip install --python "!ENV_DIR!" ponychart-classifier
if !errorlevel! neq 0 (
    echo [錯誤] 安裝 ponychart-classifier 套件失敗！
    goto :error
)

echo.
echo [4/5] 建立測試程式 1 (高階 API): pony_env\test_model_v1.py...
set "PY1=!ENV_DIR!\test_model_v1.py"
echo from ponychart_classifier import ^( > "!PY1!"
echo     clear_artifacts, >> "!PY1!"
echo     predict, >> "!PY1!"
echo     preload, >> "!PY1!"
echo     update, >> "!PY1!"
echo     get_thresholds, >> "!PY1!"
echo ^) >> "!PY1!"
echo from ponychart_classifier import PonyChartClassifier, PredictionResult, ClassThresholds >> "!PY1!"
echo preload^(^) >> "!PY1!"
echo update^(^) >> "!PY1!"
echo result = predict^('path/to/image.png'^) >> "!PY1!"
echo print^("V1 Results:", result.labels^) >> "!PY1!"

echo.
echo [5/5] 建立測試程式 2 (物件導向): pony_env\test_model_v2.py...
set "PY2=!ENV_DIR!\test_model_v2.py"
echo from ponychart_classifier import PonyChartClassifier > "!PY2!"
echo classifier = PonyChartClassifier^( >> "!PY2!"
echo     model_path="artifacts/model.onnx", >> "!PY2!"
echo     thresholds_path="artifacts/thresholds.json", >> "!PY2!"
echo ^) >> "!PY2!"
echo result = classifier.predict^("path/to/image.png", min_k=1, max_k=3^) >> "!PY2!"
echo print^("V2 Results:", result.labels^) >> "!PY2!"

echo.
echo ==========================================================
echo [成功] 環境建立與 2 個測試腳本產出完畢！
echo ==========================================================
echo.
echo ==========================================================
echo [測試檔說明與重要提醒]
echo.
echo 【腳本 1: test_model_v1.py (高階 API)】
echo - 特色：會「自動」從網路下載最新模型，適合快速測試。
echo - 提醒：請記得修改程式碼中的 'path/to/image.png'。
echo.
echo 【腳本 2: test_model_v2.py (物件導向 API)】
echo - 特色：更靈活，可設定預測數量限制 (如: min_k=1, max_k=3)
echo         與自訂模型檔案的路徑。
echo - 提醒 1：請記得修改程式碼中的 'path/to/image.png'。
echo - 提醒 2：這個版本「不會」自動下載模型！
echo           執行前請務必確保當前目錄下有一個名為 artifacts 的資料夾，
echo           並將 model.onnx 與 thresholds.json 放入其中，
echo           否則會發生找不到檔案的錯誤 (FileNotFoundError)。
echo ==========================================================
echo.
echo [執行指令 (請複製貼上執行)]
echo V1: .\pony_env\Scripts\python.exe .\pony_env\test_model_v1.py
echo V2: .\pony_env\Scripts\python.exe .\pony_env\test_model_v2.py
echo ==========================================================
echo.
pause
exit /b 0

:error
echo.
echo ==========================================================
echo [中斷] 執行過程中發生錯誤，已停止執行，請查看上方錯誤訊息。
echo ==========================================================
pause
exit /b 1