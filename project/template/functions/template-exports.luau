--!strict

--> Credits to XeroOl and all of the mirin template contributors.
--> By: @synnwave

local _G = require("../globals")
local _E = require("easings")
local _S = require("sort")
local Types = require("../types/TypeDefs")

local makeFunctionDataStructure = require("makeFunctionDataStructure")

local exports = {}
local internals = {}

local thisSong = _G.GAMESTATE:GetCurrentSong()
local assureCaller = _G.assureCaller

local function deepCopy<T>(tbl: T): T
	local function __copy(t: { [any]: any })
		local tCopy = table.clone(t)
		for k, v in pairs(tCopy) do
			if type(v) == "table" then tCopy[k] = __copy(v) end
		end
		return tCopy
	end

	return __copy(tbl :: any) :: T
end

do --> "easeMod", "setMod", "resetMod"
	--> easeMod
	type ease_props = {
		beat: number,
		length: number?,
		easing: (_E.allEasings | _E.easingType)?,
		mod: { value: number, mod: Types.mods } | { { value: number, mod: Types.mods } },
		player: (number | { number })?,

		relativeValue: boolean?, -- "relativeValue" and "add" are the same thing, add is only here as a shorthand
		add: boolean?, -- "add" & "acc" from the mirin template don't exist here, use this value instead (add = easeMod, acc = setMod)

		endMode: boolean?,
		timeBased: boolean?,

		__reset: boolean?,
		__only: { string }?,
		__exclude: { [string]: boolean }?,
	}
	type INTERNAL_ease = {
		beat: number,
		length: number,
		startTime: number,
		easing: (number) -> number,
		player: number,
		mod: { { value: number, mod: Types.mods } },

		endMode: boolean?,
		timeBased: boolean?,

		only: { string }?,
		exclude: { [string]: boolean }?,
		relative: boolean?,
		reset: boolean?,

		offset: number,
	}
	internals.__eases = {} :: { INTERNAL_ease }
	function exports.easeMod(props: ease_props)
		assureCaller("easeMod", false, true)

		if not props.player then props.player = rawget(_G :: any, "affectedPlayers") or { 1, 2 } end -- i HATE metatables..

		local thisEase = {
			beat = props.beat,
			length = props.length or 0,
			easing = _E.getEasing(props.easing),

			endMode = props.endMode,
			timeBased = props.timeBased,
			player = props.player,

			relative = props.add or props.relativeValue,
			reset = props.__reset,
			only = props.__only,
			exclude = props.__exclude,
		} :: INTERNAL_ease

		if props.endMode then
			thisEase.length -= thisEase.beat
		end
		thisEase.startTime = props.timeBased and props.beat or thisSong:GetElapsedTimeFromBeat(props.beat)

		if type(props.mod) == "table" and (props.mod :: any)[1] == nil then
			thisEase.mod = { props.mod :: any }
		elseif type(props.mod) == "table" then
			thisEase.mod = props.mod
		end

		if type(props.player) == "table" then
			local savedEase = thisEase.easing
			thisEase.easing = nil :: any -- remove the ease from the table so it doesn't get deep copied

			for _, player in ipairs(props.player) do
				local thisCopy = deepCopy(thisEase)
				thisCopy.player = player
				thisCopy.easing = savedEase -- add the ease back
				table.insert(internals.__eases, thisCopy)
			end
		else
			table.insert(internals.__eases, thisEase)
		end

		return exports.easeMod
	end

	--> setMod
	function exports.setMod(props: ease_props)
		assureCaller("setMod", false, true)

		props.length = 0
		props.easing = _E.instant
		exports.easeMod(props)

		return exports.setMod
	end

	--> resetMod
	type reset_props = ease_props & {
		only: (Types.mods | { Types.mods })?,
		exclude: { Types.mods }?,
	}
	function exports.resetMod(props: reset_props)
		assureCaller("resetMod", false, true)

		props.__reset = true
		if props.only then
			if type(props.only) == "string" then props.only = { props.only } end
			props.__only = props.only :: { string }
			props.only = nil
		elseif props.exclude then
			if type(props.exclude) == "string" then props.exclude = { props.exclude } end

			local newExclude = {}
			for _, toExclude in ipairs(props.exclude) do
				newExclude[toExclude] = true
			end
			props.__exclude = newExclude
			props.exclude = nil
		end

		exports.easeMod(props)

		return exports.resetMod
	end
