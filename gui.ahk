#Requires AutoHotkey v2.0
#SingleInstance Force


DetectHiddenWindows 1

OnMessage(0x112, (wParam, *) => wParam = 0xF020 ? destroyUi() : "") ; wParam = WM_SYSCOMMAND, 0xF020 = SC_MINIMIZE
OnExit(Showall)

TraySetIcon(A_ScriptDir . "\lib\icon.ico")

configPath := A_ScriptDir . "\config.ini"

AutostartRegPath := "HKCU\Software\Microsoft\Windows\CurrentVersion\Run"
AutoStartRegName := "RDPWindowManager"

ExpectedCount := IniRead(configPath, "Main", "ExpectedCount", 1)
Blacklist := IniRead(configPath, "Main", "Blacklist", "")
Timeout := IniRead(configPath, "Main", "Timeout", 30)
TutorialComplete := IniRead(configPath, "Main", "TutorialComplete", 0)

if !TutorialComplete
    Msgbox("Before you begin, it's important that each RDP has it's own unique title. I would suggest making the title the name of the roblox account, or something like 'Main', 'Tad Alt', etc."), IniWrite(1, configPath, "Main", "TutorialComplete")

title := "RDPs"

A_TrayMenu.Delete()
A_TrayMenu.Add("Show/Hide UI", (*) => IsSet(Ui) ? destroyUi() : drawUi())
A_TrayMenu.Add("Help", (*) => Help())
A_TrayMenu.Add("Exit", (*) => ExitApp())
A_TrayMenu.Add()
A_TrayMenu.Add("Hide RDPs", (*) => Hideall())
A_TrayMenu.Add("Show RDPs", (*) => Showall())
A_TrayMenu.Add()
A_TrayMenu.Add(title, (*) => A_TrayMenu.Show())
A_TrayMenu.Disable(title)

A_TrayMenu.ClickCount := 1
A_TrayMenu.Default := title


if !(A_Args.Has(1) && (A_Args[1] = "1"))
    drawUi() ; only draw ui if opened directly

drawUi(){
    global
    if IsSet(Ui)
        destroyUi()

    Ui := Gui("+AlwaysOnTop -MaximizeBox", "RDP Window Manager")

    Ui.BackColor := 0xff808080
    Ui.SetFont("s10 cffffff", "Cascadia Mono")

    task := RegRead(AutostartRegPath, AutoStartRegName, "")

    if !task
        validAutostart := 0
    else
    {
        ; modified from Args() By SKAN,  http://goo.gl/JfMNpN,  CD:23/Aug/2014 | MD:24/Aug/2014
        A := [], pArgs := DllCall("Shell32\CommandLineToArgvW", "Str",task, "PtrP",&nArgs:=0, "Ptr")
        Loop nArgs
            A.Push(StrGet(NumGet((A_Index - 1) * A_PtrSize + pArgs, "UPtr"), "UTF-16"))
        DllCall("LocalFree", "Ptr", pArgs)

        validScript := (A.Has(1) && (A[1] = A_ScriptDir "\lib\AutoHotkey64.exe") && A.Has(2) && (A[2] = A_ScriptDir "\handler.ahk"))
        validAutostart := validScript ? 1 : 0
    }

    Ui.Add("Text", "xp y5 w205 +Center vAutostart c" (validAutostart ? "00ff00" : "ff0000"), validAutostart ? "Auto Start:`sActive" : "Auto Start:`sInactive")

    Ui.Add("Button", "xp yp+20 w100 vAdd h25 Disabled" validAutostart, "Add").OnEvent("Click", registerAutostart)
    Ui.Add("Button", "xp+105 yp w100 vRemove h25 Disabled" (!validAutostart), "Remove").OnEvent("Click", deregisterAutostart)

    Ui.Add("Text", "x220 y5 +BackgroundTrans", "Expected RDPs")
    Ui.Add("Text", "xp yp+22", "#")
    Ui.Add("Edit", "xp+10 yp-2 w20 vExpectedCount Number c000", ExpectedCount).OnEvent("Change", (Ctrl, *) => (IniWrite((ExpectedCount := Ctrl.Value), configPath, "Main", "ExpectedCount")))
    Ui.Add("Edit", "xp+40 yp w43 vTimeout Number c000", Timeout).OnEvent("Change", (Ctrl, *) => (IniWrite((Timeout := Ctrl.Value), configPath, "Main", "Timeout")))
    Ui.Add("Text", "xp+45 y27", "sec")
    Ui.Add("Text", "x330 y5 +BackgroundTrans c00ffff", "?").OnEvent("Click", (*) => (MsgBox(
        "Only needed for Autostart. The script will wait for the specified amount of seconds for the specified number of RDP windows before exiting`nSetting seconds to 0 will make the script check once"
        , "RDP Window Manager", "Owner" Ui.Hwnd)
    ))

    Ui.Add("Text", "x5 yp+54 w340 h1 0x7")

    Ui.Add("Text", "x5 yp+5 w340 +Center", "Window Title blacklist: ")
    Ui.Add("Edit", "xp yp+20 w340 vBlacklist c000", Blacklist).OnEvent("Change", (Ctrl, *) => (IniWrite((Blacklist := Ctrl.Value), configPath, "Main", "Blacklist")))

    Ui.Add("Button", "xp yp+35 w340 h30", "Hide all").OnEvent("Click", (*) => Hideall())

    Ui.Add("Button", "xp yp+35 w340 h30", "Show all").OnEvent("Click", (*) => Showall())

    Ui.Add("Button", "xp yp+35 w340 h30", "Help").OnEvent("Click", (*) => Help())

    Ui.OnEvent("Close", (*) => ExitApp())

    Ui.Show("w350 h225")
}

