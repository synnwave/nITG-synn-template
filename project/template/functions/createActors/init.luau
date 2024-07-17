--!strict

local Types = require("../../types/TypeDefs")
local _G = require("../../globals")

local exports = {}
exports.__classes = {} :: { class<any> }

type class<T> = T & {
	__className: string,
	__children: { any }?,
	appendChild: <C>(self: class<T>, C & {}) -> (),

	[string]: any,
}
type constructorProps<T> = {
	Name: string?,
	Children: { class<any> }?,

	File: string?,
	Texture: string?,
	Frag: string?,
	Vert: string?,

	InitCommand: (string | ((self: T) -> ()))?,
	OnCommand: (string | ((self: T) -> ()))?,

	[string]: any,
}
type innerConstructor<T> = (props: constructorProps<T>) -> class<T>
type constructor =
	((class: "Actor") -> innerConstructor<Types.Actor>)
	& ((class: "ActorFrame") -> innerConstructor<Types.ActorFrame>)
	& ((class: "ActorFrameTexture") -> innerConstructor<Types.ActorFrameTexture>)
	& ((class: "ActorProxy") -> innerConstructor<Types.ActorProxy>)
	& ((class: "ActorScroller") -> innerConstructor<Types.ActorScroller>)
	& ((class: "ActorSound") -> innerConstructor<Types.ActorSound>)
	& ((class: "BitmapText") -> innerConstructor<Types.BitmapText>)
	& ((class: "Model") -> innerConstructor<Types.Model>)
	& ((class: "Polygon") -> innerConstructor<Types.Polygon>)
	& ((class: "Sprite") -> innerConstructor<Types.Sprite>)
	& ((class: "Quad") -> innerConstructor<Types.Quad>)

local function removeChildFromTable(child)
	local childIndex = table.find(exports.__classes, child)
	if childIndex then table.remove(exports.__classes, childIndex) end
end

