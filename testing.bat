@echo off
setlocal

echo ============================================
echo   Network Diagnostic Tool - Full Check
echo ============================================

:: [1] Detect active NICs
echo.
echo [1] Network Interfaces (enabled):
wmic nic where "NetEnabled=TRUE" get Name
for /f %%C in ('wmic nic where "NetEnabled=TRUE" get Name /format:list ^| find /c "Name="') do set NICCOUNT=%%C
if "%NICCOUNT%"=="0" (
    call :ce "FAILED: No active network interfaces detected" Red
) else (
    call :ce "SUCCESS: Active network interfaces detected" Green
)

:: [2] TCP/IP configuration present (has an IP)
echo.
echo [2] TCP/IP configuration:
ipconfig /all
set "HASIP=0"
for /f "tokens=2 delims==" %%A in ('wmic nicconfig where "IPEnabled=TRUE" get IPAddress /value ^| find "="') do set "HASIP=1"
if "%HASIP%"=="1" (
    call :ce "SUCCESS: TCP/IP configured (IP assigned)" Green
) else (
    call :ce "FAILED: No IPv4/IPv6 address assigned" Red
)

:: [3] Default gateway detection and reachability
echo.
echo [3] Default Gateway:
set "GATEWAY="
for /f "tokens=2 delims==" %%G in ('wmic nicconfig where "IPEnabled=TRUE" get DefaultIPGateway /value ^| find "="') do set "GATEWAY=%%G"
if defined GATEWAY (
    echo Default Gateway raw: %GATEWAY%
    :: Extract first IP from array-like output {x.x.x.x, y.y.y.y}
    for /f "tokens=1 delims=,{} " %%H in ("%GATEWAY%") do set "GWIP=%%H"
    echo Default Gateway IP: %GWIP%
    call :ce "SUCCESS: Default gateway detected" Green

    ping -n 2 %GWIP% >nul
    if errorlevel 1 (
        call :ce "FAILED: Gateway unreachable (%GWIP%)" Red
    ) else (
        call :ce "SUCCESS: Gateway reachable (%GWIP%)" Green
    )
) else (
    call :ce "FAILED: No default gateway found" Red
)

:: [4] Internet connectivity (ping 8.8.8.8)
echo.
echo [4] Internet Connectivity:
ping -n 2 8.8.8.8 >nul
if errorlevel 1 (
    call :ce "FAILED: Internet check - 8.8.8.8 unreachable" Red
) else (
    call :ce "SUCCESS: Internet connectivity OK (8.8.8.8 reachable)" Green
)

echo.
echo ============================================
echo   Diagnostics Completed
echo ============================================
pause
goto :eof

:: Colored echo helper using PowerShell
:ce
set "MSG=%~1"
set "CLR=%~2"
powershell -NoProfile -Command "Write-Host '%MSG%' -ForegroundColor %CLR%"
goto :eof
