--!strict

local Easings = {}

-- Convenience shortcuts
local sqrt = math.sqrt
local sin = math.sin
local asin = math.asin
local cos = math.cos
local pow = math.pow
local exp = math.exp
local abs = math.abs
local pi = math.pi

-- ===================================================================== --

-- Utility functions

--- Flip any easing function, making it go from 1 to 0
-- Example use:
-- ```lua
-- ease {0, 20, flip(outQuad), 50, 'modname'}
-- ```
Easings.flip = setmetatable({}, {
	__call = function(self, fn)
		self[fn] = self[fn] or function(x: number) return 1 - fn(x) end
		return self[fn]
	end,
})

-- Mix two easing functions together into a new ease
-- the new ease starts by acting like the first argument, and then ends like the second argument
-- Example: ease {0, 20, blendEase(inQuad, outQuad), 100, 'modname'}
Easings.blendEase = setmetatable({}, {
	__index = function(self, key)
		self[key] = {}
		return self[key]
	end,
	__call = function(self, fn1, fn2)
		if not self[fn1][fn2] then
			local transient1 = fn1(1) <= 0.5
			local transient2 = fn2(1) <= 0.5
			if transient1 and not transient2 then
				error("blendEase: the first argument is a transient ease, but the second argument doesn't match")
			end
			if transient2 and not transient1 then
				error("blendEase: the second argument is a transient ease, but the first argument doesn't match")
			end
			self[fn1][fn2] = function(x: number)
				local mixFactor = 3 * x ^ 2 - 2 * x ^ 3
				return (1 - mixFactor) * fn1(x) + mixFactor * fn2(x)
			end
		end
		return self[fn1][fn2]
	end,
})

do -- Declare an easing function taking one custom parameter
	type fn = (number, number) -> number
	type mt = typeof(setmetatable({} :: { fn: fn, dp1: number, cache: {} }, {}))

	local function param1cache(self: mt, param1: number)
		self.cache[param1] = self.cache[param1] or function(x) return self.fn(x, param1) end
		return self.cache[param1]
	end

	local param1mt = {
		__call = function(self: mt, x: number, param1: number) return self.fn(x, param1 or self.dp1) end,
		__index = {
			param = param1cache,
			params = param1cache,
		},
	}

	function Easings._with1param(fn: fn, defaultparam1: number)
		return setmetatable({
			fn = fn,
			dp1 = defaultparam1,
			cache = {},
		}, param1mt)
	end
end

do -- Declare an easing function taking two custom parameters
	type fn = (number, number, number) -> number
	type mt = typeof(setmetatable({} :: { fn: fn, dp1: number, dp2: number, cache: {} }, {}))

	local function param2cache(self: mt, param1: number, param2: number)
		self.cache[param1] = self.cache[param1] or {}
		self.cache[param1][param2] = self.cache[param1][param2] or function(x) return self.fn(x, param1, param2) end
		return self.cache[param1][param2]
	end

	local param2mt = {
		__call = function(self: mt, x, param1: number, param2: number)
			return self.fn(x, param1 or self.dp1, param2 or self.dp2)
		end,
		__index = {
			param = param2cache,
			params = param2cache,
		},
	}

	function Easings._with2params(fn: fn, defaultparam1: number, defaultparam2: number)
		return setmetatable({
			fn = fn,
			dp1 = defaultparam1,
			dp2 = defaultparam2,
			cache = {},
		}, param2mt)
	end
end

-- ===================================================================== --

-- Easing functions

function Easings.bounce(t: number) return 4 * t * (1 - t) end
function Easings.tri(t: number) return 1 - abs(2 * t - 1) end
function Easings.bell(t: number) return Easings.inOutQuint(Easings.tri(t)) end
function Easings.pop(t: number) return 3.5 * (1 - t) * (1 - t) * sqrt(t) end
function Easings.tap(t: number) return 3.5 * t * t * sqrt(1 - t) end
function Easings.pulse(t: number) return t < 0.5 and Easings.tap(t * 2) or -Easings.pop(t * 2 - 1) end
function Easings.spike(t: number) return exp(-10 * abs(2 * t - 1)) end
function Easings.inverse(t: number) return t * t * (1 - t) * (1 - t) / (0.5 - t) end
function Easings.instant(_: number) return 1 end
function Easings.linear(t: number) return t end
function Easings.inQuad(t: number) return t * t end
function Easings.outQuad(t: number) return -t * (t - 2) end
function Easings.inOutQuad(t: number)
	t *= 2
	if t < 1 then
		return 0.5 * t ^ 2
	else
		return 1 - 0.5 * (2 - t) ^ 2
	end
