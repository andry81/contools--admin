@echo off

rem USAGE:
rem   read-junction-points.bat [<flags>] [//] <from-path> > <junction-list-file>

setlocal DISABLEDELAYEDEXPANSION

rem script flags
set "BARE_FLAGS="

:FLAGS_LOOP

rem flags always at first
set "FLAG=%~1"

if defined FLAG ^
if not "%FLAG:~0,1%" == "/" set "FLAG="

if defined FLAG (
  if not "%FLAG%" == "//" (
    set BARE_FLAGS=%BARE_FLAGS% %1
  )

  shift

  rem read until no flags
  if not "%FLAG%" == "//" goto FLAGS_LOOP
)

set "FROM_PATH=%~1"

if not defined FROM_PATH set "FROM_PATH=."

for /F "tokens=* delims="eol^= %%i in ("%FROM_PATH%\.") do set "FROM_PATH=%%~fi" & set "FROM_DRIVE=%%~di"

rem CAUTION:
rem   1. If a variable is empty, then it would not be expanded in the `cmd.exe`
rem      command line or in the inner expression of the
rem      `for /F "usebackq ..." %%i in (`<inner-expression>`) do ...`
rem      statement.
rem   2. The `cmd.exe` command line or the inner expression of the
rem      `for /F "usebackq ..." %%i in (`<inner-expression>`) do ...`
rem      statement does expand twice.
rem
rem   We must expand the command line into a variable to avoid these above.
rem
set ?.=@dir "%FROM_PATH%"%BARE_FLAGS% /A:L /O:N 2^>nul ^| "%SystemRoot%\System32\findstr.exe" /R /C:"[^ ][^ ]*  *[^ ][^ ]*  *\<JUNCTION\>" /C:"[^ ][^ ]*  *[^ ][^ ]*  *\<SYMLINKD\>" /C:"^ Directory of "

for /F "usebackq tokens=* delims="eol^= %%i in (`%%?.%%`) do set "LINE=%%i" & call :PROCESS_LINE
exit /b 0

:PROCESS_LINE
if not "%LINE:~0,14%" == " Directory of " goto PROCESS_DIR
set "FROM_DIR=%LINE:~14%"
if "%FROM_DIR:~-1%" == "\" set "FROM_DIR=%FROM_DIR:~0,-1%"
exit /b 0
:PROCESS_DIR
setlocal ENABLEDELAYEDEXPANSION & for /F "tokens=3,* delims= "eol^= %%i in ("!LINE!") do endlocal & set "LINE=%%j" & ^
setlocal ENABLEDELAYEDEXPANSION & for /F "tokens=1,* delims=:"eol^= %%i in ("!LINE!") do endlocal & set "LINK=%%i" & set "DIR=%%j" & ^
setlocal ENABLEDELAYEDEXPANSION & for /F "tokens=1,* delims=|"eol^= %%i in ("!FROM_DIR!\!LINK:~0,-3!|!LINK:~-1!:!DIR:~0,-1!") do endlocal & echo;%%i*%%j
