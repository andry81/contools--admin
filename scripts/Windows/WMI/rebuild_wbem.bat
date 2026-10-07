@echo off & goto DOC_END

rem NOTE:
rem   The general code is based on:
rem     * https://github.com/search?q=repo%3Abmrf%2Ftron%20path%3Arepair_wmi.bat&type=code
rem     * `Is there any Script for Rebuilding WMI` :
rem       https://learn.microsoft.com/en-us/answers/questions/1791997/is-there-any-script-for-rebuilding-wmi
rem     * `WMI: Rebuilding the WMI Repository` :
rem       https://techcommunity.microsoft.com/blog/askperf/wmi-rebuilding-the-wmi-repository/373846

rem NOTE:
rem   The elevation shell code is based on:
rem     `Uniform variant of a command line as a single argument for the mshta.exe executable and other cases` :
rem     https://github.com/andry81/contools/discussions/11

rem NOTE:
rem   A command line or a variable (ex: `__SCRIPT__`) can contain an even
rem   number of double quotes prefixed by the `\` character.
rem
rem   It can be replaced by N/2 number of quotes without the prefix or
rem   a quote with N/2-nested escape sequence:
rem
rem     \""     -> "    or \"
rem     \""""   -> ""   or \\\"
rem     \"""""" -> """  or \\\\\\\"
rem     etc
rem
rem   The meaning is to always use an even number of quotes to insert an
rem   arbitrary number of quotes with or without an escape sequence.
rem
rem   For example, in the `set` command, because
rem   the `set` command argument is started by a double quote:
rem
rem     >
rem     set "A=X \"" | & < > \"""
rem     set "B=Y \"" | & < > \"" | & < > \"""" | & < > \"""""

rem CAUTION:
rem   The environment variables does use by the shell code to workaround the
rem   `mshta.exe` command line length limitation (see the link).

rem CAUTION:
rem   The `mshta.exe` does expand all the %-escape placeholders (`%NN`).
rem   The script does not use `%` character in the shell code. In case of a
rem   change in the future you must prevent the expansion by replacing all the
rem   `%` by `%25` to avoid the command line breakage.
rem   All the `"` does process for the same reason.

rem NOTE:
rem   The `ExecuteGlobal` is used as a workaround, because the `mshta.exe`
rem   first argument must not be used with the surrounded quotes.

rem CAUTION:
rem   The `ShellExecute` does not wait a child process close.

rem CAUTION:
rem   The `cmd.exe` does expand the %-variables in the context of an elevated
rem   process. You must properly escape these to avoid the expansion before the
rem   elevation!

rem CAUTION:
rem   `\""`, `\""""`, etc expressions only has meaning inside a `.bat` script.
rem   Any attempt to use it outside of a script (including a terminal command
rem   line) will lead into incorrect expansion because a terminal command
rem   line or an `.exe` command line has their own different expansion rules
rem   including command line of the `cmd.exe` executable.

rem CAUTION:
rem   Avoid a back slash before the double quote in an executable (`.exe`)
rem   command line, otherwise a command line parse will be broken:
rem     >
rem     some.exe "... ... \"
rem                        ^ - escaped
rem     >
rem     some.exe "... ... \""
rem                        ^ - escaped
rem   To workaround:
rem     >
rem     some.exe "... ... \\"
rem                        ^ - escaped
rem     >
rem     some.exe "... ... \\""
rem                        ^ - escaped
rem
rem   A trailing double quote will be escaped in some command line parse code
rem   runtimes. But not everywhere, for example, `cmd.exe` has different rules:
rem
rem     >
rem     cmd.exe /c @echo "... ... \"
rem                               ^ - prints as is

rem NOTE:
rem   The `::"::"::` is an unexisted statement in the VBS
rem   (error: `VBScript compilation error: Expected statement`) in case of
rem   strip from a string with a valid VBS shell code. So it can be used as a
rem   VBS shell code lines delimiter in another shell code or Windows Batch
rem   script.

