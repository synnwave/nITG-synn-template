--!strict

local function mergeTable(into: any, from: any?, ...: any): any
	if from == nil then return into end
	for i, v in pairs(from) do
		into[i] = v
	end

	return mergeTable(into, unpack(...))
end

type Merge_schema =
	(<A>(A & {}) -> A)
	& (<A, B>(A & {}, B & {}) -> A & B)
	& (<A, B, C>(A & {}, B & {}, C & {}) -> A & B & C)
	& (<A, B, C, D>(A & {}, B & {}, C & {}, D & {}) -> A & B & C & D)
	& (<A, B, C, D, E>(A & {}, B & {}, C & {}, D & {}, E & {}) -> A & B & C & D & E)
	& (<A, B, C, D, E, F>(A & {}, B & {}, C & {}, D & {}, E & {}, F & {}) -> A & B & C & D & E & F)

return mergeTable :: Merge_schema
