@echo off

rem Based on:
rem   https://stackoverflow.com/questions/21689831/change-regional-and-language-options-in-batch/21701835#21701835

start "" /B Rundll32 User32.dll,UpdatePerUserSystemParameters ,1 ,True