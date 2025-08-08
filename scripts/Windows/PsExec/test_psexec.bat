@echo off

setlocal

call "%%~dp0..\__init__\__init__.bat" || exit /b

if not defined PSEXEC set "PSEXEC=%CONTOOLS_SYSINTERNALS_ROOT%/psexec.exe"

if not exist "%PSEXEC%" (
  echo;%~nx0: error: `psexec.exe` is not found: "%PSEXEC%".
  exit /b 255
) >&2

"%CONTOOLS_TOOL_ADAPTORS_ROOT%/hta/cmd_admin.bat" /k @"%PSEXEC%" -i -s -d "%COMSPEC%" /k
