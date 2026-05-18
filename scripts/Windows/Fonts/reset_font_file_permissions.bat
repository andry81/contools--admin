@echo off & goto DOC_END

rem USAGE:
rem   reset_font_file_permissions.bat [<flags>] [--] <glob-files>...

rem Description:
rem   Script to update a font file permissions before or after install into
rem   system fonts directory.

rem <flags>:
rem   -WD
rem     Working directory path used instead of current directory path.
rem     Has no effect if <glob-files> is absolute path.
rem
rem   -nolog
rem     Disable logging and so a log directory allocation.

rem --:
rem   Separator to stop parse flags.

rem <glob-files>
rem   File path list with globbing.
:DOC_END

setlocal

rem cast to integer
set /A IMPL_MODE+=0

set "?~0=%~0"
set "?~dp0=%~dp0"

if %IMPL_MODE%0 NEQ 0 goto SKIP_PREINIT_FLAGS

rem script flags
set FLAG_SHIFT=0
set FLAG_NO_LOG=0

:FLAGS_LOOP_0

rem flags always at first
set "FLAG=%~1"

if defined FLAG ^
if not "%FLAG:~0,1%" == "-" set "FLAG="

if defined FLAG (
  if "%FLAG%" == "-WD" (
    shift
  ) else if "%FLAG%" == "-nolog" (
    set FLAG_NO_LOG=1
  )

  shift
  set /A FLAG_SHIFT+=1

  rem read until no flags
  if not "%FLAG%" == "--" goto FLAGS_LOOP_0
)

rem log into current directory
if %FLAG_NO_LOG% EQU 0 (
  if not defined PROJECT_LOG_ROOT set PROJECT_LOG_ROOT=.log
) else set NO_LOG=1

set "EXEC_CALLF_PREFIX_ELEVATE_NAME=contools--admin"

:SKIP_PREINIT_FLAGS

call "%%?~dp0%%__init__/script_init.bat" "%%?~0%%" %%* || exit /b
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
set "FLAG_NOLOG="

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
  ) else if "%FLAG%" == "-nolog" (
    rem
  ) else if not "%FLAG%" == "--" (
    echo;%?~%: error: invalid flag: %FLAG%
    exit /b -255
  ) >&2

  shift
  set /A FLAG_SHIFT+=1

  rem read until no flags
  if not "%FLAG%" == "--" goto FLAGS_LOOP
)

if defined FLAG_WD pushd "%FLAG_WD%" || exit /b 255

call "%%CONTOOLS_ROOT%%/std/setshift.bat" %%FLAG_SHIFT%% GLOB_PATHS %%*

for %%i in ("%GLOB_PATHS%") do set "FILE_PATH=%%~fi" & call :PROCESS_FILE
exit /b 0

:PROCESS_FILE
for /F "tokens=* delims="eol^= %%i in ("\\?\%FILE_PATH%") do set "FILE_ATTR=%%~ai"

if not defined FILE_ATTR exit /b

rem skip links
if /i not "%FILE_ATTR:l=%" == "%FILE_ATTR%" exit /b

call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/call.bat" "%%SystemRoot%%\System32\icacls.exe" "%%FILE_PATH%%" /reset /c || exit /b
call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/call.bat" "%%SystemRoot%%\System32\icacls.exe" "%%FILE_PATH%%" /setowner "NT AUTHORITY\SYSTEM" || exit /b
rem call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/call.bat" "%%SystemRoot%%\System32\takeown.exe" /S localhost /U "SYSTEM" /F "%%FILE_PATH%%" || exit /b
echo;
