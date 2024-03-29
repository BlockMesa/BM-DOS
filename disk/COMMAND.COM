term.clear()
term.setCursorPos(1,1)
term.write("BM-DOS version 1.00")
term.setCursorPos(1,3)

--modify the env
_G.os.version = function() return "BM-DOS version 1.00" end
_G.shell.setDir = function(...) return end
_G.shell.openTab = nil
_G.shell.switchTab = nil

local path = "/disk/"
local romPrograms = {
	edit = "/rom/programs/edit.lua",
	pastebin = "/rom/programs/http/pastebin.lua",
	wget = "/rom/programs/http/wget.lua"
}
local programFunctions = {
	dir = function(...)
		for i,v in pairs(fs.list(path)) do
			print("    "..v)
		end
	end,
	rem = function(...) end,
	pause = function(...) print("Press any key to continue.") os.pullEvent("key") end,
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
function splitString(str)
	local words = {}
	for w in str:gmatch("%S+") do
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
local function interpret(command)
	local command = string.lower(command)
	if command == "" then return end
	local program = ""
	local splitcommand = splitString(command)
	local args = removeFirstIndex(splitcommand)
	if romPrograms[splitcommand[1]] then
		program = romPrograms[splitcommand[1]]
	elseif programFunctions[splitcommand[1]] then
		programFunctions[splitcommand[1]](table.unpack(args))
		return
	else
		program = path..splitcommand[1]
	end
	local args1 = args
	args1[0] = splitcommand[1]
	local success, response = pcall(os.run,{['shell']=shell,arg=args1},program,table.unpack(args))
	if not success then
		print("Illegal command: "..command..".")
	end
end
pcall(function()
	if fs.exists("autoexec.bat") then
		for line in io.lines("autoexec.bat") do
			interpret(line)
		end
	end
end)
while true do
	term.setTextColor(colors.white)
	term.write("A> ")
	local command = read()
	local success, _ = pcall(interpret,command)
	if not success then
		print("Illegal command: "..command..".")
	end
end