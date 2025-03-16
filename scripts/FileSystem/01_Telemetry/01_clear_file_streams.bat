@echo off

rem USAGE:
rem   01_clear_file_streams.bat <glob-path> <streams>...

rem Description:
rem   Script clears (not removing) all alternative file streams from files
rem   recursively using file globbing.
rem

rem <streams>
rem   List of stream names.
rem   If `*`, then a known list is used:
rem     * Zone.identifier

setlocal

rem log into current directory
if not defined PROJECT_LOG_ROOT set PROJECT_LOG_ROOT=.log

call "%%~dp0../__init__/script_init.bat" %%0 %%* || exit /b
if %IMPL_MODE%0 EQU 0 exit /b

rem call "%%CONTOOLS_ROOT%%/std/allocate_temp_dir.bat" . "%%?~n0%%" || exit /b

call :MAIN %%*
set LAST_ERROR=%ERRORLEVEL%

:FREE_TEMP_DIR
rem cleanup temporary files
rem call "%%CONTOOLS_ROOT%%/std/free_temp_dir.bat"

exit /b %LAST_ERROR%

:MAIN
call "%%CONTOOLS_ROOT%%/std/setshift.bat" 1 __STRING__ %%*

if not defined __STRING__ (
  echo.%?~%: error: streams are not defined.
  exit /b 255
) >&2

rem default list
if ^%__STRING__:~0,1%^%__STRING__:~1,1%/ == ^*/ set "__STRING__=Zone.Identifier"

rem escape globbing
call "%%CONTOOLS_ROOT%%/std/encode/encode_glob_chars.bat"

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
set ?.=@dir "%~1" /A:-D /B /O:N /S 2^>nul

echo Clearing alternative file streams...
for /F "usebackq eol=; tokens=* delims=" %%i in (`%%?.%%`) do set "FILE=%%i" & call :REMOVE_FILE_STREAMS
echo.

exit /b

:REMOVE_FILE_STREAMS
rem skip `.log` directory
setlocal ENABLEDELAYEDEXPANSION & ^
for /F "tokens=* delims="eol^= %%i in ("!FILE!") do ^
for /F "tokens=* delims="eol^= %%j in ("!FILE:\.log\=!") do endlocal & if not "%%i" == "%%j" exit /b

setlocal ENABLEDELAYEDEXPANSION & for /F "tokens=* delims="eol^= %%i in ("!FILE!") do endlocal & ^
for %%j in (%__STRING__%) do for /F "tokens=* delims="eol^= %%k in ("%%i:%%~j") do if not "%%~zk" == "" (echo.^>%%k) & type nul > "%%k"
exit /b
