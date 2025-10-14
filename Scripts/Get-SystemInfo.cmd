  echo off
  cls
  
  :: +------------------------------------------------------------------------------------+
  :: ! Script Name: Get-SystemInfo.cmd                                                    !
  :: ! Github URL:  https://github.com/nelsonbrett55/ConnectWise-CMD-Script               !
  :: ! Description:                                                                       !
  :: !   Collects detailed system information on a Windows computer. This includes        !
  :: !   computer name, domain, OS version, serial number, BIOS version, CPU,             !
  :: !   motherboard, installed RAM, GPU(s), disk drives, network adapters, last          !
  :: !   logged-on user, and local user accounts. The output is formatted for             !
  :: !   easy reading and suitable for MSP ConnectWise CMD scripts.                       !
  :: ! Purpose:                                                                           !
  :: !   To provide a comprehensive, quick snapshot of a system’s hardware and            !
  :: !   software configuration for IT administrators performing audits, support,         !
  :: !   or troubleshooting.                                                              !
  :: ! Example Use Case:                                                                  !
  :: !   1. IT Admin remotely logs into a client machine.                                 !
  :: !   2. Runs Get-SystemInfo.cmd to gather system details for documentation or         !
  :: !      troubleshooting.                                                              !
  :: !   3. The script outputs all information to the console in a clean, readable        !
  :: !      format.                                                                       !
  :: +------------------------------------------------------------------------------------+

echo ===================================================
echo              SYSTEM INFORMATION REPORT             
echo ===================================================
echo.

:: +---------------------------------------------------+
:: ! Temporary file                                    !
:: +---------------------------------------------------+
    set "tempFile=%TEMP%\SystemInfo.tmp"
    if exist "%tempFile%" del "%tempFile%"

:: +---------------------------------------------------+
:: ! Computer & OS                                     !
:: +---------------------------------------------------+
    echo [*] Computer Name:         %COMPUTERNAME% >> "%tempFile%"
    for /f "tokens=2 delims==" %%i in ('wmic computersystem get domain /value') do echo [*] Domain:                %%i >> "%tempFile%"
    systeminfo | findstr /B /C:"OS Name" /C:"OS Version" >> "%tempFile%"
    echo. >> "%tempFile%"

:: +---------------------------------------------------+
:: ! Serial Number & BIOS                              !
:: +---------------------------------------------------+
    for /f "tokens=2 delims==" %%i in ('wmic bios get serialnumber /value') do echo [*] Serial Number:         %%i >> "%tempFile%"
    for /f "tokens=2 delims==" %%i in ('wmic bios get smbiosbiosversion /value') do echo [*] BIOS Version:          %%i >> "%tempFile%"

:: +---------------------------------------------------+
:: ! CPU                                               !
:: +---------------------------------------------------+
    for /f "tokens=2 delims==" %%i in ('wmic cpu get name /value') do echo [*] CPU:                   %%i >> "%tempFile%"

:: +---------------------------------------------------+
:: ! Motherboard                                       !
:: +---------------------------------------------------+
    for /f "tokens=2 delims==" %%i in ('wmic baseboard get product /value') do echo [*] Motherboard:           %%i >> "%tempFile%"

:: +---------------------------------------------------+
:: ! RAM                                               !
:: +---------------------------------------------------+
    for /f "delims=" %%i in ('powershell -NoProfile -Command "(Get-CimInstance Win32_PhysicalMemory | Measure-Object -Property Capacity -Sum).Sum /1GB"') do echo [*] Installed RAM:         %%i GB >> "%tempFile%"

:: +---------------------------------------------------+
:: ! GPU                                               !
:: +---------------------------------------------------+
    echo [*] GPU(s): >> "%tempFile%"
    for /f "skip=1 tokens=*" %%G in ('wmic path win32_videocontroller get name') do (
        for /f "tokens=* delims= " %%T in ("%%G") do (
            if not "%%T"=="" echo                            %%T >> "%tempFile%"
        )
    )
    echo. >> "%tempFile%"

:: +---------------------------------------------------+
:: ! Disk Drives                                       !
:: +---------------------------------------------------+
    echo [*] Disk Drives: >> "%tempFile%"
    powershell -NoProfile -Command "Get-CimInstance Win32_LogicalDisk | ForEach-Object { '                           {0}: Free {1} GB / Total {2} GB' -f $_.DeviceID.TrimEnd(':',' '), [math]::Round($_.FreeSpace/1GB,2), [math]::Round($_.Size/1GB,2) }" >> "%tempFile%"

:: +---------------------------------------------------+
:: ! Network Adapters                                  !
:: +---------------------------------------------------+
    echo [*] Network Adapters: >> "%tempFile%"
    for /f "skip=1 tokens=*" %%N in ('wmic nic where "NetEnabled=true" get Name') do (
        for /f "tokens=* delims= " %%T in ("%%N") do (
            if not "%%T"=="" echo                            %%T >> "%tempFile%"
        )
    )
    echo. >> "%tempFile%"

:: +---------------------------------------------------+
:: ! Last Logged-On User                               !
:: +---------------------------------------------------+
    for /f "tokens=3" %%i in ('reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI" /v LastLoggedOnUser 2^>nul') do echo [*] Last Logged-On User:   %%i >> "%tempFile%"

:: +---------------------------------------------------+
:: ! Local Users                                       !
:: +---------------------------------------------------+
    echo [*] Local Users: >> "%tempFile%"
    for /f "skip=4 tokens=*" %%U in ('net user') do (
        set "line=%%U"
        setlocal enabledelayedexpansion
        if not "!line!"=="" (
            echo !line! | findstr /r /v "^----" | findstr /r /v "^The command" >nul
            if !errorlevel! == 0 (
                for %%L in (!line!) do echo                            %%L >> "%tempFile%"
            )
        )
        endlocal
    )

:: +---------------------------------------------------+
:: ! Output & Cleanup                                  !
:: +---------------------------------------------------+
    type "%tempFile%"
    del "%tempFile%" >nul

echo.
echo ===================================================
