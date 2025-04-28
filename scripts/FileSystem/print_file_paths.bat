@echo off

rem USAGE:
rem   print_file_paths.bat [<flags>] [--] [<glob-path>]

rem Description:
rem   Script prints file paths using file globbing in format:
rem     >PATH
rem   Does support long paths, but without recursion in them.
rem   Does skip Links by default.

rem <flags>:
rem   -WD
rem     Working directory path used instead of current directory path.
rem     Has no effect if <glob-path> is absolute path.
rem
rem   -r
rem     Search files and/or directories recursively.
rem
rem   -len
rem     Print path length at beginning separated from the path by a tabulation:
rem       LENGTH	>PATH
rem
rem   -long
rem     Prints only long paths.
rem
rem   -no-long
rem     Does not print long paths.
rem     Has no effect if `-long` is used.
rem
rem   -links
rem     Allow print symbolic link paths
rem     CAUTION:
rem       Does not detect links recursion.

rem --:
rem   Separator to stop parse flags.

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
set FLAG_LENGTH=0
set FLAG_LONG=0
set FLAG_NO_LONG=0
set FLAG_ALLOW_LINKS=0

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
  ) else if "%FLAG%" == "-len" (
    set FLAG_LENGTH=1
  ) else if "%FLAG%" == "-long" (
    set FLAG_LONG=1
  ) else if "%FLAG%" == "-no-long" (
    set FLAG_NO_LONG=1
  ) else if "%FLAG%" == "-links" (
    set FLAG_ALLOW_LINKS=1
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
if %FLAG_ALLOW_LINKS% EQU 0 if /i not "%FILE_ATTR:l=%" == "%FILE_ATTR%" exit /b

if %FLAG_LONG% EQU 0 if %FLAG_NO_LONG% NEQ 0 if not exist "%FILE_PATH%" exit /b

set "LEN_PREFIX="
set "FILE_PATH_TMP=%FILE_PATH%"

setlocal ENABLEDELAYEDEXPANSION
if %FLAG_LENGTH% NEQ 0 for /F "tokens=* delims="eol^= %%i in ("!FILE_PATH_TMP!") do (
  set "LEN=1" & for %%j in (65536 32768 16384 8192 4096 2048 1024 512 256 128 64 32 16 8 4 2 1) do if not "!FILE_PATH_TMP:~%%j,1!" == "" set /A "LEN+=%%j" & set "FILE_PATH_TMP=!FILE_PATH_TMP:~%%j!"
  set "LEN_PREFIX=!LEN!	"
)

if !FLAG_LONG! NEQ 0 (
  if not exist "!FILE_PATH!" for /F "tokens=* delims="eol^= %%i in ("!LEN_PREFIX!>!FILE_PATH!") do endlocal & echo;%%i
) else for /F "tokens=* delims="eol^= %%i in ("!LEN_PREFIX!>!FILE_PATH!") do endlocal & echo;%%i

if %FLAG_RECUR% NEQ 0 if /i not "%FILE_ATTR:d=%" == "%FILE_ATTR%" (
  setlocal
  set "FROM_DIR=%FILE_PATH%"
  call :MAIN_RECUR
)
