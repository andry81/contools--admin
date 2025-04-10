@echo off

rem Example:
rem   newcred.bat git:https://github.com USER PASS Enterprise
rem   newcred.bat git:https://USER@github.com USER PASS LocalMachine

setlocal

rem script names call stack, disabled due to self call and partial inheritance (process elevation does not inherit a parent process variables by default)
rem if defined ?~ ( set "?~=%?~%-^>%~nx0" ) else if defined ?~nx0 ( set "?~=%?~nx0%-^>%~nx0" ) else set "?~=%~nx0"
set "?~=%~nx0"

call :IS_ADMIN_ELEVATED && goto MAIN

(
  echo.%?~%: error: process must be elevated before continue.
  exit /b 255
) >&2

rem CAUTIOM:
rem   Windows 7 has an issue around the `find.exe` utility and code page 65001.
rem   We use `findstr.exe` instead of `find.exe` to workaround it.
rem
rem   Based on: https://superuser.com/questions/557387/pipe-not-working-in-cmd-exe-on-windows-7/1869422#1869422

:IS_ADMIN_ELEVATED
if exist "%SystemRoot%\System32\whoami.exe" "%SystemRoot%\System32\whoami.exe" /groups | "%SystemRoot%\System32\findstr.exe" /L "S-1-16-12288" >nul 2>nul & exit /b
if exist "%SystemRoot%\System32\fltmc.exe" "%SystemRoot%\System32\fltmc.exe" >nul 2>nul & exit /b
if exist "%SystemRoot%\System64\openfiles.exe" "%SystemRoot%\System64\openfiles.exe" >nul 2>nul & exit /b
if exist "%SystemRoot%\System32\openfiles.exe" "%SystemRoot%\System32\openfiles.exe" >nul 2>nul & exit /b
if exist "%SystemRoot%\System32\config\system" exit /b 0
exit /b 255

:MAIN
where "powershell.exe" || (
  echo.%?~%: error: `powershell.exe` is not found.
  exit /b 255
) >&2

set "TARGET=%~1"
set "USER=%~2"
set "PASS=%~3"
set "PERSIST=%~4"

powershell.exe -NoLogo -Command "& {New-StoredCredential -Target "'"%TARGET:'=''%"'" -UserName "'"%USER:'=''%"'" -Password "'"%PASS:'=''%"'" -Persist "'"%PERSIST:'=''%"'"}"