end
function Easings.outInQuad(t: number)
	t *= 2
	if t < 1 then
		return 0.5 - 0.5 * (1 - t) ^ 2
	else
		return 0.5 + 0.5 * (t - 1) ^ 2
	end
end
function Easings.inCubic(t: number) return t * t * t end
function Easings.outCubic(t: number) return 1 - (1 - t) ^ 3 end
function Easings.inOutCubic(t: number)
	t *= 2
	if t < 1 then
		return 0.5 * t ^ 3
	else
		return 1 - 0.5 * (2 - t) ^ 3
	end
end
function Easings.outInCubic(t: number)
	t *= 2
	if t < 1 then
		return 0.5 - 0.5 * (1 - t) ^ 3
	else
		return 0.5 + 0.5 * (t - 1) ^ 3
	end
end
function Easings.inQuart(t: number) return t * t * t * t end
function Easings.outQuart(t: number) return 1 - (1 - t) ^ 4 end
function Easings.inOutQuart(t: number)
	t *= 2
	if t < 1 then
		return 0.5 * t ^ 4
	else
		return 1 - 0.5 * (2 - t) ^ 4
	end
end
function Easings.outInQuart(t: number)
	t *= 2
	if t < 1 then
		return 0.5 - 0.5 * (1 - t) ^ 4
	else
		return 0.5 + 0.5 * (t - 1) ^ 4
	end
end
function Easings.inQuint(t: number) return t ^ 5 end
function Easings.outQuint(t: number) return 1 - (1 - t) ^ 5 end
function Easings.inOutQuint(t: number)
	t *= 2
	if t < 1 then
		return 0.5 * t ^ 5
	else
		return 1 - 0.5 * (2 - t) ^ 5
	end
end
function Easings.outInQuint(t: number)
	t *= 2
	if t < 1 then
		return 0.5 - 0.5 * (1 - t) ^ 5
	else
		return 0.5 + 0.5 * (t - 1) ^ 5
	end
end
function Easings.inExpo(t: number) return 1000 ^ (t - 1) - 0.001 end
function Easings.outExpo(t: number) return 1.001 - 1000 ^ -t end
function Easings.inOutExpo(t: number)
	t *= 2
	if t < 1 then
		return 0.5 * 1000 ^ (t - 1) - 0.0005
	else
		return 1.0005 - 0.5 * 1000 ^ (1 - t)
	end
end
function Easings.outInExpo(t: number)
	if t < 0.5 then
		return Easings.outExpo(t * 2) * 0.5
	else
		return Easings.inExpo(t * 2 - 1) * 0.5 + 0.5
	end
end
function Easings.inCirc(t: number) return 1 - sqrt(1 - t * t) end
function Easings.outCirc(t: number) return sqrt(-t * t + 2 * t) end
function Easings.inOutCirc(t: number)
	t *= 2
	if t < 1 then
		return 0.5 - 0.5 * sqrt(1 - t * t)
	else
		t -= 2
		return 0.5 + 0.5 * sqrt(1 - t * t)
	end
end
function Easings.outInCirc(t: number)
	if t < 0.5 then
		return Easings.outCirc(t * 2) * 0.5
	else
		return Easings.inCirc(t * 2 - 1) * 0.5 + 0.5
	end
end
function Easings.outBounce(t: number)
	if t < 1 / 2.75 then
		return 7.5625 * t * t
	elseif t < 2 / 2.75 then
		t -= 1.5 / 2.75
		return 7.5625 * t * t + 0.75
	elseif t < 2.5 / 2.75 then
		t -= 2.25 / 2.75
		return 7.5625 * t * t + 0.9375
	else
		t -= 2.625 / 2.75
		return 7.5625 * t * t + 0.984375
	end
end
function Easings.inBounce(t: number) return 1 - Easings.outBounce(1 - t) end
function Easings.inOutBounce(t: number)
	if t < 0.5 then
		return Easings.inBounce(t * 2) * 0.5
	else
		return Easings.outBounce(t * 2 - 1) * 0.5 + 0.5
	end
end
function Easings.outInBounce(t: number)
	if t < 0.5 then
		return Easings.outBounce(t * 2) * 0.5
	else
		return Easings.inBounce(t * 2 - 1) * 0.5 + 0.5
	end
end
function Easings.inSine(x: number) return 1 - cos(x * (pi * 0.5)) end
function Easings.outSine(x: number) return sin(x * (pi * 0.5)) end
function Easings.inOutSine(x: number) return 0.5 - 0.5 * cos(x * pi) end
function Easings.outInSine(t: number)
	if t < 0.5 then
		return Easings.outSine(t * 2) * 0.5
	else
		return Easings.inSine(t * 2 - 1) * 0.5 + 0.5
	end
end

