@echo off
cd /d "%~dp0"
echo Start %date% %time% > start.log
set "PYEXE=%LOCALAPPDATA%\Programs\Python\Python312\python.exe"
if not exist "%PYEXE%" (
  echo Installiere Python 3.12 per winget >> start.log
  winget install --id Python.Python.3.12 -e --scope user --silent --accept-package-agreements --accept-source-agreements >> start.log 2>&1
)
if not exist "%PYEXE%" ( echo Python fehlt weiterhin >> start.log & exit /b 1 )
if not exist venv ( "%PYEXE%" -m venv venv >> start.log 2>&1 )
venv\Scripts\python.exe -m pip install -q -r requirements.txt >> start.log 2>&1
echo pip fertig >> start.log
venv\Scripts\python.exe app.py >> start.log 2>&1
