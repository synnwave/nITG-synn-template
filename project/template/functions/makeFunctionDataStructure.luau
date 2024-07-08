--!strict

-- seperate script because this looks really, really ugly and i can't be bothered to rewrite it in any way
-- no metatables because fuck metatables

local _S = require("sort")
local function makeFunctionDataStructure<T>(_: { T }, comparator: (T, T) -> boolean) -- the _ variable is only there to capture the type
	local function reverseComparator(a: T, b: T) return comparator(b, a) end

	local stage, stage_n = {}, 0
	local list, list_n = {}, 0
	local swap, swap_n = {}, 0
	local self_n = 0

	local methods = {}
	function methods:add(obj: T)
		self_n += 1
		stage_n += 1
		stage[stage_n] = obj
	end

	function methods:remove()
		swap[swap_n] = nil
		swap_n -= 1
		self_n -= 1
	end

	function methods:next(): T?
		if self_n == 0 then return end
		if swap_n == 0 then _S.stable_sort(stage, reverseComparator) end
		if stage_n == 0 then
			if list_n == 0 then
				while swap_n ~= 0 do
					list_n += 1
					list[list_n] = swap[swap_n]
					swap[swap_n] = nil
					swap_n -= 1
				end
			else
				swap_n += 1
				swap[swap_n] = list[list_n]
				list[list_n] = nil
				list_n -= 1
			end
		else
			if list_n == 0 then
				swap_n += 1
				swap[swap_n] = stage[stage_n]
				stage[stage_n] = nil
				stage_n -= 1
			else
				if comparator(list[list_n], stage[stage_n]) then
					swap_n += 1
					swap[swap_n] = list[list_n]
					list[list_n] = nil
					list_n -= 1
				else
					swap_n += 1
					swap[swap_n] = stage[stage_n]
					stage[stage_n] = nil
					stage_n -= 1
				end
			end
		end

		return swap[swap_n]
	end

	return methods
end

return makeFunctionDataStructure
