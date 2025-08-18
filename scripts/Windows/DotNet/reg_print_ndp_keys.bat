@echo off

rem USAGE:
rem   reg-print-install-keys.bat

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
set ?.=@"%SystemRoot%\System32\reg.exe" query "HKLM\SOFTWARE\Microsoft\Net Framework Setup\NDP" /s ^| "%SystemRoot%\System32\findstr.exe" /I /R ^
  /C:"\\NDP\\v[0-9][0-9]*$" /C:"\\NDP\\v[0-9][0-9]*\.[0-9][0-9]*$" /C:"\\NDP\\v[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*$" /C:"\\NDP\\v[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*$"

set HKEY_ALL_COUNT=0
for /F "usebackq tokens=* delims="eol^= %%i in (`%%?.%%`) do set "REGKEY=%%i" & call :REG_QUERY
exit /b

:REG_QUERY
"%SystemRoot%\System32\reg.exe" query "%REGKEY%\Full" /ve >nul 2>nul

if %ERRORLEVEL% EQU 0 (
  set ?.=@"%SystemRoot%\System32\reg.exe" query "%REGKEY%\Full"
) else set ?.=@"%SystemRoot%\System32\reg.exe" query "%REGKEY%"

set HKEY_COUNT=0
for /F "usebackq tokens=* delims="eol^= %%i in (`%%?.%%`) do set "REG_QUERY_LINE=%%i" & call :REG_QUERY_LINE && echo;%%i || exit /b 0
exit /b

:REG_QUERY_LINE
if defined REG_QUERY_LINE if "%REG_QUERY_LINE:~0,5%" == "HKEY_" set /A "HKEY_ALL_COUNT+=1" & set /A "HKEY_COUNT+=1"
if %HKEY_COUNT% GTR 1 exit /b 1
if defined REG_QUERY_LINE if "%REG_QUERY_LINE:~0,5%" == "HKEY_" if %HKEY_ALL_COUNT% GTR 1 echo;
exit /b 0
