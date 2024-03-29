--inject code stolen from https://pastebin.com/yzfDMjwf
os.pullEvent = os.pullEventRaw
term.redirect(term.native())
term.clear()
local oldShell = _G.shell
if not settings.get("dos.hasFinishedSetup") then
	settings.set("bios.use_multishell",false)
	settings.set("shell.allow_disk_startup",false)
	settings.set("list.show_hidden",false)
	settings.set("shell.autocomplete",false)
	settings.set("dos.hasFinishedSetup",true)
	settings.save()
	print("Rebooting...")
	os.reboot()
end
local function boot()
	if not fs.find("disk") and not fs.find("/disk/.BOOT") then
		print("NO BOOT DEVICE FOUND!")
		while true do os.sleep() end
	else
		local success, response = pcall(os.run,{['shell']=oldShell},"/disk/command.com")
		if not success then
			print(response)
			while true do os.sleep() end
		end
	end
end
local oldErr = printError
local oldPull = os.pullEvent
local function overwrite()
    _G.printError = oldErr
	_G.os.pullEvent = oldPull
    _G['rednet'] = nil
    os.loadAPI("/rom/apis/rednet")
	term.redirect(term.native())
	term.setPaletteColour(colors.white, 0xE9A226)
	term.setPaletteColour(colors.black, 0x43422C)
	term.clear()
	term.setCursorPos(1,1)
	local success, err = parallel.waitForAny(boot, rednet.run)
	if not success then
		print(err)
		print("Press any key to continue.")
		os.pullEvent("key")
	end
end

_G.printError = overwrite
_G.os.pullEvent = nil
os.queueEvent("terminate")

