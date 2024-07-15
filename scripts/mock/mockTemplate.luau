--!strict

local currentMock
return function(fullRefresh: boolean?)
	if fullRefresh or not currentMock then
		local mock = { env = {} }
		currentMock = mock

		mock.env.synn_env = {
			string = string,
			table = table,
			normalizePath = function(path: string)
				local parts = {}
				for part in string.gmatch(path, "[^/]+") do
					if part == ".." then
						table.remove(parts)
					elseif part ~= "." then
						table.insert(parts, part)
					end
				end

				return `/{table.concat(parts, "/")}`
			end,
		}
	end

	return currentMock
end
