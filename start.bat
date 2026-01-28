@echo off
setlocal EnableDelayedExpansion
chcp 65001 > nul
cd %~dp0

if exist "gui.ahk" (
	if exist "lib\AutoHotkey64.exe" (
		start "" "%~dp0lib\AutoHotkey64.exe" "%~dp0gui.ahk" %*
		exit
	)
)

echo Couldn't launch automatically. Try downloading autohotkey and running 'gui.ahk' manually:
echo https://www.autohotkey.com/download/ (v2.0)
<nul set /p "=Press any key to exit . . ."
pause >nul
exit
