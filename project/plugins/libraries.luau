--!strict
--> all libraries (except the coord library. sorry but i did not feel like doing math 😭) made by synnwave!!
--> credits to egomoose for their coord library implementation https://github.com/EgoMoose/Articles/blob/master/CFrames/cframe%20class.lua
--> these libraries are inspired by roblox's libraries Lol... they're really useful though!!

--> i may or may not have gotten lazy when writing error messages so sorry about that

--> any questions or suggestions you have, please let me know!

local _T = require("../template")
local _G = _T.Globals

local exports = {}

-- stylua: ignore start
local setmetatable, getmetatable, insert = setmetatable, getmetatable, table.insert
local format, sub, gmatch = string.format, string.sub, string.gmatch
local abs, cos, sin, sqrt, acos, asin, atan2, floor, deg, mMax, mMin, round =
	math.abs, math.cos, math.sin, math.sqrt, math.acos, math.asin, math.atan2, math.floor, math.deg, math.max, math.min, math.round
-- stylua: ignore end

--> Utility methods
local function checkClassMeta<T>(class: T, classMetatable): (boolean, string)
	local thisMetatable = getmetatable(class :: any)
	return thisMetatable == classMetatable, ((thisMetatable and thisMetatable.__type) or "?")
end

local function checkClassType(class: any, classType: string): (boolean, string)
	local thisType = type(class)
	thisType = thisType == "table" and class.__type or thisType
	return thisType == classType, thisType
end

local function lerp(start: number, goal: number, alpha: number) return start + (goal - start) * alpha end

local function lock<T>(table: T, name: string, restrictMissingMembers: boolean?): T
	local metatable = getmetatable(table :: any)
	local thisMetatable
	if metatable == nil then
		thisMetatable = {}
		setmetatable(table :: any, thisMetatable)
	else
		thisMetatable = metatable
	end

	function thisMetatable:__newindex() error(`attempt to modify a readonly table '{name or ""}'`, 2) end
	if restrictMissingMembers then
		function thisMetatable:__index(k) error(`'{k}' is not a valid member of table '{name or ""}'`, 2) end
	end

	return table
end

-- https://github.com/EmmanuelOga/columns/blob/master/utils/color.lua#L89
local function rgbToHsv(r: number, g: number, b: number)
	local max, min = mMax(r, g, b), mMin(r, g, b)
	local h, s, v
	v = max

	local d = max - min
	if max == 0 then
		s = 0
	else
		s = d / max
	end

	if max == min then
		h = 0
	else
		if max == r then
			h = (g - b) / d
			if g < b then h = h + 6 end
		elseif max == g then
			h = (b - r) / d + 2
		elseif max == b then
			h = (r - g) / d + 4
		end
		h = h / 6
	end

	return h, s, v
end

local function hsvToRgb(h: number, s: number, v: number)
	local r, g, b

	local i = floor(h * 6)
	local f = h * 6 - i
	local p = v * (1 - s)
	local q = v * (1 - f * s)
	local t = v * (1 - (1 - f) * s)

	i = i % 6

	if i == 0 then
		r, g, b = v, t, p
	elseif i == 1 then
		r, g, b = q, v, p
	elseif i == 2 then
		r, g, b = p, v, t
	elseif i == 3 then
		r, g, b = p, q, v
	elseif i == 4 then
		r, g, b = t, p, v
	elseif i == 5 then
		r, g, b = v, p, q
	end
	return r, g, b
end

-- credits to Xero Ol for this -> https://github.com/XeroOl/notitg-mirin-plugins/blob/master/rand.xml
local __randomState = 1
local function randomFloat(a: number?, b: number?)
	__randomState = __randomState + 1
	local r = abs((sin(632459.86 * __randomState) * 1023341.55) % 1)
	if not a then
		return r
	elseif not b then
		return r * a
	else
		return lerp(b, a, r)
	end
end
local function randomInt(a: number, b: number?, c: number?)
	local realA, realB, realC = a, b or a, c or 1
	if not b then
		realA, realB = 1, a
	end
	return floor(randomFloat() * (realB - realA) / realC) * realC + realA
end
-------------------
local classMetatables = {} -- i ended up only using this for the coord library and nothing else but whatever

