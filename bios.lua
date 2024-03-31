--BLOCK MESA BIOS
--Used for all Block Mesa bootable computers
--inject code stolen from https://pastebin.com/yzfDMjwf
local oldPull = os.pullEvent
local oldRequire = _ENV.require
local oldSettingsGet = settings.get
local oldSettingsSet = settings.set
local fsOpen = fs.open
local oldDebug = _G.debug
_G.os.pullEvent = os.pullEventRaw
_G.os.pullEventOld = oldPull

--internal flag things
local version = "1.20"
local isDiskBooted = false
local baseDirectory = ""
local directory = "/"
local driveLetter = "C"

local whiteColor = 0x00FF00
local blackColor = 0x000000
local function setColors()
	term.redirect(term.native())
	term.setPaletteColour(colors.white, whiteColor)
	term.setPaletteColour(colors.red, whiteColor)
	term.setPaletteColour(colors.yellow, whiteColor)
	term.setPaletteColour(colors.orange, whiteColor)
	term.setPaletteColour(colors.lime, whiteColor)
	term.setPaletteColour(colors.green, whiteColor)
	term.setPaletteColour(colors.blue, whiteColor)
	term.setPaletteColour(colors.cyan, whiteColor)

	term.setPaletteColour(colors.black, blackColor)
	term.setPaletteColour(colors.gray, blackColor)
	term.setBackgroundColor(colors.black)
	term.setTextColor(colors.white)
end
local function resolvePath(path)
    local matches = {}
    for i in path:gmatch("[^/]+") do
        table.insert(matches,i)
    end
    local result1 = {}
    local lastIndex = 1
    for i,v in pairs(matches) do
        if v ~= "." then
            if v== ".." then
                result1[lastIndex] = nil
                lastIndex = lastIndex-1
            else
                lastIndex = lastIndex + 1
                result1[lastIndex] = v
            end
        end
    end
    local result = {}
    for i,v in pairs(result1) do
        table.insert(result,v)
    end
    local final = "/"
    for i,v in pairs(result) do
        if i ~= 1 then
            final = final .. "/"
        end
        final = final..v
    end
    return final
end
local function setupTerm()
	setColors()
	term.setCursorBlink(false)
	term.clear()
	term.setCursorPos(1,1)
	print("BLOCK MESA BIOS v"..version)
end
setupTerm()
local function enterSetup()
	--For a future update
end
if not oldSettingsGet("dos.hasFinishedSetup") then
	oldSettingsSet("bios.use_multishell",false)
	oldSettingsSet("shell.allow_disk_startup",false)
	oldSettingsSet("dos.hasFinishedSetup",true)
	settings.save()
	print("Rebooting...")
	os.reboot()
end
local bootIntoSetup = settings.get("dos.bootToSetup")
if bootIntoSetup == nil or bootIntoSetup then
	enterSetup()
end
local notAllowed = {
	["/startup.lua"] = true,
	["/startup"] = true,
	["/startup.lua/"] = true,
	["/startup/"] = true,
	["/.settings"] = true,
	["/.settings/"] = true,
}
local updateUrl = "https://raw.githubusercontent.com/BlockMesa/BM-DOS/main/"
local bios = {
	getBootedDrive = function()
		return baseDirectory
	end,
	isDiskBooted = function()
		return isDiskBooted
	end,
	getDir = function()
		return directory
	end,
	setDir = function(dir)
		--shell.setDir(dir)
		directory = dir
	end,
	getDrive = function()
		return driveLetter
	end,
	setDrive = function(a)
		driveLetter = a
	end,
	updateFile = function(file,url)
		if oldSettingsGet("dos.secureboot") and string.sub(url,1,56) ~= updateUrl then
			print("Trust check failed")
			return
		end
		local result, reason = http.get({url = url, binary = true}) --make names better
		if not result then
			print(("Failed to update %s from %s (%s)"):format(file, url, reason)) --include more detail
			return
		end
		a1 = fsOpen(file,"wb")
		a1.write(result.readAll())
		a1.close()
		result.close()
	end,
	protect = function(path)
		notAllowed[path] = true
		return
	end,
	require = oldRequire,
	fixColorScheme = setColors,
	resolvePath = resolvePath,
	settingsGet = oldSettingsGet,
	settingsSet = oldSettingsSet,
}
local function boot(prefix)
	print("Booting from drive "..driveLetter)
	baseDirectory = prefix
	directory = prefix
	local success, response = pcall(os.run,{bios=bios},prefix..".BOOT")
	if not success then
		print(response)
		while true do os.sleep() end
	end
end
local function findBootableDevice()
	if fs.exists("disk") and fs.exists("/disk/.BOOT") then
		bios.setDrive("A")
		isDiskBooted = true
		boot("/disk/")

	elseif fs.exists("/.BOOT") then
		bios.setDrive("C")
		boot("/")
	else
		print("NO BOOT DEVICE FOUND!")
		while true do os.sleep() end
	end
end
local blankFunction = function(...) 
	return
