--!strict

-- Original by XeroOl
-- Luau version by @synnwave

local _T = require("../template")
local _G, _F = _T.Globals, _T.Functions

export type spellcard = {
	startBeat: number,
	endBeat: number,
	name: string,
	difficulty: number,
	color: string | { number },
}
local spellcards = {} :: { spellcard }

local function registerSpellcards()
	local thisSong = _G.GAMESTATE:GetCurrentSong()

	thisSong:SetNumSpellCards(#spellcards)
	table.sort(spellcards, function(a, b) return a.startBeat < b.startBeat end)

	for i, card in ipairs(spellcards) do
		local index = i - 1
		thisSong:SetSpellCardTiming(index, card.startBeat, card.endBeat)
		thisSong:SetSpellCardName(index, card.name)
		thisSong:SetSpellCardDifficulty(index, card.difficulty)

		local thisColor = {}
		if type(card.color) == "string" then
			for match in string.gmatch(card.color, "[a-fA-F0-9][a-fA-F0-9]") do
				table.insert(thisColor, assert(tonumber(match, 16)) / 255)
			end
		elseif type(card.color) == "table" then
			thisColor = card.color
		end

		thisSong:SetSpellCardColor(index, thisColor[1] or 0, thisColor[2] or 0, thisColor[3] or 0, thisColor[4] or 1)
	end
end

local function createSpellcard(card: spellcard)
	if not spellcards[1] then _F.bindFunction { method = registerSpellcards } end
	table.insert(spellcards, card)

	return createSpellcard
end

return createSpellcard
