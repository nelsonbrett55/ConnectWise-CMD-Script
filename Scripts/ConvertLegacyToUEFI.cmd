  echo off
  cls
  
  :: +------------------------------------------------------------------------------------+
  :: ! Script Name: ConvertLegacyToUEFI.cmd                                               !
  :: ! Github URL:  https://github.com/nelsonbrett55/ConnectWise-CMD-Script               !
  :: ! Description:                                                                       !
  :: !   Checks if the system is in Legacy BIOS mode, validates compatibility,            !
  :: !   and converts the system disk from MBR to GPT for UEFI boot.                      !
  :: !                                                                                    !
  :: !                                                                                    !
  :: !                                                                                    !
  :: !                                                                                    !
  :: !                                                                                    !
  :: ! Purpose:                                                                           !
  :: !   Automate safe conversion from Legacy BIOS (MBR) to UEFI (GPT).                   !
  :: !                                                                                    !
  :: !                                                                                    !
  :: !                                                                                    !
  :: !                                                                                    !
  :: ! Example Use Case:                                                                  !
  :: !   Use when preparing systems for Windows 11 upgrade or Secure Boot deployment.     !
  :: !                                                                                    !
  :: !                                                                                    !
  :: !                                                                                    !
  :: !                                                                                    !
  :: !                                                                                    !
  :: !                                                                                    !
  :: !                                                                                    !
  :: +------------------------------------------------------------------------------------+

echo ===================================================
echo           CHANGE BIOS FROM LEGACY TO UEFI
echo ===================================================
echo.

:: +---------------------------------------------------+
:: ! Check if BIOS is already UEFI                     !
:: +---------------------------------------------------+
    for /f "delims=" %%A in ('powershell -command "$env:firmware_type"') do set firmware=%%A
    if /I "%firmware%"=="UEFI" (
       echo Operating system is already running in UEFI mode.
       goto :EOF
    )
    echo Firmware Type: %firmware%
    echo.

:: +---------------------------------------------------+
:: ! Check Partition Count                             !
:: +---------------------------------------------------+
    for /f "skip=1 tokens=2 delims==" %%A in ('wmic diskdrive get partitions /value ^| find "="') do set partitions=%%A
    if "%partitions%"=="" set partitions=0
    if %partitions% GTR 3 (
        echo Too many partitions detected (%partitions%). Conversion not recommended.
        echo Conversion requires 3 or fewer partitions.
        goto :EOF
    )
    echo Partition Count: %partitions%
    echo.

:: +---------------------------------------------------+
:: ! Validate MBR2GPT Conversion                       !
:: +---------------------------------------------------+
    mbr2gpt /validate /allowfullos | find /i "MBR2GPT: Validation completed successfully" >nul
    if errorlevel 1 (
        echo MBR2GPT failed to validate for UEFI. Conversion cannot continue.
        goto :EOF
    )
    echo Validation successful.
    echo.

:: +---------------------------------------------------+
:: ! Check Windows Recovery Environment (WinRE)        !
:: +---------------------------------------------------+
    for /f "tokens=2 delims=:" %%A in ('reagentc /info ^| find /i "Windows RE status"') do set restatus=%%A
    set restatus=%restatus: =%
    if /I "%restatus%"=="Disabled" (
        echo Windows Recovery Environment is disabled.
        echo It is recommended to enable before conversion.
        echo To enable: reagentc /enable
        echo.
    ) else (
        echo Windows RE status: %restatus%
    )
    echo.

:: +---------------------------------------------------+
:: ! Convert to GPT                                    !
:: +---------------------------------------------------+
    mbr2gpt /convert /allowfullos
    if errorlevel 1 (
        echo Conversion failed. Please review the log above.
        goto :EOF
    )
    echo Conversion completed successfully.
    echo.

:: +---------------------------------------------------+
:: ! Verify Conversion Result                          !
:: +---------------------------------------------------+
    wmic diskdrive get PartitionStyle | find /i "GPT" >nul
    if errorlevel 1 (
        echo Disk is still MBR. Conversion did not succeed.
        goto :EOF
    )
    echo Disk partition style is now GPT.
    echo.

:: +---------------------------------------------------+
:: ! Final Instructions                                !
:: +---------------------------------------------------+
echo ---------------------------------------------------
echo Conversion Complete! Next steps:
echo.
echo.  1. Reboot and enter BIOS/UEFI Setup.
echo.  2. Change Boot Mode from Legacy to UEFI.
echo.  3. Save and exit BIOS.
echo.  4. Windows should boot normally under UEFI mode.
echo ---------------------------------------------------

echo.
echo ===================================================
