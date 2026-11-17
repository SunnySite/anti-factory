@echo off
setlocal

REM Pindah ke root project (satu level di atas folder .agents)
cd /d "%~dp0.."

set "INTERVAL_SECONDS=300"

if "%~1"=="--once" (
    call :run_poll
    exit /b %ERRORLEVEL%
)

echo ==================================================
echo  Antigravity Headless Software Factory
echo  Project : %CD%
echo  Interval: %INTERVAL_SECONDS% detik (Ctrl+C untuk stop)
echo ==================================================

:loop
call :run_poll
echo.
echo [%DATE% %TIME%] Menunggu %INTERVAL_SECONDS% detik sebelum poll berikutnya...
timeout /t %INTERVAL_SECONDS% /nobreak >nul
goto :loop

:run_poll
echo [%DATE% %TIME%] Menjalankan factory-watcher...
agy -p "Run the factory-watcher skill against .agents/factory.config.json." --dangerously-skip-permissions
set "EXIT_CODE=%ERRORLEVEL%"
echo [%DATE% %TIME%] Selesai (exit code: %EXIT_CODE%).
exit /b %EXIT_CODE%