--> Base sequence class
local function __makeSequenceConstructor(classMetatable: any?)
	local isNumberSequence = classMetatable == nil
	local className = isNumberSequence and "number" or classMetatable.__type
	local keypointName = className .. "Keypoint"
	local function checkType(value)
		if isNumberSequence then
			local thisType = type(value)
			return thisType == "number", thisType
		else
			return checkClassMeta(value, classMetatable)
		end
	end

	local function keypoint(time: number, value: any, envelope: number?)
		if type(time) ~= "number" then
			error(`invalid {keypointName} parameter #1 (expected number, got {type(time)})`, 2)
		end

		local isClassType, gotType = checkType(value)
		if not isClassType then error(`invalid {keypointName} parameter #2 (expected {className}, got {gotType})`, 2) end
		if isNumberSequence then
			if envelope and type(envelope) ~= "number" then
				error(`invalid {keypointName} parameter #3 (expected number, got {type(envelope)})`, 2)
			end
			if type(value) == "number" and value ~= value then value = 0 end
			if (envelope ~= envelope) or not envelope then envelope = 0 end
		else
			envelope = nil
		end

		return lock({ __type = keypointName, time = time, value = value, envelope = envelope }, keypointName)
	end

	local sequence
	local sequenceClassName = className .. "Sequence"
	local sequenceMeta = { __type = sequenceClassName }
	sequenceMeta.__index = sequenceMeta
	classMetatables[sequenceMeta.__type] = sequenceMeta

	local lerpMethod = lerp
	if not isNumberSequence then lerpMethod = function(a: any, b: any, t: number) return a:lerp(b, t) end end

	function sequenceMeta:evaluate(time: number): any
		-- this will make elastic eases not look like shit. this expects your sequence to loop in some way!!
		if time < 0 then time = 1 + time end
		time = abs(time)
		if time > 1 then time = time % 1 end -- is there a better way to do this? i want the effect of modulo but not if time = 1

		local keypoints = self.keypoints
		local keypointCount = #keypoints - 1

		for i = 1, keypointCount do
			local thisKeypoint = keypoints[i]
			local nextKeypoint = keypoints[i + 1]
			local thisTime, nextTime = thisKeypoint.time, nextKeypoint.time
			if (time >= thisTime and time < nextTime) or (i == 1 and time <= 0) or (i == keypointCount and time >= 1) then
				local alpha = (time - thisTime) / (nextTime - thisTime)
				return lerpMethod(thisKeypoint.value, nextKeypoint.value, alpha)
			end
		end

		error("failed to evaluate " .. sequenceClassName, 2)
	end

	if isNumberSequence then
		function sequenceMeta:resolve()
			local thisSequence = {}
			for i, thisKeypoint in ipairs(self.keypoints) do
				thisSequence[i] = keypoint(
					thisKeypoint.time,
					(thisKeypoint.value :: number) + randomFloat(-thisKeypoint.envelope or 0, thisKeypoint.envelope or 0)
				)
			end
			return sequence(thisSequence)
		end
	end

	function sequence(a: any, b: any)
		local keypoints = {}

		local isClassType, gotType = checkType(a)
		if type(a) ~= "table" and not isClassType then
			error(`invalid {sequenceClassName} parameter #1 (expected table or {className}, got {className})`, 2)
		end
		if b then
			isClassType, gotType = checkType(b)
			if not isClassType then
				error(`invalid {sequenceClassName} parameter #2 (expected {className}, got {gotType})`, 2)
			end
		end

		if checkType(a) then
			keypoints = { keypoint(0, a), keypoint(1, b or a) }
		elseif type(a) == "table" then
			local lastTime = -1
			for i, thisKeypoint in ipairs(a) do
				if not checkClassType(thisKeypoint, keypointName) then
					error(`keypoint {i} must be of type '{keypointName}'`)
				end
				if thisKeypoint.time < 0 or thisKeypoint.time > 1 then error(`keypoint {i}'s time must be within 0-1`, 2) end
				if thisKeypoint.time < lastTime then error(`all {keypointName}s must be ordered by time`, 2) end
				lastTime = thisKeypoint.time
				insert(keypoints, thisKeypoint)
			end

			if lastTime < 1 or lastTime > 1 then error(`{sequenceClassName} must end at time=1.0`, 2) end
		end

		if #keypoints < 2 then error(`{sequenceClassName} requires at least 2 keypoints`, 2) end
		return setmetatable({ keypoints = keypoints }, sequenceMeta) :: any
	end

	return sequence, keypoint
end

-- these types suck
type keypointReturns<T> = { __type: string, time: number, value: T }
type sequenceKeypointConstructor<T> = (time: number, value: T) -> keypointReturns<T>
type sequenceMeta<T> = { __index: sequenceMeta<T>, evaluate: (self: sequenceReturns<T>, time: number) -> T }
type sequenceReturns<T> = typeof(setmetatable({} :: { keypoints: keypointReturns<T> }, {} :: sequenceMeta<T>))
type sequenceConstructor<T> =
	((n: T) -> sequenceReturns<T>)
	& ((n0: T, n1: T) -> sequenceReturns<T>)
	& ((keypoints: { { __type: string, time: number, value: T } }) -> sequenceReturns<T>)

local function makeSequenceConstructor<T>(_: T, classMetatable: any)
	local newSequence, newKeypoint = __makeSequenceConstructor(classMetatable)
	return newSequence :: sequenceConstructor<T>, newKeypoint :: sequenceKeypointConstructor<T>
end

do --> numberSequence
	type numberKeypointReturns = { __type: string, time: number, value: number, envelope: number? }
	type numberSequenceKeypointConstructor = (time: number, value: number, envelope: number?) -> numberKeypointReturns
	type sequenceMeta = {
		__index: sequenceMeta,
		evaluate: (self: numberSequenceReturns, time: number) -> number,
		resolve: (self: numberSequenceReturns) -> numberSequenceReturns,
	}
	type numberSequenceReturns = typeof(setmetatable({} :: { keypoints: numberKeypointReturns }, {} :: sequenceMeta))
	type numberSequenceConstructor =
		((n: number) -> numberSequenceReturns)
		& ((n0: number, n1: number) -> numberSequenceReturns)
		& ((keypoints: { numberKeypointReturns }) -> numberSequenceReturns)

	exports.numberSequence = {}
	local newSequence, newKeypoint = __makeSequenceConstructor()
	exports.numberSequence.new = newSequence :: numberSequenceConstructor
	exports.numberSequence.keypoint = newKeypoint :: numberSequenceKeypointConstructor
	lock(exports.numberSequence, "numberSequence", true)
end

do --> numberRange
	local numberRange = {}
	local rangeMeta = { __type = "numberRange" }
	rangeMeta.__index = rangeMeta
	classMetatables.numberRange = rangeMeta

	function rangeMeta:isWithin(x: number): boolean return x >= self.min and x <= self.max end
	function rangeMeta:isOutside(x: number): boolean return not self:isWithin(x) end
	function rangeMeta:randomNumber(): number return randomFloat(self.min, self.max) end
	function rangeMeta:randomInt(): number return randomInt(self.min, self.max) end

	function numberRange.new(min: number, max: number)
		if (min and max) and (min > max) then error("invalid range", 2) end
		return setmetatable({ min = min or 0, max = max or min or 0 }, rangeMeta)
	end

	--> export
	exports.numberRange = lock(numberRange, "numberRange", true)
