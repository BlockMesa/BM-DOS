--BLOCK MESA BIOS
--Used for all Block Mesa bootable computers
--inject code stolen from https://pastebin.com/yzfDMjwf
local oldPull = os.pullEvent
_G.os.pullEvent = os.pullEventRaw
_G.os.pullEventOld = oldPull
--internal flag things
local version = "1.10"
local isDiskBooted = false
local baseDirectory = ""
local directory = "/"
local driveLetter = "C"

local whiteColor = 0xE9A226
local blackColor = 0x43422C
local function setColors()
	term.setPaletteColour(colors.white, whiteColor)
	term.setPaletteColour(colors.red, whiteColor)
	term.setPaletteColour(colors.yellow, whiteColor)
	term.setPaletteColour(colors.orange, whiteColor)
	term.setPaletteColour(colors.black, blackColor)
	term.setBackgroundColor(colors.black)
	term.setTextColor(colors.white)
end
local function setupTerm()
	term.redirect(term.native())
	setColors()
	term.setCursorBlink(false)
	term.clear()
	term.setCursorPos(1,1)
	print("BLOCK MESA BIOS v"..version)
end
setupTerm()
if not settings.get("dos.hasFinishedSetup") then
	settings.set("bios.use_multishell",false)
	settings.set("shell.allow_disk_startup",false)
	settings.set("dos.hasFinishedSetup",true)
	settings.save()
	print("Rebooting...")
	os.reboot()
end
local ioOpen = fs.open
_G.bios = {
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
		shell.setDir(dir)
		directory = dir
	end,
	getDrive = function()
		return driveLetter
	end,
	setDrive = function(a)
		driveLetter = a
	end,
	updateFile = function(file,url)
		--a = http.get(url	)
		a, b, c = http.get {url = url, binary = true}
		if not a then
			print(b)
			return
		end
		a1 = ioOpen(file,"wb")
		a1.write(a.readAll())
		a1.close()
		a.close()
	end,
	fixColorScheme = setColors
}
local function boot(prefix)
	print("Booting from drive "..driveLetter)
	baseDirectory = prefix
	directory = prefix
	local success, response = pcall(os.run,{['shell']=shell},prefix..".BOOT")
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
local oldErr = printError
local oldPull = os.pullEvent
local function overwrite()
    _G.printError = oldErr
	_G.os.pullEvent = oldPull
    _G['rednet'] = nil
    --os.loadAPI("/rom/apis/rednet.lua")
	setupTerm()
	--local success, err = pcall(parallel.waitForAny, boot, rednet.run)
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

