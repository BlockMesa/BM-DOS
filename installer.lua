local baseUrl = "https://raw.githubusercontent.com/BlockMesa/MISC/master/BM-DOS/"
print("Installing BM-DOS")
shell.run("wget "..baseUrl.."startup.lua")

--setting the settings
settings.set("bios.use_multishell",false)
settings.set("shell.allow_disk_startup",false)
settings.set("list.show_hidden",false)
settings.set("shell.autocomplete",false)
settings.set("dos.hasFinishedSetup",true)
settings.save()
if fs.find("disk") then
	local diskName = peripheral.getName(peripheral.find("drive"))
	term.write("Make boot disk? Y/n: ")
	local command = read()
	if string.lower(command) == "y" then
		shell.run("wget "..baseUrl.."disk/.BOOT disk/.BOOT")
		shell.run("wget "..baseUrl.."disk/COMMAND.COM disk/COMMAND.COM")
		shell.run("wget "..baseUrl.."disk/autoexec.bat disk/autoexec.bat")
		disk.setLabel(diskName, "BOOT DISK")
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