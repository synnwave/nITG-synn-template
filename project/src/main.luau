--!strict

local _T = require("../template")
local _G, _P, _F, _A, _E, _D = _T.Globals, _T.Players, _T.Functions, _T.Actors, _T.Easings, _T.Def

do --> Declare Actors here (if needed, see: https://github.com/synnwave/nITG-synn-template/pull/1)
	for playerId = 1, 2 do --> Create actor proxies for the player, judgment & combo actors.
		_D.ActorProxy { Name = `PP[{playerId}]` } -- Player Proxy
		if playerId <= 2 then -- We only need to create combo & judgment proxies for players 1 and 2
			_D.ActorProxy { Name = `PJ[{playerId}]` } -- Player Judgment Proxy
			_D.ActorProxy { Name = `PC[{playerId}]` } -- Player Combo Proxy
		end
	end

	--> Add more actors after this line!

	---
end

return function()
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

		--> Setup Judgment & Combo Proxies
		for playerId = 1, 2 do
			local thisPlayer = _P[playerId]
			_F.setupJudgeProxy(_A.PJ[playerId], thisPlayer:GetChild("Judgment"), playerId)
			_F.setupJudgeProxy(_A.PC[playerId], thisPlayer:GetChild("Combo"), playerId)
		end
	end

	-- your code goes here here here:
	-- code
	-- it goes here here
	-- :
	-- and its yours

	-- Mod example:
	_F.setModDefault { xmod = 3, confusion = 100 }
end
