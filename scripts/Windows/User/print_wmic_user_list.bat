@echo off

setlocal

"%SystemRoot%\System32\wbem\wmic.exe" useraccount get name,sid /format:csv