end

do --> "bindFunction", "bindToUpdate", "easeFunction"
	--> bindFunction
	type boundFunction = (beat: number, time: number, deltaTime: number, poptions: { { [string]: number } }) -> ()
	type bindFunction_props = {
		beat: number?,
		method: (beat: number, time: number) -> (),
		persist: (boolean | number)?,

		defer: boolean?,
		timeBased: boolean?,
		endMode: boolean?,
	}
	type INTERNAL_bindFunction = {
		beat: number,
		method: boundFunction,

		timeBased: boolean?,
		startTime: number,
		priority: number,

		--> frameBound
		length: number?,
		mods: { [any]: { [string]: any } }?,
	}

	internals.__functions = {} :: { INTERNAL_bindFunction }
	function exports.bindFunction(props: bindFunction_props)
		assureCaller("bindFunction", false, true)

		local thisFunction = {
			beat = props.beat or 0,
			method = props.method,
			timeBased = props.timeBased,
		} :: INTERNAL_bindFunction

		local thisPersist
		if type(props.persist) == "number" and props.endMode then
			thisPersist = (props.persist - thisFunction.beat)
		elseif type(props.persist) == "boolean" and props.persist == false then
			thisPersist = 0.5
		end
		if type(thisPersist) == "number" then
			local oldMethod = thisFunction.method
			local time = thisFunction.beat + thisPersist
			thisFunction.method = function(beat: number, ...: any)
				if beat < time then oldMethod(beat, ...) end
			end
		end

		thisFunction.priority = (props.defer and -1 or 1) * (#internals.__functions + 1)
		thisFunction.startTime = props.timeBased and props.beat or thisSong:GetElapsedTimeFromBeat(thisFunction.beat)
		table.insert(internals.__functions, thisFunction)

		return exports.bindFunction
	end

	--> bindToUpdate
	type bindToUpdate_props = {
		length: number?,

		beat: number?,
		method: boundFunction,
		persist: (boolean | number)?,

		defer: boolean?,
		timeBased: boolean?,
		endMode: boolean?,
	}
	local preventPoptions: any = setmetatable({}, {
		__index = function() error("you cannot use poptions and persist at the same time. </3", 2) end,
	})
	function exports.bindToUpdate(props: bindToUpdate_props, noPoptions: boolean?)
		assureCaller("bindToUpdate", false, true)

		local thisFunction = {
			beat = props.beat or 0,
			length = props.length or math.huge,
			method = props.method,
		}
		if props.endMode then
			thisFunction.length -= thisFunction.beat
		end

		if not noPoptions then
			local thisMods = {}
			thisFunction.mods = thisMods
			for playerId = 1, _G.PLAYER_COUNT do
				thisMods[playerId] = {}
			end
		end

		thisFunction.priority = (props.defer and -1 or 1) * (#internals.__functions + 1)
		thisFunction.startTime = props.timeBased and thisFunction.beat or thisSong:GetElapsedTimeFromBeat(thisFunction.beat)
		local thisPersist = props.persist
		if thisPersist then
			if type(thisPersist) == "number" and props.endMode then
				thisPersist -= thisFunction.beat - thisFunction.length
			end

			exports.bindFunction {
				beat = thisFunction.beat + thisFunction.length,
				method = function() thisFunction.method(_G.GAMESTATE:GetSongBeat(), 0, 0, preventPoptions) end,
				persist = props.persist,
			}
		end

		table.insert(internals.__functions, thisFunction)

		return exports.bindToUpdate
	end

	--> easeFunction
	type easeFunction_props = {
		length: number?,
		beat: number?,
		method: (value: number) -> (),
		persist: (boolean | number)?,

		defer: boolean?,
		timeBased: boolean?,
		endMode: boolean?,

		startValue: number?,
		targetValue: number?,
		easing: (_E.allEasings | _E.easingType)?,
	}
	function exports.easeFunction(props: easeFunction_props)
		assureCaller("easeFunction", false, true)

		local thisFunction = {
			beat = props.beat or 0,
			length = props.length or 0,
			timeBased = props.timeBased,
			persist = false,
		}

		local startValue = props.startValue or 0
		local targetValue = props.targetValue or 1
		local easing = _E.getEasing(props.easing) :: (number) -> number
		function thisFunction.method(beat: number)
			local progress = (beat - thisFunction.beat) / thisFunction.length
			props.method(startValue + (targetValue - startValue) * easing(progress))
		end

		if props.endMode then
			thisFunction.length -= thisFunction.beat
		end
		if props.persist ~= false then
			local finalValue = easing(1) > 0.5 and targetValue or startValue
			exports.bindFunction {
				beat = thisFunction.beat + thisFunction.length,
				method = function() props.method(finalValue) end,
				persist = props.persist,
				defer = props.defer,
			}
		end

		exports.bindToUpdate(thisFunction, true)

		return exports.easeFunction
	end
end

do --> "setAlias", "setModDefault", "setAux", "makeNode", "defineMod"
	--> setAlias
	internals.__aliases = {}
	function exports.setAlias(old: Types.mods, new: string)
		internals.__aliases[string.lower(old)] = string.lower(new)
		return exports.setAlias
	end

	--> setDefault
	internals.__defaultMods = setmetatable({}, {
		__index = function(self, i)
			self[i] = 0
			return 0
		end,
	})
	do --> Hell. beware
		type setModDefault_schema =
			((value: number, mod: Types.mods) -> setModDefault_schema)
			& (({ value: number, mod: Types.mods }) -> setModDefault_schema)
			& (({ { value: number, mod: Types.mods } }) -> setModDefault_schema)
		local function __setModDefault(...: any)
			assureCaller("setModDefault", false, true)
			local arg1: any, arg2: any = ...

			if type(arg1) == "table" then
				if type(arg1.mod) == "string" and type(arg1.value) == "number" then
					internals.__defaultMods[string.lower(arg1.mod)] = arg1.value
				else
					for _, v in ipairs(arg1) do
						internals.__defaultMods[string.lower(v.mod)] = v.value
					end
				end
			elseif type(arg1) == "number" and type(arg2) == "string" then
				internals.__defaultMods[string.lower(arg2)] = arg1
			end

			return __setModDefault :: setModDefault_schema
		end

		exports.setModDefault = __setModDefault :: setModDefault_schema
	end

	--> setAux
	internals.__auxes = {}
	function exports.setAux(toAux: string | { string })
		assureCaller("setAux", false, true)

		if type(toAux) == "string" then
			internals.__auxes[toAux] = true
		elseif type(toAux) == "table" then
			for _, thisAux in ipairs(toAux) do
				exports.setAux(thisAux)
			end
		end

		return exports.setAux
	end

	--> makeNode
	internals.__nodes = {} :: { INTERNAL_makeNode }
	type makeNode_props = {
		modName: string | { string },
		outputMod: (string | { string })?,
		method: (...number) -> ...number,

		defer: boolean?,
	}
	type INTERNAL_makeNode = {
		inputs: { string },
		outputs: { string },
		method: (...number) -> ...number,
		priority: number,

		isTerminator: boolean?,
		seen: number?,
		children: { INTERNAL_makeNode }?,
		parents: { [any]: { locked: boolean?, list: {} } }?,
		outs: { [any]: any }?,
		realMethod: ((number) -> ...any)?,
	}
	function exports.makeNode(props: makeNode_props)
		assureCaller("makeNode", false, true)

		local thisNode = {
			inputs = (type(props.modName) == "string" and { props.modName } or props.modName),
			outputs = (type(props.outputMod) == "string" and { props.outputMod } or props.outputMod),
			method = props.method,
			priority = (props.defer and -1 or 1) * (#internals.__nodes + 1),
		} :: INTERNAL_makeNode

		table.insert(internals.__nodes, thisNode)

		return exports.makeNode
	end

	--> defineMod
	type defineMod_props = {
		modName: string | { string },
		outputMod: (string | { string })?,
		method: (...number) -> ...number,

		defer: boolean?,
	}
	function exports.defineMod(props: defineMod_props)
		assureCaller("defineMod", false, true)

		local thisMod: makeNode_props = {
			modName = props.modName,
			outputMod = props.outputMod or {},
			method = props.method,
			defer = props.defer,
		}
		thisMod.modName = type(thisMod.modName) == "string" and { thisMod.modName } or thisMod.modName
		thisMod.outputMod = type(thisMod.outputMod) == "string" and { thisMod.outputMod } or thisMod.outputMod
		if type(thisMod.modName) == "table" then
			for _, modName in ipairs(thisMod.modName) do
				exports.setAux(modName)
			end
		end

		exports.makeNode(thisMod)

		return exports.defineMod
	end
end

do --> Runtime
	--> Setup Variables
	local function normalizeModName(mod: string): string
		mod = string.lower(mod)
		return internals.__aliases[mod] or mod
	end

	local bannedCharacters = `"'\{}(),;* `
	local bannedCharsList = string.split(bannedCharacters, "")
	local function safeNormalizeModName(mod: string): string
		if not internals.__auxes[mod] then
			-- stylua: ignore start
			if table.find(bannedCharsList, string.sub(mod, 1, 1)) or table.find(bannedCharsList, string.sub(mod, #mod, #mod)) then
				error(`You have a typo in your mod name. You wrote '{mod}', but you probably meant '{string.gsub(mod, `[{bannedCharacters}]`, "")}'`,2)
			end
			-- stylua: ignore end
			if string.find(mod, "^c[0-9]+$") then
				error(`You can't name your mod '{mod}'.\nUse 'cmod' if you want to set a cmod.`, 2)
			end
			if string.find(mod, "^[0-9.]+x$") then
				error(`You can't name your mod '{mod}'.\nUse 'xmod' if you want to set an xmod.`, 2)
			end
		end

		return normalizeModName(mod)
	end

	--> player targets
	local modTargets = {} :: { { [string]: number } }
	internals.__modTargets = modTargets
	for playerId = 1, _G.PLAYER_COUNT do
		modTargets[playerId] = setmetatable({}, { __index = internals.__defaultMods }) :: any
	end

	--> Mod values, gets recomputed every frame
	local modValues = {}
	internals.__modValues = modValues
	for playerId = 1, _G.PLAYER_COUNT do
		modValues[playerId] = setmetatable({}, { __index = modTargets[playerId] })
	end

	--> Mod string
	local modStringBuffer = {}
	internals.__modStringBuffer = modStringBuffer
	for playerId = 1, _G.PLAYER_COUNT do
		modStringBuffer[playerId] = {}
	end

	--> Keep track of which players are awake
	local lastSeenAwake = {}

	--> Poptions table
	local poptions = {} :: { { [string]: any } }
	local poptionsLoggingTarget = nil
	for playerId = 1, _G.PLAYER_COUNT do
		local playerMods = modValues[playerId]
		local thisMetatable = {
			__index = function(_, modName) return playerMods[normalizeModName(modName)] end,
			__newindex = function(_, modName, modValue)
				modName = normalizeModName(modName)
				playerMods[modName] = modValue
				if modValue and poptionsLoggingTarget then poptionsLoggingTarget[playerId][modName] = true end
			end,
		}
		poptions[playerId] = setmetatable({}, thisMetatable) :: any
	end

	--> Touch Mod
	local touchedMods = {}
	for playerId = 1, _G.PLAYER_COUNT do
		touchedMods[playerId] = {}
	end

	function exports.touchMod(mod: string, playerId: number?)
		if playerId then
			modValues[playerId][mod] = modValues[playerId][mod]
			return
		end

		for _playerId = 1, _G.PLAYER_COUNT do
			exports.touchMod(mod, _playerId)
		end

		return exports.touchMod
	end
	function exports.touchAllMods(playerId: number?)
		for mod in pairs(internals.__defaultMods) do
			exports.touchMod(mod)
		end

		if playerId then
			for mod in pairs(modTargets[playerId]) do
				exports.touchMod(mod, playerId)
			end
			return
		end
		for _playerId = 1, _G.PLAYER_COUNT do
			for mod in pairs(modTargets[_playerId]) do
				exports.touchMod(mod, _playerId)
			end
		end
	end

	--> Table Sorting
	--> Only runs once, during ScreenReadyCommand
	local function sortTables()
		--> sort Eases
		_S.stable_sort(internals.__eases, function(a, b)
			if a.startTime == b.startTime then
				return (not not a.reset) and not b.reset
			else
				return a.startTime < b.startTime
			end
		end)

		--> sort Functions
		_S.stable_sort(internals.__functions, function(a, b)
			if a.startTime == b.startTime then
				local priorityA, priorityB = a.priority, b.priority
				return (priorityA * priorityA * priorityB) < (priorityA * priorityB * priorityB)
			else
				return a.startTime < b.startTime
			end
		end)

		--> sort Nodes
		_S.stable_sort(internals.__nodes, function(a, b)
			local priorityA, priorityB = a.priority, b.priority
			return (priorityA * priorityA * priorityB) < (priorityA * priorityB * priorityB)
		end)
	end

	--> Resolve Aliases
	--> Only runs once, during ScreenReadyCommand
	local function resolveAliases()
		--> Auxes
		local clonedAuxes = table.clone(internals.__auxes)
		table.clear(internals.__auxes)
		for auxedMod in pairs(clonedAuxes) do
			internals.__auxes[normalizeModName(auxedMod)] = true
		end

		--> Eases
		for _, ease in ipairs(internals.__eases) do
			for _, modData in pairs(ease.mod) do
				modData.mod = safeNormalizeModName(modData.mod)
			end

			if ease.exclude then
				local newExclude = {}
				for mod, v in pairs(ease.exclude) do
					newExclude[safeNormalizeModName(mod)] = v
				end
				ease.exclude = newExclude
			end
			if ease.only then
				for i, mod in pairs(ease.only) do
					ease.only[i] = safeNormalizeModName(mod)
				end
			end
		end

		--> Nodes
		for _, node in ipairs(internals.__nodes) do
			for i, mod in pairs(node.inputs) do
				node.inputs[i] = safeNormalizeModName(mod)
			end
			for i, mod in pairs(node.outputs or {}) do
				node.outputs[i] = safeNormalizeModName(mod)
			end
		end

		--> Default mods
		local clonedDefaults = table.clone(internals.__defaultMods)
		table.clear(internals.__defaultMods :: any) -- stupid metatable
		for mod, value in pairs(clonedDefaults) do
			local normalized = safeNormalizeModName(mod)
			internals.__defaultMods[normalized] = value
			for playerId = 1, _G.PLAYER_COUNT do
				touchedMods[playerId][normalized] = true
			end
		end
	end

	--> Compile Nodes
	--> Only runs once, during ScreenReadyCommand
	local nodeStart = {} :: { [string]: any }
	local doNothing = function() end
	local function escapeString(str: string): string return `'{string.gsub(str, "[\\']", "\\%1" :: any)}'` end
	local function compileNodes()
		do --> Make terminators
			local terminators = {}
			for _, node in ipairs(internals.__nodes) do
				for _, mod in ipairs(node.outputs or {}) do
					terminators[mod] = true
				end
			end

			local terminatorPriority = -1 * (#internals.__nodes + 1)
			for terminator in pairs(terminators) do
				table.insert(internals.__nodes, {
					inputs = { terminator },
					outputs = {},
					priority = terminatorPriority,
					method = doNothing,
					isTerminator = true,
				})
			end
		end

		local lockedNode = {}
		local lastNode = {}
		for _, node in pairs(internals.__nodes) do
			if not node.isTerminator then
				node.children = {}
				local nodeOuts = {}
				node.outs = nodeOuts
				for playerId = 1, _G.PLAYER_COUNT do
					nodeOuts[playerId] = {}
				end
			end

			local nodeParents = {}
			node.parents = nodeParents
			for i, input in ipairs(node.inputs) do
				nodeStart[input] = nodeStart[input] or {}
				nodeParents[i] = { list = {} }

				if not nodeStart[input][lockedNode] then table.insert(nodeStart[input], node) end
				if nodeStart[input][lockedNode] then nodeParents[i].locked = true end
				for _, otherNode in ipairs(lastNode[input] or {}) do
					table.insert(otherNode.children, node)
					table.insert(nodeParents[i].list, otherNode.outs)
				end
			end

			for _, output in ipairs(node.outputs or {}) do
				if table.find(node.inputs, output) then
					nodeStart[output][lockedNode] = true
					lastNode[output] = { node }
				elseif not lastNode[output] then
					lastNode[output] = { node }
				else
					table.insert(lastNode[output], node)
				end
			end

			local nodeCode = "return function(node, mods)\nreturn function(playerId)\n"
			local function appendIndex(index, str)
				if index ~= 1 then
					nodeCode ..= str
				end
			end

			local function appendInputs()
				for i, mod in ipairs(node.inputs) do
					appendIndex(i, ",")

					local thisParent = nodeParents[i]
					for j = 1, #thisParent.list do
						appendIndex(j, "+")
						nodeCode ..= `\n\nnode.parents[{i}].list[{j}][playerId][{escapeString(mod)}]`
					end
					if not thisParent.locked then
						appendIndex(#thisParent.list + 1, "+")
						nodeCode ..= `\n\nmods[playerId][{escapeString(mod)}]`
					end
				end
			end
			if node.isTerminator then
				nodeCode ..= `\n\nmods[playerId][{escapeString(node.inputs[1])}] = `
				appendInputs()
				nodeCode ..= "\n"
			else
				if node.outputs then
					for i, mod in ipairs(node.outputs) do
						appendIndex(i, ",")
						nodeCode ..= `\n\nnode.outs[playerId][{escapeString(mod)}]`
					end
					if node.outputs[1] then
						nodeCode ..= " = "
					end
				end

				nodeCode ..= "node.method("
				appendInputs()
				nodeCode ..= "\n\n, playerId)\n"
			end
			nodeCode ..= "end\nend\n"

			local compiledCode = assert(loadstring(nodeCode, "node_generated"))()
			node.realMethod = compiledCode(node, modValues)
			if (not node.isTerminator) and node.realMethod then
				for playerID = 1, _G.PLAYER_COUNT do
					node.realMethod(playerID)
				end
			end
		end

		for _, node in pairs(nodeStart) do
			node[lockedNode] = nil
		end
	end

	--> Run Eases
	local easesIndex = 1
	local activeEases = {}
	local function runEases(beat: number, time: number)
		--> Get & Setup active eases
		while easesIndex <= #internals.__eases do
			local ease = internals.__eases[easesIndex]
			local measure = ease.timeBased and time or beat
			if measure < ease.beat then break end

			local player = ease.player
			if ease.reset then
				if ease.only then
					for _, mod in ipairs(ease.only) do
						table.insert(ease.mod, { mod = mod, value = internals.__defaultMods[mod] })
					end
				else
					for mod in pairs(modTargets[player]) do
						if not (ease.exclude and ease.exclude[mod]) and modTargets[player][mod] ~= internals.__defaultMods[mod] then
							table.insert(ease.mod, { mod = mod, value = internals.__defaultMods[mod] })
						end
					end
				end
			end

			local easeEndsAtDifferentPosition = ease.easing(1) >= 0.5
			ease.offset = easeEndsAtDifferentPosition and 1 or 0

			for _, mod in ipairs(ease.mod) do
				if not ease.relative then
					mod.value -= modTargets[player][mod.mod]
				end

				if easeEndsAtDifferentPosition then modTargets[player][mod.mod] = modTargets[player][mod.mod] + mod.value end
			end

			table.insert(activeEases, ease)
			easesIndex += 1
		end

		--> Animate Eases
		local activeEasesIndex = 1
		while activeEasesIndex <= #activeEases do
			local ease = activeEases[activeEasesIndex]
			local player = ease.player
			local measure = ease.timeBased and time or beat

			if measure < ease.beat + ease.length then
				local eased = ease.easing((measure - ease.beat) / ease.length) - ease.offset
				for _, mod in ipairs(ease.mod) do
					modValues[player][mod.mod] = modValues[player][mod.mod] + eased * mod.value
				end

				activeEasesIndex += 1
			else
				for _, mod in ipairs(ease.mod) do
					exports.touchMod(mod.mod)
				end

				if activeEasesIndex ~= #activeEases then
					activeEases[activeEasesIndex] = table.remove(activeEases) :: any
				else
					table.remove(activeEases)
				end
			end
		end
	end

	--> Run functions
	local functionsIndex = 1
	local activeFunctions = makeFunctionDataStructure(internals.__functions, function(a, b)
		local priorityA, priorityB = a.priority, b.priority
		return (priorityA * priorityA * priorityB) < (priorityA * priorityB * priorityB)
	end)
	local preventBindFunctionPoptions: any = setmetatable({}, {
		__index = function() error("you cannot use poptions on bindFunction", 2) end, -- because bindToUpdate shares the same type as bindFunction
	})
	local function runFunctions(beat: number, time: number, deltaTime: number)
		while functionsIndex <= #internals.__functions do
			local func = internals.__functions[functionsIndex]
			local measure = func.timeBased and time or beat
			if measure < func.beat then break end

			if not func.length then
				func.method(measure, time, deltaTime, preventBindFunctionPoptions)
			elseif measure < func.beat + func.length then
				activeFunctions:add(func)
			end

			functionsIndex += 1
		end

		local playerCount = _G.PLAYER_COUNT
		while true do
			local func = activeFunctions:next()
			if not func then break end

			local measure = func.timeBased and time or beat
			if func.length and measure < func.beat + func.length then
				poptionsLoggingTarget = func.mods :: any
				func.method(measure, time, deltaTime, poptions)
			else
				if func.mods then
					for playerId = 1, playerCount do
						for mod in pairs(func.mods[playerId]) do
							exports.touchMod(mod, playerId)
						end
					end
				end
				activeFunctions:remove()
			end
		end
	end

	--> Run Nodes
	local playersSeen = 1
	local activeNodes = {}
	local activeNodeTerminators = {}
	local propagateAllNodes, propagateNode
	function propagateAllNodes(nodesToPropagate)
		if nodesToPropagate then
			for _, node in ipairs(nodesToPropagate) do
				propagateNode(node)
			end
		end
	end
	function propagateNode(node)
		if node.seen ~= playersSeen then
			node.seen = playersSeen
			if node.isTerminator then
				table.insert(activeNodeTerminators, node)
			else
				propagateAllNodes(node.children)
				table.insert(activeNodes, node)
			end
		end
	end

	local function runNodes()
		for playerId = 1, _G.PLAYER_COUNT do
			local thisPlayer = _G.Players[playerId]
			if thisPlayer and thisPlayer:IsAwake() then
				if not lastSeenAwake[playerId] then
					lastSeenAwake[playerId] = true
					for mod in pairs(touchedMods[playerId]) do
						exports.touchMod(mod, playerId)
						touchedMods[playerId][mod] = nil
					end
				end
				playersSeen += 1
				for mod in pairs(modValues[playerId]) do
					propagateAllNodes(nodeStart[mod])
				end

				for _ = 1, #activeNodes do
					local lastNode = table.remove(activeNodes)
					if lastNode then lastNode.realMethod(playerId) end
				end

				for _ = 1, #activeNodeTerminators do
					local lastNode = table.remove(activeNodeTerminators)
					if lastNode then lastNode.realMethod(playerId) end
				end
			else
				lastSeenAwake[playerId] = false
				for mod in pairs(modValues[playerId]) do
					modValues[playerId][mod] = nil
					touchedMods[playerId][mod] = true
				end
			end
		end
	end

	--> Run Mods
	local function indexClear(t)
		for _ = 1, #t do
			table.remove(t)
		end
		return t
	end

	local function runMods()
		for playerId = 1, _G.PLAYER_COUNT do
			local thisPlayer = _G.Players[playerId]
			if thisPlayer and thisPlayer:IsAwake() then
				local thisBuffer = modStringBuffer[playerId]
				for mod, value in pairs(modValues[playerId]) do
					if not internals.__auxes[mod] then table.insert(thisBuffer, `*-1 {value} {mod}`) end
					modValues[playerId][mod] = nil
				end

				if thisBuffer[1] then
					local compiledBuffer = table.concat(thisBuffer, ",")
					_G.GAMESTATE:ApplyModifiers(compiledBuffer, playerId)
					indexClear(thisBuffer)
				end
			end
		end
	end

	--> Finalize
	function internals.__onUpdate(beat: number, time: number, deltaTime: number)
		runEases(beat, time)
		runFunctions(beat, time, deltaTime)
		runNodes()
		runMods()
	end
	function internals.__onReady()
		sortTables()
		resolveAliases()
		compileNodes()

		for playerId = 1, _G.PLAYER_COUNT do
			indexClear(modStringBuffer[playerId])
		end

		_G.templateReady = true
		pcall(_G.clearRequireCache)

		runNodes()
		runMods()
	end
end

do --> Setup mods
	_G.GAMESTATE:ApplyModifiers("clearall")

	--> zoom, zoomx, zoomy
	exports.setAux "zoom"
	exports.makeNode {
		modName = { "zoom", "zoomx", "zoomy" },
		method = function(zoom, x, y)
			local mod = zoom * 0.01
			return x * mod, y * mod
		end,
		outputMod = { "zoomx", "zoomy" },
		defer = true,
	}
	exports.setModDefault {
		{ value = 100, mod = "zoom" },
		{ value = 100, mod = "zoomx" },
		{ value = 100, mod = "zoomy" },
		{ value = 100, mod = "zoomz" },
		{ value = 400, mod = "grain" },
	}

	--> movex, movey, movez
	for _, axis in ipairs({ "x", "y", "z" }) do
		local thisName = `move{axis}`
		local outputs = {}
		for i = 0, 7 do
			table.insert(outputs, `{thisName}{i}`)
		end

		exports.defineMod {
			modName = thisName,
			method = function(a) return a, a, a, a, a, a, a, a end,
			outputMod = outputs,
			defer = true,
		}
	end

	--> xmod, cmod
	exports.setModDefault { { value = 1, mod = "xmod" } }
	exports.defineMod {
		modName = { "xmod", "cmod" },
		method = function(xmod, cmod, playerId)
			local thisBuffer = internals.__modStringBuffer[playerId]
			if cmod == 0 then
				table.insert(thisBuffer, string.format("*-1 %fx", xmod))
			else
				table.insert(thisBuffer, string.format("*-1 %fx,*-1 c%f", xmod, cmod))
			end
		end,

		defer = true,
	}
end

return {
	exports = exports,
	internals = internals,
}
