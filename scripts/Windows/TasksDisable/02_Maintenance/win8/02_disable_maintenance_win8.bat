@echo off

rem Description:
rem   Script disables maintenance tasks in Windows 8...
rem
rem   Based on:
rem     https://serverfault.com/questions/866336/do-i-need-to-disable-tiworker-exe-and-respective-tasksheduler-task-in-windows-se

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

call :CMD schtasks /Change /tn "\Microsoft\Windows\TaskScheduler\Idle Maintenance" /Disable
call :CMD schtasks /Change /tn "\Microsoft\Windows\TaskScheduler\Maintenance Configurator" /Disable
call :CMD schtasks /Change /tn "\Microsoft\Windows\TaskScheduler\Manual Maintenance" /Disable
call :CMD schtasks /Change /tn "\Microsoft\Windows\TaskScheduler\Regular Maintenance" /Disable

call :CMD "%%SystemRoot%%\System32\reg.exe" add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\Maintenance" /v MaintenanceDisabled /t REG_DWORD /d 1 /f

echo;

pause

exit /b

:CMD
echo;^>%*
(
  %*
)
