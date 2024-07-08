--!strict

local function mergeTable(into: any, from: any?, ...: any): any
	if from == nil then return into end
	for i, v in pairs(from) do
		into[i] = v
	end
	return mergeTable(into, unpack(...))
end

-- THERE HAS GOT TO BE A BETTER WAY TO DO THIS...
-- stylua: ignore start
type Merge_schema = (<A>(A & {}) -> A)
	& (<A, B>(A & {}, B & {}) -> A & B)
	& (<A, B, C>(A & {}, B & {}, C & {}) -> A & B & C)
	& (<A, B, C, D>(A & {}, B & {}, C & {}, D & {}) -> A & B & C & D)
	& (<A, B, C, D, E>(A & {}, B & {}, C & {}, D & {}, E & {}) -> A & B & C & D & E)
	& (<A, B, C, D, E, F>(A & {}, B & {}, C & {}, D & {}, E & {}, F & {}) -> A & B & C & D & E & F)
	& (<A, B, C, D, E, F, G>(A & {}, B & {}, C & {}, D & {}, E & {}, F & {}, G & {}) -> A & B & C & D & E & F & G)
	& (<A, B, C, D, E, F, G, H>(A & {}, B & {}, C & {}, D & {}, E & {}, F & {}, G & {}, H & {}) -> A & B & C & D & E & F & G & H)
	& (<A, B, C, D, E, F, G, H, I>(A & {}, B & {}, C & {}, D & {}, E & {}, F & {}, G & {}, H & {}, I & {}) -> A & B & C & D & E & F & G & H & I)
	& (<A, B, C, D, E, F, G, H, I, J>(A & {}, B & {}, C & {}, D & {}, E & {}, F & {}, G & {}, H & {}, I & {}, J & {}) -> A & B & C & D & E & F & G & H & I & J)
	& (<A, B, C, D, E, F, G, H, I, J, K>(A & {}, B & {}, C & {}, D & {}, E & {}, F & {}, G & {}, H & {}, I & {}, J & {}, K & {}) -> A & B & C & D & E & F & G & H & I & J & K)

return mergeTable :: Merge_schema
