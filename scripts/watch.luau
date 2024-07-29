--!strict
local fs = require("@lune/fs")
local stdio = require("@lune/stdio")
local task = require("@lune/task")
local process = require("@lune/process")
local DateTime = require("@lune/datetime")

process.spawn("clear", {}, { shell = true })
print("Watching..")

local finalResponse
local madeResponseString = false
local function makeResponse()
	task.defer(function() madeResponseString = true end)
	finalResponse = stdio.prompt("confirm", "Do you want to stop watching the project?")
	if not finalResponse then
		finalResponse = nil
		makeResponse()
	end
end
task.spawn(makeResponse)

local function iterateDir(startingPath, method: (thisFile: string) -> ())
	if not fs.isDir(startingPath) then return print(`Path isn't a directory ({startingPath})`) end
	for _, file in fs.readDir(startingPath) do
		local thisFile = `{startingPath}/{file}`
		method(thisFile)
		if fs.isDir(thisFile) then iterateDir(thisFile, method) end
	end
end

local build = require("buildProject")
local metadataCaches = {}
while task.wait(0.2) do
	if finalResponse then
		print("Stopping..")
		break
	end

	local canBuild = false
	iterateDir("project", function(path)
		local splitPath = path:split("/")
		if splitPath[#splitPath] == "XMLTypeDefs.luau" then return end -- this gets regenerated every time we build so there's no point in watching it

		local thisMetadata = fs.metadata(path)
		if not thisMetadata.modifiedAt then return end
		local timeString = thisMetadata.modifiedAt:toIsoDate()
		if metadataCaches[path] ~= timeString then
			metadataCaches[path] = timeString
			canBuild = true
		end
	end)

	if canBuild then
		stdio.write(stdio.style("bold") .. stdio.color("green"))
		stdio.write(
			`{if madeResponseString then "\n" else ""}Building @ {DateTime.now():formatLocalTime("%d/%m/%y %H:%M:%S %p")}`
		)
		stdio.write(stdio.style("reset") .. stdio.color("reset") .. " - ")
		madeResponseString = false

		build()
	end
end
