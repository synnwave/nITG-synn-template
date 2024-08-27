--!strict

local Types = require("../../types/TypeDefs")
local _G = require("../../globals")
local _ENV = _G._G

export type class_params<Class> = {
	__className: string,
	__children: { any },
	__functionQueue: { any },
	__resolved: boolean,
	__props: { [any]: any },
	__source: string,
	__rawClass: Class,
	__isActorFrame: boolean,

	[string]: any,
}
export type class_schema<Class> = {
	__index: class_schema<Class>,

	appendChild: <C>(self: class<Class>, C & {}) -> C,
	__queueFunction: (self: class<Class>, methodName: string, ...any) -> (),
	__iterChildren: (self: class<Class>, doNotRemove: boolean?) -> (),
	__tostring: (self: class<Class>) -> string,
	__newindex: (self: class<Class>, k: string, v: any) -> (),
	__call: (self: class<Class>, child: (string | number)?) -> Types.Actor?,
}
export type class<Class> = Class & typeof(setmetatable({} :: class_params<Class>, {} :: class_schema<Class>))

local exports = {}
exports.__classes = {} :: { class<any> }

type baseConstructorProps<T> = {
	Name: string?,
	File: string?,
	Texture: string?,
	Frag: string?,
	Shader: string?,
	Vert: string?,
	Text: string?,
	Font: string?,

	Children: (class<any> | { class<any> })?,

	InitCommand: (string | ((self: T) -> ()))?,
	OnCommand: (string | ((self: T) -> ()))?,
	LoadCommand: (string | ((self: T) -> ()))?,

	[string]: any,
}
type constructorProps_ActorScroller = baseConstructorProps<Types.ActorScroller> & {
	UseScroller: number?,
	SecondsPerItem: number?,
	NumItemsToDraw: number?,
	ItemPaddingStart: number?,
	ItemPaddingEnd: number?,
	TransformFunction: ((self: Types.ActorScroller, offset: number, itemIndex: number, numItems: number) -> ())?,
	[string]: any,
}
type constructorProps_ActorFrame = baseConstructorProps<Types.ActorFrame> & {
	FOV: number?,
	VanishX: number?,
	VanishY: number?,
	FarDist: number?,
	[string]: any,
}
type constructorProps_Polygon = baseConstructorProps<Types.Polygon> & {
	DrawMode: (number | string | "triangles" | "quads" | "quadstrip" | "strip" | "linestrip")?,
	Vertices: number?,
	[string]: any,
}
type innerConstructor<T> = (props: baseConstructorProps<T>) -> class<T>
type constructor =
	((class: "Actor") -> innerConstructor<Types.Actor>)
	& ((class: "ActorFrame") -> (props: constructorProps_ActorFrame) -> class<Types.ActorFrame>)
	& ((class: "ActorScroller") -> (props: constructorProps_ActorScroller) -> class<Types.ActorScroller>)
	& ((class: "Polygon") -> (props: constructorProps_Polygon) -> class<Types.Polygon>)
	& ((class: "ActorFrameTexture") -> innerConstructor<Types.ActorFrameTexture>)
	& ((class: "ActorProxy") -> innerConstructor<Types.ActorProxy>)
	& ((class: "ActorSound") -> innerConstructor<Types.ActorSound>)
	& ((class: "BitmapText") -> innerConstructor<Types.BitmapText>)
	& ((class: "Model") -> innerConstructor<Types.Model>)
	& ((class: "Sprite") -> innerConstructor<Types.Sprite>)
	& ((class: "Quad") -> innerConstructor<Types.Quad>)
	& ((class: "Plugin") -> innerConstructor<Types.Actor>)
type defConstructors = {
	__index: defConstructors,
	Actor: innerConstructor<Types.Actor>,
	ActorFrame: (props: constructorProps_ActorFrame) -> class<Types.ActorFrame>,
	ActorScroller: (props: constructorProps_ActorScroller) -> class<Types.ActorScroller>,
	Polygon: (props: constructorProps_Polygon) -> class<Types.Polygon>,
	ActorFrameTexture: innerConstructor<Types.ActorFrameTexture>,
	ActorProxy: innerConstructor<Types.ActorProxy>,
	ActorSound: innerConstructor<Types.ActorSound>,
	BitmapText: innerConstructor<Types.BitmapText>,
	Model: innerConstructor<Types.Model>,
	Sprite: innerConstructor<Types.Sprite>,
	Quad: innerConstructor<Types.Quad>,
	Plugin: innerConstructor<Types.Actor>,
	ClearZBuffer: innerConstructor<Types.Quad>,
	[string]: innerConstructor<Types.Actor>,
}

local function findAndRemove(list, item)
	local index = table.find(list, item)
	if index then table.remove(list, index) end
end

