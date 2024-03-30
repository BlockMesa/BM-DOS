echo Boot disk creator/updater
pause
echo Updating .BOOT
update-file disk/.BOOT https://raw.githubusercontent.com/BlockMesa/BM-DOS/main/dos/.BOOT
echo Updating COMMAND.COM
update-file disk/COMMAND.COM https://raw.githubusercontent.com/BlockMesa/BM-DOS/main/dos/COMMAND.COM
echo Done!
pause
