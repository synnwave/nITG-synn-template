--!strict

local Types = require("../types/TypeDefs")
local XMLTypes = require("../types/XMLTypeDefs")
local _G = require("../globals")

local exports = {}

local assureCaller = _G.assureCaller

do --> Utilities for setting up AFTs & Sprites
	local setupCache: { [any]: boolean } = {}
	function exports.setupAFT(aft: Types.ActorFrameTexture? | XMLTypes.ActorFrameTexture_names): Types.ActorFrameTexture
		assureCaller("setupAFT")

		local thisAFT: Types.ActorFrameTexture?
		if type(aft) == "string" then
			thisAFT = _G.Actors[aft]
		else
			thisAFT = aft
		end

		assert(thisAFT, `[_F.setupAFT]: AFT{type(aft) == "string" and ` '{aft}' ` or " "}doesn't exist`)
		if setupCache[thisAFT] then
			print(`[_F.setupAFT]: AFT{type(aft) == "string" and ` '{aft}' ` or " "}has already been set up.`)
			return thisAFT
		end

		setupCache[thisAFT] = true
		thisAFT:SetWidth(_G.DISPLAY:GetDisplayWidth())
		thisAFT:SetHeight(_G.DISPLAY:GetDisplayHeight())
		thisAFT:EnableDepthBuffer(false)
		thisAFT:EnableAlphaBuffer(false)
		thisAFT:EnableFloat(false)
		thisAFT:EnablePreserveTexture(true)
		thisAFT:Create()
		return thisAFT
	end

	function exports.setupSprite(sprite: Types.Sprite? | XMLTypes.Sprite_names): Types.Sprite
		assureCaller("setupSprite")

		local thisSprite: Types.Sprite?
		if type(sprite) == "string" then
			thisSprite = _G.Actors[sprite]
		else
			thisSprite = sprite
		end

		assert(thisSprite, `[_F.setupSprite]: Sprite{type(sprite) == "string" and ` '{sprite}' ` or " "}doesn't exist`)
		if setupCache[thisSprite] then
			print(
				`[_F.setupSprite]: Sprite{type(sprite) == "string" and ` '{sprite}' ` or " "}has already been set up.`
			)
			return thisSprite
		end

		setupCache[thisSprite] = true
		thisSprite:basezoomx(_G.SW / _G.DW)
		thisSprite:basezoomy(-_G.SH / _G.DH)
		thisSprite:x(_G.SCX)
		thisSprite:y(_G.SCY)
		return thisSprite
	end

	function exports.setupAFTAndSprite(
		aft: Types.ActorFrameTexture? | XMLTypes.ActorFrameTexture_names,
		sprite: Types.Sprite? | XMLTypes.Sprite_names
	): (Types.ActorFrameTexture, Types.Sprite)
		assureCaller("setupAFTAndSprite")

		local thisAFT = exports.setupAFT(aft)
		local thisSprite = exports.setupSprite(sprite)

		thisSprite:SetTexture(thisAFT:GetTexture())
		return thisAFT, thisSprite
	end
end

do --> Setup Utilities
	function exports.setupJudgeProxy(proxy: Types.ActorProxy?, target: Types.Actor?, playerID: number)
		if not (proxy and target) then return end
		proxy:SetTarget(target)
		proxy:xy(_G.SCX * (playerID - 0.5), _G.SCY)
		target:hidden(1)
		target:sleep(math.huge)

		return exports.setupJudgeProxy
	end

	function exports.backToSongWheel(message: string?)
		if message then
			_G.SCREENMAN:SystemMessage(message)
			print(message)
		end
		_G.GAMESTATE:FinishSong()
		_G.foreground:hidden(1)
	end
end

return exports
