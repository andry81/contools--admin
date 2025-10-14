@echo off

rem USAGE:
rem   print_installer_packages.bat [<flags>] [--] [<glob-path>]

rem Description:
rem   Script prints Windows Installer files using file globbing for the
rem   directory `%SystemRoot%\Installer`.

rem <flags>:
rem   -no-skip-commons
rem     Do not skip common titles:
rem       * Installation Database
rem       * Setup

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
set NO_SKIP_COMMONS=0

:FLAGS_LOOP

rem flags always at first
set "FLAG=%~1"

if defined FLAG ^
if not "%FLAG:~0,1%" == "-" set "FLAG="

if defined FLAG (
  if "%FLAG%" == "-no-skip-commons" (
    set NO_SKIP_COMMONS=1
  ) else if not "%FLAG%" == "--" (
    echo;%?~%: error: invalid flag: %FLAG%
    exit /b -255
  ) >&2

  shift
  set /A FLAG_SHIFT+=1

  rem read until no flags
  if not "%FLAG%" == "--" goto FLAGS_LOOP
)

set "FROM_FILE=%~1"

if defined FROM_FILE (
  set "FROM_PATH=%SystemRoot%\Installer\%FROM_FILE%"
) else set "FROM_PATH=%SystemRoot%\Installer\*.msi"

setlocal ENABLEDELAYEDEXPANSION & for /F "tokens=* delims="eol^= %%i in ("!FROM_PATH!\..") do endlocal & set "FROM_DIR=%%~fi"

if not exist "\\?\%FROM_DIR%\*" (
  echo;%?~%: error: directory path does not exist: "%FROM_DIR%".
  exit /b 1
) >&2

for %%i in ("%FROM_PATH%") do set "FILE=%%i" & call :PROCESS_FILE_PATH
exit /b 0

:PROCESS_FILE_PATH
for /F "tokens=* delims="eol^= %%i in ("%FILE%") do set "FILE_NAME=%%~nxi"

for /F "usebackq tokens=* delims="eol^= %%i in (`@"%SystemRoot%\System32\cscript.exe" //nologo "%CONTOOLS_TOOL_ADAPTORS_ROOT%/vbs/read_msi_summary_props.vbs" -v Title "%FILE%"`) do set "MSI_TITLE=%%i"

setlocal ENABLEDELAYEDEXPANSION

if !NO_SKIP_COMMONS! EQU 0 (
  if /i "!MSI_TITLE!" == "Installation Database" exit /b
  if /i "!MSI_TITLE!" == "Setup" exit /b
)

for /F "tokens=* delims="eol^= %%i in ("!FILE_NAME!|!MSI_TITLE!") do echo;%%i