end
local function overides()
	--misc overides
	_G.debug = {
		debug = blankFunction,
		gethook = blankFunction,
		getinfo = blankFunction,
		getlocal = blankFunction,
		getmetatable = blankFunction,
		getregistry = blankFunction,
		getupvalue = blankFunction,
		getuservalue = blankFunction,
		sethook = blankFunction,
		setmetatable = blankFunction,
		setupvalue = blankFunction,
		setuservalue = blankFunction,
		traceback = blankFunction,
		upvalueid = blankFunction,
		upvaluejoin = blankFunction
	}
	_G.settings.set = function(key,newKey)
		key = string.lower(key)
		newKey = string.lower(newKey)
		if key == "dos.passphrase" or key == "dos.secureboot" then
			error("Permissions error!")
		else
			return oldSettingsSet(key,newKey)
		end
	end
	_G.settings.get = function(key)
		key = string.lower(key)
		if key == "dos.passphrase" or key == "dos.secureboot" then
			error("Permissions error!")
		else
			return oldSettingsGet(key)
		end
	end
	_G.settings.save = function()
		local t = {}
		for i,v in pairs(settings.getNames()) do
			t[v] = oldSettingsGet(v)
		end
		local new = textutils.serialise(t)
		local a = fsOpen("/.settings","w")
		a.write(new)
		a.close()
		return true
	end

	local oldFs = {}
	local fakeFs ={}
	local oldIo = {}
	local fakeIo = {}
	--IO library
	oldIo.open = io.open
	function fakeIo.open(oldPath,a)
		local path = resolvePath(oldPath)
		if notAllowed[string.lower(path)] then
			return nil
		end	
		return oldIo.open(path,a)
	end
	_G.io.open = fakeIo.open

	oldIo.output = io.output
	function fakeIo.output(oldPath)
		if type(oldPath) == "string" then
			local path = resolvePath(oldPath)
			if notAllowed[string.lower(path)] then
				return nil
			end	
			return oldIo.output(path)
		end
	end
	_G.io.output = fakeIo.output

	oldIo.input = io.input
	function fakeIo.input(oldPath)
		if type(oldPath) == "string" then
			local path = resolvePath(oldPath)
			if notAllowed[string.lower(path)] then
				return nil
			end	
			return oldIo.input(path)
		end
	end
	_G.io.input = fakeIo.input

	oldIo.lines = io.lines
	function fakeIo.lines(oldPath)
		local path = resolvePath(oldPath)
		if notAllowed[string.lower(path)] then
			return nil
		end	
		return oldIo.lines(path)
	end
	_G.io.lines = fakeIo.lines

	--FS library
	oldFs.open = fs.open
	function fakeFs.open(oldPath,a)
		local path = resolvePath(oldPath)
		if notAllowed[string.lower(path)] then
			return nil
		end	
		return oldFs.open(path,a)
	end
	_G.fs.open = fakeFs.open

	oldFs.delete = fs.delete
	function fakeFs.delete(oldPath)
		local path = resolvePath(oldPath)
		if notAllowed[string.lower(path)] then
			return nil
		end	
		return oldFs.delete(path)
	end
	_G.fs.delete = fakeFs.delete

	oldFs.copy = fs.copy
	function fakeFs.copy(oldPath,oldpath1)
		local path = resolvePath(oldPath)
		local path1 = resolvePath(oldPath1)
		if notAllowed[string.lower(path)] or notAllowed[string.lower(path1)] then
			return nil
		end	
		return oldFs.copy(path)
	end
	_G.fs.copy = fakeFs.copy

	oldFs.move = fs.move
	function fakeFs.move(oldPath,oldpath1)
		local path = resolvePath(oldPath)
		local path1 = resolvePath(oldPath1)
		if notAllowed[string.lower(path)] or notAllowed[string.lower(path1)] then
			return nil
		end	
		return oldFs.move(path)
	end
	_G.fs.move = fakeFs.move

	oldFs.makeDir = fs.makeDir
	function fakeFs.makeDir(oldPath)
		local path = resolvePath(oldPath)
		if notAllowed[string.lower(path)] then
			return nil
		end	
		return oldFs.makeDir(path)
	end
	_G.fs.makeDir = fakeFs.makeDir

	oldFs.exists = fs.exists
	function fakeFs.exists(oldPath)
		local path = resolvePath(oldPath)
		if notAllowed[string.lower(path)] then
			return false
		end	
		return oldFs.exists(path)
	end
	_G.fs.exists = fakeFs.exists
end
local oldErr = printError
local function overwrite()
    _G.printError = oldErr
    _G.os.pullEvent = oldPull
    _G['rednet'] = nil
    setupTerm()
	if oldSettingsGet("dos.secureboot") then
		overides()
	end
	local success, err = pcall(findBootableDevice)
	if not success then
		print(err)
		print("Press any key to continue.")
		os.pullEvent("key")
	end
end

_G.printError = overwrite
_G.os.pullEvent = nil
--os.queueEvent("key")