destroyUi(){
    global Ui
    Ui.Destroy()
    Ui := unset
}

redrawUi(){
    global Ui
    Ui["Autostart"].Text := validAutostart ? "Auto Start: Active" : "Auto Start: Inactive"
    Ui["Autostart"].SetFont("c" (validAutostart ? "00ff00" : "ff0000"))

    Ui["Add"].Enabled := !(validAutostart)
    Ui["Remove"].Enabled := (validAutostart)
}

Array.Prototype.DefineProp("HasValue", {call: arrayHasValue})

arrayHasValue(this, value){
    for index, item in this {
        if (item = value)
            return index
    }
    return false
}

Map.Prototype.DefineProp("FindKeyByValue", {call: mapFindKeyByValue})

mapFindKeyByValue(this, value){
    for key, val in this {
        if (val = value)
            return key
    }
    return false
}

; representation of RDP windows listed in tray
RDPs := Map()

rdpClass := "ahk_class TscShellContainerClass"

updateTray(){
    RDP_windows := WinGetList(rdpClass, , blacklist)

    for hwnd in RDP_windows {
        hidden := isWindowHidden(hwnd)

        if WinExist(rdpClass " ahk_id " hwnd) = 0
            continue
        
        title := SubStr(WinGetTitle(), 1, 260)

        if !RDPs.Has(hwnd)
            A_TrayMenu.Add(title, (title, *) => toggleWindowMode(title))
        
        if hidden
            addHiddenWindow(hwnd)
        else
            addActiveWindow(hwnd)

        RDPs.Set(hwnd, title)
    }

    for hwnd, title in RDPs {
        if !RDP_windows.HasValue(hwnd) {
            A_TrayMenu.Delete(title)
            RDPs.Delete(hwnd)
        }
    }
}

updateTray()

SetTimer(updateTray, 100)

F2::Reload

isWindowHidden(hwnd) => (DllCall("IsWindowVisible", "Ptr", hwnd) = 0)

addActiveWindow(input) => A_TrayMenu.Check(inputResolver(input))

addHiddenWindow(input) => A_TrayMenu.Uncheck(inputResolver(input))

inputResolver(input){
    if IsNumber(input)
        if WinExist(rdpClass " ahk_id " input)
            return WinGetTitle()
    else ; title
        return SubStr(input, 1, 260)
}

toggleWindowMode(name){
    hwnd := RDPs.FindKeyByValue(name)

    switch isWindowHidden(hwnd){
        case 1:
            WinShow("ahk_id " hwnd)
            addActiveWindow(hwnd)
        case 0:
            WinHide("ahk_id " hwnd)
            addHiddenWindow(hwnd)
    }
}

Hideall() => Run('"' A_ScriptDir '\handler.ahk" "0"')

Showall(*) => Run('"' A_ScriptDir '\handler.ahk" "1"')

Help() => ( Run('https://github.com/Noobyguy775/RDPWindowManager/blob/main/README.md') )


deregisterAutostart(*){
    global validAutostart := 0
    try RegDelete AutostartRegPath, AutoStartRegName
    catch {
        MsgBox("Failed to deregister autostart.")
    }
    redrawUi()
}

registerAutostart(*){
    global validAutostart := 1
    try RegWrite('"' A_ScriptDir '\lib\AutoHotkey64.exe" ' ; executable
        . '"' A_ScriptDir "\handler.ahk" '" ' ; handler
        . '"0" ' ; 0 = hide windows
        . '"1"' ; 1 = repeat until failure (because we're autostarting, the windows might not be open yet)
        , "REG_SZ", AutostartRegPath, AutoStartRegName
    )
    catch {
        MsgBox("Failed to register autostart.")
    }
    redrawUi()
}
