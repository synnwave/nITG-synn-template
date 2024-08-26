--!strict

-- credits to: @XeroOl
-- modifications & code cleanliness done by: @synnwave

local _T = require("../types/TypeDefs")
local _G = require("../globals")

local function makeActorTableProxy()
	local proxy = {}
	function proxy.__index(self, k)
		self[k] = setmetatable({}, proxy)
		return self[k]
	end

	local actorTable = setmetatable({}, proxy)
	local function clearMetatables(tab: any)
		setmetatable(tab, nil)
		for _, obj in pairs(tab) do
			if type(obj) == "table" and getmetatable(obj) == proxy then clearMetatables(obj) end
		end
	end

	return actorTable, function()
		clearMetatables(actorTable)
		proxy = nil :: any
	end
end

local function scanActors()
	local allActors = {}
	local actorTableProcessor = "return function(allActors, outputTable)" -- this processor will be used to add actors to the actorTable table
	--                                                                       we need to do this for those actors with names that are tables, like "PC[1]"
	--                                                                       makeActorTableProxy will be used to dynamically create tables for actors with names like this

	local actorTable, clearMetatables = makeActorTableProxy()
	local function iter(actor: _T.ActorFrame?, skip: boolean?)
		if not actor then return end
		if actor.GetNumChildren then
			for i = 0, actor:GetNumChildren() - 1 do
				iter(actor:GetChildAt(i) :: any)
			end
		end

		if skip then return end
		local actorName = actor:GetName()
		if actorName and actorName ~= "" then
			if loadstring(`t.{actorName}=t`) then
				allActors[actorName] = actor
				actorTableProcessor ..= `\n\toutputTable.{actorName}=allActors["{actorName}"]\n`
			else
				_G.SCREENMAN:SystemMessage(`invalid actor name: '{actorName}'`)
			end
		end
	end

	iter(_G.foreground, true)

	actorTableProcessor ..= "\nend"
	assert(loadstring(actorTableProcessor, "actor_processor"), "Actor processor failed to load")()(allActors, actorTable)
	clearMetatables()

	local finalActorTable = {} :: any
	for actorName, actorData in pairs(actorTable) do
		finalActorTable[actorName] = actorData
	end

	actorTable, clearMetatables = nil :: any, nil :: any
	return finalActorTable
end

return {
	scan = scanActors,
	makeProxy = makeActorTableProxy,
}
