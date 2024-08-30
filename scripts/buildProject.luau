--!strict

local fs = require("@lune/fs")
local process = require("@lune/process")

local projectDir = "project"
local outputDir = ".build"
local FILE_ENDING = { from = ".luau", to = ".lua" }

local function dirFileIterator(startingPath, method: (startingPath: string, file: string, thisFile: string) -> ())
	if not fs.isDir(startingPath) then return print(`Path isn't a directory ({startingPath})`) end
	for _, file in fs.readDir(startingPath) do
		local thisFile = `{startingPath}/{file}`
		if fs.isFile(thisFile) then
			method(startingPath, file, thisFile)
		elseif fs.isDir(thisFile) then
			dirFileIterator(thisFile, method)
		end
	end
end

return function()
	--> delete any existing files/directories
	if fs.isDir(outputDir) then fs.removeDir(outputDir) end
	if fs.isFile(outputDir) then fs.removeFile(outputDir) end

	--> refresh types & copy files
	require("refreshTypes")()
	fs.copy(projectDir, outputDir)

	--> before processing, fix variadics (replace "..." to "unpack(arg)" because of lua 5.0, unless it has a colon in front of it.
	-->                                   we do this before processing because colons/types get removed after processing)
	local characterWhitelist = { "", " ", "}", ")", "\r", "\n", "\t" }
	dirFileIterator(outputDir, function(_, file, thisFile)
		if file:sub(-FILE_ENDING.from:len()) ~= FILE_ENDING.from then return end -- make sure we're editing a .luau file
		local fileContents = fs.readFile(thisFile):gsub("%.%.%..?", function(match)
			local lastCharacter = match:sub(-1)
			if lastCharacter == "." then lastCharacter = "" end -- in the case where it only captures "...", which will probably never happen but i want to be safe ok...
			if table.find(characterWhitelist, lastCharacter) then return `unpack(arg){lastCharacter}` end
			return match
		end)
		fs.writeFile(thisFile, fileContents)
	end)

	--> process!
	process.spawn("darklua", { "process", outputDir, outputDir, "--config", "scripts/.darklua.json5" }, {
		stdio = "forward",
	})

	--> iterate through each file in the project (convert file endings from .luau to .lua and do other things that we need to do)
	dirFileIterator(outputDir, function(startingPath, file, thisFile)
		local isLuau = file:sub(-FILE_ENDING.from:len()) == FILE_ENDING.from
		if isLuau then
			local fileName = file:sub(1, -FILE_ENDING.from:len() - 1)
			do --> Convert File ending
				local newFile = `{startingPath}/{fileName}{FILE_ENDING.to}`
				fs.move(thisFile, newFile)
				thisFile = newFile
			end

			local fileContents = fs.readFile(thisFile)
			fileContents = `-- Don't edit this script! File processed using darklua --> https://darklua.com/\n{fileContents}` --> Add darklua comment
			fileContents = fileContents:gsub("for .-do", function(str) --> Fix loops
				-- TODO: make this not fuck up when there's a string with the word "for" in it 😭
				local variablesToFix = str:match("for (.-) in") or str:match("for (.-)=")
				if variablesToFix then return `{str} local {variablesToFix}={variablesToFix}; ` end
				return str
			end)

			fs.writeFile(thisFile, fileContents)
		end

		fs.writeFile(thisFile, (fs.readFile(thisFile):gsub(FILE_ENDING.from, FILE_ENDING.to)))
	end)
end
