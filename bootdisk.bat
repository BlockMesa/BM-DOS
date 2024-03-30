echo Boot disk creator/updater
pause
erase disk/.BOOT
erase disk/COMMAND.COM
erase disk/autoexec.bat
wget https://raw.githubusercontent.com/BlockMesa/BM-DOS/master/dos/.BOOT disk/.BOOT
wget https://raw.githubusercontent.com/BlockMesa/BM-DOS/master/dos/COMMAND.COM disk/COMMAND.COM
wget https://raw.githubusercontent.com/BlockMesa/BM-DOS/master/dos/autoexec.bat disk/autoexec.bat