end

do --> vec2
	local vec2 = {}

	type vec2_params = { x: number, y: number }
	type vec2_schema = {
		__type: "vec2",
		__index: vec2_schema,
		__div: (self: vec2, other: vec2 | number) -> vec2,
		__mul: (self: vec2, other: vec2 | number) -> vec2,
		__add: (self: vec2, other: vec2) -> vec2,
		__sub: (self: vec2, other: vec2) -> vec2,
		__eq: (self: vec2, other: vec2) -> boolean,
		__unm: (self: vec2) -> vec2,
		__tostring: (self: vec2) -> string,
		__call: (self: vec2) -> (number, number),

		lerp: (self: vec2, other: vec2, alpha: number) -> vec2,
		dot: (self: vec2, other: vec2) -> number,
		cross: (self: vec2, other: vec2) -> number,
		length: number,
		unit: vec2,
	}
	type vec2 = typeof(setmetatable({} :: vec2_params, {} :: vec2_schema))

	local vecMeta = { __type = "vec2" } :: vec2_schema
	local vec2new
	classMetatables.vec2 = vecMeta

	vecMeta.__index = function(self: vec2, k): any
		if k == "length" then
			local x, y = self.x, self.y
			return sqrt((x * x) + (y * y))
		end
		if k == "unit" then return self / self.length end
		return vecMeta[k]
	end :: any

	function vecMeta:__call() return self.x, self.y end
	function vecMeta:__tostring() return `vec2[{self.x}, {self.y}]` end
	function vecMeta:__div(other)
		if type(other) == "number" then
			return vec2new((self.x / other), (self.y / other))
		elseif checkClassMeta(other, vecMeta) then
			if type(self) == "number" then
				return vec2new((self / other.x), (self / other.y))
			else
				return vec2new((self.x / other.x), (self.y / other.y))
			end
		end
		error("invalid vec3.__div parameter", 2)
	end
	function vecMeta:__mul(other)
		if type(self) == "number" then
			self, other = other, self
		end -- invert values
		if type(other) == "number" then
			return vec2new((self.x * other), (self.y * other))
		elseif checkClassMeta(other, vecMeta) then
			return vec2new((self.x * other.x), (self.y * other.y))
		end
		error("invalid vec3.__mul parameter", 2)
	end
	function vecMeta:__add(other)
		if checkClassMeta(other, vecMeta) then
			if type(self) == "number" then
				return vec2new((self + other.x), (self + other.y))
			else
				return vec2new((self.x + other.x), (self.y + other.y))
			end
		end
		error("invalid vec3.__add parameter", 2)
	end
	function vecMeta:__sub(other)
		if checkClassMeta(other, vecMeta) then
			if type(self) == "number" then
				return vec2new((self - other.x), (self - other.y))
			else
				return vec2new((self.x - other.x), (self.y - other.y))
			end
		end
		error("invalid vec3.__sub parameter", 2)
	end
	function vecMeta:__unm()
		if checkClassMeta(self, vecMeta) then return vec2new(-self.x, -self.y) end
		error("invalid vec3.__unm parameter", 2)
	end
	function vecMeta:__eq(other)
		if checkClassMeta(other, vecMeta) then return (self.x == other.x) and (self.y == other.y) end
		error("invalid vec3.__eq parameter", 2)
	end
	function vecMeta:lerp(other, alpha)
		if checkClassMeta(self, vecMeta) and checkClassMeta(other, vecMeta) and type(alpha) == "number" then
			return vec2new(lerp(self.x, other.x, alpha), lerp(self.y, other.y, alpha))
		end
		error("invalid vec3.lerp parameter", 2)
	end
	function vecMeta:dot(other)
		if checkClassMeta(self, vecMeta) and checkClassMeta(other, vecMeta) then
			return (self.x * other.x) + (self.y * other.y)
		end
		error("invalid vec3.dot parameter", 2)
	end
	function vecMeta:cross(other)
		if checkClassMeta(self, vecMeta) and checkClassMeta(other, vecMeta) then
			return (self.x * other.y) - (self.y * other.x)
		end
		error("invalid vec3.cross parameter", 2)
	end

	function vec2.new(x: number?, y: number?): vec2 return setmetatable({ x = x or 0, y = y or 0 }, vecMeta) end

	vec2new = vec2.new
	vec2.zero = vec2new() -- Ol
	vec2.one = vec2new(1, 1)
	vec2.xAxis = vec2new(1, 0)
	vec2.yAxis = vec2new(0, 1)
	vec2.center = vec2new(_G.SCX, _G.SCY)
	vec2.scale = vec2new(_G.SW, _G.SH)

	--> export
	vec2.sequence, vec2.keypoint = makeSequenceConstructor(vec2.zero, vecMeta)
	exports.vec2 = lock(vec2, "vec2", true)
end

