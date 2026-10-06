<!-- : bat in wsf skip

@echo off & goto DOC_END

rem USAGE:
rem   install_hklm_shutdown_command.bat [-+] [<flags>] [--] <command> <args>...

rem Description:
rem   Script installs a command to run at shutdown phase.
rem   If respective files must be changed but already exist, then the script
rem   backups them into the directory:
rem
rem     `%SystemRoot%\System32\GroupPolicy\%DATE%.backup\%TIME%`
rem
rem   Based on:
rem     https://serverfault.com/questions/377387/how-to-add-a-shutdown-script-not-by-using-gpedit-msc-or-active-directory

rem <flags>:
rem   -s
rem     The `<command>` is a file script to copy into
rem     `%SystemRoot%\System32\GroupPolicy\Machine\Scripts\Shutdown` directory.
rem
rem   -ps
rem     Command script is a PowerShell script.
rem     Implies `-s` flag.

rem Examples (in console):
rem
rem   1. Install a command to disable `Wi-Fi` interface
rem     >
rem     install_hklm_shutdown_command.bat netsh.exe interface set interface name="Wi-Fi" admin=DISABLED
rem
rem   2. To install a script
rem     >
rem     install_hklm_shutdown_command.bat -s "...\shutdown.bat"
rem
rem   3. To reinstall been installed script
rem     >
rem     install_hklm_shutdown_command.bat -s "%SystemRoot%\System32\GroupPolicy\Machine\Scripts\Shutdown\shutdown.bat"
:DOC_END

setlocal

call "%%~dp0..\__init__\__init__.bat" || exit /b

rem script names call stack, disabled due to self call and partial inheritance (process elevation does not inherit a parent process variables by default)
rem if defined ?~ ( set "?~=%?~%-^>%~nx0" ) else if defined ?~nx0 ( set "?~=%?~nx0%-^>%~nx0" ) else set "?~=%~nx0"
set "?~=%~nx0"

set "?~f0=%~f0"

if 0%IMPL_MODE% NEQ 0 goto IMPL
"%USERBIN_SCRIPTS_BAT_ROOT%/runas/hta/cmd-admin.bat" /c @set "IMPL_MODE=1" ^& "%~f0" %*
exit /b

:IMPL
call "%%CONTOOLS_ROOT%%/std/is_admin_elevated.bat" || (
  echo;%?~%: error: process must be Administrator account elevated to continue.
  exit /b 255
) >&2

setlocal DISABLEDELAYEDEXPANSION

rem script flags
set FLAG_SHIFT=0
set FLAG_FLAGS_SCOPE=0
set FLAG_SCRIPT=0
set FLAG_PS_SCRIPT=0

:FLAGS_LOOP

rem flags always at first
set "FLAG=%~1"

if defined FLAG ^
if not "%FLAG:~0,1%" == "-" set "FLAG="

if defined FLAG if "%FLAG%" == "-+" set /A FLAG_FLAGS_SCOPE+=1
if defined FLAG if "%FLAG%" == "--" set /A FLAG_FLAGS_SCOPE-=1

if defined FLAG (
  if "%FLAG%" == "-s" (
    set FLAG_SCRIPT=1
  ) else if "%FLAG%" == "-ps" (
    set FLAG_PS_SCRIPT=1
  ) else if not "%FLAG%" == "-+" if not "%FLAG%" == "--" (
    echo;%?~%: error: invalid flag: %FLAG%
    exit /b -255
  ) >&2

  shift
  set /A FLAG_SHIFT+=1

  rem read until no flags
  if not "%FLAG%" == "--" goto FLAGS_LOOP

  if %FLAG_FLAGS_SCOPE% GTR 0 goto FLAGS_LOOP
)

if %FLAG_FLAGS_SCOPE% GTR 0 (
  echo;%?~%: error: not ended flags scope: %FLAG_FLAGS_SCOPE%
  exit /b -255
) >&2

if %FLAG_PS_SCRIPT% NEQ 0 set FLAG_SCRIPT=1

call :MAIN %%*
set LAST_ERROR=%ERRORLEVEL%

pause

exit /b %LAST_ERROR%

:MAIN
set "DATE_FNAME=%DATE%"
set "TIME_FNAME=%TIME%"

call :FNAME DATE_FNAME
call :FNAME TIME_FNAME

set "CMD="
set "ARG="

call "%%CONTOOLS_ROOT%%/std/setshift.bat" -exe -num 1 %%FLAG_SHIFT%% CMD %%*

set /A FLAG_SHIFT+=1

