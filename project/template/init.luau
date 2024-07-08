--!strict
local _G = require("globals")

local Types = require("types/TypeDefs")
local XMLTypes = require("types/XMLTypeDefs")

local easing = require("functions/easings")
local template = require("functions/template-exports")

local _T = {
	_initialized = false,
	_isReady = false,

	Actors = {} :: XMLTypes.actorTable,
	Players = {} :: { Types.Player },
	Functions = template.exports,
	Easings = easing,
	Globals = _G,
}

function _T:Init(initActor: Types.Actor, onReady: () -> ())
	if _T._initialized then return end
	_T._initialized = true
	_G.Players = _T.Players

	initActor:effectclock("music")
	initActor:addcommand("On", function()
		--> Get Actors
		local _, actorTable = require("functions/scanActors").scan()
		_T.Actors = actorTable
		_G.Actors = actorTable

		initActor:queuecommand("Ready")
	end)

	initActor:addcommand("Ready", function()
		local topScreen = _G.SCREENMAN:GetTopScreen()

		--> Hide screen actors
		local themeActors = { "Overlay", "Underlay", "ScoreP1", "ScoreP2", "LifeP1", "LifeP2" }
		for _, elementName in ipairs(themeActors) do
			local element = topScreen:GetChild(elementName)
			if element then element:hidden(1) end
		end

		--> Get Players
		for playerID = 1, _G.PLAYER_COUNT do
			local playerElement = topScreen:GetChild(`PlayerP{playerID}`) :: Types.Player?
			if playerElement then _T.Players[playerID] = playerElement end
		end

		_G.foreground:hidden(0)
		_G.foreground:playcommand("Load")
		onReady()
		template.internals.__onReady()
		initActor:luaeffect("Update")
	end)

	local function onUpdate(this: Types.Actor)
		this:hidden(1)

		local thisBeat = _G.GAMESTATE:GetSongBeat()
		local time = this:GetSecsIntoEffect()
		local deltaTime = this:GetEffectDelta()
		template.internals.__onUpdate(thisBeat, time, deltaTime)

		this:hidden(0)
	end
	initActor:addcommand("Update", function()
		initActor:removecommand("Update") -- Defer by a frame
		initActor:addcommand("Update", onUpdate)
	end)

	initActor:removecommand("Init")
end

return _T
