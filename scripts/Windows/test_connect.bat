@echo off

setlocal

rem script names call stack
if defined ?~ ( set "?~=%?~%-^>%~nx0" ) else if defined ?~nx0 ( set "?~=%?~nx0%-^>%~nx0" ) else set "?~=%~nx0"

set "DOMAIN=%~1"
set "PORT=%~2"

if not defined DOMAIN (
  echo;%?~%: error: DOMAIN is not defined.
  exit /b 127
) >&2

if not defined PORT (
  echo;%?~%: error: PORT is not defined.
  exit /b 128
) >&2

echo;$connection = (New-Object Net.Sockets.TcpClient).Connect("%DOMAIN%", %PORT%); If ($connection.Connected) { $connection.Close(); } | powershell -Command -
