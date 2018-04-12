
rem Modify these as appropriate for your environment

SET SRC=%userprofile%\Documents\HANDS Briefcase\HANDS Documents\Software
SET DST=%appdata%\HANDSBox

rem Install the desktop shortcut
copy "%SRC%\HANDS Box.lnk" "%userprofile%\Desktop\HANDS Box.lnk"

rem Stop any running HANDS Box
taskkill /IM "HANDS Box.exe"

rem Copy program files one by one
copy "%SRC%\HANDS Box.exe" "%DST%\HANDS Box.exe" /Y
copy "%SRC%\pdftk.exe" "%DST%\pdftk.exe" /Y
copy "%SRC%\libiconv2.dll" "%DST%\libiconv2.dll" /Y
copy "%SRC%\Sync HANDS Box.ffs_batch" "%DST%\Sync HANDS Box.ffs_batch" /Y
copy "%SRC%\hands_defaults.ini" "%DST%\hands_defaults.ini" /Y

rem Re-launch the HANDS Box
start "" "%DST%\HANDS Box.exe"

rem Finally, update the updater script itself
cmd /c copy "%SRC%\updateinstall.cmd" "%DST%\updateinstall.cmd" /Y
