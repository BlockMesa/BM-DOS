echo BM-DOS UNINSTALLER!
echo This does NOT reset the settings file!
echo To fix that, delete .settings!
pause
echo Wiping startup.lua/bios.lua
update-file startup.lua https://raw.githubusercontent.com/BlockMesa/BM-DOS/main/blank.lua
echo Wiping .BOOT
update-file .BOOT https://raw.githubusercontent.com/BlockMesa/BM-DOS/main/blank.lua
echo Wiping COMMAND.COM
update-file COMMAND.COM https://raw.githubusercontent.com/BlockMesa/BM-DOS/main/blank.lua
echo Done!
pause
reboot