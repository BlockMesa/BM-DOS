--hidden programs stuff originally by someone else
--i forget who originally made it and i cant find the post, sorry :(

-- #### Preperation
term.clear()
term.setCursorPos(1,1)
term.write("Starting BM-DOS...")
term.setCursorPos(1,3)
if not fs.find("disk") then
	print("ERROR LOADING BOOT DEVICE!")
	while true do os.sleep() end
end


-- #### Vars
local hiddenPrograms = {"rom", "startup.lua", ".BOOT"}
local fake = {}
local real = {}

-- #### "Local" functions
local function shouldBeHidden(path)
	for i=1, #hiddenPrograms do
		if string.lower(path) == string.lower(hiddenPrograms[i]) then
			return true
		end
	end
	return false
end

-- #### Tweaking compromising functions
real.error = _G.printError
function fakeError(text)
	if type(string.find(text, "startup.lua:")) == "number" then
		return false
	else
		real.error(text)
	end
end
_G.printError = fakeError

real.find = fs.find
local function fakeFind(path)
	if string.lower(path) == "startup" then
		path = userStartupPath
	end
	if shouldBeHidden(path) == true then
		return nil
	end

	list = real.find(path)
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
		if list[i] == userStartupPath then
			list[i] = "startup"
		end
	end
	return list
end
_G.fs.find = fakeFind

real.list = fs.list
local function fakeList(path)
	list = real.list(path)
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
		if list[i] == "startup" then
			table.remove(list, i)
		end
	end
	for i=1,#list do
		if list[i] == userStartupPath then
			list[i] = "startup"
		end
	end	
	return list
end
_G.fs.list = fakeList

real.exists = fs.exists
local function fakeExists(path)
	if shouldBeHidden(path) == true then
		return nil
	end
	return real.exists(path)
end
_G.fs.exists = fakeExists

real.ioOpen = io.open
local function fakeIoOpen(path)
	if shouldBeHidden(path) == true then
		return nil
	end
	if string.lower(path) == "command.com" then
		return nil
	end	
	return real.ioOpen(path)
end
_G.io.open = fakeIoOpen


real.makeDir = fs.makeDir

real.delete = fs.delete
_G.fs.makeDir = function(...) return end
--_G.fs.isDir = function(...) return false end

local function fakeDelete(path)
	if shouldBeHidden(path) == true then
		return nil
	end
	if string.lower(path) == "command.com" then
		return nil
	end	
	return real.delete(path)
end
_G.fs.delete = fakeDelete

real.open = fs.open
local function fakeOpen(path, mode)
	if shouldBeHidden(path) == true then
		return nil
	end
	if string.lower(path) == "command.com" then
		return nil
	end	
	return real.open(path, mode)
end
_G.fs.open = fakeOpen

real.isReadOnly = fs.isReadOnly
local function fakeIsReadOnly(path)
	if shouldBeHidden(path) == true then
		return nil
	end
	if string.lower(path) == "command.com" then
		return true
	end
	return real.isReadOnly(path)
end
_G.fs.isReadOnly = fakeIsReadOnly

real.getSize = fs.getSize
local function fakeGetSize(path)
	if shouldBeHidden(path) == true then
		return nil
	end
	return real.getSize(path)
end
_G.fs.getSize = fakeGetSize

real.move = fs.move
local function fakeMove(fromPath, toPath)
	if shouldBeHidden(fromPath) == true or shouldBeHidden(toPath) == true then
		return nil
	end
	if string.lower(fromPath) == "command.com" then
		return nil
	end
	
	return real.move(fromPath, toPath)
end
_G.fs.move = fakeMove

real.copy = fs.copy
local function fakeCopy(fromPath, toPath)
	if shouldBeHidden(fromPath) == true or shouldBeHidden(toPath) == true then
		return nil
	end

	
	return real.copy(fromPath, toPath)
end
_G.fs.copy = fakeCopy

_G.table.shallow_copy = function(t) --https://stackoverflow.com/a/641993
  local t2 = {}
  for k,v in pairs(t) do
    t2[k] = v
  end
  return t2
end

--modify the env
shell.setDir("/disk/")
shell.setDir = function(...) return end
shell.dir = function(...) return "/" end
shell.openTab = nil
shell.switchTab = nil



if real.exists("/disk/COMMAND.COM") then
	local success, response = pcall(os.run,{['shell']=shell},"/disk/COMMAND.COM")
	if not success then
		while true do os.sleep() end
	end
else
	while true do
		print("Bad or missing Command Interpretor\nEnter correct name of Command Interpretor (eg, /COMMAND.COM)")
		term.write("A> ")
		read()
	end
end