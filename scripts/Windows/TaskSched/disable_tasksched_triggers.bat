@echo off

setlocal

call "%%~dp0..\__init__\__init__.bat"

rem script names call stack, disabled due to self call and partial inheritance (process elevation does not inherit a parent process variables by default)
rem if defined ?~ ( set "?~=%?~%-^>%~nx0" ) else if defined ?~nx0 ( set "?~=%?~nx0%-^>%~nx0" ) else set "?~=%~nx0"
set "?~=%~nx0"

if 0%IMPL_MODE% NEQ 0 goto IMPL
set "PSEXEC=%CONTOOLS_ADMIN_PROJECT_EXTERNALS_ROOT%/sysinternals/psexec.exe"
"%USERBIN_SCRIPTS_BAT_ROOT%/runas/hta/cmd-admin-system.bat" /c @set "IMPL_MODE=1" ^& "%~f0" %*
exit /b

:IMPL
call "%%CONTOOLS_ROOT%%/std/is_system_elevated.bat" || (
  echo;%?~%: error: process must be System account elevated to continue.
  exit /b 255
) >&2

"%SystemRoot%\System32\cscript.exe" //nologo "%~dpn0.vbs" %*

pause
