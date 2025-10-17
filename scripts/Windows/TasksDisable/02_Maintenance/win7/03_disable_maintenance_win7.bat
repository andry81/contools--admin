@echo off

rem Description:
rem   Script disables maintenance tasks in Windows 7...

setlocal

call "%%~dp0..\__init__\__init__.bat"

rem script names call stack, disabled due to self call and partial inheritance (process elevation does not inherit a parent process variables by default)
rem if defined ?~ ( set "?~=%?~%-^>%~nx0" ) else if defined ?~nx0 ( set "?~=%?~nx0%-^>%~nx0" ) else set "?~=%~nx0"
set "?~=%~nx0"

if 0%IMPL_MODE% NEQ 0 goto IMPL
set "PSEXEC=%CONTOOLS_SYSINTERNALS_ROOT%/psexec.exe"
"%CONTOOLS_TOOL_ADAPTORS_ROOT%/hta/cmd_admin_system.bat" /c @set "IMPL_MODE=1" ^& "%~f0" %*
exit /b

:IMPL
call "%%CONTOOLS_ROOT%%/std/is_system_elevated.bat" || (
  echo;%?~%: error: process must be System account elevated to continue.
  exit /b 255
) >&2

rem detect date year ending format in `control.exe intl.cpl` because of different `/SD` parameter format in `schtasks /change /?`
set DATE_YEAR_FORMAT_LEFT=1
(
  reg query "HKCU\Control Panel\International" /v sShortDate | findstr /L /C:"sShortDate" | findstr /R /C:"[-/]yy"
) >nul && set DATE_YEAR_FORMAT_LEFT=0

call :CMD schtasks /Change /tn "\Microsoft\Windows\AppID\VerifiedPublisherCertStoreCheck" /Disable

call :CMD schtasks /Change /tn "\Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector" /Disable
call :CMD schtasks /Change /tn "\Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticResolver" /Disable

call :CMD schtasks /Change /tn "\Microsoft\Windows\Maintenance\WinSAT" /Disable

call :CMD schtasks /Change /tn "\Microsoft\Windows\PerfTrack\BackgroundConfigSurveyor" /Disable

rem call :CMD schtasks /Change /tn "\Microsoft\Windows\Shell\IndexerAutomaticMaintenance" /Disable

rem call :CMD schtasks /Change /tn "\Microsoft\Windows\SkyDrive\Routine Maintenance Task" /Disable

rem saw a reenable by WUS, update the trigger time instead
if %DATE_YEAR_FORMAT_LEFT% NEQ 0 (
  call :CMD schtasks /Change /tn "\Microsoft\Windows\SoftwareProtectionPlatform\SvcRestartTask" /SD 3000/01/01
) else call :CMD schtasks /Change /tn "\Microsoft\Windows\SoftwareProtectionPlatform\SvcRestartTask" /SD 01/01/3000

rem call :CMD schtasks /Change /tn "\Microsoft\Windows\SoftwareProtectionPlatform\SvcRestartTaskLogon" /Disable
rem call :CMD schtasks /Change /tn "\Microsoft\Windows\SoftwareProtectionPlatform\SvcRestartTaskNetwork" /Disable

rem call :CMD schtasks /Change /tn "\Microsoft\Windows\Work Folders\Work Folders Logon Synchronization" /Disable
rem call :CMD schtasks /Change /tn "\Microsoft\Windows\Work Folders\Work Folders Maintenance Work" /Disable

rem call :CMD schtasks /Change /tn "\Microsoft\Windows\WS\WSTask" /Disable

rem Annoying attempts to remove a Language Pack on each boot consuming drive space.
rem Details: https://www.techguy.org/threads/solved-can-i-safely-delete-the-tons-of-lpksetup-files-in-my-temp-folder.719411/
rem
call :CMD schtasks /Change /tn "\Microsoft\Windows\MUI\Lpksetup" /Disable

echo;

pause

exit /b

:CMD
echo;^>%*
(
  %*
)
