local version = "1.00"
term.clear()
term.setCursorPos(1,1)
term.write("BM-DOS version "..version)
term.setCursorPos(1,3)

--modify the env
_G.os.version = function() return "BM-DOS version 1.00" end
shell.setDir = function(...) return end
shell.openTab = nil
shell.switchTab = nil
local fakeApis = {
	dos = {
		version = function() return version end,
		isSentient = function() return true end,
	}
}
local path = "/disk/"
local romPrograms = {
	edit = "/rom/programs/edit.lua",
	pastebin = "/rom/programs/http/pastebin.lua",
	wget = "/rom/programs/http/wget.lua",
	--lua = "/rom/programs/lua.lua", --doesnt work for some fucking reason
}
local programFunctions = {
	dir = function(...)
		for i,v in pairs(fs.list(path)) do
			print("    "..v)
		end
	end,
	rem = function(...) end,
	pause = function(...) print("Press any key to continue.") os.pullEvent("key") end,
	loadapi = function(name)
		local file = path..name
		if fs.exists(file) then
			os.loadAPI(file)
		else
			print("FILE NOT FOUND")
		end
	end,
	type = function(file)
		local file = path..file
		local data = fs.open(file,"r")
		print(data.readAll())
		data.close()
		return
	end,
	copy = function(file,destination)
		local file = path..file
		local destination = path..destination
		if fs.exists(file) then
			fs.copy(file,destination)
		else
			print("FILE NOT FOUND")
		end
	end,
	echo = function(...)
		print(...)
	end,
	shutdown = function(...)
		os.shutdown()
	end,
	reboot = function(...)
		os.reboot()
	end,
	rename = function(file,destination) --also works as move lol
		local file = path..file
		local destination = path..destination
		if fs.exists(file) then
			fs.move(file,destination)
		else
			print("FILE NOT FOUND")
		end
	end,
	erase = function(file,destination)
		local file = path..file
		if fs.exists(file) then
			fs.delete(file)
		else
			print("FILE NOT FOUND")
		end
	end,
	help = function(...)
		print("    DIR: Lists files on disk")
		print("    TYPE: Outputs contents of a file")
		print("    COPY: Duplicates a file")
		print("    RENAME: Renames a file")
		print("    ERASE: Deletes a file")
		print("    HELP: Displays this message")
	end
}
function splitString(str,toMatch)
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
local runBatch = nil
local function interpret(command)
	local command = string.lower(command)
	if command == "" then return end
	local program = ""
	local splitcommand = splitString(command,"%S")
	local args = removeFirstIndex(splitcommand)
	local name = splitString(splitcommand[1],"%P")
	if romPrograms[splitcommand[1]] then
		program = romPrograms[splitcommand[1]]
	elseif programFunctions[splitcommand[1]] then
		programFunctions[splitcommand[1]](table.unpack(args))
		return
	elseif name[2] == "bat" then
		runBatch(splitcommand[1])
		return
	elseif name[2] or not fs.exists(path..splitcommand[1]..".lua") then
		program = path..splitcommand[1]
	else
		program = path..splitcommand[1]..".lua"
	end
	if fs.exists(program) then
		local args1 = args
		args1[0] = splitcommand[1]
		local fakeGlobals = {shell=shell,arg=args1}
		for i,v in pairs(fakeApis) do
			fakeGlobals[i] = v
		end
		local success, response = pcall(os.run,fakeGlobals,program,table.unpack(args))
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
	term.write("A> ")
	local command = read()
	local success, _ = pcall(interpret,command)
	if not success then
		print("Illegal command: "..command..".")
	end
end