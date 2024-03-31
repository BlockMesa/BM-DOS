--WARNING: All code edited here will be overwriten
--after every update. Modifications need to
--be reapplied every update.
local version = "3.30"
local versionString = "BM-DOS version "..version
term.clear()
term.setCursorPos(1,1)
term.write(versionString)
term.setCursorPos(1,3)

--modify the env
local oldSettingsGet = settings.get
local oldSettingsSet = settings.set
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
_G.os.version = function() return versionString end

local romPrograms = {
	edit = "/rom/programs/edit.lua",
	pastebin = "/rom/programs/http/pastebin.lua",
	wget = "/rom/programs/http/wget.lua",
	import = "/rom/programs/import.lua",
	lua = "/rom/programs/lua.lua",
}
local help = {
	"DIR: Lists files in directory",
	"CD: Changes directory",
	"MKDIR: creates directory",
	"TYPE: Outputs contents of a file",
	"COPY: Duplicates a file",
	"RENAME: Renames a file",
	"ERASE: Deletes a file",
	"HELP: Displays this message",
}
local function splitString(str,toMatch)
	if not toMatch then
		toMatch = "%S"
	end
	local words = {}
	for w in str:gmatch(toMatch.."+") do
		table.insert(words,w)
	end
	return words
end
local function removeFirstIndex(t)
	local newTable = {}
	for i,v in pairs(t) do
		if i ~= 1 then
			table.insert(newTable,v)
		end
	end
	return newTable
end
bios.protect("/command.com")
bios.protect("/.boot")
local programFunctions
programFunctions = {
	dir = function(...)
		local path = bios.getDir()
		if bios.getDrive() ~= "C" then
			local a = splitString(path,"[^/]")
			a = removeFirstIndex(a)
			path = "\\"
			for i,v in pairs(a) do
				path = path..v.."\\"
			end
		else
			path = string.gsub(path,"/","\\")
		end
        print("Directory of  "..bios.getDrive()..":"..path)
		for i,v in pairs(fs.list(bios.getDir())) do
			if string.sub(v, 1, 1) ~= "." then
				if bios.getDir() == "/" and ((v:gmatch("disk".."[1-9]+")() ~= nil or v:gmatch("disk")() ~= nil) or v == "startup.lua" or v == "rom") then
					--skip
				else
					if fs.isDir(bios.getDir()..v) then
						v = v.."  <DIR>"
					end
					print("    "..v)
				end
			end
		end
	end,
	rem = function(...) end,
	pause = function(...) print("Press any key to continue.") os.pullEvent("key") end,
	loadapi = function(name)
		local file = bios.getDir()..name
		if fs.exists(file) then
			os.loadAPI(file)
		else
			print("FILE NOT FOUND")
		end
	end,
	type = function(file)
		local file = bios.getDir()..file
		local data = fs.open(file,"r")
		print(data.readAll())
		data.close()
		return
	end,
	copy = function(file,destination)
		local file = bios.getDir()..file
		local destination = bios.getDir()..destination
		if fs.exists(file) then
			fs.copy(file,destination)
		else
			print("FILE NOT FOUND")
		end
	end,
	echo = print,
	shutdown = os.shutdown,
	reboot = os.reboot,
	rename = function(file,destination) --also works as move lol
		local file = bios.getDir()..file
		local destination = bios.getDir()..destination
		if fs.exists(file) then
			fs.move(file,destination)
		else
			print("FILE NOT FOUND")
		end
	end,
	erase = function(file,destination)
		local file = bios.getDir()..file
		if fs.exists(file) then
			fs.delete(file)
		else
			print("FILE NOT FOUND")
		end
	end,
	help = function(...)
		for i,v in pairs(help) do
			print("    "..v)
		end
	end,
	mkdir = function(newDir)
		if bios.getDir() == "/" and string.sub(newDir,1,4) == "disk" and (string.len(newDir) == 5 or string.len(newDir) == 6) then
			return
		end
		if not fs.exists(bios.getDir()..newDir.."/") then
				fs.makeDir(bios.getDir()..newDir.."/")
		else
			print("Direcotry already exists!")
		end
	end,
	cd = function(newDir)
		if bios.getDir() == "/" and string.sub(newDir,1,4) == "disk" and (string.len(newDir) == 5 or string.len(newDir) == 6) then
			print("Invalid directory!") --Use the commands like a normal person
			return
		end
		local newDir = bios.resolvePath(bios.getDir()..newDir)
		if newDir == "/" then
			local sub = string.sub(bios.getDir(),1,6)
			if sub == "/disk/" or sub:gmatch("/disk".."[1-9]+")() ~= nil then
				print("Invalid directory!")
				return
			end
		else
			newDir = newDir.."/"
		end
		bios.setDir(newDir)
	end,
	["c:"] = function()
		bios.setDir("/")
		bios.setDrive("C")
	end,
	["update-file"] = function(file,url)
		bios.updateFile(file,url)
	end,
	ver = function(...)
		print("    "..versionString)
	end,
	uninstall = function()
		print("ARE YOU SURE?")
		write("y/N: ")
		local a = read()
		if string.lower(a) == "y" then
			if oldSettingsGet("dos.secureboot") then
				print("Please disable secureboot first.")
				return
			end
			print("Uninstalling BM-DOS")
			bios.updateFile("startup.lua","https://raw.githubusercontent.com/BlockMesa/BM-DOS/main/blank.lua")
			bios.updateFile(".BOOT","https://raw.githubusercontent.com/BlockMesa/BM-DOS/main/blank.lua")
			bios.updateFile("COMMAND.COM","https://raw.githubusercontent.com/BlockMesa/BM-DOS/main/blank.lua")
			os.reboot()
		end
	end,
	update = function()
		print("Updating BM-DOS")
		bios.updateFile("startup.lua","https://raw.githubusercontent.com/BlockMesa/BM-DOS/main/bios.lua")
		bios.updateFile(".BOOT","https://raw.githubusercontent.com/BlockMesa/BM-DOS/main/dos/.BOOT")
		bios.updateFile("COMMAND.COM","https://raw.githubusercontent.com/BlockMesa/BM-DOS/main/dos/COMMAND.COM")
		os.reboot()
	end,
	secureboot = function(status)
		if status == nil then
			print("	Secure boot is"..(oldSettingsGet("dos.secureboot") and "on" or "off"))
			return
		else
			local status = (status == "on")
			if status then
				if not oldSettingsGet("dos.passphrase") then
					print("Secureboot pin not found!")
					print("Please enter a pin:")
					write(">")
					while true do
						local pass = read("*")
						if pass ~= "" then
							oldSettingsSet("dos.passphrase",pass)
							break
						end
					end
				end
			elseif oldSettingsGet("dos.passphrase") then
				local passphrase = oldSettingsGet("dos.passphrase")
				print("Please enter your pin to continue")
				write(">")
				while true do
					local pass = read("*")
					if passphrase == pass then
						oldSettingsSet("dos.passphrase",false)
						break
					end
				end
			end
			oldSettingsSet("dos.secureboot",status)
			settings.save()
			print("Secure boot set to "..(status and "on" or "off"))
			programFunctions["pause"]()
			os.reboot()
		end
	end,
	clr = function()
		term.setCursorPos(1,1)
		term.clear()
	end,
}

