@echo off

rem USAGE:
rem   save-credential-manager.bat

setlocal DISABLEDELAYEDEXPANSION

rem script names call stack, disabled due to self call and partial inheritance (process elevation does not inherit a parent process variables by default)
rem if defined ?~ ( set "?~=%?~%-^>%~nx0" ) else if defined ?~nx0 ( set "?~=%?~nx0%-^>%~nx0" ) else set "?~=%~nx0"
set "?~=%~nx0"

set "?~dp0=%~dp0"
set "?~n0=%~n0"

where "powershell.exe" || (
  echo.%?~%: error: `powershell.exe` is not found.
  exit /b 255
) >&2

set "PS_SCRIPT_FILE=%?~dp0%%?~n0%.ps1"

rem parameters escape
set "PS_SCRIPT_FILE=%PS_SCRIPT_FILE:'=''%"

call :CMD powershell.exe "& "'"%PS_SCRIPT_FILE%"'""
exit /b

:CMD
echo.^>%*
echo.
(
  %*
)
