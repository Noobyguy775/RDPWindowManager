#Requires AutoHotkey v2.0
#SingleInstance Force
#NoTrayIcon

/** ARGS
 * 1 = action:
    * 0 = hide RDP windows
    * 1 = show RDP windows
 * 2 = continue until failure
    * boolean 
 */

if (A_Args.Length = 0)
{
	msgbox "This script is not meant to be run directly. Please use the GUI window to launch"
	ExitApp
}

action ?? (action := A_Args[1])
repeat ?? (repeat := (A_Args.Has(2) ? A_Args[2] : false))

DetectHiddenWindows 1
CoordMode "Tooltip", "Screen"

mstscPath := A_WinDir . "\System32\mstsc.exe"
className := "TscShellContainerClass"
configPath := A_ScriptDir . "\config.ini"

minimizeWindowOffset := 115

expected_count := IniRead(configPath, "Main", "ExpectedCount", 0)
blacklist_titles := Trim(IniRead(configPath, "Main", "Blacklist", ""))
timeout := IniRead(configPath, "Main", "Timeout", 30)

managedWindows := []


while (!repeat && A_Index = 1 ;run once 
    || repeat && (!(expected_count <= managedWindows.Length) && !(A_Index > timeout)) ;run until all windows found or until timeout
){
    RDP_windows := WinGetList("ahk_exe " mstscPath " ahk_class " className, , blacklist_titles)
    
    switch A_Args[1]
    {
        case 0:
            HideWindows()
        case 1:
            ShowWindows()
    }
    sleep 1000
    if repeat
        ToolTip "[RDP Window Manager] " A_Index " sec: Found " managedWindows.Length "/" expected_count " RDP windows...", 0, 0
    if A_Index = timeout 
        MsgBox "Failed to find all windows after " timeout " attempts. Found " managedWindows.Length "/" expected_count ". Exiting in 10 seconds.", "RDP Window Manager", "T10"
}
if repeat {
    Tooltip "", 0, 0

    if !WinExist("gui.ahk ahk_class AutoHotkey")
        Run('"' A_ScriptDir '\lib\AutoHotkey64.exe" "' A_ScriptDir '\gui.ahk" "1"')
}

HideWindows(){
    for hwnd in RDP_windows {
        if managedWindows.Has(hwnd)
            continue

        WinHide("ahk_id " hwnd)

        managedWindows.Push(hwnd)
    }
}

ShowWindows(){
    for hwnd in RDP_windows {
        if managedWindows.Has(hwnd)
            continue

        WinShow("ahk_id " hwnd)

        managedWindows.Push(hwnd)
    }
}