rem CAUTION:
rem   If you pass a parameter or set of parameters starting the first argument,
rem   then these may be skipped, due to the internal `cmd.exe` command line
rem   parse logic. The command line does not ignored if started using the slash
rem   character with the known option - `/k`, `/c` and etc.
:DOC_END

rem second `setlocal` to drop locals before a command line execution
setlocal DISABLEDELAYEDEXPANSION & setlocal

rem script names call stack, disabled due to self call and partial inheritance (process elevation does not inherit a parent process variables by default)
rem if defined ?~ ( set "?~=%?~%-^>%~nx0" ) else if defined ?~nx0 ( set "?~=%?~nx0%-^>%~nx0" ) else set "?~=%~nx0"
set "?~=%~nx0"

set /A ELEVATED+=0

if %IMPL_MODE%0 NEQ 0 goto IMPL
call :IS_ADMIN_ELEVATED || goto CALL_ELEVATE_AND_EXIT

goto ELEVATED

rem CAUTIOM:
rem   Windows 7 has an issue around the `find.exe` utility and code page 65001.
rem   We use `findstr.exe` instead of `find.exe` to workaround it.
rem
rem   Based on: https://superuser.com/questions/557387/pipe-not-working-in-cmd-exe-on-windows-7/1869422#1869422

rem CAUTION:
rem   In Windows XP an elevated call under data protection flag will block the wmic tool, so we have to use `ver` command instead!

:IS_ADMIN_ELEVATED
set "WINDOWS_VER_STR=" & set "WINDOWS_MAJOR_VER=0" & for /F "usebackq tokens=1,2,* delims=[]" %%i in (`@ver 2^>nul`) do set "WINDOWS_VER_STR=%%j"
if not defined WINDOWS_VER_STR goto SKIP_VER
setlocal ENABLEDELAYEDEXPANSION & for /F "usebackq tokens=* delims="eol^= %%i in ('"!WINDOWS_VER_STR:* =!"') do endlocal & set "WINDOWS_VER_STR=%%~i"
for /F "tokens=1,2,* delims=."eol^= %%i in ("%WINDOWS_VER_STR%") do set "WINDOWS_MAJOR_VER=%%i"
:SKIP_VER
if %WINDOWS_MAJOR_VER% GEQ 6 (
  if exist "%SystemRoot%\System32\where.exe" "%SystemRoot%\System32\whoami.exe" /groups | "%SystemRoot%\System32\findstr.exe" /L "S-1-16-12288" >nul 2>nul & exit /b
) else if exist "%SystemRoot%\System32\fltmc.exe" "%SystemRoot%\System32\fltmc.exe" >nul 2>nul & exit /b
exit /b 255

:CALL_ELEVATE_AND_EXIT
rem Windows Batch compatible command line with escapes
set "?@=/c @set \""IMPL_MODE=1\"" & \""%~f0\"" %* & pause"

rem shell code
set "__SCRIPT__=ExecuteGlobal(\""Set objProc = CreateObject(\""""WScript.Shell\"""").Environment(\""""Process\"""") : ::"^
::"::CreateObject(\""""Shell.Application\"""").ShellExecute objProc(\""""?0\""""), objProc(\""""?@\""""), \""""\"""", \""""runas\"""", 1 : Close()\"")"

set "__SCRIPT__=%__SCRIPT__:::"::"::=%"

rem command
set "?0="

(
  setlocal ENABLEDELAYEDEXPANSION

  if defined COMSPEC set "?0=!COMSPEC!"

  rem translate Windows Batch compatible escapes into escape placeholders
  set "__SCRIPT__=!__SCRIPT__:$=$0!"
  set "__SCRIPT__=!__SCRIPT__:\""""""=$3!"
  set "__SCRIPT__=!__SCRIPT__:\""""=$2!"
  set "__SCRIPT__=!__SCRIPT__:\""=$1!"
  set "__SCRIPT__=!__SCRIPT__:"^=$1!"

  set "?@=!?@:$=$0!"
  set "?@=!?@:\""""""=$3!"
  set "?@=!?@:\""""=$2!"
  set "?@=!?@:\""=$1!"
  set "?@=!?@:"^=$1!"

  rem translate escape placeholders into `mshta.exe` (vbs) escapes
  set "__SCRIPT__=!__SCRIPT__:$3=""""!"
  set "__SCRIPT__=!__SCRIPT__:$2=""!"
  set "__SCRIPT__=!__SCRIPT__:$1="!"
  set "__SCRIPT__=!__SCRIPT__:$0=$!"

  set "?@=!?@:$3=""""!"
  set "?@=!?@:$2=""!"
  set "?@=!?@:$1="!"
  set "?@=!?@:$0=$!"

  rem with locals drop
  for /F "tokens=* delims="eol^= %%i in ("!__SCRIPT__!") do break ^
  & for /F "usebackq tokens=* delims="eol^= %%j in ('"!?0!"') do break ^
  & for /F "usebackq tokens=* delims="eol^= %%k in ('"!?@!"') do endlocal & endlocal ^
  & set "?0=%%~j" & set "?@=%%~k" ^
  & start "" /B /WAIT "%SystemRoot%\System32\mshta.exe" vbscript:%%i
  exit /b
)

