@echo off

setlocal

"%SystemRoot%\System32\cscript.exe" //nologo "%~dpn0.vbs" %*
