@echo off

setlocal

rem script names call stack
if defined ?~ ( set "?~=%?~%-^>%~nx0" ) else if defined ?~nx0 ( set "?~=%?~nx0%-^>%~nx0" ) else set "?~=%~nx0"

set "VDI_DIR=%~1"

if not defined VBOX_MANAGE_EXE set "VBOX_MANAGE_EXE=%~2"

if not defined VBOX_MANAGE_EXE for /f "usebackq tokens=1,2,* delims=	 " %%i in (`@"%SystemRoot%\System32\reg.exe" query "HKEY_LOCAL_MACHINE\SOFTWARE\Oracle\VirtualBox" /v "InstallDir"`) do (
  if "%%i" == "InstallDir" set "VBOX_MANAGE_EXE=%%kVBoxManage.exe"
)

if not defined VBOX_MANAGE_EXE set "VBOX_MANAGE_EXE=c:\Program Files\VirtualBox\VBoxManage.exe"

if not defined VDI_DIR (
  echo;%?~%: error: VDI_DIR is not defined.
  exit /b 255
) >&2

for /F "tokens=* delims="eol^= %%i in ("%VDI_DIR%\.") do set "VDI_DIR=%%~fi"

if not exist "%VDI_DIR%\*" (
  echo;%?~%: error: VDI_DIR does not exist: VDI_DIR="%VDI_DIR%"
  exit /b 255
) >&2

if not exist "%VBOX_MANAGE_EXE%" (
  echo;%?~%: error: VBOX_MANAGE_EXE not exist: VBOX_MANAGE_EXE="%VBOX_MANAGE_EXE%"
  exit /b 255
) >&2

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
set ?.=@dir "%VDI_DIR%\*.vdi" /A:-D /B /O:N /S 2^>nul

for /F "usebackq tokens=* delims="eol^= %%i in (`%%?.%%`) do set "VDI_FILE=%%i" & call :COMPACT_VDI_FILE

exit /b

:COMPACT_VDI_FILE
call :CMD "%%VBOX_MANAGE_EXE%%" modifymedium --compact "%%VDI_FILE%%"
echo;
exit /b

:CMD
echo;^>%*
(
  %*
)
exit /b
