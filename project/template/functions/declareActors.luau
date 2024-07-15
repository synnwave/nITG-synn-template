--!strict

local Types = require("../types/TypeDefs")
local _G = require("../globals")

local exports = {}
exports.__classes = {} :: { class<any> }

type class<T> = {
	actor: T,
	className: string,
	children: { any }?,
	[string]: any,

	get: (self: class<T>) -> T,
	appendChild: <C>(self: class<T>, C & {}) -> (),
}
type constructorProps<T> = {
	Name: string?,
	InitCommand: ((self: T) -> ())?,
	Condition: (() -> boolean)?,
	File: string?,
	Texture: string?,
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

local function _constructor(class: string)
	if _G.templateReady then error("Cannot call CreateActor after the song has loaded") end
	if not _G.DECLARATIVE_LAYOUT_ENABLED then
		error("Cannot call CreateActor because declarative layout is disabled")
	end
	if _G.isLoadingUserMods then error("Cannot call CreateActor because the template has already initialized") end

	return function<T>(props: constructorProps<T>)
		local thisClass = {} :: class<any>
		thisClass.className = class
		for i, v in props do
			if i ~= "className" then thisClass[i] = v end
			if i == "File" or i == "Texture" then thisClass[i] = _G.resolveLuaPath(v, 3) end
		end

		if class == "ActorFrame" then thisClass.children = thisClass.children or {} end
		function thisClass:appendChild<C>(child: any)
			if class ~= "ActorFrame" or not thisClass.children then
				error(`Cannot append child to class of type {class}`)
			end

			local childIndex = table.find(exports.__classes, child)
			if childIndex then table.remove(exports.__classes, childIndex) end

			table.insert(thisClass.children, child)
		end
		function thisClass:get() return assert(thisClass.actor, "actor doesn't exist yet") end

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
	if not classes.children then return end
	self:push({
		classes = classes.children,
		depth = getDepth(classes.children),
		width = #classes.children,
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

function exports.__canContinue()
	local thisLayer: layer_schema = currentStack:getTop()
	return thisLayer.width > thisLayer.nodeIndex
end

function exports.__getType()
	local thisLayer: layer_schema = currentStack:getTop()
	if thisLayer.currentDepth < thisLayer.depth then return end

	thisLayer.index += 1
	local thisClass = thisLayer.classes[thisLayer.index]
	if thisClass.className == "ActorFrame" and (thisClass.children and #thisClass.children > 0) then return end
	return thisClass.className
end

local xmlPath = "declarativeActors.xml"
function exports.__getFile(): string?
	local thisLayer: layer_schema = currentStack:getTop()
	if thisLayer.currentDepth < thisLayer.depth then
		thisLayer.currentDepth += 1
		return xmlPath
	end

	local thisClass = thisLayer.classes[thisLayer.index]
	if thisClass.className == "ActorFrame" and (thisClass.children and #thisClass.children > 0) then
		currentStack:newLayer(thisClass)
		return xmlPath
	end

	return thisClass.File
end

function exports.__onInit(actor: any)
	local thisLayer: layer_schema = currentStack:getTop()
	if thisLayer.currentDepth < 1 then
		currentStack:pop()
		thisLayer = currentStack:getTop()
	end

	local thisClass = thisLayer.classes[thisLayer.index]
	if thisLayer.currentDepth == thisLayer.depth then
		if thisClass.Name then actor:SetName(thisClass.Name) end
		thisClass.actor = actor

		local initFunc = thisClass.InitCommand
		if initFunc then
			if type(initFunc) == "string" then
				actor:cmd(initFunc)
			elseif type(initFunc) == "function" then
				initFunc(actor)
			end
		end

		for commandName, commandFunction in pairs(thisClass) do
			if string.sub(commandName, -7) == "Command" and typeof(commandFunction) == "function" then
				commandName = string.sub(commandName, 1, -8)
				if actor:hascommand(commandName) then actor:removecommand(commandName) end
				actor:addcommand(commandName, commandFunction)
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

function exports.__init()
	currentStack = setmetatable({}, stackMetatable)
	currentStack:newLayer({ children = exports.__classes })
end

return exports
