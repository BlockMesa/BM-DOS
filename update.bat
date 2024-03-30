rem This can't be used to install to a new computer because the BIOS is needed to boot
rem You *could* add bios.lua to the bootdisk but theres no point
echo BM-DOS UPDATER!
echo This does NOT update bootdisks!
echo To update those, run bootdisk.bat!
pause
update-file https://raw.githubusercontent.com/BlockMesa/BM-DOS/main/bios.lua startup.lua
update-file https://raw.githubusercontent.com/BlockMesa/BM-DOS/main/dos/.BOOT .BOOT
update-file https://raw.githubusercontent.com/BlockMesa/BM-DOS/main/dos/COMMAND.COM COMMAND.COM
reboot