:ELEVATED
set ELEVATED=1

:IMPL
if %ELEVATED% EQU 0 call :IS_ADMIN_ELEVATED || (
  echo;%?~%: error: process must be elevated before continue.
  exit /b 255
) >&2

rem ===========================================================================

rem stop dependencies
for /f "usebackq tokens=1,* delims= "eol^= %%i in (`@"%%SystemRoot%%\System32\sc.exe" enumdepend winmgmt ^| "%%SystemRoot%%\System32\findstr.exe" -i "SERVICE_NAME"`) do call :CMD "%%SystemRoot%%\System32\net.exe" stop %%j /y

call :CMD "%%SystemRoot%%\System32\net.exe" stop winmgmt /y
call :CMD "%%SystemRoot%%\System32\sc.exe" stop winmgmt

timeout /t 5

call :CMD "%%SYSDIR%%\wbem\winmgmt.exe" /verifyrepository
call :CMD "%%SYSDIR%%\wbem\winmgmt.exe" /salvagerepository

set "SYSDIR=%SystemRoot%\System32" && call :REREG
set "SYSDIR=%SystemRoot%\SysWOW64" && call :REREG

call :CMD "%%SystemRoot%%\System32\sc.exe" start winmgmt

for /f "usebackq tokens=1,* delims= "eol^= %%i in (`@"%%SystemRoot%%\System32\sc.exe" enumdepend winmgmt ^| "%%SystemRoot%%\System32\findstr.exe" -i "SERVICE_NAME"`) do call :CMD "%%SystemRoot%%\System32\sc.exe" start %%j

timeout /t 5

call :CMD "%%SystemRoot%%\System32\wbem\winmgmt.exe" /resyncperf
call :CMD "%%SystemRoot%%\SysWOW64\wbem\winmgmt.exe" /resyncperf

exit /b 0

:REREG
call :CMD cd /d "%%SYSDIR%%\wbem" || exit /b

echo;Rebuilding "%SYSDIR%"...

call :CMD "%%SYSDIR%%\wbem\winmgmt.exe" /clearadap
call :CMD "%%SYSDIR%%\wbem\winmgmt.exe" /kill

setlocal

rem CD to system drive root
call :CMD cd /d "%%SystemDrive%%"

call :CMD "%SYSDIR%\regsvr32.exe" /s "%SYSDIR%\scecli.dll"
call :CMD "%SYSDIR%\regsvr32.exe" /s "%SYSDIR%\userenv.dll"

rem rebuild at first
for %%i in (cimwin32 rsop) do (
  call :CMD "%%SYSDIR%%\wbem\mofcomp.exe" "%%SYSDIR%%\wbem\%%i.mof"
  call :CMD "%%SYSDIR%%\wbem\mofcomp.exe" "%%SYSDIR%%\wbem\%%i.mfl"
)

endlocal

for /F "usebackq tokens=* delims="eol^= %%i in (`@dir *.dll /A:-D /B /O:N`) do ^
set "FILE=%%i" & call :CMD "%%SYSDIR%%\regsvr32.exe" /s "%%FILE%%"

