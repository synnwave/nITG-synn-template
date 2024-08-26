--!nocheck
--!nolint UnknownGlobal
--!nolint BuiltinGlobalWrite
--!nolint GlobalUsedAsLocal
--!nolint FunctionUnused
--!nolint ImplicitReturn
--# selene: allow(incorrect_standard_library_use, unused_variable, global_usage, mixed_table)

-- do stuff that i Do not like to do but we have to do...(modify globals, setfenv and stuff like that)
-- thankfully we won't have to do anything when writing actual scripts, since the env is automatically applied by require()
-- and we have the globals script to prevent any "UnknownGlobal" lint warnings

return function(self: ActorFrame)
	local function cloneTable<T>(t: T): T
		local cloned = {}
		for k, v in pairs(t) do
			cloned[k] = v
		end
		return cloned
	end

	--> Make environment
	synn = {
		foreground = self,
		math = cloneTable(_G.math),
		table = cloneTable(_G.table),
		string = cloneTable(_G.string),
		type = _G.type,
		print = _G.print,
		pairs = _G.pairs,
		ipairs = _G.ipairs,
		unpack = _G.unpack,
		tonumber = _G.tonumber,
		tostring = _G.tostring,
		setmetatable = _G.setmetatable,
		rawget = _G.rawget,
		rawset = _G.rawset,
	}
	synn.synn = _G.synn -- lol

	local definedGlobals
	local metamethods = {
		apply = function(env, fenv)
			setfenv(fenv or 2, env)
			return fenv
		end,
	}
	setmetatable(synn, {
		__index = function(_, k) return metamethods[k] or _G[k] or synn.rawget(definedGlobals or {}, k) end,
		__call = metamethods.apply,
	})

	do --> Library backports (from lua 5.1 to 5.0)
		--> global backports
		function synn.select(index, ...: any)
			local items = arg.n or #arg
			if index == "#" then
				return items
			else
				local result = {}
				for i = index, items do
					synn.table.insert(result, arg[i])
				end
				return unpack(result)
			end
		end

		--> "string" library backports
		synn.string.gmatch = string.gmatch or string.gfind
		synn.string.match = string.match
			or function(s: string, pattern: string, init: number?)
				local first, last = synn.string.find(s, pattern, init or 1)
				if first then return synn.string.gmatch(synn.string.sub(s, first, last), pattern)() end
			end

		-- https://stackoverflow.com/a/43582076
		local function gsplit(text, pattern, plain)
			local splitStart, length = 1, #text
			return function()
				if splitStart then
					local sepStart, sepEnd = synn.string.find(text, pattern, splitStart, plain)
					local ret
					if not sepStart then
						ret = synn.string.sub(text, splitStart)
						splitStart = nil
					elseif sepEnd < sepStart then
						ret = synn.string.sub(text, splitStart, sepStart)
						if sepStart < length then
							splitStart = sepStart + 1
						else
							splitStart = nil
						end
					else
						ret = sepStart > splitStart and synn.string.sub(text, splitStart, sepStart - 1) or ""
						splitStart = sepEnd + 1
					end
					return ret
				end
			end
		end
		synn.string.split = string.split
			or function(s: string, separator: string?, plain: boolean?)
				separator = separator or ""
				local t = {}
				for match in gsplit(s, separator, plain) do
					table.insert(t, match)
				end
				return t
			end

		--> "math" library backports
		synn.math.clamp = math.clamp or function(n, min, max) return synn.math.min(math.max(n, min), max) end
		synn.math.huge = math.huge or 9e9
		synn.math.round = math.round or function(x) return x > 0 and synn.math.floor(x + 0.5) or synn.math.ceil(x - 0.5) end
		synn.math.modf = math.modf
			or function(x)
				local int = x >= 0 and synn.math.floor(x) or synn.math.ceil(x)
				return int, x - int
			end

		--> "table" library backports
		synn.table.clone = table.clone or cloneTable
		synn.table.clear = table.clear
			or function(t)
				for _ = 1, #t do
					table.remove(t)
				end
				for i in pairs(t) do
					t[i] = nil
					if i == "n" then t[i] = 0 end
				end
				return t
			end
		synn.table.find = table.find
			or function<V>(haystack: { V }, needle: V, init: number?)
				for i, v in ipairs(haystack) do
					if not (init and init > i) then
						if v == needle then return i end
					end
				end
				return
			end
		synn.table.pack = table.pack or function(...: any) return { n = synn.select("#", ...), ... } end
		synn.table.unpack = table.unpack
			or function(list, i, j)
				i = i or 1
				j = j or list.n or #list
				if i > j then
					return
				else
					return list[i], synn.table.unpack(list, i + 1, j)
				end
			end
	end

	self:removecommand("Init")
	self:sleep(synn.math.huge) -- Needed by StepMania, in order to not kill lua mods early

	do --> Custom require function
		local string, table = synn.string, synn.table
		function synn.normalizePath(path: string)
			local parts = {}
			for part in string.gmatch(path, "[^/]+") do
				if part == ".." then
					table.remove(parts)
				elseif part ~= "." then
					table.insert(parts, part)
				end
			end

			return `/{table.concat(parts, "/")}`
		end

		function synn.resolveLuaPath(path: string, sourcePoint: (number | string)?)
			local source
			if type(sourcePoint) == "string" then
				source = sourcePoint
			else
				local level = sourcePoint or 2
				local info
				repeat
					info = debug.getinfo(level, "S")
					if info then
						source = string.sub(info.source, 1, 1) == "@" and info.source
						level += 1
					end
				until source or not info
			end

			if type(source) == "string" and string.sub(source, 1, 1) == "@" and string.sub(path, 1, 6) ~= "/Songs" then
				source = string.sub(source, 2)
				local filePath = string.split(source, "/")
				filePath = filePath[#filePath] -- lol
				if filePath then source = string.sub(source, 1, -string.len(filePath) - 1) end
				path = source .. path
			end

			path = synn.normalizePath(path)
			if string.sub(path, -4) == ".lua" then path = string.sub(path, 1, -5) end

			return path
		end

		local cache = {}
		function synn.require(path)
			if not cache then error("Cannot call require() after the song has loaded") end

			local oldPath = path
			path = synn.resolveLuaPath(path, 3)

			local altPath = `{path}/init`
			local thisRequire = cache[altPath] or cache[path]
			if not thisRequire then
				local usedPath = path
				local loaded, loadError = loadfile(path)
				if not loaded then -- try alternative path
					usedPath = altPath
					loaded, loadError = loadfile(usedPath)
				end

				if not loaded then error(`[REQUIRE]: Could not require "{oldPath}", {loadError}`, 2) end
				print(`[REQUIRE]: {path}`)
				thisRequire = synn:apply(loaded)()
				cache[path] = thisRequire
				cache[usedPath] = thisRequire
			end

			return thisRequire
		end

		synn.definedGlobals = synn.require("globals")
		definedGlobals = synn.definedGlobals
		function synn.clearRequireCache() -- clear cache after LoadCommand
			cache = nil :: any
		end
	end

	synn:apply()
end
