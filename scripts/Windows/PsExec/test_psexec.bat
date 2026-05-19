@echo off

setlocal

call "%%~dp0..\__init__\__init__.bat" || exit /b

if not defined PSEXEC set "PSEXEC=%CONTOOLS_ADMIN_PROJECT_EXTERNALS_ROOT%/sysinternals/psexec.exe"

if not exist "%PSEXEC%" (
  echo;%~nx0: error: `psexec.exe` is not found: "%PSEXEC%".
  exit /b 255
) >&2

"%USERBIN_SCRIPTS_BAT_ROOT%/runas/hta/cmd-admin.bat" /k @"%PSEXEC%" -i -s -d "%COMSPEC%" /k
