## RDP Window Hider
A Ui that can manage RDP windows' hiding/showing with features like Autostart and a blacklist

To get started, run `start.bat`

### Ui
The Ui is launched by running `start.bat` (which runs `gui.ahk`). Here you can manage Auto start and also access a few useful settings, such as the blacklist and autostart settings.

To add the RDP handler to your startup programs, click the Add button. To remove it, press the Remove button.

The autostart is created at the following registry address:
`HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run`.

More details about autostart can be found in the Autostart section.

For information about how the blacklist works, please read [this](https://www.autohotkey.com/docs/v2/misc/WinTitle.htm#multi)
(As far as I've tested, it only works with one title. this might be fixed in the future)

### System Tray
Pressing the — button (minimize) will destroy the UI, but the program will stay running.

Whenever the program is running (with a UI or without it), the icon will appear in your system tray, allowing you to manage hidden RDP windows manually. Hidden RDP windows should be displayed in your system tray after the Hide all/Show all buttons.

### Autostart
When you enable autostart, `handler.ahk` will run upon the startup using values from `config.ini` (automatically set by `gui.ahk`).

After reaching the expected # of RDPs, the handler will exit (and start `gui.ahk` in your tray). However, if the number of RDPs is not found within the timeout provided, an error box will be shown for a few seconds letting the user know that the script was not successful.
