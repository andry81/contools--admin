@echo off & goto DOC_END

rem USAGE:
rem   print_wevt_last_errors.bat [<flags>] [--]

rem Description:
rem   Print Event Log last (10 by default) `System` and `Application` errors
rem   and warnings.
rem   By default script prints for the current day only.

rem <flags>:
rem   -a
rem     Print for all the time.
rem
rem     Has no effect on the events quantity.
rem
rem     NOTE:
rem       To limit or increase the events quantity use `/c:N` bare option.
rem
rem   -long
rem     Print long output instead of short as by default.
rem
rem   -err
rem     Print errors only.
rem
rem   /<bare>
rem     Bare option for the `wevtutil.exe` utility.

rem Examples:
rem
rem   1. >print_wevt_last_errors.bat -err /c:100
:DOC_END

setlocal DISABLEDELAYEDEXPANSION

rem call "%%~dp0__init__/__init__.bat" %%0 %%* || exit /b

rem script flags
set FLAG_SHIFT=0
set FLAG_ALL_TIME=0
set FLAG_LONG=0
set FLAG_ERR=0
set FLAG_BARE_COUNT=0
set "FLAG_BARE="

:FLAGS_LOOP

rem flags always at first
set "FLAG=%~1"

if defined FLAG ^
if not "%FLAG:~0,1%" == "-" if not "%FLAG:~0,1%" == "/" set "FLAG="

if defined FLAG (
  if "%FLAG%" == "-a" (
    set FLAG_ALL_TIME=1
  ) else if "%FLAG%" == "-long" (
    set FLAG_LONG=1
  ) else if "%FLAG%" == "-err" (
    set FLAG_ERR=1
  ) else if "/c:" == "%FLAG:~0,3%" (
    set FLAG_BARE_COUNT=1
    set FLAG_BARE=%FLAG_BARE% %FLAG%
  ) else if "%FLAG:~0,1%" == "/" (
    rem if-OR-else
    (
      rem quote if a flag has a white space
      if "%FLAG%" == "%FLAG: =%" (call) else if "%FLAG%" == "%FLAG:	=%" (call) else (
        set FLAG_BARE=%FLAG_BARE% %FLAG%
        call;
      )
    ) || set FLAG_BARE=%FLAG_BARE% "%FLAG%"
  ) else if not "%FLAG%" == "--" (
    echo;%?~%: error: invalid flag: %FLAG%
    exit /b -255
  ) >&2

  shift
  set /A FLAG_SHIFT+=1

  rem read until no flags
  if not "%FLAG%" == "--" goto FLAGS_LOOP
)

if %FLAG_BARE_COUNT% EQU 0 set FLAG_BARE=%FLAG_BARE% /c:10

set "WEVT_LEVEL_QUERY=Level=1 or Level=2"
set "WEVT_TIME_QUERY="

if %FLAG_ERR% EQU 0 set "WEVT_LEVEL_QUERY=%WEVT_LEVEL_QUERY% or Level=3"
if %FLAG_ALL_TIME% EQU 0 set "WEVT_TIME_QUERY= and TimeCreated[@SystemTime>='%DATE%T00:00:00.000Z']"

echo;%DATE%
echo;

echo;[System Errors]
echo;

for /F "usebackq tokens=* delims="eol^= %%i in (`@"%SystemRoot%\System32\wevtutil.exe" qe System "/q:*[System[(%WEVT_LEVEL_QUERY%)%WEVT_TIME_QUERY%]]" /f:text /rd:true%FLAG_BARE% ^| "%SystemRoot%\System32\findstr.exe" /N /R /C:"^"`) do call :PROCESS_LINE

echo;

echo;[Application Errors]
echo;

for /F "usebackq tokens=* delims="eol^= %%i in (`@"%SystemRoot%\System32\wevtutil.exe" qe Application "/q:*[System[(%WEVT_LEVEL_QUERY%)%WEVT_TIME_QUERY%]]" /f:text /rd:true%FLAG_BARE% ^| "%SystemRoot%\System32\findstr.exe" /N /R /C:"^"`) do call :PROCESS_LINE

exit /b 0

:PROCESS_LINE
for %%# in (:) do set "LINE=%%i"

setlocal ENABLEDELAYEDEXPANSION

set "LINE=!LINE:*:=!"

if !FLAG_LONG! EQU 0 (
  if "!LINE:~0,1!" == " " exit /b 0
  if "!LINE:~0,6!" == "Event[" exit /b 0
)

echo;!LINE!
