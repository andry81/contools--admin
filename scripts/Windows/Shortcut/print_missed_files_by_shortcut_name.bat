@echo off

setlocal

rem required to avoid unicode characters trim
chcp 65001 >nul

rem localized suffix variants
set SUFFIXES_LIST=" - Shortcut" " - Ярлык"

set NUM_FOUND=0

set ?.=@dir *.lnk /A:-D /B /S /O:N

for /F "usebackq tokens=* delims="eol^= %%i in (`%%?.%%`) do set "FILE_PATH=%%i" & set "FILE_DIR=%%~dpi" & set "FILE_NAME_WO_EXT=%%~ni" & call :PROCESS

echo;
echo;Found: %NUM_FOUND%

exit /b 0

:PROCESS
set "FILE_NAME_STRIPPED=%FILE_NAME_WO_EXT%"

for %%i in (%SUFFIXES_LIST%) do if defined FILE_NAME_STRIPPED call set "FILE_NAME_STRIPPED=%%FILE_NAME_STRIPPED:%%~i=%%"

if not exist "%FILE_DIR%%FILE_NAME_STRIPPED%" for %%j in (:) do set /A "NUM_FOUND+=1" & echo;%%i