do --> vec3
	local vec3 = {}

	type vec3_params = { x: number, y: number, z: number }
	type vec3_schema = {
		__type: "vec3",
		__index: vec3_schema,
		__div: (self: vec3, other: vec3 | number) -> vec3,
		__mul: (self: vec3, other: vec3 | number) -> vec3,
		__add: (self: vec3, other: vec3) -> vec3,
		__sub: (self: vec3, other: vec3) -> vec3,
		__eq: (self: vec3, other: vec3) -> boolean,
		__unm: (self: vec3) -> vec3,
		__tostring: (self: vec3) -> string,
		__call: (self: vec3) -> (number, number, number),

		lerp: (self: vec3, other: vec3, alpha: number) -> vec3,
		dot: (self: vec3, other: vec3) -> number,
		cross: (self: vec3, other: vec3) -> vec3,
		length: number,
		unit: vec3,
	}
	type vec3 = typeof(setmetatable({} :: vec3_params, {} :: vec3_schema))

	local vecMeta = { __type = "vec3" } :: vec3_schema
	local vec3new
	classMetatables.vec3 = vecMeta
	vecMeta.__index = function(self: vec3, k): any
		if k == "length" then
			local x, y, z = self.x, self.y, self.z
			return sqrt((x * x) + (y * y) + (z * z))
		end
		if k == "unit" then return self / self.length end
		return vecMeta[k]
	end :: any

	function vecMeta:__call() return self.x, self.y, self.z end
	function vecMeta:__tostring() return `vec3[{self.x}, {self.y}, {self.z}]` end
	function vecMeta:__div(other)
		if type(other) == "number" then
			return vec3new(self.x / other, self.y / other, self.z / other)
		elseif checkClassMeta(other, vecMeta) then
			if type(self) == "number" then
				return vec3new(self / other.x, self / other.y, self / other.z)
			else
				return vec3new(self.x / other.x, self.y / other.y, self.z / other.z)
			end
		end
		error("invalid vec3.__div parameter", 2)
	end
	function vecMeta:__mul(other)
		if type(self) == "number" then
			self, other = other, self
		end -- invert values
		if type(other) == "number" then
			return vec3new(self.x * other, self.y * other, self.z * other)
		elseif checkClassMeta(other, vecMeta) then
			return vec3new(self.x * other.x, self.y * other.y, self.z * other.z)
		end
		error("invalid vec3.__mul parameter", 2)
	end
	function vecMeta:__add(other)
		if checkClassMeta(other, vecMeta) then
			if type(self) == "number" then
				return vec3new(self + other.x, self + other.y, self + other.z)
			else
				return vec3new(self.x + other.x, self.y + other.y, self.z + other.z)
			end
		end
		error("invalid vec3.__add parameter", 2)
	end
	function vecMeta:__sub(other)
		if checkClassMeta(other, vecMeta) then
			if type(self) == "number" then
				return vec3new(self - other.x, self - other.y, self - other.z)
			else
				return vec3new(self.x - other.x, self.y - other.y, self.z - other.z)
			end
		end
		error("invalid vec3.__sub parameter", 2)
	end
	function vecMeta:__unm()
		if checkClassMeta(self, vecMeta) then return vec3new(-self.x, -self.y, -self.z) end
		error("invalid vec3.__unm parameter", 2)
	end
	function vecMeta:__eq(other)
		if checkClassMeta(other, vecMeta) then
			return (self.x == other.x) and (self.y == other.y) and (self.z == other.z)
		end
		error("invalid vec3.__eq parameter", 2)
	end
	function vecMeta:lerp(other, alpha)
		if checkClassMeta(self, vecMeta) and checkClassMeta(other, vecMeta) and type(alpha) == "number" then
			return vec3new(lerp(self.x, other.x, alpha), lerp(self.y, other.y, alpha), lerp(self.z, other.z, alpha))
		end
		error("invalid vec3.lerp parameter", 2)
	end
	function vecMeta:dot(other)
		if checkClassMeta(self, vecMeta) and checkClassMeta(other, vecMeta) then
			return (self.x * other.x) + (self.y * other.y) + (self.z * other.z)
		end
		error("invalid vec3.dot parameter", 2)
	end
	function vecMeta:cross(other)
		if checkClassMeta(self, vecMeta) and checkClassMeta(other, vecMeta) then
			return vec3new(
				self.y * other.z - self.z * other.y,
				self.z * other.x - self.x * other.z,
				self.x * other.y - self.y * other.x
			)
		end
		error("invalid vec3.cross parameter", 2)
	end

	function vec3.new(x: number?, y: number?, z: number?): vec3
		return setmetatable({ x = x or 0, y = y or 0, z = z or 0 }, vecMeta)
	end

	vec3new = vec3.new
	vec3.zero = vec3new() -- Ol
	vec3.one = vec3new(1, 1, 1)
	vec3.xAxis = vec3new(1, 0, 0)
	vec3.yAxis = vec3new(0, 1, 0)
	vec3.zAxis = vec3new(0, 0, 1)
	vec3.center = vec3new(_G.SCX, _G.SCY, 0)
	vec3.scale = vec3new(_G.SW, _G.SH, 0)

	--> export
	vec3.sequence, vec3.keypoint = makeSequenceConstructor(vec3.zero, vecMeta)
	exports.vec3 = lock(vec3, "vec3", true)
end

