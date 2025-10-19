@echo off

rem USAGE:
rem   print_last_mountvol.bat

rem Description:
rem   Script prints last known local drive volume GUIDs used to be printed by
rem   the `mountvol.exe` utility if a local drive is powered on and mounted.
rem
rem   The difference with the utility, it prints only for local drives and for
rem   each drive letter even if a drive letter currently is not attached.
rem
rem   See:
rem     HKEY_LOCAL_MACHINE\SYSTEM\MountedDevices

setlocal DISABLEDELAYEDEXPANSION

call "%%~dp0__init__/__init__.bat" %%0 %%* || exit /b

for /F "usebackq tokens=* delims="eol^= %%i in (`@"%SystemRoot%\System32\reg.exe" query "HKEY_LOCAL_MACHINE\SYSTEM\MountedDevices" /v "\DosDevices\?:"`) do ^
set "REGKEY_LINE=%%i" & call :PROCESS_REGKEY_LINE

exit /b

:PROCESS_REGKEY_LINE
if not "%REGKEY_LINE:~0,4%" == "    " exit /b

setlocal ENABLEDELAYEDEXPANSION & for /F "tokens=1,3 delims=	 "eol^= %%i in ("!REGKEY_LINE!") do endlocal & set "REG_KEY=%%i" & set "REG_VALUE=%%j"

if not defined REG_VALUE exit /b

if /i not "%REG_VALUE:~0,16%" == "444D494F3A49443A" exit /b & rem DMIO:ID:

set "VOLUME_GUID_BYTES=%REG_VALUE:~16,64%"

rem safe print
setlocal ENABLEDELAYEDEXPANSION & for /F "tokens=* delims="eol^= %%i in ("!REG_KEY:~12!|\\?\Volume{") do endlocal & ( set /P "=%%i" <nul )

setlocal ENABLEDELAYEDEXPANSION ^
  & ( for %%i in (6 4 2 0 - 10 8 - 14 12) do if not "%%i" == "-" ( set /P "=!VOLUME_GUID_BYTES:~%%i,2!" <nul ) else set /P "=-" <nul ) & endlocal

setlocal ENABLEDELAYEDEXPANSION & for /F "tokens=* delims="eol^= %%i in ("-!VOLUME_GUID_BYTES:~16,4!-!VOLUME_GUID_BYTES:~20,12!}\") do endlocal & echo;%%i
