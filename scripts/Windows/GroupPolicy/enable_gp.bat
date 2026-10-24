@echo off & goto DOC_END

rem Description:
rem   Script to enable GroupPolicy in Windows 7/8 Home and Single Language
rem   editions.
:DOC_END

setlocal

call "%%~dp0..\__init__\__init__.bat" || exit /b

rem script names call stack, disabled due to self call and partial inheritance (process elevation does not inherit a parent process variables by default)
rem if defined ?~ ( set "?~=%?~%-^>%~nx0" ) else if defined ?~nx0 ( set "?~=%?~nx0%-^>%~nx0" ) else set "?~=%~nx0"
set "?~=%~nx0"

if 0%IMPL_MODE% NEQ 0 goto IMPL
"%USERBIN_SCRIPTS_BAT_ROOT%/runas/hta/cmd-admin.bat" /c @set "IMPL_MODE=1" ^& "%~f0" %*
exit /b

:IMPL
call "%%CONTOOLS_ROOT%%/std/is_admin_elevated.bat" || (
  echo;%?~%: error: process must be Administrator account elevated to continue.
  exit /b 255
) >&2

setlocal DISABLEDELAYEDEXPANSION

set "TEMP_DIR=%TEMP%\%~n0.%RANDOM%-%RANDOM%"

mkdir "%TEMP_DIR%"

(
  dir "%SystemRoot%\servicing\Packages\Microsoft-Windows-GroupPolicy-ClientExtensions-Package~3*.mum" /A:-D /B /O:N
  rem Windows 7
  dir "%SystemRoot%\servicing\Packages\Microsoft-Windows-GroupPolicy-ClientTools-Package~3*.mum" /A:-D /B /O:N
  rem Windows 8
  dir "%SystemRoot%\servicing\Packages\Microsoft-Windows-GroupPolicy-ClientTools-Package-windows~3*.mum" /A:-D /B /O:N
) > "%TEMP_DIR%\packages.lst"

for /F "usebackq tokens=* delims="eol^= %%i in (`@"%%SystemRoot%%\System32\findstr.exe" /I . "%%TEMP_DIR%%\packages.lst" 2^>nul`) do ^
call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/call_.bat" dism /online /norestart /add-package:"%%SystemRoot%%\servicing\Packages\%%i"

rmdir /S /Q "%TEMP_DIR%"

pause
