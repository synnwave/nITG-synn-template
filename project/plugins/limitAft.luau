--!strict

-- Original by Chegg
-- Luau version by @synnwave

local Types = require("../template/types/TypeDefs")
local ActorDefs = require("../template/types/ActorDefs")
local _T = require("../template")
local _G, _F, _D = _T.Globals, _T.Functions, _T.Def

type limitMetaProps = {
	__actor: Types.ActorFrameTexture,
	__hidden: boolean,
	__autoUpdate: boolean,
	__fps: number,
	__frameDelay: number,
	__frameUptime: number,
	__frameWait: number,
}
type limitMeta_schema = {
	__index: limitMeta_schema,
	hidden: (self: limitAft, enable: number) -> (),
	visible: (self: limitAft, enable: number) -> (),
	AutoUpdate: (self: limitAft, enable: boolean) -> (),
	SetFPS: (self: limitAft, fps: number) -> (),
	GetHidden: (self: limitAft) -> boolean,
	GetAutoUpdate: (self: limitAft) -> boolean,
	GetFPS: (self: limitAft) -> number,
	update: (self: limitAft) -> (),
}
type limitAft = Types.ActorFrameTexture & typeof(setmetatable({} :: limitMetaProps, {} :: limitMeta_schema))

--> Metatable
local meta = {} :: limitMeta_schema
meta.__index = function(_, k)
	if meta[k] then return meta[k] end
	return function(self, ...: any)
		local output = { pcall(self.__actor[k], self.__actor, ...) } -- Error handling so that errors point to the correct file and line number
		if table.remove(output, 1) then -- If the function ran sucessfully return the results if any
			return unpack(output)
		end

		error(string.gsub(output[1] :: any, "?", k), 2) -- If the function failed cause a crash with the error message returned
	end
end :: any

function meta:hidden(enable) -- Replaces default hidden
	if type(enable) == "number" then
		self.__hidden = math.abs(enable) >= 1
		return
	end
	error(`calling 'hidden' on bad self (number expected, got {type(enable)})`, 2)
end
function meta:visible(enable) -- Replaces default visible
	if type(enable) == "number" then
		self.__hidden = math.abs(enable) < 1
		return
	end
	error(`calling 'visible' on bad self (number expected, got {type(enable)})`, 2)
end
function meta:AutoUpdate(enable) -- Toggles the auto updating of the AFT's texture
	if type(enable) == "boolean" then
		self.__autoUpdate = enable
		return
	end
	error(`calling 'AutoUpdate' on bad self (boolean expected, got {type(enable)})`, 2)
end
function meta:SetFPS(fps) -- Sets the `AutoUpdate` rate of the AFT's texture, minimum value of 1 fps
	if type(fps) == "number" then
		self.__fps = math.max(1, fps)
		return
	end
	error(`calling 'SetFPS' on bad self (number expected, got {type(fps)})`, 2)
end
function meta:GetHidden() return self.__hidden end -- Replaces default GetHidden
function meta:GetFPS() return self.__fps end -- Returns the current FPS of the AFT
function meta:GetAutoUpdate() return self.__autoUpdate end -- Returns the current state of `AutoUpadate`
function meta:update() -- Forces the AFT to update its texture
	self.__frameWait = 2
	self.__frameUptime = 0
	self.__frameDelay = 1 / self.__fps
	if not self.__hidden then self.__actor:hidden(0) end
end

--> Constructor
local aftList = {}
local function limitAFT(aft: Types.ActorFrameTexture? | ActorDefs.ActorFrameTexture_names): limitAft
	local thisAft = _F.setupAFT(aft)
	local this = setmetatable({} :: limitMetaProps, meta)
	this.__actor = thisAft
	this.__hidden = thisAft:GetHidden()
	this.__autoUpdate = true
	this.__fps = 60
	this.__frameDelay = 1 / this.__fps
	this.__frameUptime = 0
	this.__frameWait = 1

	table.insert(aftList, this)
	return this :: any
end

local function limitAFTSprite(
	aft: Types.ActorFrameTexture? | ActorDefs.ActorFrameTexture_names,
	sprite: Types.Sprite? | ActorDefs.Sprite_names
): (limitAft, Types.Sprite)
	local thisAft, thisSprite = _F.setupAFTAndSprite(aft, sprite)
	local this = setmetatable({} :: limitMetaProps, meta)
	this.__actor = thisAft
	this.__hidden = thisAft:GetHidden()
	this.__autoUpdate = true
	this.__fps = 60
	this.__frameDelay = 1 / this.__fps
	this.__frameUptime = 0
	this.__frameWait = 1

	table.insert(aftList, this)
	return this :: any, thisSprite
end

--> Initialize Loop
_D.Plugin {
	InitCommand = function(self)
		self:addcommand("update", function()
			local deltaTime = self:GetEffectDelta()

			for _, aft in ipairs(aftList) do
				aft.__frameUptime += deltaTime
				if aft.__frameUptime >= aft.__frameDelay then
					aft.__frameUptime %= aft.__frameDelay
					aft.__frameDelay = 1 / aft.__fps
					if not aft.__hidden and aft.__autoUpdate then
						aft.__frameWait = 2
						aft.__actor:hidden(0)
					end
				end

				if aft.__frameWait > 0 then
					aft.__frameWait -= 1
					if aft.__frameWait == 0 then aft.__actor:hidden(1) end
				end
			end
		end)
		self:luaeffect("update")
	end,
}

return { limitAFT = limitAFT, limitAFTSprite = limitAFTSprite }