for /F "usebackq tokens=* delims="eol^= %%i in (`@dir *.exe /A:-D /B /O:N`) do ^
if /i not "%%i" == "wbemcntl.exe" ^
if /i not "%%i" == "wbemtest.exe" ^
if /i not "%%i" == "wmic.exe" ^
if /i not "%%i" == "mofcomp.exe" ^
set "FILE=%%i" & call :CMD "%%FILE%%" /regserver

setlocal

rem CD to system drive root
call :CMD cd /d "%%SystemDrive%%"

rem exclude `uninstall` and `remove`
for /F "usebackq tokens=* delims="eol^= %%i in (`@dir "%%SYSDIR%%\wbem\*.mof" /A:-D /B /O:N ^| "%%SystemRoot%%\System32\findstr.exe" /I /V /C:"uninstall" /C:"remove"`) do ^
set "FILE=%%i" & call :CMD "%%SYSDIR%%\wbem\mofcomp.exe" "%%SYSDIR%%\wbem\%%FILE%%"

if exist "%SYSDIR%\wbem\MUI\*" ^
for /F "usebackq tokens=* delims="eol^= %%i in (`@dir "%%SYSDIR%%\wbem\MUI\*.mof" /A:-D /B /O:N /S ^| "%%SystemRoot%%\System32\findstr.exe" /I /V /C:"uninstall" /C:"remove"`) do ^
set "FILE=%%i" & call :CMD "%%SYSDIR%%\wbem\mofcomp.exe" "%%FILE%%"

for /F "usebackq tokens=* delims="eol^= %%i in (`@dir "%%SYSDIR%%\wbem\*.mfl" /A:-D /B /O:N ^| "%%SystemRoot%%\System32\findstr.exe" /I /V /C:"uninstall" /C:"remove"`) do ^
set "FILE=%%i" & call :CMD "%%SYSDIR%%\wbem\mofcomp.exe" "%%SYSDIR%%\wbem\%%FILE%%"

if exist "%SYSDIR%\wbem\MUI\*" ^
for /F "usebackq tokens=* delims="eol^= %%i in (`@dir "%%SYSDIR%%\wbem\MUI\*.mfl" /A:-D /B /O:N /S ^| "%%SystemRoot%%\System32\findstr.exe" /I /V /C:"uninstall" /C:"remove"`) do ^
set "FILE=%%i" & call :CMD "%%SYSDIR%%\wbem\mofcomp.exe" "%%FILE%%"

if exist "%SYSDIR%\wbem\exwmi.mof" (
  call :CMD "%%SYSDIR%%\wbem\mofcomp.exe" "%%SYSDIR%%\wbem\exwmi.mof"

  call :CMD "%%SYSDIR%%\wbem\mofcomp.exe" -n:root\cimv2\applications\exchange "%%SYSDIR%%\wbem\wbemcons.mof"
  call :CMD "%%SYSDIR%%\wbem\mofcomp.exe" -n:root\cimv2\applications\exchange "%%SYSDIR%%\wbem\smtpcons.mof"

  call :CMD "%%SYSDIR%%\wbem\mofcomp.exe" "%%SYSDIR%%\wbem\exmgmt.mof"
)

endlocal

rem call :CMD "%%SYSDIR%%\rundll32.exe" wbemupgd, UpgradeRepository
call :CMD "%%SYSDIR%%\rundll32.exe" wbemupgd, RepairWMISetup

rem trigger a post install by `wmic.exe` execution
call :CMD_NOSTDOUT "%%SYSDIR%%\wbem\wmic.exe" exit
call :CMD_NOSTDOUT "%%SYSDIR%%\wbem\wmic.exe" computersystem get name
call :CMD_NOSTDOUT "%%SYSDIR%%\wbem\wmic.exe" path Win32_OperatingSystem get LocalDateTime

echo;===
echo;

exit /b 0

:CMD
echo;^>%*
(
  %*
)
echo;
exit /b 0

:CMD_NOSTDOUT
echo;^>%*
(
  %*
) >nul
echo;
exit /b 0