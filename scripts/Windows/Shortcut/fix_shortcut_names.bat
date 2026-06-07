@echo off

setlocal

rem required to avoid unicode characters trim
chcp 65001 >nul

rem localized suffix variants
set SUFFIXES_LIST=" - Shortcut" " - Ярлык"

set /A "NUM_FIXED=0", "NUM_NOT_FIXED=0"

set ?.=@dir *.lnk /A:-D /B /S /O:N

for /F "usebackq tokens=* delims="eol^= %%i in (`%%?.%%`) do set "FILE_PATH=%%i" & set "FILE_DIR=%%~dpi" & set "FILE_NAME_WO_EXT=%%~ni" & call :PROCESS

echo:    Fixed: %NUM_FIXED%
echo:Not Fixed: %NUM_NOT_FIXED%

exit /b 0

:PROCESS
set "FILE_NAME_STRIPPED=%FILE_NAME_WO_EXT%"

for %%i in (%SUFFIXES_LIST%) do if defined FILE_NAME_STRIPPED call set "FILE_NAME_STRIPPED=%%FILE_NAME_STRIPPED:%%~i=%%"

if exist "%FILE_DIR%%FILE_NAME_STRIPPED%" exit /b

set FOUND_FILES_COUNT=0
set "FOUND_FILES_LIST="

for %%i in ("%FILE_DIR%%FILE_NAME_STRIPPED%.*") do if not "%%~xi" == ".lnk" set "LAST_FOUND_FILE_NAME=%%~nxi" & call :PROCESS_FILE_NAME

goto PROCESS_FILE_NAME_END

:PROCESS_FILE_NAME
call set "FOUND_FILE_NAME_SUFFIX=%%LAST_FOUND_FILE_NAME:%FILE_NAME_STRIPPED%.=%%"

if not "%FOUND_FILE_NAME_SUFFIX:.=%" == "%FOUND_FILE_NAME_SUFFIX%" exit /b 1

set /A "FOUND_FILES_COUNT+=1"

set FOUND_FILES_LIST=%FOUND_FILES_LIST% "%LAST_FOUND_FILE_NAME%"

exit /b 0

:PROCESS_FILE_NAME_END

if %FOUND_FILES_COUNT% EQU 1 (
  set /A NUM_FIXED+=1
  echo;[FIXED]
  echo;"%FILE_PATH%"
  for %%i in (%FOUND_FILES_LIST%) do (
    echo;  -^> %%~nxi
    rename "%FILE_PATH%" "%%~nxi.lnk"
  )
  echo;
  exit /b 0
)

set /A NUM_NOT_FIXED+=1

echo;[NOT FIXED]
echo;"%FILE_PATH%"

if %FOUND_FILES_COUNT% GTR 1 (
  for %%i in (%FOUND_FILES_LIST%) do echo;  -^> %%~nxi
  echo;
  exit /b -1
)

echo;

exit /b 1
