local baseUrl = "https://raw.githubusercontent.com/BlockMesa/BM-DOS/main/"
print("Installing BM-DOS")
if not settings.get("dos.hasFinishedSetup") then
	term.write("Install BM-DOS to this computer? y/N: ")
	local command = read()
	if string.lower(command) == "y" then
		shell.run("wget https://raw.githubusercontent.com/BlockMesa/BM-BIOS/main/bios.lua startup.lua")
		shell.run("wget "..baseUrl.."dos/.BOOT .BOOT")
		shell.run("wget "..baseUrl.."dos/COMMAND.COM COMMAND.COM")
		shell.run("wget "..baseUrl.."dos/autoexec.bat autoexec.bat")

		--setting the settings
		settings.set("bios.use_multishell",false)
		settings.set("shell.allow_disk_startup",false)
		settings.set("dos.hasFinishedSetup",true)
		settings.save()
	end
end
if fs.exists("/disk") then
	local diskName = peripheral.getName(peripheral.find("drive"))
	term.write("Make boot disk? n/Y: ")
	local command = read()
	if string.lower(command) == "y" then
		shell.run("wget "..baseUrl.."dos/.BOOT disk/.BOOT")
		shell.run("wget "..baseUrl.."dos/COMMAND.COM disk/COMMAND.COM")
		shell.run("wget "..baseUrl.."dos/autoexec.bat disk/autoexec.bat")
		disk.setLabel(diskName, "BM-DOS Boot Disk")
	end
end

for s=3,1,-1 do
	print(("Rebooting in %d seconds"):format(s))
	sleep(1)
end
print("Rebooting!")
os.reboot()
