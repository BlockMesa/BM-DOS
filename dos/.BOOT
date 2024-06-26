--DOS specific code that used to live in the BIOS
local driveLetter = (bios.getBootedDrive() == "/") and "C" or "A"
_ENV.bios.getDrive = function()
	return driveLetter
end
_ENV.bios.setDrive = function(a)
	driveLetter = a
end

bios.protect("/.boot")
bios.protect(bios.getBootedDrive()..".boot")
term.clear()
term.setCursorPos(1,1)
term.write("Starting BM-DOS...")
term.setCursorPos(1,3)
if not fs.exists(bios.getBootedDrive()) then
	print("ERROR LOADING BOOT DEVICE!") --how does this happen
	while true do os.sleep() end
end
--translate old settings into new settings
if bios.settingsGet("dos.secureboot") then
	bios.settingsSet("bm-bios.secureboot",true)
	bios.settingsSet("dos.secureboot",false)
	bios.settingsSet("bm-bios.passphrase",bios.settingsGet("dos.passphrase"))
	bios.settingsSet("dos.passphrase",false)
	settings.save()
	os.reboot()
end
if fs.exists(bios.getBootedDrive().."COMMAND.COM") then
	local success, response = pcall(os.run,{bios=bios},bios.getBootedDrive().."COMMAND.COM")
	if not success then
		while true do os.sleep() end
	end
else
	while true do
		print("Bad or missing Command Interpretor\nEnter correct name of Command Interpreter (eg, /COMMAND.COM)")
		term.write(bios.getDrive().."> ")
		local thing = read()
		local success, response = pcall(os.run,{bios=bios},thing)
	end
end
