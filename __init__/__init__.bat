@echo off

if /i "%CONTOOLS_ADMIN_PROJECT_ROOT_INIT0_DIR%" == "%~dp0" exit /b 0

set "CONTOOLS_ADMIN_PROJECT_ROOT_INIT0_DIR=%~dp0"

rem cast to integer
set /A NEST_LVL+=0

rem Initialize with verbose
if defined INIT_VERBOSE set /A INIT_VERBOSE+=0

rem Do not make a file or a directory
if defined NO_GEN set /A NO_GEN+=0

rem Do not make a log directory or a log file
if defined NO_LOG set /A NO_LOG+=0

rem Do not make a log output or stdio duplication into files
if defined NO_LOG_OUTPUT set /A NO_LOG_OUTPUT+=0

call "%%~dp0canonical_path_if_ndef.bat" CONTOOLS_ADMIN_PROJECT_ROOT                         "%%~dp0.."
call "%%~dp0canonical_path_if_ndef.bat" CONTOOLS_ADMIN_PROJECT_EXTERNALS_ROOT               "%%CONTOOLS_ADMIN_PROJECT_ROOT%%/_externals"

if not exist "%CONTOOLS_ADMIN_PROJECT_EXTERNALS_ROOT%\*" (
  echo;%~nx0: error: CONTOOLS_ADMIN_PROJECT_EXTERNALS_ROOT directory does not exist: "%CONTOOLS_ADMIN_PROJECT_EXTERNALS_ROOT%".
  exit /b 255
) >&2

call "%%~dp0canonical_path_if_ndef.bat" PROJECT_OUTPUT_ROOT                                 "%%CONTOOLS_ADMIN_PROJECT_ROOT%%/_out"
call "%%~dp0canonical_path_if_ndef.bat" PROJECT_LOG_ROOT                                    "%%CONTOOLS_ADMIN_PROJECT_ROOT%%/.log"

call "%%~dp0canonical_path_if_ndef.bat" CONTOOLS_ADMIN_PROJECT_INPUT_CONFIG_ROOT            "%%CONTOOLS_ADMIN_PROJECT_ROOT%%/_config"
call "%%~dp0canonical_path_if_ndef.bat" CONTOOLS_ADMIN_PROJECT_OUTPUT_CONFIG_ROOT           "%%PROJECT_OUTPUT_ROOT%%/config/contools--admin"

rem retarget externals of an external project

call "%%~dp0canonical_path_if_ndef.bat" CONTOOLS_PROJECT_EXTERNALS_ROOT                     "%%CONTOOLS_ADMIN_PROJECT_EXTERNALS_ROOT%%"
call "%%~dp0canonical_path_if_ndef.bat" USERBIN_PROJECT_EXTERNALS_ROOT                      "%%CONTOOLS_ADMIN_PROJECT_EXTERNALS_ROOT%%"

rem init immediate external projects

if exist "%CONTOOLS_ADMIN_PROJECT_EXTERNALS_ROOT%/contools/__init__/__init__.bat" (
  call "%%CONTOOLS_ADMIN_PROJECT_EXTERNALS_ROOT%%/contools/__init__/__init__.bat" -no_load_user_config || exit /b
)

rem init external projects

call "%%CONTOOLS_ROOT%%/std/call_if_exist.bat" ^
"%%CONTOOLS_ADMIN_PROJECT_EXTERNALS_ROOT%%/userbin/__init__/__init__.bat" -no_load_user_config || exit /b

if %NO_GEN%0 EQU 0 (
  call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/mkdir_if_notexist.bat" "%%CONTOOLS_ADMIN_PROJECT_OUTPUT_CONFIG_ROOT%%" || exit /b
)

if not defined LOAD_CONFIG_VERBOSE if %INIT_VERBOSE%0 NEQ 0 set LOAD_CONFIG_VERBOSE=1

if %NO_GEN%0 EQU 0 (
  call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/load_config_dir.bat" -+ %%* -gen_user_config -- "%%CONTOOLS_ADMIN_PROJECT_INPUT_CONFIG_ROOT%%" "%%CONTOOLS_ADMIN_PROJECT_OUTPUT_CONFIG_ROOT%%" || exit /b
) else call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/load_config_dir.bat" -+ %%* -- "%%CONTOOLS_ADMIN_PROJECT_INPUT_CONFIG_ROOT%%" "%%CONTOOLS_ADMIN_PROJECT_OUTPUT_CONFIG_ROOT%%" || exit /b

if %NO_GEN%0 EQU 0 (
  call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/mkdir_if_notexist.bat" "%%PROJECT_OUTPUT_ROOT%%" || exit /b
)

exit /b 0
