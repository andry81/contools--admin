@echo off

setlocal DISABLEDELAYEDEXPANSION

rem Query the registry to find the ProgID associated with .html files (default browser)
for /F "usebackq tokens=1,2,*"eol^= %%i in (`@"%SystemRoot%\System32\reg.exe" query "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.html\UserChoice" /v "Progid" 2^>nul`) do if "%%i" == "Progid" set "BrowserProgID=%%k"

rem If no UserChoice is found, fall back to HKEY_CLASSES_ROOT\htmlfile
if not defined BrowserProgID set "BrowserProgID=htmlfile"

REM Query the registry to get the command for opening the default browser
for /f "usebackq tokens=1,2,*"eol^= %%i in (`@"%SystemRoot%\System32\reg.exe" query "HKCR\%BrowserProgID%\shell\open\command" /ve 2^>nul`) do if "%%i" == "(Default)" set "BrowserCommand=%%k"

setlocal ENABLEDELAYEDEXPANSION

set "BrowserCommand=!BrowserCommand:%%0=!"

for /L %%i in (1,1,9) do set "BrowserCommand=!BrowserCommand:%%%%i=%%~%%i!"

for /F "usebackq tokens=* delims="eol^= %%i in ('"!BrowserCommand!"') do endlocal & set "BrowserCommand=%%~i"

if not defined BrowserCommand exit /b 255

set "?3E=>"
setlocal ENABLEDELAYEDEXPANSION & for /F "usebackq tokens=* delims="eol^= %%i in ('"!BrowserCommand!"') do endlocal & set /P "=>" <nul & call echo;%%~i
call start "" %BrowserCommand%
exit /b