do --> vec4
	local vec4 = {}

	type vec4_params = { x: number, y: number, w: number, h: number }
	type vec4_schema = {
		__type: "vec4",
		__index: vec4_schema,
		__div: (self: vec4, other: vec4 | number) -> vec4,
		__mul: (self: vec4, other: vec4 | number) -> vec4,
		__add: (self: vec4, other: vec4) -> vec4,
		__sub: (self: vec4, other: vec4) -> vec4,
		__eq: (self: vec4, other: vec4) -> boolean,
		__unm: (self: vec4) -> vec4,
		__tostring: (self: vec4) -> string,
		__call: (self: vec4) -> (number, number, number),

		lerp: (self: vec4, other: vec4, alpha: number) -> vec4,
		dot: (self: vec4, other: vec4) -> number,
		length: number,
		unit: vec4,
	}
	type vec4 = typeof(setmetatable({} :: vec4_params, {} :: vec4_schema))

	local vecMeta = { __type = "vec4" } :: vec4_schema
	local vec4new
	classMetatables.vec4 = vecMeta
	vecMeta.__index = function(self: any, k): any
		if k == "length" then
			local x, y, w, h = self.x, self.y, self.w, self.h
			return sqrt((x * x) + (y * y) + (w * w) + (h * h))
		end
		if k == "unit" then return self / self.length end
		return vecMeta[k]
	end :: any

	function vecMeta:__call() return self.x, self.y, self.w, self.h end
	function vecMeta:__tostring() return `vec4[{self.x}, {self.y}, {self.w}, {self.h}]` end
	function vecMeta:__div(other)
		if type(other) == "number" then
			return vec4new(self.x / other, self.y / other, self.w / other, self.h / other)
		elseif checkClassMeta(other, vecMeta) then
			if type(self) == "number" then
				return vec4new(self / other.x, self / other.y, self / other.w, self / other.h)
			else
				return vec4new(self.x / other.x, self.y / other.y, self.w / other.w, self.h / other.h)
			end
		end
		error("invalid vec4.__div parameter", 2)
	end
	function vecMeta:__mul(other)
		if type(self) == "number" then
			self, other = other, self
		end -- invert values
		if type(other) == "number" then
			return vec4new(self.x * other, self.y * other, self.w * other, self.h * other)
		elseif checkClassMeta(other, vecMeta) then
			return vec4new(self.x * other.x, self.y * other.y, self.w * other.w, self.h * other.h)
		end
		error("invalid vec4.__mul parameter", 2)
	end
	function vecMeta:__add(other)
		if checkClassMeta(other, vecMeta) then
			if type(self) == "number" then
				return vec4new(self + other.x, self + other.y, self + other.w, self + other.h)
			else
				return vec4new(self.x + other.x, self.y + other.y, self.w + other.w, self.h + other.h)
			end
		end
		error("invalid vec4.__add parameter", 2)
	end
	function vecMeta:__sub(other)
		if checkClassMeta(other, vecMeta) then
			if type(self) == "number" then
				return vec4new(self - other.x, self - other.y, self - other.w, self - other.h)
			else
				return vec4new(self.x - other.x, self.y - other.y, self.w - other.w, self.h - other.h)
			end
		end
		error("invalid vec4.__sub parameter", 2)
	end
	function vecMeta:__unm()
		if checkClassMeta(self, vecMeta) then return vec4new(-self.x, -self.y, -self.w, -self.h) end
		error("invalid vec4.__unm parameter", 2)
	end
	function vecMeta:__eq(other)
		if checkClassMeta(other, vecMeta) then
			return (self.x == other.x) and (self.y == other.y) and (self.w == other.w) and (self.h == other.h)
		end
		error("invalid vec4.__eq parameter", 2)
	end
	function vecMeta:lerp(other, alpha)
		if checkClassMeta(self, vecMeta) and checkClassMeta(other, vecMeta) and type(alpha) == "number" then
			return vec4new(
				lerp(self.x, other.x, alpha),
				lerp(self.y, other.y, alpha),
				lerp(self.w, other.w, alpha),
				lerp(self.h, other.h, alpha)
			)
		end
		error("invalid vec4.lerp parameter", 2)
	end
	function vecMeta:dot(other)
		if checkClassMeta(self, vecMeta) and checkClassMeta(other, vecMeta) then
			return (self.x * other.x) + (self.y * other.y) + (self.w * other.w) + (self.h * other.h)
		end
		error("invalid vec4.dot parameter", 2)
	end
	function vec4.new(x: number?, y: number?, w: number?, h: number?): vec4
		return setmetatable({ x = x or 0, y = y or 0, w = w or 0, h = h or 0 }, vecMeta)
	end

	vec4new = vec4.new
	vec4.zero = vec4new() -- Ol
	vec4.one = vec4new(1, 1, 1, 1)
	vec4.xAxis = vec4new(1, 0, 0, 0)
	vec4.yAxis = vec4new(0, 1, 0, 0)
	vec4.wAxis = vec4new(0, 0, 1, 0)
	vec4.hAxis = vec4new(0, 0, 0, 1)
	vec4.center = vec4new(_G.SCX, _G.SCY, 0, 0)
	vec4.scale = vec4new(0, 0, _G.SW, _G.SH)
	vec4.full = vec4new(_G.SCX, _G.SCY, _G.SW, _G.SH)

	--> export
	vec4.sequence, vec4.keypoint = makeSequenceConstructor(vec4.zero, vecMeta)
	exports.vec4 = lock(vec4, "vec4", true)
end

