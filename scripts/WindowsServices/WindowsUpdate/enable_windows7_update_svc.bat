@echo off

setlocal DISABLEDELAYEDEXPANSION

rem script names call stack, disabled due to self call and partial inheritance (process elevation does not inherit a parent process variables by default)
rem if defined ?~ ( set "?~=%?~%-^>%~nx0" ) else if defined ?~nx0 ( set "?~=%?~nx0%-^>%~nx0" ) else set "?~=%~nx0"
set "?~=%~nx0"

set /A ELEVATED+=0

if %IMPL_MODE%0 NEQ 0 goto IMPL
call :IS_ADMIN_ELEVATED && goto ELEVATED

goto ELEVATE

rem CAUTIOM:
rem   Windows 7 has an issue around the `find.exe` utility and code page 65001.
rem   We use `findstr.exe` instead of `find.exe` to workaround it.
rem
rem   Based on: https://superuser.com/questions/557387/pipe-not-working-in-cmd-exe-on-windows-7/1869422#1869422

rem CAUTION:
rem   In Windowx XP an elevated call under data protection flag will block the wmic tool, so we have to use `ver` command instead!

:IS_ADMIN_ELEVATED
set "WINDOWS_VER_STR=" & set "WINDOWS_MAJOR_VER=0" & for /F "usebackq tokens=1,2,* delims=[]" %%i in (`@ver 2^>nul`) do set "WINDOWS_VER_STR=%%j"
if not defined WINDOWS_VER_STR goto SKIP_VER
setlocal ENABLEDELAYEDEXPANSION & for /F "usebackq tokens=* delims="eol^= %%i in ('"!WINDOWS_VER_STR:* =!"') do endlocal & set "WINDOWS_VER_STR=%%~i"
for /F "tokens=1,2,* delims=."eol^= %%i in ("%WINDOWS_VER_STR%") do set "WINDOWS_MAJOR_VER=%%i"
:SKIP_VER
if %WINDOWS_MAJOR_VER% GEQ 6 (
  if exist "%SystemRoot%\System32\where.exe" "%SystemRoot%\System32\whoami.exe" /groups | "%SystemRoot%\System32\findstr.exe" /L "S-1-16-12288" >nul 2>nul & exit /b
) else if exist "%SystemRoot%\System32\fltmc.exe" "%SystemRoot%\System32\fltmc.exe" >nul 2>nul & exit /b
exit /b 255

:ELEVATE
rem Based on:
rem   `Uniform variant of a command line as a single argument for the `mshta.exe` executable and other cases` :
rem   https://github.com/andry81/contools/discussions/11

rem Windows Batch compatible command line with escapes (`\""` is a single nested `"`, `\""""` is a double nested `"` and so on).
set ?.=set "IMPL_MODE=1" ^& "%~f0" %* ^& pause

rem translate Windows Batch compatible escapes into escape placeholders
setlocal ENABLEDELAYEDEXPANSION & for /F "tokens=* delims="eol^= %%i in ("!?.:$=$0!") do endlocal & set "?.=%%i"
setlocal ENABLEDELAYEDEXPANSION & for /F "tokens=* delims="eol^= %%i in ("!?.:\""""""""=$4!") do endlocal & set "?.=%%i"
setlocal ENABLEDELAYEDEXPANSION & for /F "tokens=* delims="eol^= %%i in ("!?.:\""""=$3!") do endlocal & set "?.=%%i"
setlocal ENABLEDELAYEDEXPANSION & for /F "tokens=* delims="eol^= %%i in ("!?.:\""=$2!") do endlocal & set "?.=%%i"
setlocal ENABLEDELAYEDEXPANSION & for /F "tokens=* delims="eol^= %%i in ("!?.:"^=$1!"") do endlocal & set "?.=%%i"
setlocal ENABLEDELAYEDEXPANSION & for /F "tokens=* delims="eol^= %%i in ("!?.:~0,-1!") do endlocal & set "?.=%%i"

rem translate escape placeholders into `mshta.exe` (vbs) escapes (`""` is a single nested `"`, `""""` is a double nested `"` and so on)
setlocal ENABLEDELAYEDEXPANSION & for /F "tokens=* delims="eol^= %%i in ("!?.:$4=""""""""""""""""""""""""""""""""!") do endlocal & set "?.=%%i"
setlocal ENABLEDELAYEDEXPANSION & for /F "tokens=* delims="eol^= %%i in ("!?.:$3=""""""""""""""""!") do endlocal & set "?.=%%i"
setlocal ENABLEDELAYEDEXPANSION & for /F "tokens=* delims="eol^= %%i in ("!?.:$2=""""""""!") do endlocal & set "?.=%%i"
setlocal ENABLEDELAYEDEXPANSION & for /F "tokens=* delims="eol^= %%i in ("!?.:$1=""""!") do endlocal & set "?.=%%i"
setlocal ENABLEDELAYEDEXPANSION & for /F "tokens=* delims="eol^= %%i in ("!?.:$0=$!") do endlocal & set "?.=%%i"

rem CAUTION: ShellExecute does not wait a child process close!
rem NOTE: `ExecuteGlobal` is used as a workaround, because the `mshta.exe` first argument must not be used with the surrounded quotes
start /B /WAIT "" "%SystemRoot%\System32\mshta.exe" vbscript:ExecuteGlobal("Close(CreateObject(""Shell.Application"").ShellExecute(""%COMSPEC%"", ""/c @%?.%"", """", ""runas"", 1))")
exit /b

:ELEVATED
set ELEVATED=1

:IMPL
if %ELEVATED% EQU 0 call :IS_ADMIN_ELEVATED || (
  echo;%?~%: error: process must be elevated before continue.
  exit /b 255
) >&2

rem Windows Update Service
echo;^>sc config wuauserv start= demand
sc config wuauserv start= demand
