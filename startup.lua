os.pullEvent = os.pullEventRaw
term.redirect(term.native)
term.setPaletteColour(colors.white, 0xE9A226)
term.setPaletteColour(colors.black, 0x43422C)
term.clear()
if not settings.get("dos.hasFinishedSetup") then
	settings.set("bios.use_multishell",false)
	settings.set("shell.allow_disk_startup",false)
	settings.set("list.show_hidden",false)
	settings.set("shell.autocomplete",false)
	settings.set("dos.hasFinishedSetup",true)
	settings.save()
	print("Rebooting...")
end
if not fs.find("disk") and not fs.find("/disk/.BOOT") then
	print("NO BOOT DEVICE FOUND!")
	while true do os.sleep() end
else
	local success, response = pcall(os.run,{['shell']=shell},"/disk/command.com")
	if not success then
		print(response)
		while true do os.sleep() end
	end
end