local runBatch = nil
local alphabet = { 
	["a"] = "",
	["b"] = "2",
	["d"] = "3",
	["e"] = "4",
	["f"] = "5",
	["g"] = "6",
	["h"] = "7",
	["i"] = "8",
	["j"] = "9",
	["k"] = "10",
	["l"] = "11",
	["m"] = "12",
	["n"] = "13",
	["o"] = "14",
	["p"] = "15",
	["q"] = "16",
	["r"] = "17",
	["s"] = "18",
	["t"] = "19",
	["u"] = "20",
	["v"] = "21",
	["w"] = "22",
	["x"] = "23",
	["y"] = "24",
	["z"] = "25",
}
for i,v in pairs(alphabet) do
	programFunctions[i..":"] = function()
		bios.setDir("/disk"..v.."/")
		bios.setDrive(string.upper(i))
	end
end
local interpret = nil
local fakeApis = nil
fakeApis = {
	dos = {
		version = function() return version end,
		isSentient = function() return true end,
	},
	shell = { --bare minimum to get some programs to run, more functions to be added when i feel like it
		run = function(...)
			local args = {...}
			local command = ""
			for i,v in pairs(args) do
				if type(v) == "string" then
					if i ~= 1 then
						command = command.." "
					end
					command = command..v
				end
			end
			interpret(command)
		end,
		execute = function(...) return fakeApis["shell"]["run"](...) end,
		exit = function(...) return end,
		dir = bios.getDir,
		setDir = programFunctions["cd"],
		path = function() return ".:/rom/programs:/rom/programs/http" end,
		setPath = function(...) return end,
		resolve = function(path)
			local program = path
			local name = splitString(path,"%P")
			if romPrograms[string.lower(path)] then
				program = romPrograms[string.lower(path)]
			elseif path[2] or not fs.exists(bios.getDir()..path..".lua") then
				program = bios.getDir()..path
			else
				program = bios.getDir()..path..".lua"
			end
			return program
		end,
	},
	require = bios.require
}
function interpret(command)
	--local command = string.lower(command)
	if command == "" then return end
	local program = ""
	local splitcommand = splitString(command,"%S")
	local args = removeFirstIndex(splitcommand)
	local name = splitString(splitcommand[1],"%P")
	if romPrograms[string.lower(splitcommand[1])] then
		program = romPrograms[string.lower(splitcommand[1])]
	elseif programFunctions[string.lower(splitcommand[1])] then
		programFunctions[string.lower(splitcommand[1])](table.unpack(args))
		return
	elseif name[2] == "bat" then
		runBatch(bios.getDir()..splitcommand[1])
		return
	elseif name[2] or not fs.exists(bios.getDir()..splitcommand[1]..".lua") then
		program = bios.getDir()..splitcommand[1]
	else
		program = bios.getDir()..splitcommand[1]..".lua"
	end
	if fs.exists(program) then
		local args1 = args
		args1[0] = splitcommand[1]
		local fakeGlobals = {shell=shell,arg=args1}
		for i,v in pairs(fakeApis) do
			fakeGlobals[i] = v
		end
		_G.os.pullEvent = os.pullEventOld
		local success, response = pcall(os.run,fakeGlobals,program,table.unpack(args))
		bios.fixColorScheme()
		_G.os.pullEvent = os.pullEventRaw
		if not success then
			print("Illegal command: "..command..".")
		end
	else
		print("Illegal command: "..command..".")
	end
end
function runBatch(batchFile)
	if fs.exists(batchFile) then
		for line in io.lines(batchFile) do
			interpret(line)
		end
	end
end
pcall(function()
	if fs.exists("autoexec.bat") then
		runBatch("autoexec.bat")
	end
end)
while true do
	term.setCursorBlink(true)
	term.setTextColor(colors.white)
	term.write(bios.getDrive()..">") --DOS 3.30 used a ">" not a "\>"
	local command = read()
	local success, err = pcall(interpret,command)
	if not success then
		--print(err)
		print("Illegal command: "..command..".")
	end
end
