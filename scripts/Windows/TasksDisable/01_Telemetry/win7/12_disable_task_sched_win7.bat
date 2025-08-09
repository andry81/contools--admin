@echo off

rem Description:
rem   Script disables telemetry tasks in Windows 7...

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

call :CMD schtasks /Change /tn "\Microsoft\Windows\Active Directory Rights Management Services Client\AD RMS Rights Policy Template Management (Automated)" /Disable
call :CMD schtasks /Change /tn "\Microsoft\Windows\Active Directory Rights Management Services Client\AD RMS Rights Policy Template Management (Manual)" /Disable

call :CMD schtasks /Change /tn "\Microsoft\Windows\AppID\SmartScreenSpecific" /Disable

call :CMD schtasks /Change /tn "\Microsoft\Windows\Autochk\Proxy" /Disable

call :CMD schtasks /Change /tn "\Microsoft\Windows\Location\Notifications" /Disable

call :CMD schtasks /Change /tn "\Microsoft\Windows\NetTrace\GatherNetworkInfo" /Disable

call :CMD schtasks /Change /tn "\Microsoft\Windows\RemoteAssistance\RemoteAssistanceTask" /Disable

rem call :CMD schtasks /Change /tn "\Microsoft\Windows\SettingSync\BackgroundUploadTask" /Disable
rem call :CMD schtasks /Change /tn "\Microsoft\Windows\SettingSync\BackupTask" /Disable
rem call :CMD schtasks /Change /tn "\Microsoft\Windows\SettingSync\NetworkStateChangeTask" /Disable

call :CMD schtasks /Change /tn "\Microsoft\Windows\Setup\EOSNotify" /Disable
call :CMD schtasks /Change /tn "\Microsoft\Windows\Setup\EOSNotify2" /Disable

call :CMD schtasks /Change /tn "\Microsoft\Windows\Shell\WindowsParentalControls/Disable
call :CMD schtasks /Change /tn "\Microsoft\Windows\Shell\WindowsParentalControlsMigration" /Disable

rem call :CMD schtasks /Change /tn "\Microsoft\Windows\SkyDrive\Idle Sync Maintenance Task" /Disable

rem call :CMD schtasks /Change /tn "\Microsoft\Windows\Time Synchronization\ForceSynchronizeTime" /Disable
call :CMD schtasks /Change /tn "\Microsoft\Windows\Time Synchronization\SynchronizeTime" /Disable

rem call :CMD schtasks /Change /tn "\Microsoft\Windows\Time Zone\SynchronizeTimeZone" /Disable

call :CMD schtasks /Change /tn "\Microsoft\Windows\User Profile Service\HiveUploadTask" /Disable

call :CMD schtasks /Change /tn "\Microsoft\Windows\Windows Media Sharing\UpdateLibrary" /Disable

rem call :CMD schtasks /Change /tn "\Microsoft\Windows\WS\Badge Update" /Disable
rem call :CMD schtasks /Change /tn "\Microsoft\Windows\WS\License Validation" /Disable
rem call :CMD schtasks /Change /tn "\Microsoft\Windows\WS\Sync Licenses" /Disable
rem call :CMD schtasks /Change /tn "\Microsoft\Windows\WS\WSRefreshBannedAppsListTask" /Disable

echo;

pause

exit /b

:CMD
echo;^>%*
(
  %*
)
