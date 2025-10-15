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
    set "firmware=%firmware_type%" 
    if /I "%firmware%"=="UEFI" (
       echo Operating system is already running in UEFI mode.
       goto :EOF
    )
    echo Firmware Type: %firmware%
    echo.

:: +---------------------------------------------------+
:: ! Check Partition Count                             !
:: +---------------------------------------------------+
    for /f "skip=1 tokens=2 delims==" %%A in ('wmic diskdrive get partitions /value') do set partitions=%%A
    if "%partitions%"=="" set partitions=0
    if %partitions% GTR 3 echo Too many partitions detected (%partitions%). Conversion not recommended.
    if %partitions% GTR 3 echo Conversion requires 3 or fewer partitions.
    if %partitions% GTR 3 goto :EOF
    
    echo Partition Count: %partitions%
    echo.

:: +---------------------------------------------------+
:: ! Validate MBR2GPT Conversion                       !
:: +---------------------------------------------------+
    mbr2gpt /validate /allowfullos | find /i "MBR2GPT: Validation completed successfully" >nul
    if errorlevel 1 Set "MBR2GPTFailed=1"
	if "%MBR2GPTFailed%" NEQ "" echo MBR2GPT failed to validate for UEFI. Conversion cannot continue.
    if "%MBR2GPTFailed%" NEQ "" goto :EOF
    
    echo Validation successful.
    echo.

:: +---------------------------------------------------+
:: ! Check Windows Recovery Environment (WinRE)        !
:: +---------------------------------------------------+
    for /f "tokens=2 delims=:" %%A in ('reagentc /info ^| find /i "Windows RE status"') do set restatus=%%A
    set restatus=%restatus: =%
    if /I "%restatus%"=="Disabled" echo Windows Recovery Environment is disabled.
    if /I "%restatus%"=="Disabled" echo It is recommended to enable before conversion.
    if /I "%restatus%"=="Disabled" echo To enable: reagentc /enable
    if /I "%restatus%"=="Disabled" echo.
    if /I "%restatus%"=="Disabled" goto :EOF
    
	echo Windows RE status: %restatus%
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
	for /f "delims=" %%A in ('powershell -command "Get-Disk"') do set GetDisk=%%A
	echo %GetDisk% | Find "GPT"
    if errorlevel 1 Set "DiskMBR=1"
    if "%DiskMBR%" NEQ "" echo Disk is still MBR. Conversion did not succeed.
    if "%DiskMBR%" NEQ "" goto :EOF
    
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
