@echo off

rem USAGE:
rem   clear_file_streams.bat [<flags>] [--] [<glob-path> [<streams>...]]

rem Description:
rem   Script clears (not removing) all alternative file streams from files
rem   using file globbing.
rem   Does support long paths, but without recursion in them.
rem   Does skip Links.

rem <flags>:
rem   -WD
rem     Working directory path used instead of current directory path.
rem     Has no effect if <glob-path> is absolute path.
rem
rem   -r
rem     Search files recursively.
rem
rem   -size
rem     Print alternative file stream size at beginning separated from the path
rem     by a tabulation:
rem       SIZE	>PATH:STREAM

rem --:
rem   Separator to stop parse flags.

rem <streams>
rem   List of stream names.
rem   If `*`, then a known list is used:
rem     * Zone.identifier

setlocal

rem log into current directory
if not defined PROJECT_LOG_ROOT set PROJECT_LOG_ROOT=.log

call "%%~dp0__init__/script_init.bat" %%0 %%* || exit /b
if %IMPL_MODE%0 EQU 0 exit /b

rem call "%%CONTOOLS_ROOT%%/std/allocate_temp_dir.bat" . "%%?~n0%%" || exit /b

call :MAIN %%*
set LAST_ERROR=%ERRORLEVEL%

:FREE_TEMP_DIR
rem cleanup temporary files
rem call "%%CONTOOLS_ROOT%%/std/free_temp_dir.bat"

exit /b %LAST_ERROR%

:MAIN
rem script flags
set FLAG_SHIFT=0
set "FLAG_WD="
set FLAG_RECUR=0
set FLAG_SIZE=0

:FLAGS_LOOP

rem flags always at first
set "FLAG=%~1"

if defined FLAG ^
if not "%FLAG:~0,1%" == "-" set "FLAG="

if defined FLAG (
  if "%FLAG%" == "-WD" (
    set "FLAG_WD=%~2"
    shift
    set /A FLAG_SHIFT+=1
  ) else if "%FLAG%" == "-r" (
    set FLAG_RECUR=1
  ) else if "%FLAG%" == "-size" (
    set FLAG_SIZE=1
  ) else if not "%FLAG%" == "--" (
    echo;%?~%: error: invalid flag: %FLAG%
    exit /b -255
  ) >&2

  shift
  set /A FLAG_SHIFT+=1

  rem read until no flags
  if not "%FLAG%" == "--" goto FLAGS_LOOP
)

set "FROM_PATH=%~1"

set /A FLAG_SHIFT+=1
call "%%CONTOOLS_ROOT%%/std/setshift.bat" %%FLAG_SHIFT%% __STRING__ %%*

if not defined __STRING__ (
  echo;%?~%: error: streams are not defined.
  exit /b 255
) >&2

if defined FLAG_WD (
  set "WD=%FLAG_WD%"
) else set "WD=%CD%"

if not defined FROM_PATH set "FROM_PATH=."

if not "%FROM_PATH:~0,1%" == "\" if not "%FROM_PATH:~1,1%" == ":" set "FROM_PATH=%WD%\%FROM_PATH%"

setlocal ENABLEDELAYEDEXPANSION & for /F "tokens=* delims="eol^= %%i in ("!FROM_PATH!\.") do endlocal & set "FROM_DIR=%%~fi"

if not exist "\\?\%FROM_DIR%\*" (
  echo;%?~%: error: directory path does not exist: "%FROM_DIR%".
  exit /b 1
) >&2

rem default list
if ^%__STRING__:~0,1%^%__STRING__:~1,1%/ == ^*/ set "__STRING__=Zone.Identifier"

rem escape globbing
call "%%CONTOOLS_ROOT%%/std/encode/encode_glob_chars.bat"

:MAIN_RECUR
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
set ?.=@dir "\\?\%FROM_DIR%" /B /O:N 2^>nul

for /F "usebackq tokens=* delims="eol^= %%i in (`%%?.%%`) do set "FILE=%%i" & call :PROCESS_FILE_PATH
exit /b 0

:PROCESS_FILE_PATH
rem skip `.log` directory
if "%FILE%" == ".log" if exist ".log\*" exit /b

for /F "tokens=* delims="eol^= %%i in ("%FROM_DIR%\%FILE%") do set "FILE_PATH=%%~fi"
for /F "tokens=* delims="eol^= %%i in ("\\?\%FILE_PATH%") do set "FILE_ATTR=%%~ai"

if not defined FILE_ATTR exit /b

rem skip links
if /i not "%FILE_ATTR:l=%" == "%FILE_ATTR%" exit /b

setlocal ENABLEDELAYEDEXPANSION & for /F "tokens=* delims="eol^= %%i in ("!FILE_PATH!") do endlocal & ^
for %%j in (%__STRING__%) do for /F "tokens=* delims="eol^= %%k in ("\\?\%%i:%%~j") do (
  set "PRINT_LINE=>%%i:%%~j"
  set "STREAM_SIZE=%%~zk"
  if defined STREAM_SIZE (
    setlocal ENABLEDELAYEDEXPANSION
    if %FLAG_SIZE% NEQ 0 set "PRINT_LINE=!STREAM_SIZE!	!PRINT_LINE!"
    for /F "tokens=* delims="eol^= %%l in ("!PRINT_LINE!") do endlocal & echo;%%l
    setlocal ENABLEDELAYEDEXPANSION
    if !STREAM_SIZE! NEQ 0 (
      endlocal & "%SystemRoot%\System32\find.exe" /V "" < "%%k" & echo;
    ) else endlocal
    type nul > "%%k"
  )
)

if %FLAG_RECUR% NEQ 0 if /i not "%FILE_ATTR:d=%" == "%FILE_ATTR%" (
  setlocal
  set "FROM_DIR=%FILE_PATH%"
  call :MAIN_RECUR
)