call "%%CONTOOLS_ROOT%%/std/setshift.bat" -exe %%FLAG_SHIFT%% ARGS %%*

if not defined CMD (
  echo;%?~%: error: command is not defined.
  exit /b 1
) >&2

if %FLAG_SCRIPT% EQU 0 goto SKIP_CMD_SCRIPT

for /F "tokens=* delims="eol^= %%i in ("%CMD%\.") do set "CMD_FILE_NAME=%%~nxi" & set "CMD_FILE_PATH=%%~fi"

if not exist "\\?\%CMD_FILE_PATH%" (
  echo;%?~%: error: command path is not found: "%CMD_FILE_PATH%".
  exit /b 2
) >&2

if exist "\\?\%CMD_FILE_PATH%\*" (
  echo;%?~%: error: command path is a directory: "%CMD_FILE_PATH%".
  exit /b 3
) >&2

:SKIP_CMD_SCRIPT

rem back up at first

set "BACKUP_DIR=%SystemRoot%\System32\GroupPolicy\%DATE_FNAME%.backup\%TIME_FNAME%"

( call "%%CONTOOLS_ROOT%%/std/mkdir_if_notexist_and.bat" "%%SystemRoot%%\System32\GroupPolicy\Machine\Scripts\Shutdown" && echo;) ^
  || call "%%CONTOOLS_ROOT%%/std/if_pass.bat" %%ERRORLEVEL%% EQU -1 || exit /b

( call "%%CONTOOLS_ROOT%%/std/mkdir_if_notexist_and.bat" "%%BACKUP_DIR%%\Machine\Scripts\Shutdown" && echo;) ^
  || call "%%CONTOOLS_ROOT%%/std/if_pass.bat" %%ERRORLEVEL%% EQU -1 || exit /b

(
  call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/call.bat" "%%SystemRoot%%\System32\reg.exe" export "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Group Policy\Scripts\Shutdown"               "%%BACKUP_DIR%%\Machine\Scripts\Shutdown.reg"
  call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/call.bat" "%%SystemRoot%%\System32\reg.exe" export "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Group Policy\State\Machine\Scripts\Shutdown" "%%BACKUP_DIR%%\Machine\Scripts\ShutdownState.reg"
) 2>nul

if %FLAG_SCRIPT% EQU 0 goto SKIP_BACKUP_CMD

if exist "%SystemRoot%\System32\GroupPolicy\Machine\Scripts\Shutdown\%CMD_FILE_NAME%" (
  rem check on reinstall
  if /i not "%CMD_FILE_PATH%" == "%SystemRoot%\System32\GroupPolicy\Machine\Scripts\Shutdown\%CMD_FILE_NAME%" (
    call "%%CONTOOLS_ROOT%%/std/copy.bat" "%%SystemRoot%%\System32\GroupPolicy\Machine\Scripts\Shutdown\%%CMD_FILE_NAME%%" "%%BACKUP_DIR%%\Machine\Scripts\Shutdown\." /Y /B || exit /b
    echo;
  )
)

:SKIP_BACKUP_CMD

rem install by overwrite

"%SystemRoot%\System32\cscript.exe" //NOLOGO //JOB:IMPORT_REGISTRY "%?~f0%?.wsf"

if exist "%SystemRoot%\System32\GroupPolicy\Machine\Scripts\Scripts.ini" (
  call "%%CONTOOLS_ROOT%%/std/copy.bat" "%%SystemRoot%%\System32\GroupPolicy\Machine\Scripts\Scripts.ini" "%%BACKUP_DIR%%\Machine\Scripts\." /Y /B || exit /b
  echo;
)

if exist "%SystemRoot%\System32\GroupPolicy\gpt.ini" (
  call "%%CONTOOLS_ROOT%%/std/copy.bat" "%%SystemRoot%%\System32\GroupPolicy\gpt.ini" "%%BACKUP_DIR%%\." /Y /B || exit /b
  echo;
)

rem install by overwrite

if %FLAG_SCRIPT% NEQ 0 (
  rem check on reinstall
  if /i not "%CMD_FILE_PATH%" == "%SystemRoot%\System32\GroupPolicy\Machine\Scripts\Shutdown\%CMD_FILE_NAME%" (
    call "%%CONTOOLS_ROOT%%/std/copy.bat" "%%CMD_FILE_PATH%%" "%%SystemRoot%%\System32\GroupPolicy\Machine\Scripts\Shutdown\%%CMD_FILE_NAME%%" /Y /B || exit /b
    echo;
  )
)

rem install by conditional write

