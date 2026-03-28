@echo off

rem USAGE:
rem   ping_drives.bat

rem Description:
rem   Script to ping a drive if `.pingme` file exists in the drive root to
rem   prevent the drive fall into a sleep state because of inactivity.

setlocal

set "PING_DRIVES="
for %%i in (a b c d e f g h i j k l m n o p q r s t u v w x y z) do if exist "%%i:\.pingme" call set "PING_DRIVES=%%PING_DRIVES%% %%i"

set COUNT=1

:LOOP
echo %COUNT% - %TIME%
set /A COUNT+=1
for %%i in (%PING_DRIVES%) do if exist "%%i:\.pingme" call :PING_DRIVE
timeout /T 60 >nul
goto LOOP

:PING_DRIVE
for %%# in (:) do for /F "tokens=* delims=" %%j in ("%%i:\.pingme") do set "PING_FILE=%%~fj" & set "FILE_ATTR=%%~aj"

rem touch a file without stdout redirection into a file (write)
if "%FILE_ATTR%" == "%FILE_ATTR:r=%" (
  copy /B "%PING_FILE%"+,, "%PING_FILE%" >nul
) else (
  "%SystemRoot%\System32\attrib.exe" -r "%PING_FILE%" >nul & copy /B "%PING_FILE%"+,, "%PING_FILE%" >nul & "%SystemRoot%\System32\attrib.exe" +r "%PING_FILE%" >nul
)
