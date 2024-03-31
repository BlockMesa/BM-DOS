--hidden programs stuff originally by someone else
--i forget who originally made it and i cant find the post, sorry :(
--all that remains of that is the fake list

-- #### Preperation
local path = bios.getBootedDrive()

term.clear()
term.setCursorPos(1,1)
term.write("Starting BM-DOS...")
term.setCursorPos(1,3)
if not fs.find(path) then
	print("ERROR LOADING BOOT DEVICE!") --how does this happen
	while true do os.sleep() end
end

-- #### Vars
local real = {}
local hiddenPrograms = {"rom","startup.lua"}
local function shouldBeHidden(path)
	for i=1, #hiddenPrograms do
		if string.lower(path) == string.lower(hiddenPrograms[i]) then
			return true
		end
	end
	return false
end

real.isReadOnly = fs.isReadOnly
local function fakeIsReadOnly(path)
	path = bios.resolvePath(path)
	if string.sub(string.lower(path),1,5) == "/rom/" then
		return true
	end
	if string.lower(path) == "/command.com" then
		return true
	end
	return false--real.isReadOnly(path)
end
_G.fs.isReadOnly = fakeIsReadOnly
real.list = fs.list
local function fakeList(path1)
	local path = bios.resolvePath(path1)
	list = real.list(path)
	if path == "/" then
		for i=1,#list do
			for j=1, #hiddenPrograms do
				if type(list[i]) == "string" then
					if string.lower(list[i]) == string.lower(hiddenPrograms[j]) then
						table.remove(list, i)
					end
				end
			end
		end
		for i=1,#list do
			if bios.getDir() == "/" and string.sub(path,1,4) == "disk" and (string.len(path) == 5 or string.len(path) == 6) then
				table.remove(list, i)
				return
			end
		end
	end
	return list
end
_G.fs.list = fakeList

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