(
  setlocal ENABLEDELAYEDEXPANSION

  echo;[Shutdown]
  if !FLAG_SCRIPT! NEQ 0 (
    echo;0CmdLine=!CMD_FILE_NAME!
  ) else echo;0CmdLine=!CMD!
  echo;0Parameters=!ARGS!

  endlocal
) > "%SystemRoot%\System32\GroupPolicy\Machine\Scripts\Scripts.ini"

if not exist "%SystemRoot%\System32\GroupPolicy\gpt.ini" (
  echo;[General]
  echo;Version=1
) > "%SystemRoot%\System32\GroupPolicy\gpt.ini"

exit /b 0

:FNAME
setlocal ENABLEDELAYEDEXPANSION
set "%~1=!%~1::='!"
set "%~1=!%~1:/='!"
set "%~1=!%~1:-='!"
set "%~1=!%~1:.='!"
set "%~1=!%~1:,=''!"
for /F "usebackq tokens=* delims="eol^= %%i in ('"!%~1:;='!"') do endlocal & set "%~1=%%~i"
exit /b

rem end of bat -->

<package>
  <job id="IMPORT_REGISTRY">
    <script language="VBScript">
      Set objShell = CreateObject("WScript.Shell")
      Set objProc = objShell.Environment("Process")

      Set objWMIReg = GetObject("winmgmts://./root/default:StdRegProv")

      Const TypeBinary = 1
      Const HKLM = &H80000002

      ' SysRoot = objProc("SystemRoot") ' relied on the bitness of the parent process (`cmd.exe`)
      SysRoot = objShell.ExpandEnvironmentStrings("%SystemRoot%") ' relied on the bitness of the `cscript.exe` process

      CMD = objProc("CMD")
      CMD_FILE_NAME = objProc("CMD_FILE_NAME")
      ARGS = objProc("ARGS")
      FLAG_SCRIPT = objProc("FLAG_SCRIPT")
      FLAG_PS_SCRIPT = objProc("FLAG_PS_SCRIPT")

      Set objXmlNode = CreateObject("MSXML2.DOMDocument").createElement("bin")
      Set objStream = CreateObject("ADODB.Stream")

      objStream.Type = TypeBinary
      objStream.Open()

      ' binary data as hex string
      objXmlNode.dataType = "bin.hex"
      objXmlNode.text = "00000000000000000000000000000000"

      objStream.Write objXmlNode.nodeTypedValue
      objStream.Position = 0

      ExecTimeBytes = objStream.Read

      objStream.Close
      Set objStream = Nothing
      set objXmlNode = Nothing

      SubKeys = Array("Scripts\Shutdown\0", "State\Machine\Scripts\Shutdown\0")

      For Each Key In SubKeys
        objShell.RegWrite "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Group Policy\" & Key & "\GPO-ID",           "LocalGPO",                                     "REG_SZ"
        objShell.RegWrite "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Group Policy\" & Key & "\SOM-ID",           "Local",                                        "REG_SZ"
        objShell.RegWrite "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Group Policy\" & Key & "\FileSysPath",      SysRoot & "\System32\GroupPolicy\Machine",      "REG_SZ"
        objShell.RegWrite "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Group Policy\" & Key & "\DisplayName",      "Local Group Policy",                           "REG_SZ"
        objShell.RegWrite "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Group Policy\" & Key & "\PSScriptOrder",    &h00000001,                                     "REG_DWORD"

        If FLAG_SCRIPT Then
          objShell.RegWrite "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Group Policy\" & Key & "\0\Script",       CMD_FILE_NAME,                                  "REG_SZ"
        Else
          objShell.RegWrite "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Group Policy\" & Key & "\0\Script",       CMD,                                            "REG_SZ"
        End If
        objShell.RegWrite "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Group Policy\" & Key & "\0\Parameters",     ARGS,                                           "REG_SZ"

        objWMIReg.CreateKey HKLM, "SOFTWARE\Microsoft\Windows\CurrentVersion\Group Policy\" & Key & "\0"
        objWMIReg.SetBinaryValue HKLM, "SOFTWARE\Microsoft\Windows\CurrentVersion\Group Policy\" & Key & "\0", "ExecTime", ExecTimeBytes
      Next

      If FLAG_PS_SCRIPT Then
        objShell.RegWrite "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Group Policy\" & SubKeys(0) & "\0\IsPowershell",  &h00000001,                               "REG_DWORD"
      Else
        objShell.RegWrite "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Group Policy\" & SubKeys(0) & "\0\IsPowershell",  &h00000000,                               "REG_DWORD"
      End If
    </script>
  </job>
</package>
