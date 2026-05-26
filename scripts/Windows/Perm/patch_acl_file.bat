@echo off & goto DOC_END

rem USAGE:
rem   patch_acl_file.bat [-+] [<flags>] [--] <acl-file-in> <acl-file-out>

rem Description:
rem   Script patches ACL file (`icacls.exe` UTF16-LE format) to a specific
rem   property value leaving all the rest untouched.

rem <flags>:
rem   -chcp <code-page>
rem     Set explicit code page.
rem
rem   -replace-path <from> <to>
rem     Replaces the path property in the first line.

rem -+:
rem   Separator to begin flags scope to parse.
rem --:
rem   Separator to end flags scope to parse.
rem   Required if `-+` is used.
rem   If `-+` is used, then must be used the same quantity of times.

rem <acl-file-in>:
rem   Path to the input ACL file to patch.

rem <acl-file-out>:
rem   Path to the output ACL file.
:DOC_END

setlocal

call "%%~dp0__init__/script_init.bat" %%0 %%* || exit /b
if %IMPL_MODE%0 EQU 0 exit /b

rem script flags
set RESTORE_LOCALE=0

call "%%CONTOOLS_ROOT%%/std/allocate_temp_dir.bat" . "%%?~n0%%" || exit /b

call :MAIN %%*
set LAST_ERROR=%ERRORLEVEL%

rem restore locale
if %RESTORE_LOCALE% NEQ 0 call "%%CONTOOLS_ROOT%%/std/restorecp.bat"

:FREE_TEMP_DIR
rem cleanup temporary files
call "%%CONTOOLS_ROOT%%/std/free_temp_dir.bat"

exit /b %LAST_ERROR%

:MAIN
rem script flags
set FLAG_FLAGS_SCOPE=0
set "FLAG_CHCP="
set "FLAG_REPLACE_PATH_FROM="
set "FLAG_REPLACE_PATH_TO="

:FLAGS_LOOP

rem flags always at first
set "FLAG=%~1"

if defined FLAG ^
if not "%FLAG:~0,1%" == "-" set "FLAG="

if defined FLAG if "%FLAG%" == "-+" set /A FLAG_FLAGS_SCOPE+=1
if defined FLAG if "%FLAG%" == "--" set /A FLAG_FLAGS_SCOPE-=1

if defined FLAG (
  if "%FLAG%" == "-chcp" (
    set "FLAG_CHCP=%~2"
    shift
  ) else if "%FLAG%" == "-replace-path" (
    set "FLAG_REPLACE_PATH_FROM=%~2"
    set "FLAG_REPLACE_PATH_TO=%~3"
    shift
    shift
  ) else if not "%FLAG%" == "-+" if not "%FLAG%" == "--" (
    echo;%?~%: error: invalid flag: %FLAG%
    exit /b -255
  ) >&2

  shift

  rem read until no flags
  if not "%FLAG%" == "--" goto FLAGS_LOOP

  if %FLAG_FLAGS_SCOPE% GTR 0 goto FLAGS_LOOP
)

if %FLAG_FLAGS_SCOPE% GTR 0 (
  echo;%?~%: error: not ended flags scope: %FLAG_FLAGS_SCOPE%
  exit /b -255
) >&2

if not defined FLAG_REPLACE_PATH_FROM (
  echo %~nx0: error: path property to match is not defined.
  exit /b 255
) >&2

if not defined FLAG_REPLACE_PATH_TO (
  echo %~nx0: error: path property to replace is not defined.
  exit /b 255
) >&2

if /i "%FLAG_REPLACE_PATH_FROM%" == "%FLAG_REPLACE_PATH_TO%" (
  echo %~nx0: error: path property to match and to replace must not be equal.
  exit /b 255
) >&2

set "ACL_FILE_IN=%~1"
set "ACL_FILE_OUT=%~2"

if not exist "%ACL_FILE_IN%" (
  echo %~nx0: error: input ACL file is not found: "%ACL_FILE_IN%"
  exit /b 1
) >&2

if exist "%ACL_FILE_OUT%" (
  echo %~nx0: error: output ACL file must not exist: "%ACL_FILE_OUT%"
  exit /b 2
) >&2

if defined FLAG_CHCP (
  call "%%CONTOOLS_ROOT%%/std/chcp.bat" "%%FLAG_CHCP%%"
  set RESTORE_LOCALE=1
) else call "%%CONTOOLS_ROOT%%/std/getcp.bat"

set "ACL_FILE_TO_PATCH_UTF16LE=%SCRIPT_TEMP_CURRENT_DIR%\acl-to-patch-utf16le.acl"
set "ACL_FILE_PATCHED_UTF8=%SCRIPT_TEMP_CURRENT_DIR%\acl-patched-utf8.acl"

call "%%CONTOOLS_ROOT%%/encoding/prepend_bom_to_utf_file.bat" -- "%%ACL_FILE_IN%%" fffe "%%ACL_FILE_TO_PATCH_UTF16LE%%" || exit /b

set /A ACL_FILE_LINE=0

rem use `type` to detect UTF-16LE-BOM and output into UTF-8
(
  for /F "usebackq tokens=* delims="eol^= %%i in (`@type "%ACL_FILE_TO_PATCH_UTF16LE%"`) do set "ACL_LINE=%%i" & call :PATCH_ACL_FILE || goto SKIP_PATCH
) > "%ACL_FILE_PATCHED_UTF8%"

call "%%CONTOOLS_ROOT%%/encoding/convert_utf8_to_utf16le.bat" "%%ACL_FILE_PATCHED_UTF8%%" "%%ACL_FILE_OUT%%" || exit /b

exit /b 0

:SKIP_PATCH
exit /b

:PATCH_ACL_FILE
set /A ACL_FILE_LINE+=1

setlocal ENABLEDELAYEDEXPANSION

if !ACL_FILE_LINE! EQU 1 (
  if /i not "!ACL_LINE!" == "!FLAG_REPLACE_PATH_FROM!" (
    echo;%~nx0: error: unmatched path parameter:
    echo;  Current: "%ACL_LINE%"
    echo;  Matched: "%FLAG_PATH%"
    exit /b 10
  ) >&2

  echo;!FLAG_REPLACE_PATH_TO!
  exit /b 0
)

echo;!ACL_LINE!
exit /b 0
