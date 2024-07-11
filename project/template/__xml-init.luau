--!nocheck
--!nolint UnknownGlobal
--!nolint BuiltinGlobalWrite
--!nolint GlobalUsedAsLocal
--!nolint FunctionUnused
--!nolint ImplicitReturn
--# selene: allow(incorrect_standard_library_use, unused_variable, global_usage)

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
	synn_env = {
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
	}
	synn_env.synn_env = _G.synn_env -- lol
	setmetatable(synn_env, {
		__index = _G,
		__call = function(env, fenv)
			setfenv(fenv or 2, env)
			return fenv
		end,
	})

	do --> Library backports (from lua 5.1 to 5.0)
		--> "string" library backports
		synn_env.string.gmatch = string.gmatch or string.gfind
		synn_env.string.match = string.match
			or function(s: string, pattern: string, init: number?)
				local match = string.gmatch(s, pattern)
				local final
				for _ = 1, (init or 1) do
					final = match()
				end
				return final
			end

		-- https://stackoverflow.com/a/43582076
		local function gsplit(text, pattern, plain)
			local splitStart, length = 1, #text
			return function()
				if splitStart then
					local sepStart, sepEnd = string.find(text, pattern, splitStart, plain)
					local ret
					if not sepStart then
						ret = string.sub(text, splitStart)
						splitStart = nil
					elseif sepEnd < sepStart then
						ret = string.sub(text, splitStart, sepStart)
						if sepStart < length then
							splitStart = sepStart + 1
						else
							splitStart = nil
						end
					else
						ret = sepStart > splitStart and string.sub(text, splitStart, sepStart - 1) or ""
						splitStart = sepEnd + 1
					end
					return ret
				end
			end
		end
		synn_env.string.split = string.split
			or function(s: string, separator: string?, plain: boolean?)
				separator = separator or ""
				local t = {}
				for match in gsplit(s, separator, plain) do
					table.insert(t, match)
				end
				return t
			end

		--> "math" library backports
		synn_env.math.clamp = math.clamp or function(n, min, max) return math.min(math.max(n, min), max) end
		synn_env.math.huge = math.huge or 9e9
		synn_env.math.round = math.round or function(x) return x > 0 and math.floor(x + 0.5) or math.ceil(x - 0.5) end
		synn_env.math.modf = function(x)
			local int = x >= 0 and math.floor(x) or math.ceil(x)
			return int, x - int
		end

		--> "table" library backports
		synn_env.table.clone = table.clone or cloneTable
		synn_env.table.clear = table.clear
			or function(t)
				for _ in ipairs(t) do
					table.remove(t)
				end
				for i in pairs(t) do
					t[i] = nil
				end
				return t
			end
		synn_env.table.find = table.find
			or function<V>(haystack: { V }, needle: V, init: number?)
				for i, v in ipairs(haystack) do
					if not (init and init > i) then
						if v == needle then return i end
					end
				end
				return
			end
	end

	self:removecommand("Init")
	self:sleep(synn_env.math.huge) -- Needed by StepMania, in order to not kill lua mods early

	do --> Custom require function
		local string, table = synn_env.string, synn_env.table
		function synn_env.normalizePath(path: string)
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

		function synn_env.resolveLuaPath(path: string, sourcePoint: number?)
			local source = debug.getinfo(sourcePoint or 2, "S").source
			if type(source) == "string" and string.sub(source, 1, 1) == "@" and string.sub(path, 1, 6) ~= "/Songs" then
				source = string.sub(source, 2)
				local filePath = string.split(source, "/")
				filePath = filePath[#filePath] -- lol
				if filePath then source = string.sub(source, 1, -string.len(filePath) - 1) end
				path = source .. path
			end

			path = synn_env.normalizePath(path)
			if string.sub(path, -4) == ".lua" then path = string.sub(path, 1, -5) end

			return path
		end

		local cache = {}
		synn_env.require = function(path)
			if not cache then error("Cannot call require() after the song has loaded") end

			local oldPath = path
			path = synn_env.resolveLuaPath(path, 3)

			local altPath = `{path}/init`
			local thisRequire = cache[altPath] or cache[path]
			if not thisRequire then
				local usedPath = path
				local loaded = loadfile(path)
				if not loaded then -- try alternative path
					usedPath = altPath
					loaded = loadfile(usedPath)
				end

				if not loaded then error(`[REQUIRE]: Could not find "{oldPath}"`, 2) end
				print(`[REQUIRE]: {path}`)
				thisRequire = synn_env(loaded)()
				cache[path] = thisRequire
				cache[usedPath] = thisRequire
			end

			return thisRequire
		end

		function synn_env.clearRequireCache() -- clear cache after LoadCommand
			cache = nil :: any
		end
	end

	synn_env()
end