local resolvePathsFor = { "File", "Texture", "Font" }
local resolvePathsFor2 = { "Frag", "Vert" } -- shaders handle paths differently for some reason...
local rootPath = string.rep("../", #string.split(_G.resolveLuaPath(""), "/")) -- this line is terrible, but it's for the reason above

local function _constructor(class: string)
	if _G.templateReady then error("Cannot call createActor after the song has loaded") end
	if not _G.CREATE_ACTORS_IN_LUA then error("Cannot call createActor because CREATE_ACTORS_IN_LUA is disabled") end
	if _G.isLoadingUserMods then error("Cannot call createActor because the template has already initialized") end

	return function<T>(props: constructorProps<T>)
		local thisClass = {} :: any
		thisClass.__className = class

		function thisClass:appendChild<C>(child: any)
			if class ~= "ActorFrame" or not thisClass.__children then
				error(`Cannot append child "{child.__className}" to class of type "{class}"`)
			end

			removeChildFromTable(child)
			table.insert(thisClass.__children, child)
		end
		if props.Children then
			if class == "ActorFrame" then
				if not thisClass.__children then thisClass.__children = {} end
				for _, child in ipairs(props.Children) do
					thisClass:appendChild(child)
				end
			else
				error(`Class "{class}" cannot have any children since it's not an ActorFrame`)
			end
		end
		if class == "ActorFrame" then thisClass.__children = thisClass.__children or {} end

		for i, v in pairs(props) do
			if i ~= "className" and i ~= "__className" then thisClass[i] = v end
			if table.find(resolvePathsFor, i) then thisClass[i] = _G.resolveLuaPath(v, 3) end
			if table.find(resolvePathsFor2, i) then thisClass[i] = rootPath .. _G.resolveLuaPath(v, 3) end
		end

		table.insert(exports.__classes, thisClass)
		return thisClass
	end
end

exports.createActor = (_constructor :: any) :: constructor

-- time for internal stuff --
-- credits to: https://github.com/ArcticFqx/nitg-theme/blob/master/Lua/geno.lua !
-- heavily modified by @synnwave

local NODES_PER_ACTOR_FRAME = 1000
local log = function(n) return math.log(n) / math.log(NODES_PER_ACTOR_FRAME) end
local function getDepth(t)
	local depth = math.ceil(log(#t))
	return depth > 0 and depth or 1
end

type layer_schema = {
	classes: { class<any> },
	depth: number,
	width: number,
	currentDepth: number,
	index: number,
	nodes: { number },
	nodeIndex: number,
}

local stackMetatable = {
	push = table.insert,
	pop = table.remove :: any,
}
stackMetatable.__index = stackMetatable
function stackMetatable:getTop() return self[#self] end
function stackMetatable:newLayer(classes: any)
	if not classes.__children then return end
	self:push({
		classes = classes.__children,
		depth = getDepth(classes.__children),
		width = #classes.__children,
		currentDepth = 1,
		index = 0,
		nodes = {},
		nodeIndex = 0,
	} :: layer_schema)
end

type stackType = typeof(setmetatable({}, {} :: typeof(stackMetatable)))
local currentStack: stackType = nil

function exports.__condition()
	local thisLayer: layer_schema = currentStack:getTop()
	thisLayer.nodes[thisLayer.currentDepth] = thisLayer.nodeIndex
	if thisLayer.width <= thisLayer.index then return false end

	thisLayer.nodeIndex += 1
	return true
end

function exports.__getType()
	local thisLayer: layer_schema = currentStack:getTop()
	if thisLayer.currentDepth < thisLayer.depth then return end

	thisLayer.index += 1
	local thisClass = thisLayer.classes[thisLayer.index]
	if thisClass.__className == "ActorFrame" and (thisClass.__children and #thisClass.__children > 0) then return end
	if thisClass.Frag or thisClass.Vert or thisClass.Text or thisClass.Font then return end

	return thisClass.__className
end

function exports.__getFile(): string?
	local thisLayer: layer_schema = currentStack:getTop()
	if thisLayer.currentDepth < thisLayer.depth then
		thisLayer.currentDepth += 1
		return "actors.xml"
	end

	local thisClass = thisLayer.classes[thisLayer.index]
	if thisClass.__className == "ActorFrame" and (thisClass.__children and #thisClass.__children > 0) then
		currentStack:newLayer(thisClass)
		return "actors.xml"
	end

	if thisClass.Frag or thisClass.Vert then return "shader.xml" end
	if thisClass.Text or thisClass.Font then return "bitmapText.xml" end
	return thisClass.File
end

local propertyDefaults = {
	Frag = "nop.frag",
	Vert = "nop.vert",
	Text = "",
	Font = "_eurostile normal",
}
function exports.__getProperty(property: string): any
	local thisLayer: layer_schema = currentStack:getTop()
	local thisClass = thisLayer.classes[thisLayer.index] :: any
	return thisClass[property] or propertyDefaults[property]
end

local function useCommand(actor, command: (string | (...any) -> ...any)?)
	return function()
		if type(command) == "string" then
			actor:cmd(command)
		elseif type(command) == "function" then
			command(actor)
		end
	end
end

function exports.__onInit(actor: any)
	if actor:hascommand("Init") then actor:removecommand("Init") end -- don't you love it when InitCommand runs twice?

	local thisLayer: layer_schema = currentStack:getTop()
	if thisLayer.currentDepth < 1 then
		currentStack:pop()
		thisLayer = currentStack:getTop()
	end

	local thisClass = thisLayer.classes[thisLayer.index]
	if thisLayer.currentDepth == thisLayer.depth then
		if thisClass.Frag or thisClass.Vert then actor = actor:GetChildAt(0) end
		if thisClass.Name then actor:SetName(thisClass.Name) end

		setmetatable(thisClass :: any, {
			__index = function(self, prop)
				local actorProp = actor[prop]
				if type(actorProp) == "function" then -- allow actor functions to be accessed
					return function(_, ...: any) return actorProp(actor, ...) end
				end
				return rawget(self, prop)
			end,
		})

		useCommand(actor, thisClass.InitCommand)()
		for name, func in pairs(thisClass) do
			if name ~= "InitCommand" and string.sub(name, -7) == "Command" then
				name = string.sub(name, 1, -8)
				if actor:hascommand(name) then actor:removecommand(name) end
				actor:addcommand(name, useCommand(actor, func))
			end
		end
	else
		actor:SetName("")
	end

	if thisClass.Texture then actor:Load(thisClass.Texture) end
	if thisLayer.nodes[thisLayer.currentDepth] >= NODES_PER_ACTOR_FRAME or thisLayer.width <= thisLayer.index then
		thisLayer.currentDepth -= 1
	end
end

function exports.__canContinue()
	local thisLayer: layer_schema = currentStack:getTop()
	return thisLayer.width > thisLayer.nodeIndex
end

function exports.__init()
	currentStack = setmetatable({}, stackMetatable)
	currentStack:newLayer({ __children = exports.__classes })
end

return exports
