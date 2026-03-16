@echo off
title ROG Ally Optimizer
cd /d "%~dp0"

echo.
echo  Starting ROG Ally Optimizer...
echo.

:: Unlock PowerShell scripts for this user (fixes "execution policy" block)
powershell.exe -NoProfile -Command "Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope CurrentUser -Force" >nul 2>&1

:: Try PowerShell 7 first (better), fall back to built-in PowerShell 5
set PS7="C:\Program Files\PowerShell\7\pwsh.exe"
set PS5=powershell.exe

if exist %PS7% (
    echo  Using PowerShell 7...
    %PS7% -NoProfile -ExecutionPolicy Bypass -File "%~dp0ROGAllyOptimizer.ps1"
) else (
    echo  Using PowerShell 5...
    %PS5% -NoProfile -ExecutionPolicy Bypass -File "%~dp0ROGAllyOptimizer.ps1"
)

:: If we get here something went wrong - keep window open
if errorlevel 1 (
    echo.
    echo  ============================================
    echo  ERROR: The app failed to start.
    echo  ============================================
    echo.
    echo  Take a photo of this screen and share it.
    echo.
    pause
)
