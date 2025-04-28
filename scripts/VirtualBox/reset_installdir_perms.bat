@echo off

rem USAGE:
rem   reset_installdir_perms.bat [<flags>] [--] <INSTALLDIR>

rem Description:
rem   Resets the INSTALLDIR directory permissions for inner files and
rem   directories. Includes directory permissions above the INSTALLDIR
rem   directory.
rem
rem   Works for the VirtualBox setup executable version 7.0.14 and lower.
rem

rem <flags>:
rem   -r
rem     Reset INSTALLDIR with recursion.
rem     By default has no recursion, because INSTALLDIR may not exist after
rem     uninstall AND the parent directory permissions may not let you create
rem     it. So you can call the script at least on the parent directory.

rem CAUTION:
rem   1. INSTALLDIR must be the end installation directory, otherwise the permissions would be overwritten everythere!
rem   2. You must create the end installation directory if does not exist and run the script on it.
rem

setlocal DISABLEDELAYEDEXPANSION

rem script names call stack, disabled due to self call and partial inheritance (process elevation does not inherit a parent process variables by default)
rem if defined ?~ ( set "?~=%?~%-^>%~nx0" ) else if defined ?~nx0 ( set "?~=%?~nx0%-^>%~nx0" ) else set "?~=%~nx0"
set "?~=%~nx0"

set "?~f0=%~f0"

set /A ELEVATED+=0

rem script flags
set FLAG_SHIFT=0
set FLAG_RECUR=0

:FLAGS_LOOP

rem flags always at first
set "FLAG=%~1"

if defined FLAG ^
if not "%FLAG:~0,1%" == "-" set "FLAG="

if defined FLAG (
  if "%FLAG%" == "-r" (
    set FLAG_RECUR=1
  ) else if not "%FLAG%" == "--" (
    echo;%?~%: error: invalid flag: %FLAG%
    exit /b -255
  ) >&2

  shift
  set /A FLAG_SHIFT+=1

  rem read until no flags
  if not "%FLAG%" == "--" goto FLAGS_LOOP
)

if %IMPL_MODE%0 NEQ 0 goto IMPL
call :IS_ADMIN_ELEVATED && goto ELEVATED

goto ELEVATE

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

:ELEVATE
rem Based on:
rem   `Uniform variant of a command line as a single argument for the `mshta.exe` executable and other cases` :
rem   https://github.com/andry81/contools/discussions/11

rem CAUTION:
rem   The `cd "%CD%" ^& %CD:~0,2%` must be before the command, otherwise the system root will be the current directory!
rem

rem Windows Batch compatible command line with escapes (`\""` is a single nested `"`, `\""""` is a double nested `"` and so on).
set ?.=set "IMPL_MODE=1" ^& cd "%CD%" ^& %CD:~0,2% ^& "%?~f0%" %* ^& pause

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

set "INSTALLDIR=%~1"

if not defined INSTALLDIR set INSTALLDIR=.

for /F "tokens=* delims="eol^= %%i in ("%INSTALLDIR%\.") do set "INSTALLDIR=%%~fi"

if not exist "%INSTALLDIR%" (
  echo;%~nx0: error: installation directory does not exits: "%INSTALLDIR%".
  exit /b 255
) >&2

for /F "tokens=1,* delims=\" %%i in ("%INSTALLDIR%") do set "INSTALLDIR_PREFIX=%%i" & set "INSTALLDIR_SUFFIX=%%j"

if not defined INSTALLDIR_SUFFIX (
  echo;%~nx0: error: installation directory must be not a drive root: "%INSTALLDIR%".
  exit /b 255
) >&2

:LOOP
for /F "tokens=1,* delims=\" %%i in ("%INSTALLDIR_SUFFIX%") do set "INSTALLDIR_PREFIX=%INSTALLDIR_PREFIX%\%%i" & set "INSTALLDIR_SUFFIX=%%j"

setlocal ENABLEDELAYEDEXPANSION & echo;^>!INSTALLDIR_PREFIX!& endlocal
echo;

if defined INSTALLDIR_SUFFIX (
  rem not the end installation directory, without recursion
  call :CMD icacls "%INSTALLDIR_PREFIX%" /reset /c || exit /b
) else if %FLAG_RECUR% NEQ 0 (
  rem the end installation directory, with recursion
  call :CMD icacls "%INSTALLDIR_PREFIX%" /reset /t /c || exit /b
) else (
  rem not the end installation directory, without recursion
  call :CMD icacls "%INSTALLDIR_PREFIX%" /reset /c || exit /b
)

echo;

if not defined INSTALLDIR_SUFFIX exit /b 0

goto LOOP

:CMD
echo;^>%*
(
  %*
)