do --> color
	local color = {}

	type color_params = { r: number, g: number, b: number, a: number }
	type color_schema = {
		__type: "color",
		__index: color_schema,
		__eq: (self: color, other: color) -> boolean,
		__tostring: (self: color) -> string,
		__call: (self: color) -> (number, number, number, number), -- if you call the color this will allow you to use it in actor:diffuse!!
		__unm: (self: color) -> color,

		lerp: (self: color, other: color, alpha: number) -> color,
		toHex: (self: color) -> string,
		toHSV: (self: color) -> (number, number, number),
		invert: (self: color) -> color,
		invertColor: (self: color) -> color,
	}
	type color = typeof(setmetatable({} :: color_params, {} :: color_schema))

	local colorMeta = { __type = "color" } :: color_schema
	local colornew
	colorMeta.__index = colorMeta
	classMetatables.color = colorMeta

	function colorMeta:__tostring() return `color[{self.r}, {self.g}, {self.b} ({round(self.a * 100)}%)]` end
	function colorMeta:__call() return self.r, self.g, self.b, self.a end
	function colorMeta:toHSV() return rgbToHsv(self.r, self.g, self.b) end
	function colorMeta:toHex() -- will probably never be used
		return string.format("#%02x%02x%02x", round(self.r), round(self.g), round(self.b))
	end
	function colorMeta:invert() return colornew(1 - self.r, 1 - self.g, 1 - self.b, 1 - self.a) end
	function colorMeta:__unm() return self:invert() end -- i'm not sure if i should use invert or invertColor
	function colorMeta:invertColor() return colornew(1 - self.r, 1 - self.g, 1 - self.b, self.a) end
	function colorMeta:lerp(other, alpha)
		return colornew(
			lerp(self.r, other.r, alpha),
			lerp(self.g, other.g, alpha),
			lerp(self.b, other.b, alpha),
			lerp(self.a, other.a, alpha)
		)
	end

	function color.new(r: number?, g: number?, b: number?, a: number?): color
		return setmetatable({ r = r or 0, g = g or 0, b = b or 0, a = a or 1 }, colorMeta)
	end
	colornew = color.new
	function color.rgba(r: number?, g: number?, b: number?, a: number?): color
		return setmetatable({ r = (r or 0) / 255, g = (g or 0) / 255, b = (b or 0) / 255, a = (a or 255) / 255 }, colorMeta)
	end

	function color.hexa(hex: string, a: number?): color
		if sub(hex, 1, 1) == "#" then hex = sub(hex, 2) end
		local r, g, b = gmatch(hex, "(..)(..)(..)")()
		return color.rgba(tonumber(r, 16), tonumber(g, 16), tonumber(b, 16), a)
	end

	function color.hsva(hue: number?, saturation: number?, value: number?, a: number?): color
		local r, g, b = hsvToRgb(hue or 0, saturation or 0, value or 0)
		return colornew(r, g, b, a)
	end

	color.transparent, color.white, color.black, color.red, color.green, color.blue, color.yellow, color.magenta, color.cyan =
		colornew(1, 1, 1, 0),
		colornew(1, 1, 1),
		colornew(0, 0, 0),
		colornew(1, 0, 0),
		colornew(0, 1, 0),
		colornew(0, 0, 1),
		colornew(1, 1, 0),
		colornew(1, 0, 1),
		colornew(0, 1, 1)

	--> export
	color.sequence, color.keypoint = makeSequenceConstructor(color.white, colorMeta)
	exports.color = lock(color, "color", true)
end

