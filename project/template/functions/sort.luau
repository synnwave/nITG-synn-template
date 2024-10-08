--!strict
--[[
this is based on code from Dirk Laurie and Steve Fisher,
used under license as follows:


	Copyright © 2013 Dirk Laurie and Steve Fisher.
	Permission is hereby granted, free of charge, to any person obtaining a
	copy of this software and associated documentation files (the 'Software'),
	to deal in the Software without restriction, including without limitation
	the rights to use, copy, modify, merge, publish, distribute, sublicense,
	and/or sell copies of the Software, and to permit persons to whom the
	Software is furnished to do so, subject to the following conditions:
	The above copyright notice and this permission notice shall be included in
	all copies or substantial portions of the Software.
	THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
	FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
	DEALINGS IN THE SOFTWARE.

(modifications by Max Cahill 2018, 2020)
(modifications by XeroOl 2021)
(modifications by synnwave 2024)

Found at: https://github.com/1bardesign/batteries/blob/master/sort.lua
]]

-- `sort` object, container of the following methods
local sort = {}
-- Tunable threshold, deciding between the insertion sort and merge sort
sort.max_chunk_size = 32

-- ===================================================================== --

-- Internal implementations

-- Insertion sort on a section of an array
function sort._insertion_sort_impl(array: { any }, first: number, last: number, less)
	for i = first + 1, last do
		local k = first
		local v = array[i]
		for j = i, first + 1, -1 do
			if less(v, array[j - 1]) then
				array[j] = array[j - 1]
			else
				k = j
				break
			end
		end
		array[k] = v
	end
end

-- Merge sort on two sorted portions of an array
function sort._merge(array: { any }, workspace: { any }, low: number, middle: number, high: number, less)
	local i, j, k
	i = 1
	-- copy first half of array to auxiliary array
	for l = low, middle do
		workspace[i] = array[l]
		i += 1
	end
	-- sieve through
	i = 1
	j = middle + 1
	k = low
	while true do
		if (k >= j) or (j > high) then break end
		if less(array[j], workspace[i]) then
			array[k] = array[j]
			j += 1
		else
			array[k] = workspace[i]
			i += 1
		end
		k += 1
	end
	-- copy back any remaining elements of first half
	for l = k, j - 1 do
		array[l] = workspace[i]
		i += 1
	end
end

-- Recursive merge sort implementation
function sort._merge_sort_impl(array: { any }, workspace: { any }, low: number, high: number, less)
	if high - low <= sort.max_chunk_size then
		sort._insertion_sort_impl(array, low, high, less)
	else
		local middle = math.floor((low + high) / 2)
		sort._merge_sort_impl(array, workspace, low, middle, less)
		sort._merge_sort_impl(array, workspace, middle + 1, high, less)
		sort._merge(array, workspace, low, middle, high, less)
	end
end

-- Default comparison function: sort from smallest to biggest
local function default_less(a: any, b: any) return a < b end

-- Setup a sorting algorithm, check the validity of the comparator,
-- and determine if a case is trivial (no sorting needed)
function sort._sort_setup<V>(array: { V }, comp: ((V, V) -> boolean)?)
	local thisComp: any = comp or default_less
	local n = #array
	--trivial cases; empty or 1 element
	local trivial = (n <= 1)
	if not trivial then
		--check comp
		if thisComp(array[1], array[1]) then
			error("invalid order function for sorting; comp(v, v) should not be true for any v.", 2)
		end
	end
	--setup complete
	return trivial, n, thisComp
end

-- Public method: merge sort on an array. If the array length is
-- less than `max_chunk_size`, an insertion sort will be done instead.
function sort.stable_sort<V>(array: { V }, comp: ((V, V) -> boolean)?)
	--setup
	local trivial, n, less = sort._sort_setup(array, comp)
	if not trivial then
		--temp storage; allocate ahead of time
		local workspace = {}
		local middle = math.ceil(n / 2)
		workspace[middle] = array[1]
		--dive in
		sort._merge_sort_impl(array, workspace, 1, n, less)
	end
	return array
end

-- Public method: insertion sort
function sort.insertion_sort<V>(array: { V }, comp: ((V, V) -> boolean)?)
	--setup
	local trivial, n, less = sort._sort_setup(array, comp)
	if not trivial then sort._insertion_sort_impl(array, 1, n, less) end
	return array
end

return {
	stable_sort = sort.stable_sort,
	insertion_sort = sort.insertion_sort,
	unstable_sort = table.sort,
}