local actorScrollerCache =
	{ function(self: Types.Actor, offset: number, _itemIndex, _numItems) self:x(offset * 256) end }

local actorMetatable = {} :: class_schema<any>
do
	function actorMetatable:__tostring()
		return `[LUA-ACTOR]: {(self.Name and self.Name .. ", " or "")}{self.actor or self.__className}`
	end

	actorMetatable.__index = function(self: any, k)
		if self.__rawClass[k] then
			return function(_, ...: any)
				actorMetatable.__queueFunction(self, k, { ... })
				return self
			end
		end
		return actorMetatable[k] or rawget(self, k) or rawget(self, "__props")[k] -- probably inefficient
	end :: any

	function actorMetatable:__newindex(k, v)
		if not self.__resolved then return rawset(self.__props, k, v) end
		if k == "actor" then return rawset(self, k, v) end
		error("Cannot call __newindex", 3)
	end

	function actorMetatable:appendChild<C>(child: C & {}, doNotRemove: boolean?): C
		if self.__resolved then return error("Cannot use appendChild after the actor has loaded.") end
		if not self.__isActorFrame then return child end
		if not doNotRemove then findAndRemove(exports.__classes, child :: any) end
		table.insert(self.__children, child)
		return child
	end

	function actorMetatable:__queueFunction(methodName: string, args: any)
		if self.__resolved then return error("Cannot use queueFunction after the actor has loaded.") end
		table.insert(self.__functionQueue, { method = methodName, args = args })
	end

	function actorMetatable:__iterChildren(doNotRemove: boolean?)
		if self.__resolved then return error("Cannot use iterChildren after the actor has loaded.") end

		local allChildren = {}
		local props = self.__props
		local isActorFrame = self.__isActorFrame

		if type(props.Children) == "table" then
			if isActorFrame then
				if props.Children.__className then props.Children = { props.Children } :: any end
				for _, child in ipairs(props.Children) do
					table.insert(allChildren, child)
					self:appendChild(child, doNotRemove)
				end
			end

			props.Children = {}
		end

		return allChildren
	end
end

local actorAliases = { Quad = "Sprite", Plugin = "Actor", ClearZBuffer = "Sprite" }
local classConstructorCaches = {}
local pluginActor
local function _constructor(class: string)
	if _G.templateReady then error("Cannot call createActor after the song has loaded", 2) end
	if _G.isLoadingUserMods then error("Cannot call createActor because the template has already initialized", 2) end

	if classConstructorCaches[class] then return classConstructorCaches[class] end
	local actorClass = _ENV[class] or _ENV[actorAliases[class]]
	if not (actorClass and actorClass["SetName"] ~= nil and actorClass["GetName"] ~= nil) then
		error(`class {class} isn't a valid actor class`, 3)
	end

	local isActorFrame = actorClass["GetChild"] ~= nil
	local function thisConstructor(props)
		local self = setmetatable(
			{
				__className = class,
				__children = {},
				__functionQueue = {},
				__resolved = false,
				__props = props,
				__source = _G.resolveLuaPath("", 3) .. "/",
				__rawClass = actorClass,
				__isActorFrame = isActorFrame,
			} :: class_params<any>,
			actorMetatable
		) :: class<Types.Actor>

		self:__iterChildren(false)
		table.insert(exports.__classes, self)
		if class == "Plugin" then pluginActor:appendChild(self) end
		if class == "ClearZBuffer" then
			self.__className = "Quad"
			self:cmd("blend,noeffect;clearzbuffer,1")
		end

		return self
	end

	classConstructorCaches[class] = thisConstructor
	return thisConstructor
end