--> Internal Functions
local function popElasticInternal(t: number, damp: number, count: number)
	return (1000 ^ -(t ^ damp) - 0.001) * sin(count * pi * t)
end
local function tapElasticInternal(t: number, damp: number, count: number)
	return (1000 ^ -((1 - t) ^ damp) - 0.001) * sin(count * pi * (1 - t))
end
local function pulseElasticInternal(t: number, damp: number, count: number)
	if t < 0.5 then
		return tapElasticInternal(t * 2, damp, count)
	else
		return -popElasticInternal(t * 2 - 1, damp, count)
	end
end

local function outElasticInternal(t: number, a: number, p: number)
	return a * pow(2, -10 * t) * sin((t - p / (2 * pi) * asin(1 / a)) * 2 * pi / p) + 1
end
local function inElasticInternal(t: number, a: number, p: number) return 1 - outElasticInternal(1 - t, a, p) end
local function inOutElasticInternal(t: number, a: number, p: number)
	return t < 0.5 and 0.5 * inElasticInternal(t * 2, a, p) or 0.5 + 0.5 * outElasticInternal(t * 2 - 1, a, p)
end
local function outInElasticInternal(t: number, a: number, p: number)
	return t < 0.5 and 0.5 * outElasticInternal(t * 2, a, p) or 0.5 + 0.5 * inElasticInternal(t * 2 - 1, a, p)
end

local function inBackInternal(t: number, a: number) return t * t * (a * t + t - a) end
local function outBackInternal(t: number, a: number)
	t -= 1
	return t * t * ((a + 1) * t + a) + 1
end
local function inOutBackInternal(t: number, a: number)
	return t < 0.5 and 0.5 * inBackInternal(t * 2, a) or 0.5 + 0.5 * outBackInternal(t * 2 - 1, a)
end
local function outInBackInternal(t: number, a: number)
	return t < 0.5 and 0.5 * outBackInternal(t * 2, a) or 0.5 + 0.5 * inBackInternal(t * 2 - 1, a)
end

Easings.popElastic = Easings._with2params(popElasticInternal, 1.4, 6)
Easings.tapElastic = Easings._with2params(tapElasticInternal, 1.4, 6)
Easings.pulseElastic = Easings._with2params(pulseElasticInternal, 1.4, 6)
Easings.inElastic = Easings._with2params(inElasticInternal, 1, 0.3)
Easings.outElastic = Easings._with2params(outElasticInternal, 1, 0.3)
Easings.inOutElastic = Easings._with2params(inOutElasticInternal, 1, 0.3)
Easings.outInElastic = Easings._with2params(outInElasticInternal, 1, 0.3)
Easings.inBack = Easings._with1param(inBackInternal, 1.70158)
Easings.outBack = Easings._with1param(outBackInternal, 1.70158)
Easings.inOutBack = Easings._with1param(inOutBackInternal, 1.70158)
Easings.outInBack = Easings._with1param(outInBackInternal, 1.70158)
Easings.impulse = Easings._with1param(function(t: number, damp: number)
	t ^= damp
	return t * (1000 ^ -t - 0.001) * 18.6
end, 0.9)
------------------------
export type easingType = ((number) -> number) | typeof(Easings.inBack) | typeof(Easings.popElastic)
export type allEasings =
	string
	| "bounce"
	| "tri"
	| "bell"
	| "pop"
	| "tap"
	| "pulse"
	| "spike"
	| "inverse"
	| "instant"
	| "linear"
	| "inQuad"
	| "outQuad"
	| "inOutQuad"
	| "outInQuad"
	| "inCubic"
	| "outCubic"
	| "inOutCubic"
	| "outInCubic"
	| "inQuart"
	| "outQuart"
	| "inOutQuart"
	| "outInQuart"
	| "inQuint"
	| "outQuint"
	| "inOutQuint"
	| "outInQuint"
	| "inExpo"
	| "outExpo"
	| "inOutExpo"
	| "outInExpo"
	| "inCirc"
	| "outCirc"
	| "inOutCirc"
	| "outInCirc"
	| "outBounce"
	| "inBounce"
	| "inOutBounce"
	| "outInBounce"
	| "inSine"
	| "outSine"
	| "inOutSine"
	| "outInSine"
	| "popElastic"
	| "tapElastic"
	| "pulseElastic"
	| "impulse"
	| "inElastic"
	| "outElastic"
	| "inOutElastic"
	| "outInElastic"
	| "inBack"
	| "outBack"
	| "inOutBack"
	| "outInBack"

function Easings.getEasing(easing: (allEasings | easingType)?): easingType
	if type(easing) == "string" then return Easings[easing] or Easings.linear end
	return easing or Easings.linear
end

return Easings
