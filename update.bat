rem This can't be used to install to a new computer because the BIOS is needed to boot
rem You *could* add bios.lua to the bootdisk but theres no point
echo BM-DOS UPDATER!
echo This does NOT update bootdisks!
echo To update those, run bootdisk.bat!
pause
echo Updating startup.lua/bios.lua
update-file startup.lua https://raw.githubusercontent.com/BlockMesa/BM-DOS/main/bios.lua
echo Updating .BOOT
update-file .BOOT https://raw.githubusercontent.com/BlockMesa/BM-DOS/main/dos/.BOOT
echo Updating COMMAND.COM
update-file COMMAND.COM https://raw.githubusercontent.com/BlockMesa/BM-DOS/main/dos/COMMAND.COM
echo Done!
pause
reboot