exports.createActor = (_constructor :: any) :: constructor
exports.Def = (
	setmetatable({}, { __index = function(_, k) return _constructor(k) end }) :: any
) :: typeof(setmetatable({} :: { RootPath: string }, {} :: defConstructors))
pluginActor = exports.Def.ActorFrame {}

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
	parent: class<any>,
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
		parent = classes,
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
	if thisClass.__isActorFrame and (thisClass.__children and #thisClass.__children > 0) then return end
	if thisClass.Frag or thisClass.Vert or thisClass.Text or thisClass.Font then return end

	return thisClass.__className
end

local classRedirFile = { ActorScroller = "actorScroller.xml", ActorFrame = "actors.xml" }
function exports.__getFile(): string?
	local thisLayer: layer_schema = currentStack:getTop()
	if thisLayer.currentDepth < thisLayer.depth then
		thisLayer.currentDepth += 1
		return "actors.xml"
	end

	local thisClass = thisLayer.classes[thisLayer.index]
	if thisClass.__isActorFrame and (thisClass.__children and #thisClass.__children > 0) then
		currentStack:newLayer(thisClass)
		return classRedirFile[thisClass.__className] or "actors.xml"
	end

	if thisClass.Frag or thisClass.Vert then return "shader.xml" end
	return thisClass.File
end

local propertyDefaults = {
	Frag = "nop.frag",
	Vert = "nop.vert",

	UseScroller = 1,
	SecondsPerItem = 0,
	NumItemsToDraw = 999,
	ItemPaddingStart = 0,
	ItemPaddingEnd = 0,
}
function exports.__getProperty(property: string, useLayerBefore: boolean?): any
	local thisLayer: layer_schema = useLayerBefore and currentStack[#currentStack - 1] or currentStack:getTop()
	local thisClass = thisLayer.classes[thisLayer.index] :: any
	if property == "Font" and thisClass.__className == "BitmapText" then -- only return a fallback if it's a BitmapText
		return thisClass[property] or "Common Normal"
	end
	if property == "TransformFunction" then
		return actorScrollerCache[thisClass[property] or 1] or actorScrollerCache[1]
	end

	return thisClass[property] or propertyDefaults[property]
end

local function useCommand(actor, command: (string | (...any) -> ...any)?)
	return function(...: any)
		if type(command) == "string" then
			actor:cmd(command)
		elseif type(command) == "function" then
			command(actor, ...)
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
		thisClass.actor = actor

		--> Run Queued Functions
		for _, queued in ipairs(thisClass.__functionQueue) do
			local methodSuccess, methodError = pcall(actor[queued.method], actor, unpack(queued.args))
			if not methodSuccess then
				error(
					`Failed to run actor function '{queued.method}', '{methodError}'\n Please note that if you're calling a getter function (eg. GetTexture, GetShader), it will not work.`,
					2
				)
			end
		end

		--> Bind Commands
		useCommand(actor, thisClass.InitCommand)()
		for name, func in pairs(thisClass.__props) do
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

local resolvePathsFor = { "File", "Texture" }
local resolvePathsFor2 = { "Frag", "Vert", "Font" } -- these paths will be handled differently
local rootPath = string.rep("../", #string.split(_G.resolveLuaPath(""), "/")) -- this line is terrible, but it's for the reason above
exports.Def.RootPath = rootPath

local propertyQueues = {
	Name = "SetName",
	Text = "settext",
	Texture = "Load",
	DrawMode = "SetDrawMode",
	Vertices = "SetNumVertices",
	FOV = "fov",
	VanishX = "SetVanishX",
	VanishY = "SetVanishY",
	FarDist = "SetFarDist",
}
local propertyAliases = {
	Shader = "Frag",
}
function exports.__init()
	--> Resolve actor properties
	local classesToRemove = {}
	local function iterClasses(currentClass: { class<Types.Actor> })
		for _, this in ipairs(currentClass) do
			if not this.__resolved then
				local props = this.__props
				for _, v in ipairs(this:__iterChildren(true)) do
					table.insert(classesToRemove, v)
				end

				for i, v in pairs(props) do
					local thisAlias = propertyAliases[i]
					if thisAlias then
						i = thisAlias
						props[i] = v
					end

					if table.find(resolvePathsFor, i) then props[i] = _G.resolveLuaPath(v, this.__source) end
					if table.find(resolvePathsFor2, i) then props[i] = rootPath .. _G.resolveLuaPath(v, this.__source) end
				end

				--> Queue Functions
				for property, methodName in pairs(propertyQueues) do
					local actorProp = (this :: any)[property]
					if actorProp ~= nil then
						if type(methodName) == "string" and this.__rawClass[methodName] ~= nil then
							this:__queueFunction(methodName, { actorProp })
						elseif type(methodName) == "function" then
							methodName(this, actorProp)
						end
					end
				end

				this.__resolved = true
				if this.__children and #this.__children > 0 then iterClasses(this.__children) end
			end
		end
	end
	iterClasses(exports.__classes)

	for _, class in pairs(classesToRemove) do
		findAndRemove(exports.__classes, class)
	end
	classesToRemove = nil :: any

	--> since we've resolved the properties, replace __index
	actorMetatable.__index = function(self: any, k)
		local actor = rawget(self, "actor")
		if actor then
			local actorFunction = actor[k]
			if type(actorFunction) == "function" then return function(_, ...: any) return actorFunction(actor, ...) end end
		end

		return rawget(self, k) or rawget(self, "__props")[k]
	end :: any

	--> let's also set __call
	function actorMetatable:__call(k)
		local actor = self.actor
		if self.__isActorFrame then
			if type(k) == "string" then return actor:GetChild(k) end
			if type(k) == "number" then return actor:GetChildAt(k) end
		end

		return actor
	end

	--> initialize stack
	currentStack = setmetatable({}, stackMetatable)
	currentStack:newLayer({ __children = exports.__classes })
end

return exports
