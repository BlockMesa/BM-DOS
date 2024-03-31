local path = bios.getBootedDrive()
term.clear()
term.setCursorPos(1,1)
term.write("Starting BM-DOS...")
term.setCursorPos(1,3)
if not fs.find(path) then
	print("ERROR LOADING BOOT DEVICE!") --how does this happen
	while true do os.sleep() end
end

if fs.exists(bios.getBootedDrive().."COMMAND.COM") then
	local success, response = pcall(os.run,{},bios.getBootedDrive().."COMMAND.COM")
	if not success then
		while true do os.sleep() end
	end
else
	while true do
		print("Bad or missing Command Interpretor\nEnter correct name of Command Interpreter (eg, /COMMAND.COM)")
		term.write(bios.getDrive().."> ")
		local thing = read()
		local success, response = pcall(os.run,{},thing)
	end
end
