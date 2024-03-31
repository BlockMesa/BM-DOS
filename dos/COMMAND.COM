local version = "3.30"
local versionString = "BM-DOS version "..version
term.clear()
term.setCursorPos(1,1)
term.write(versionString)
term.setCursorPos(1,3)

--modify the env
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
local function writeProtect()
	local notAllowed = {
		["/command.com"] = true,
		["/.boot"] = true,
		["/command.com/"] = true,
		["/.boot/"] = true,
	}
	
	local oldIo = {}
	local fakeIo = {}
	local oldFs = {}
	local fakeFs = {}
	--IO library
	oldIo.open = io.open
	function fakeIo.open(oldPath,a)
		local path = bios.resolvePath(oldPath)
		if notAllowed[string.lower(path)] then
			return nil
		end	
		return oldIo.open(path,a)
	end
	_G.io.open = fakeIo.open

	oldIo.output = io.output
	function fakeIo.output(oldPath)
		if type(oldPath) == "string" then
			local path = bios.resolvePath(oldPath)
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
			local path = bios.resolvePath(oldPath)
			if notAllowed[string.lower(path)] then
				return nil
			end	
			return oldIo.input(path)
		end
	end
	_G.io.input = fakeIo.input

	oldIo.lines = io.lines
	function fakeIo.lines(oldPath)
		local path = bios.resolvePath(oldPath)
		if notAllowed[string.lower(path)] then
			return nil
		end	
		return oldIo.lines(path)
	end
	_G.io.lines = fakeIo.lines

	--FS library
	oldFs.open = fs.open
	function fakeFs.open(oldPath,a)
		local path = bios.resolvePath(oldPath)
		if notAllowed[string.lower(path)] then
			return nil
		end	
		return oldFs.open(path,a)
	end
	_G.fs.open = fakeFs.open

	oldFs.delete = fs.delete
	function fakeFs.delete(oldPath)
		local path = bios.resolvePath(oldPath)
		if notAllowed[string.lower(path)] then
			return nil
		end	
		return oldFs.delete(path)
	end
	_G.fs.delete = fakeFs.delete

	oldFs.copy = fs.copy
	function fakeFs.copy(oldPath,oldpath1)
		local path = bios.resolvePath(oldPath)
		local path1 = bios.resolvePath(oldPath1)
		if notAllowed[string.lower(path)] or notAllowed[string.lower(path1)] then
			return nil
		end	
		return oldFs.copy(path)
	end
	_G.fs.copy = fakeFs.copy

	oldFs.move = fs.move
	function fakeFs.move(oldPath,oldpath1)
		local path = bios.resolvePath(oldPath)
		local path1 = bios.resolvePath(oldPath1)
		if notAllowed[string.lower(path)] or notAllowed[string.lower(path1)] then
			return nil
		end	
		return oldFs.move(path)
	end
	_G.fs.move = fakeFs.move

	oldFs.makeDir = fs.makeDir
	function fakeFs.makeDir(oldPath)
		local path = bios.resolvePath(oldPath)
		if notAllowed[string.lower(path)] then
			return nil
		end	
		return oldFs.makeDir(path)
	end
	_G.fs.makeDir = fakeFs.makeDir
	
	oldFs.exists = fs.exists
	function fakeFs.exists(oldPath)
		local path = bios.resolvePath(oldPath)
		if notAllowed[string.lower(path)] then
			return false
		end	
		return oldFs.exists(path)
	end
	_G.fs.exists = fakeFs.exists
end
writeProtect()
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
local programFunctions = {
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
				if bios.getDir() == "/" and (v:gmatch("disk".."[1-9]+")() ~= nil or v:gmatch("disk")() ~= nil) then
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
		--[[if newDir == ".." then
			local newDir = "/"
			local split = splitString(bios.getDir(),"[^/]")
			if #split == 0 or (#split == 1 and (split[1]:gmatch("disk".."[1-9]+")() ~= nil or split[1]:gmatch("disk")() ~= nil)) then
				print("Invalid directory!")
				return
			else
				for i,v in pairs(split) do
					if i ~= #split then
						newDir = newDir..v.."/"
					end
				end
				bios.setDir(newDir)
			end
		else
			if bios.getDir() == "/" and (newDir:gmatch("disk".."[1-9]+")() ~= nil or newDir:gmatch("disk")() ~= nil) then
				print("Invalid directory!")
			else
				if fs.exists(bios.getDir()..newDir.."/") then
					bios.setDir(bios.getDir()..newDir.."/")
				else
					print("Invalid directory!")
				end
			end
		end]]
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
	end	
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
term.setCursorBlink(true)
while true do
	term.setTextColor(colors.white)
	term.write(bios.getDrive()..">") --DOS 3.30 used a ">" not a "\>"
	local command = read()
	local success, err = pcall(interpret,command)
	if not success then
		--print(err)
		print("Illegal command: "..command..".")
	end
end