do --> coord
	-- stylua: ignore start
	local coord = {}
	local coordnew

	type vec3 = typeof(exports.vec3.new())
	type coord_params = { components: { number } }
	type coord_schema = {
		__type: "coord",
		__index: coord_schema,
		__eq: (self: coord, other: coord) -> boolean,
		__add: (self: coord, other: vec3) -> coord,
		__sub: (self: coord, other: vec3) -> coord,
		__mul: ((self: coord, other: coord) -> coord) & ((self: coord, other: vec3) -> vec3),
		__tostring: (self: coord) -> string,

		x: number,
		y: number,
		z: number,
		position: vec3,
		xVector: vec3,
		yVector: vec3,
		zVector: vec3,
		getComponents: (self: coord) -> (number, number, number, number, number, number, number, number, number, number, number, number),
		getXYZ: (self: coord) -> (number, number, number),
		inverse: (self: coord) -> coord,
		toWorldSpace: (self: coord, other: coord) -> coord,
		toObjectSpace: (self: coord, other: coord) -> coord,
		pointToWorldSpace: (self: coord, other: vec3) -> vec3,
		pointToObjectSpace: (self: coord, other: vec3) -> vec3,
		vectorToWorldSpace: (self: coord, other: vec3) -> vec3,
		vectorToObjectSpace: (self: coord, other: vec3) -> vec3,
		toEulerAnglesXYZ: (self: coord) -> (number, number, number),
		toEulerAnglesYXZ: (self: coord) -> (number, number, number),
		toOrientationDegrees: (self: coord) -> (number, number, number),
		toAxisAngle: (self: coord) -> (vec3, number),
		lerp: (self: coord, other: coord, alpha: number) -> coord,
	}
	type coord = typeof(setmetatable({} :: coord_params, {} :: coord_schema))

	local function getTypeCount(tabl, _type)
		local x = 0
		for _, v in ipairs(tabl) do
			local thisType = type(v)
			if thisType == "table" then
				x += (v.__type == _type and 1 or 0)
			else
				x += (thisType == _type and 1 or 0)
			end
		end

		return x
	end

	local function coordToQuaternion(thisCoord: coord) -- dis cord
		local _, _, _, m11, m12, m13, m21, m22, m23, m31, m32, m33 = thisCoord:getComponents()
		local qw, qx, qy, qz

		if m11 + m22 + m33 > 0 then
			qw = sqrt(1 + m11 + m22 + m33) * 0.5
			qx = (m32 - m23) / (4 * qw)
			qy = (m13 - m31) / (4 * qw)
			qz = (m21 - m12) / (4 * qw)
		elseif m11 > m22 and m11 > m33 then
			qx = sqrt(1 + m11 - m22 - m33) * 0.5
			qy = (m21 + m12) / (4 * qx)
			qz = (m31 + m13) / (4 * qx)
			qw = (m32 - m23) / (4 * qx)
		elseif m22 > m33 then
			qy = sqrt(1 + m22 - m11 - m33) * 0.5
			qx = (m21 + m12) / (4 * qy)
			qz = (m32 + m23) / (4 * qy)
			qw = (m13 - m31) / (4 * qy)
		else
			qz = sqrt(1 + m33 - m11 - m22) * 0.5
			qx = (m31 + m13) / (4 * qz)
			qy = (m32 + m23) / (4 * qz)
			qw = (m21 - m12) / (4 * qz)
		end

		return qw, qx, qy, qz
	end

	--> metamethods
	local vec3Meta = classMetatables.vec3
	local vec3new = exports.vec3.new
	local vec3yAxis = exports.vec3.yAxis
	local coordMeta = { __type = "coord" } :: coord_schema

	--> metamethods
	coordMeta.__index = function(self: coord, key): any
		local components = self.components
		if key == "x" then
			return components[1]
		elseif key == "y" then
			return components[2]
		elseif key == "z" then
			return components[3]
		elseif key == "position" then
			return vec3new(components[1], components[2], components[3])
		elseif key == "zVector" then
			return vec3new(components[6], components[9], components[12])
		elseif key == "xVector" then
			return vec3new(components[4], components[7], components[10])
		elseif key == "yVector" then
			return vec3new(components[5], components[8], components[11])
		end

		return coordMeta[key]
	end :: any

	function coordMeta:__tostring()
		return format("coord[%.3f, %.3f, %.3f, %.3f, %.3f, %.3f, %.3f, %.3f, %.3f, %.3f, %.3f, %.3f]", self:getComponents())
	end
	function coordMeta:__eq(other)
		if checkClassMeta(other, coordMeta) then
			local componentsSelf, componentsOther = self.components, other.components
			for i = 1, 12 do
				if componentsSelf[i] ~= componentsOther[i] then return false end
			end
			return true
		end

		error("invalid coord.__eq parameter", 2)
	end
	function coordMeta:__add(other)
		if checkClassMeta(other, vec3Meta) then
			local x, y, z, m11, m12, m13, m21, m22, m23, m31, m32, m33 = self:getComponents()
			return coordnew((x + other.x), (y + other.y), (z + other.z), m11, m12, m13, m21, m22, m23, m31, m32, m33)
		end

		error("invalid coord.__add parameter", 2)
	end
	function coordMeta:__sub(other)
		if checkClassMeta(other, vec3Meta) then
			local x, y, z, m11, m12, m13, m21, m22, m23, m31, m32, m33 = self:getComponents()
			return coordnew((x - other.x), (y - other.y), (z - other.z), m11, m12, m13, m21, m22, m23, m31, m32, m33)
		end

		error("invalid coord.__sub parameter", 2)
	end
	coordMeta.__mul = function(self: coord, other)
        if checkClassMeta(other, coordMeta) then -- coord * coord
            local compA, compB = self.components, other.components
            local a1, a2, a3 =
                vec3new(compA[4], compA[5], compA[6]),
                vec3new(compA[7], compA[8], compA[9]),
                vec3new(compA[10], compA[11], compA[12])
            local b1, b2, b3, bp =
                vec3new(compB[4], compB[7], compB[10]),
                vec3new(compB[5], compB[8], compB[11]),
                vec3new(compB[6], compB[9], compB[12]),
                vec3new(compB[1], compB[2], compB[3])
            return coordnew(
                a1:dot(bp) + compA[1], a2:dot(bp) + compA[2], a3:dot(bp) + compA[3],
                a1:dot(b1), a1:dot(b2), a1:dot(b3),
                a2:dot(b1), a2:dot(b2), a2:dot(b3),
                a3:dot(b1), a3:dot(b2), a3:dot(b3)
            )
        elseif checkClassMeta(other, vec3Meta) then -- coord * vec3
            local components = self.components
            return vec3new(
                vec3new(components[4], components[5], components[6]):dot(other) + components[1],
                vec3new(components[7], components[8], components[9]):dot(other) + components[2],
                vec3new(components[10], components[11], components[12]):dot(other) + components[3]
            ) :: any
        end

		error("invalid coord.__mul parameter", 2)
	end :: any -- i can't get this to cast correctly

	--> class methods
	function coordMeta:getComponents() return unpack(self.components) end
	function coordMeta:getXYZ()
		local components = self.components
		return components[1], components[2], components[3]
	end

	function coordMeta:inverse()
		local comp = self.components
		return coordnew(
			-(comp[4] * comp[1] + comp[7] * comp[2] + comp[10] * comp[3]),
			-(comp[5] * comp[1] + comp[8] * comp[2] + comp[11] * comp[3]),
			-(comp[6] * comp[1] + comp[9] * comp[2] + comp[12] * comp[3]),
			comp[4], comp[7], comp[10],
			comp[5], comp[8], comp[11],
			comp[6], comp[9], comp[12]
		)
	end
	function coordMeta:toWorldSpace(other) return self * other end
	function coordMeta:toObjectSpace(other) return self:inverse() * other end
	function coordMeta:pointToWorldSpace(other) return self * other end
	function coordMeta:pointToObjectSpace(other) return self:inverse() * other end
	function coordMeta:vectorToWorldSpace(other) return (self - self.position) * other end
	function coordMeta:vectorToObjectSpace(other) return (self - self.position):inverse() * other end
	function coordMeta:toEulerAnglesXYZ()
		local comp = self.components
		return atan2(-comp[9], comp[12]), asin(comp[6]), atan2(-comp[5], comp[4])
	end

	function coordMeta:toEulerAnglesYXZ() -- AKA toOrientation
		local comp = self.components
		return asin(-comp[9]), atan2(comp[6], comp[12]), atan2(comp[7], comp[8])
	end

	function coordMeta:toOrientationDegrees()
		local rx, ry, rz = self:toEulerAnglesYXZ()
		return deg(rx), deg(ry), deg(rz)
	end

	function coordMeta:toAxisAngle()
		local qw, qx, qy, qz = coordToQuaternion(self)
		if qw <= 0 then -- pick the twin closest to identity quaternion
			qw, qx, qy, qz = -qw, -qx, -qy, -qz
		end

		local theta = acos(qw) * 2
		local axis = vec3new(qx, qy, qz) / sin(theta * 0.5)
		if axis:dot(axis) > 0 then
			return axis.unit, theta
		else
			return vec3new(1), theta
		end
	end

	function coordMeta:lerp(other, alpha)
		local product = (1 - alpha) * self.position + alpha * other.position
		local diff = self:inverse() * other
		local axis, theta = diff:toAxisAngle()
		local comp = (self * coord.axisAngle(axis, theta * alpha)).components
		return coordnew(
			product.x, product.y, product.z,
			comp[4], comp[5], comp[6], comp[7], comp[8], comp[9], comp[10], comp[11], comp[12]
		)
	end

	--> constructors
	coord.new = (
		function(...: any)
			local components = { ... }
			if #components < 0 or #components > 12 then
				error("invalid .new parameter count", 2)
			elseif #components == 0 then
				components = { 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1 }
			elseif #components == 1 and checkClassMeta(components[1], vec3Meta) then
				-- single vector position case
				components = { components[1].x, components[1].y, components[1].z, 1, 0, 0, 0, 1, 0, 0, 0, 1 }
			elseif #components == 2 and getTypeCount(components, "vec3") == 2 then
				-- lookAt case
				local eye, target = components[1], components[2]
				local dir = target - eye
				local right = dir:cross(vec3yAxis)

				if right:dot(right) > 0 then
					local u = right:cross(dir).unit
					local b, r = -dir.unit, right.unit
					components = { eye.x, eye.y, eye.z, r.x, u.x, b.x, r.y, u.y, b.y, r.z, u.z, b.z }
				elseif vec3yAxis:dot(dir) > 0 then
					components = { eye.x, eye.y, eye.z, 0, 1, 0, 0, 0, -1, -1, 0, 0 }
				else
					components = { eye.x, eye.y, eye.z, 0, 1, 0, 0, 0, 1, 1, 0, 0 }
				end
			elseif #components == 3 and getTypeCount(components, "number") == 3 then
				-- x, y, and z case
				components = { components[1], components[2], components[3], 1, 0, 0, 0, 1, 0, 0, 0, 1 }
			elseif #components == 7 and getTypeCount(components, "number") == 7 then
				-- quaternion case
				local px, py, pz, x, y, z, w = unpack(components)
				local m = 1 / sqrt(x * x + y * y + z * z + w * w)
				x, y, z, w = x * m, y * m, z * m, w * m
				components = {
					px, py, pz,
					1 - 2 * (y * y + z * z), 2 * (y * x - w * z), 2 * (w * y + z * x),
					2 * (w * z + y * x), 1 - 2 * (x * x + z * z), 2 * (z * y - w * x),
					2 * (z * x - w * y), 2 * (w * x + z * y), 1 - 2 * (x * x + y * y),
				}

			-- selene: allow(empty_if)
			elseif #components == 12 and getTypeCount(components, "number") == 12 then
			-- component case (do nothing)
			else
				error("invalid coord.new parameter", 2)
			end

			return setmetatable({ components = components }, coordMeta)
		end :: any
	) :: (() -> coord) & 
		((pos: vec3) -> coord) & 
		((pos: vec3, lookAt: vec3) -> coord) & 
		((x: number, y: number, z: number) -> coord) & 
		((x: number, y: number, z: number, qX: number, qY: number, qZ: number, qW: number) -> coord) & 
		((x: number, y: number, z: number, R00: number, R01: number, R02: number, R10: number, R11: number, R12: number, R20: number, R21: number, R22: number) -> coord)

	coordnew = coord.new
	coord.identity = coord.new()

	function coord.axisAngle(v, r)
		local unit = v.unit
		local kx, ky, kz = unit.x, unit.y, unit.z
		local c, s = cos(r), sin(r)
		return coordnew(
			0, 0, 0,
			c + (1 - c) * kx * kx, -s * kz + (1 - c) * kx * ky, s * ky + (1 - c) * kx * kz,
			s * kz + (1 - c) * ky * kx, c + (1 - c) * ky * ky, -s * kx + (1 - c) * ky * kz,
			-s * ky + (1 - c) * kz * kx, s * kx + (1 - c) * kz * ky, c + (1 - c) * kz * kz
		)
	end

	function coord.eulerAnglesXYZ(rx, ry, rz)
		local cx, sx = cos(rx), sin(rx)
		local cy, sy = cos(ry), sin(ry)
		local cz, sz = cos(rz), sin(rz)
		return coordnew(
			0, 0, 0,
			cy * cz, -cy * sz, sy,
			sx * sy * cz + cx * sz, -sx * sy * sz + cx * cz, -sx * cy,
			-cx * sy * cz + sx * sz, cx * sy * sz + sx * cz, cx * cy
		)
	end
	coord.angles = coord.eulerAnglesXYZ

	function coord.eulerAnglesYXZ(rx, ry, rz)
		local cx, sx = cos(rx), sin(rx)
		local cy, sy = cos(ry), sin(ry)
		local cz, sz = cos(rz), sin(rz)
		return coordnew(
			0, 0, 0,
			cy * cz + sy * sx * sz, -cy * sz + sy * sx * cz, sy * cx,
			cx * sz, cx * cz, -sx,
			-sy * cz + cy * sx * sz, sy * sz + cy * sx * cz, cy * cx
		)
	end
	coord.orientation = coord.eulerAnglesYXZ

	function coord.matrix(pos, vecX, vecY, vecZ)
		if not vecZ then vecZ = vecX:cross(vecY).unit end
		return coordnew(pos.x, pos.y, pos.z, vecX.x, vecY.x, vecZ.x, vecX.y, vecY.y, vecZ.y, vecX.z, vecY.z, vecZ.z)
	end

	--> export
	coord.sequence, coord.keypoint = makeSequenceConstructor(coord.identity, coordMeta)
	exports.coord = lock(coord, "coord", true)
	-- stylua: ignore end
end

return exports
