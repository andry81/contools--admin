@echo off

rem USAGE:
rem   ping_drives.bat

rem Description:
rem   Script to ping a drive if `.pingme` file exists in the drive root to
rem   prevent the drive fall into a sleep state because of inactivity.
rem   Rescans drives on timeout.
rem   Skips on the read only file attribute and prints the skipped drives.

setlocal

rem switch to the current directory drive root to release the current directory and avoid it's accidental lock, and then
rem switch to a temporary directory to release the current directory drive root
cd \ & cd /d "%TEMP%"

set COUNT=0

:LOOP
set "PING_DRIVES="
for %%i in (A B C D E F G H I J K L M N O P Q R S T U V W X Y Z) do if exist "%%i:\.pingme" call set "PING_DRIVES=%%PING_DRIVES%% %%i"

set /A COUNT+=1

if not defined PING_DRIVES (
  echo %COUNT% - %DATE% %TIME%
  goto WAIT
)

set "SKIP_DRIVES="
for %%i in (%PING_DRIVES%) do if exist "%%i:\.pingme" call :PING_DRIVE

if not defined SKIP_DRIVES (
  echo %COUNT% - %DATE% %TIME% -%PING_DRIVES%
) else echo %COUNT% - %DATE% %TIME% -%PING_DRIVES% - (skipped)%SKIP_DRIVES%

:WAIT
timeout /T 60 >nul
goto LOOP

:PING_DRIVE
for %%# in (:) do for /F "tokens=* delims=" %%j in ("%%i:\.pingme") do set "PING_FILE=%%~fj" & set "FILE_ATTR=%%~aj"

rem touch a file without stdout redirection into a file (write), skip on the read only attribute
if "%FILE_ATTR%" == "%FILE_ATTR:r=%" (
  copy /B "%PING_FILE%"+,, "%PING_FILE%" >nul
) else for %%# in (:) do set "SKIP_DRIVES=%SKIP_DRIVES% %%i"
