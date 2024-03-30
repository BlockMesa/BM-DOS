local baseUrl = "https://raw.githubusercontent.com/BlockMesa/BM-DOS/master/"
print("Installing BM-DOS")
if not settings.get("dos.hasFinishedSetup")
	term.write("Install BM-DOS to this computer? Y/n: ")
	local command = read()
	if string.lower(command) == "y" then
		shell.run("wget "..baseUrl.."bios.lua startup.lua")

		--setting the settings
		settings.set("bios.use_multishell",false)
		settings.set("shell.allow_disk_startup",false)
		settings.set("dos.hasFinishedSetup",true)
		settings.save()
	end
end
if fs.exists("/disk") then
	local diskName = peripheral.getName(peripheral.find("drive"))
	term.write("Make boot disk? Y/n: ")
	local command = read()
	if string.lower(command) == "y" then
		shell.run("wget "..baseUrl.."dos/.BOOT disk/.BOOT")
		shell.run("wget "..baseUrl.."dos/COMMAND.COM disk/COMMAND.COM")
		shell.run("wget "..baseUrl.."dos/autoexec.bat disk/autoexec.bat")
		disk.setLabel(diskName, "BM-DOS v1.10")
	end
end

print("Rebooting in 3 seconds!")
sleep(1)
print("Rebooting in 2 seconds!")
sleep(1)
print("Rebooting in 1 seconds!")
sleep(1)
print("Rebooting!")
os.reboot()