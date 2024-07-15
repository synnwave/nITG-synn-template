--!strict
-- credits to XeroOl for the original mock script.
-- https://github.com/XeroOl/notitg-mirin/blob/master/spec/mock.lua

local currentMock
return function(fullRefresh: boolean?)
	if fullRefresh or not currentMock then
		local globals = {
			DISPLAY = {},
			SCREEN_CENTER_X = 320,
			SCREEN_CENTER_Y = 240,
			SCREEN_WIDTH = 640,
			SCREEN_HEIGHT = 480,

			mock = {},
		}
		currentMock = globals

		globals.GAMESTATE = {}
		local Song = {}
		function globals.GAMESTATE:GetCurrentSong() return Song end

		local mods = {}
		for playerId = 1, 8 do
			mods[playerId] = {}
		end

		function globals.GAMESTATE:ApplyModifiers(str, playerId)
			for percent, mod in str:gmatch("*-1 ([^ ,]+) ([^ ,]+)") do
				mods[playerId][mod] = percent
			end
		end

		local offset = 1
		local time = offset
		local beat = 0
		local factor = 3
		function globals.GAMESTATE:GetSongTime() return time end
		function globals.GAMESTATE:GetSongBeat() return beat end
		function Song:GetSongDir() return "" end
		function Song:GetElapsedTimeFromBeat(thisBeat: number) return thisBeat / factor + offset end
		function globals.DISPLAY:GetDisplayWidth() return 800 end
		function globals.DISPLAY:GetDisplayHeight() return 600 end
		function globals.mock.advanceTime(dt)
			time += 1
			time /= factor * dt
			beat += dt
		end

		do
			local Actor = {}
			local Actor_mt = { __index = Actor }

			local ActorFrame = setmetatable({}, Actor_mt)
			local ActorFrame_mt = { __index = ActorFrame }

			local Player = setmetatable({}, Actor_mt)
			local Player_mt = { __index = Player }

			globals.mock.actors = {} :: { [any]: any }

			function globals.mock.newActor(name: string)
				local result = setmetatable({
					_name = name,
					_commands = {},
					_queue = {},
				}, Actor_mt)
				table.insert(globals.mock.actors, result)
				return result
			end
			function Actor:removecommand(name) self._commands[name] = nil end
			function Actor:luaeffect(name) self._effect = name end
			function Actor:tween(_dur: number, fn) self._tween = fn end
			function Actor:effectclock() end
			function Actor:GetSecsIntoEffect() return time end
			function Actor:sleep(_time: number) end
			function Actor:GetName() return self._name or "" end
			function Actor:hidden(i) self._hidden = if i == 0 then nil else true end
			function Actor:queuecommand(name) table.insert(self._queue, name) end
			function Actor:addcommand(name, command)
				assert(type(name) == "string", "name must be a string")
				assert(type(command) == "function", "command must be a function")
				self._commands[name] = command
			end
			function Actor:playcommand(name)
				if self._commands[name] then self._commands[name](self) end
				if self._children then
					for _, v in ipairs(self._children) do
						v:playcommand(name)
					end
				end
			end

			function globals.mock.newPlayer(name: string)
				local result = setmetatable({
					_name = name,
					_commands = {},
					_queue = {},
				}, Player_mt)
				table.insert(globals.mock.actors, result)
				return result
			end
			function Player:IsAwake() return self._name == "PlayerP1" or self._name == "PlayerP2" end

			function globals.mock.newActorFrame(name)
				local result = setmetatable({
					_name = name,
					_commands = {},
					_queue = {},
					_children = {},
				}, ActorFrame_mt)
				table.insert(globals.mock.actors, result)
				return result
			end
			function ActorFrame:GetNumChildren() return #self._children end
			function ActorFrame:GetChildAt(n: number) return self._children[n + 1] end
		end

		local screenWorld = {} :: { [any]: any }
		globals.SCREENMAN = {}
		function globals.SCREENMAN:GetTopScreen()
			return {
				GetChild = function(_, arg)
					if arg and arg:match("^PlayerP[1-8]$") then
						screenWorld[arg] = screenWorld[arg] or globals.mock.newPlayer(arg)
					end
					screenWorld[arg] = screenWorld[arg] or globals.mock.newActor(arg)
					local thing_to_hide = screenWorld[arg]
					return thing_to_hide
				end,
			}
		end

		function globals.SCREENMAN:SystemMessage(message) error(message) end
		function globals.mock.addChild(parent, child) table.insert(parent._children, child) end
	end

	return currentMock
end
