
:: +------------------------------------------------------------------------------------+
:: ! Script Name: Restore-PreviousUserLogin.bat                                         !
:: ! Description:                                                                       !
:: !   Restores the last logged-on user information in Windows after an IT Admin        !
:: !   does their work. The script retrieves the Default Domain and Username from       !
:: !   the Winlogon registry keys, clears any current LogonUI session data, and         !
:: !   resets the "LastLoggedOnUser" and "LastLoggedOnSAMUser" registry values          !
:: !   so the previous employee's username automatically appears at the Windows         !
:: !   login screen.                                                                    !
:: !                                                                                    !
:: ! Purpose:                                                                           !
:: !   When an IT Admin logs into a computer to perform work, Windows replaces          !
:: !   the login prompt with that admin account. Running this script reverts the        !
:: !   login screen back to show the employee's username, eliminating the need          !
:: !   for the employee to click "Other User" and manually enter their credentials.     !
:: !                                                                                    !
:: ! Example Use Case:                                                                  !
:: !   1. IT Admin logs in as Contoso\Administrator to perform work.                    !
:: !   2. After the IT Admin completes their work, run Restore-PreviousUserLogin.bat.   !
:: !   3. IT Admin logs out.                                                            !
:: !   4. The Windows login screen will now display the employee's username.            !
:: +------------------------------------------------------------------------------------+

:: +------------------------------------------+
:: ! Script Starts                            !
:: +------------------------------------------+
    @echo off
    cls
    echo Restoring last logged-on user...
    echo.

:: +------------------------------------------+
:: ! Registry paths                           !
:: +------------------------------------------+
    set "WinlogonPath=HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
    set "LogonUIPath=HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Authentication\LogonUI"

:: +------------------------------------------+
:: ! Retrieve DefaultDomainName               !
:: +------------------------------------------+
    for /f "tokens=3" %%i in ('reg query "%WinlogonPath%" /v DefaultDomainName 2^>nul') do set "DefaultDomainName=%%i"

:: +------------------------------------------+
:: ! Retrieve DefaultUserName                 !
:: +------------------------------------------+
    for /f "tokens=3" %%i in ('reg query "%WinlogonPath%" /v DefaultUserName 2^>nul') do set "DefaultUser=%%i"

:: +------------------------------------------+
:: ! Fallbacks                                !
:: +------------------------------------------+
    if not defined DefaultDomainName set "DefaultDomainName=%COMPUTERNAME%"
    if not defined DefaultUser echo [ERROR] Could not read DefaultUserName from registry.
    if not defined DefaultUser exit /b 1

:: +------------------------------------------+
:: ! Combine                                  !
:: +------------------------------------------+
    set "FullUser=%DefaultDomainName%\%DefaultUser%"
    echo Resetting last logged-on username to "%FullUser%"
    echo.

:: +------------------------------------------+
:: ! Clear current login info                 !
:: +------------------------------------------+
    reg delete "%LogonUIPath%" /v LastLoggedOnUserSID /f >nul 2>nul
    reg delete "%LogonUIPath%" /v LastLoggedOnDisplayName /f >nul 2>nul

:: +------------------------------------------+
:: ! Set the previous user                    !
:: +------------------------------------------+
    reg add "%LogonUIPath%" /v LastLoggedOnUser /d "%FullUser%" /f >nul
    reg add "%LogonUIPath%" /v LastLoggedOnSAMUser /d "%FullUser%" /f >nul

:: +------------------------------------------+
:: ! Verify success                           !
:: +------------------------------------------+
    reg query "%LogonUIPath%" /v LastLoggedOnUser | find "%FullUser%" >nul
    if %errorlevel%==0 (
        echo Successfully restored "%FullUser%" as last logged-on user.
    ) else (
        echo [ERROR] Failed to update last logged-on user.
    )
