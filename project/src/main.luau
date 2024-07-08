--!strict

local _T = require("../template")
local _G, _P, _F, _A, _E = _T.Globals, _T.Players, _T.Functions, _T.Actors, _T.Easings
do --> Setup
	if (not _P[1]) or not _P[2] then
		_F.backToSongWheel("Two Player Mode Required")
		return
	end

	--> Setup Player Proxies
	for playerId = 1, #_A.PP do
		local thisPlayer = _P[playerId]
		_A.PP[playerId]:SetTarget(thisPlayer)
		thisPlayer:hidden(1)
	end

	--> Setup Judgement & Combo Proxies
	for playerId = 1, 2 do
		local thisPlayer = _P[playerId]
		_F.setupJudgeProxy(_A.PJ[playerId], thisPlayer:GetChild("Judgement"), playerId)
		_F.setupJudgeProxy(_A.PC[playerId], thisPlayer:GetChild("Combo"), playerId)
	end
end

-- your code goes here here here:

-- code

-- it goes here here
-- :

-- and its yours

_F.setModDefault { { percent = 6, mod = "xmod" } }
