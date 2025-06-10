@echo off

rem USAGE:
rem   list-junction-points.bat [<flags>] [//] <from-path> > <links-list-file>

setlocal

rem script flags
set "BARE_FLAGS="

:FLAGS_LOOP

rem flags always at first
set "FLAG=%~1"

if defined FLAG ^
if not "%FLAG:~0,1%" == "/" set "FLAG="

if defined FLAG (
  if not "%FLAG%" == "//" (
    set BARE_FLAGS=%BARE_FLAGS% %1
  )

  shift

  rem read until no flags
  if not "%FLAG%" == "//" goto FLAGS_LOOP
)

set "FROM_PATH=%~1"

if not defined FROM_PATH set "FROM_PATH=."

for /F "tokens=* delims="eol^= %%i in ("%FROM_PATH%\.") do set "FROM_PATH=%%~fi" & set "FROM_DRIVE=%%~di"

dir "%FROM_PATH%"%BARE_FLAGS% /A:L /B /O:N 2>nul
