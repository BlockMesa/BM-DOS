rem Obselete!
rem A new update could render this unusable!
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