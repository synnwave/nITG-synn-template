--!strict

local fs = require("@lune/fs")
local luau = require("@lune/luau")

local utils = {}

local mergeTable = require("../../project/template/functions/mergeTable")

local template, game
local cache
function utils.require(filePath: string, path: string)
	local splitFilePath = string.split(filePath, "/")
	local lastPath = splitFilePath[#splitFilePath]
	if lastPath then filePath = filePath:sub(1, -lastPath:len() - 1) end

	local thisFilePath = template.env.synn.normalizePath(`{filePath}/{path}`)
	if thisFilePath:sub(1, 1) == "/" then thisFilePath = thisFilePath:sub(2) end

	local oldPath = thisFilePath
	if not fs.isFile(thisFilePath) then
		thisFilePath ..= ".luau"
	end
	if not fs.isFile(thisFilePath) then thisFilePath = oldPath .. "/init.luau" end
	if not fs.isFile(thisFilePath) then error("path Doesn't exist bro") end

	if utils.cache[thisFilePath] then return utils.cache[thisFilePath] end
	local thisRequire = utils.runScript(thisFilePath)
	utils.cache[thisFilePath] = thisRequire
	return thisRequire
end

function utils.runScript(path: string)
	local returns = luau.load(luau.compile(fs.readFile(path)), {
		debugName = path,
		environment = mergeTable(game, { require = function(...) return utils.require(path, ...) end }, template.env),
	})()

	return returns
end
function utils.beginMock(refresh: boolean?)
	if refresh or not (template and game) then
		game = require("mockGame")(refresh)
		template = require("mockTemplate")(refresh)
	end

	if refresh or not cache then
		cache = {
			["project/template/functions/mergeTable.luau"] = mergeTable,
		}
		utils.cache = cache
	end
end

return utils
