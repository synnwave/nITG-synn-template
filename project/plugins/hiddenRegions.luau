--!strict
local _T = require("../template")
local _G, _F = _T.Globals, _T.Functions

-- hiddenregions, made by oatmealine
-- luau version made by synnwave

export type region = {
	beat: number,
	length: number,
	player: (number | { number })?,
	column: (number | { number })?,
}
export type INTERNAL_region = {
	beat: number,
	length: number,
	player: { number },
	column: { number },
}

local hiddenRegions = {} :: { INTERNAL_region }

local hasRegistered = false
local function registerRegions()
	local result = {}
	for playerId = 1, _G.PLAYER_COUNT do -- one for each player
		result[playerId] = {}
	end

	for column = 0, 3 do
		for _, region in ipairs(hiddenRegions) do
			if table.find(region.column, column) then
				for _, playerId in ipairs(region.player) do
					table.insert(result[playerId], { region.beat, region.length, column })
				end
			end
		end
	end

	for playerID, regions in ipairs(result) do
		_T.Players[playerID]:SetHiddenRegions(regions)
	end
end

local function hideRegion(props: region)
	if not hasRegistered then
		hasRegistered = true
		_F.bindFunction { method = registerRegions }
	end

	if not props.player then props.player = rawget(_G :: any, "affectedPlayers") or { 1, 2 } end -- i HATE metatables..
	if not props.column then props.column = { 0, 1, 2, 3 } end
	local thisRegion = {
		beat = props.beat,
		length = props.beat + props.length,
		player = type(props.player) == "number" and { props.player } or props.player,
		column = type(props.column) == "number" and { props.column } or props.column,
	} :: INTERNAL_region

	table.insert(hiddenRegions, thisRegion)
	return hideRegion
end

return hideRegion
