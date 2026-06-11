@echo off
:loop
echo Starting server...
node server.js
if %errorlevel% neq 0 (
    echo Server crashed. Restarting in 5 seconds...
    timeout /t 5 /nobreak >nul
    goto loop
)
