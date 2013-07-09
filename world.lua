local va = require 'vertexarray'
local Polygon = require 'polygon'
local msvg = require 'msvg'
local path = require 'path'

local s = 0.3

World = Core.class(Sprite)

function World:init(svgTree)
    self:addEventListener("touchesMove", self.onTouch, self)
    self:addEventListener("touchesEnd", self.onTouchEnd, self)
    
    self.collisionListeners = {
        preSolve = {}, postSolve = {},
        beginContact = {}, endContact = {}
    }
    local debugDraw = b2.DebugDraw.new()
    debugDraw:setFlags(
        b2.DebugDraw.SHAPE_BIT +
        b2.DebugDraw.JOINT_BIT +
        b2.DebugDraw.PAIR_BIT
    )
    
    self.physicsWorld = b2.World.new(0, 10)
    self.physicsWorld:setDebugDraw(debugDraw)
    
    self.physicsWorld:addEventListener("preSolve", self.onPhysicsEvent, self)
    self.physicsWorld:addEventListener("postSolve", self.onPhysicsEvent, self)
    self.physicsWorld:addEventListener("beginContact", self.onPhysicsEvent, self)
    self.physicsWorld:addEventListener("endContact", self.onPhysicsEvent, self)
    
    self:loadMap(svgTree)
    
    self:test_addNinja2()
    --self:addChild(test_newShapeFromVertices({0, 0, 10, 0, 0, 10}))
    if dbg >= 2 then
		self:addChild(debugDraw)
    end
    local scale = s
    self:setScale(scale, scale)
	--self:test_screenshot()	
end

local function test_newShapeFromVertices(points, color, alpha)
    local s = Shape.new()
    --s:setLineStyle(2)
    s:setFillStyle(Shape.SOLID, color, alpha)
    s:beginPath()
    s:moveTo(points[1], points[2])
    for i=3,#points,2 do
        local px, py = points[i], points[i+1]
        s:lineTo(px, py)
        --print("test_newShapeFromVertices i, px, py ", i, px, py)
    end
    s:closePath()
    s:endPath()
    return s
end

function World:test_screenshot()
    local b = Bitmap.new(Texture.new("data/gfx/0.png", true))
    s = 2.5
	--s = 1.5
	
	--s = 1.8
	s = 3.1

    --s = 4.76
    b:setScale(s)
    self:addChild(b)
end

function World:test_addNinja2()
    self.ninja = Entity.new("ninja", self, 0, 0)
end

function World:addCollisionListener(name, sprite, listener, data)
    self.collisionListeners[name][sprite] = self.collisionListeners[name][sprite] or {}
    table.insert(self.collisionListeners[name][sprite], { listener, data })
end

function World:onPhysicsEvent(e)
	local manifold = e.contact:getWorldManifold()
    local normal = manifold.normal
	local points = manifold.points
    local sprites = { 
        e.fixtureA:getBody().sprite,
        e.fixtureB:getBody().sprite
    }
	if sprites[1].entity and sprites[1].entity == sprites[2].entity then
		return
	end
    local tags = {
        e.fixtureA.tag,
        e.fixtureB.tag
    }
	local normals = {
		normal,
		{ x = -normal.x, y = -normal.y }
	}
    for i=1,2 do
        local j = i%2 + 1
        local event = {
            sprite = sprites[i],
            otherSprite = sprites[j],
            tag = tags[i],
            otherTag = tags[j],
			normal = normals[i],
			points = points,
			contact = e.contact,
        }
        local listeners = self.collisionListeners[e:getType()][event.sprite] or {}
        for listenerInfo in all(listeners) do
            local listener, data = unpack(listenerInfo)
            -- data can be nil, then #args == 1
            local args = { data, event }
            listener(unpack(args))
        end
    end
    
end

function World:onTouch(e)
    if e.touch.id ~= 1 then return end
    local x, y = e.touch.rx, e.touch.ry
    --print("onTouch x, y", x, y)
    if self.prevTouchX then
        local px, py = self:getPosition()
        local dx, dy = x - self.prevTouchX, y - self.prevTouchY
        --print("dx, dy", dx, dy)
        self:setPosition(px + dx, py + dy)
    end
    self.prevTouchX, self.prevTouchY = x, y
end

function World:onTouchEnd(e)
    if e.touch.id ~= 1 then return end
    self.prevTouchX, self.prevTouchY = nil, nil
end

function World:loadMap(svgTree)
    print("Loading map")
	
    local function hex_color(s)
        if s:find'^#' then
            return tonumber(s:sub(2), 16)
        end
    end 
    
    -- Walk through SVG tree
    local function walk(e)
		local simplifiedPathData = msvg.simplifyElement(e)
        if simplifiedPathData then -- it is a path and simplification was ok
			print("Adding wall " .. e.id)
			--path.inspect(simplifiedPathData)
			for i in path.subpaths(simplifiedPathData) do
				local vertices = {}
				local j = i
				local prevX, prevY = 1/0, 1/0
				while j <= path.subpath_end(simplifiedPathData, i) do
					local s, x, y = path.cmd(simplifiedPathData, j)
					if s == "line" then
						-- we don't want the same point being added twice in a row
						if not (x == prevX and y == prevY) then
							table.insertall(vertices, x, y)
							prevX, prevY = x, y
						end
					end
					j = path.next_cmd(simplifiedPathData, j)
					if not j then break end
				end
								
				local alpha = tonumber(e.style.fill_opacity)
				local mesh
				local ok, msg = pcall(function()
					mesh = SimpleMesh.new(vertices, hex_color(e.style.fill), alpha, 1.9)
				end)
				if not ok then print("Warning:", msg) end
				mesh = mesh or Sprite.new()
				mesh.pathData = e.d
				mesh.pathMatrix = e.transform
				self:addChild(mesh)
				
                local shape = { vertices = vertices }
				local fixtureConfig = { type = 'chain', shape = shape, tag = "wall" }
                self:attachBody(mesh, { fixtureConfigs = { fixtureConfig }, })
				print("Adding simple mesh", vertices[1], vertices[2])
			end
        end
        for c in all(e.children) do walk(c) end
    end
    walk(svgTree)
end

local function moveToHell(body)
	body:setActive(false)
	body:setPosition(-100, -100)
end

local function updatePhysics(sprite)
	local world = sprite.world
    local parent = sprite:getParent()
    local rotation = sprite:getRotation()
    local scaleX, scaleY = sprite:getScale()
	
    while true do
        if not parent then
			moveToHell(sprite.body)
			return 
		end -- skip detached sprites
        assert(parent ~= stage, "Cannot update physics for sprite in another subtree")
        if parent == world then break end
        rotation = rotation + parent:getRotation()
        scaleX = scaleX * parent:getScaleX()
        scaleY = scaleY * parent:getScaleY()
        parent = parent:getParent()
    end
	
	sprite.body:setActive(true)
    assert(math.abs(scaleX) > 0.99 and math.abs(scaleX) < 1.01, "sprite with attached body cannot be scaled")
    
    local bodies = sprite.bodies
    local mirrored = scaleX < 0
    
    if not bodies and mirrored then
        error("sprite with body configured without enableMirroring cannot be mirrored")
    end
	
    if mirrored then 
        rotation = 360 - rotation
		rotation = -rotation
    end
    
    if bodies and sprite.body ~= bodies[mirrored] then -- swap bodies
		local oldBody = sprite.body
		sprite.body = bodies[mirrored]
		local body = sprite.body
		body:setActive(true)
		body:setLinearVelocity(oldBody:getLinearVelocity())
		-- set linear damping?
		-- set angular something?
		moveToHell(oldBody)
    end
    
    local body = sprite.body
    if body.isSlave then
        body:setLinearVelocity(0, 0)
        local x, y = sprite:localToGlobal(0, 0)
        x, y = world:globalToLocal(x, y)
        body:setPosition(x, y)
		if body.inheritRotation then
			body:setAngle(rotation * math.pi / 180)
		end
    else  -- transorm sprite according to body
        local x, y = body:getPosition()
        x, y = world:localToGlobal(x, y)
        x, y = sprite:getParent():globalToLocal(x, y)
        sprite:setPosition(x, y)
		if body.inheritRotation then
			sprite:setRotation((body:getAngle() * 180 / math.pi) - rotation)
		end
    end
end

-- Attach a physics body to a sprite. bodyConfig is a superset of bodyDef.
-- fixtureConfig is similar to fixtureDef, but has another shape handling.
function World:attachBody(sprite, bodyConfig)
    local enableMirroring = bodyConfig.enableMirroring or nil
    local bodies = {}
	local isSlave = (bodyConfig.isSlave ~= false)
    for isMirrored in all{ false, enableMirroring } do
		bodyConfig.active = false
        local body = self.physicsWorld:createBody(bodyConfig)
        body.isSlave = isSlave
		body.inheritRotation = bodyConfig.inheritRotation ~= false
        body.fixtures = {}
        local fixtureConfigs = bodyConfig.fixtureConfigs
        for fixtureConfig in all(fixtureConfigs or {}) do
			if fixtureConfig.enable ~= false then
            local fixtureDef = table.copy(fixtureConfig)
            local shape = table.deepcopy(fixtureConfig.shape)
            
            if isMirrored then
                if shape.vertices then
                    local vertices = {}
                    for x, y in va.iter(shape.vertices) do
                        table.insertall(vertices, -x, y)
                    end
                    shape.vertices = vertices
                else if shape.cx then
                        shape.cx = -shape.cx
                    end
                end
            end
			
            local type = fixtureConfig.type
            if type == 'polygon' then
				assert(#shape.vertices/2 <= 8, "#vertices == " .. tostring(#shape.vertices/2))
                local polygon = Polygon.new(unpack(shape.vertices)) -- for CW correctness
                fixtureDef.shape = b2.PolygonShape.new()
                fixtureDef.shape:set(Polygon.unpack(polygon))
            elseif type == 'chain' then
                fixtureDef.shape = b2.ChainShape.new()
                -- shape.type == "loop"/"..." ?
                fixtureDef.shape:createLoop(unpack(shape.vertices))
            elseif type == 'circle' then
                fixtureDef.shape = b2.CircleShape.new(shape.cx or 0, shape.cy or 0, assert(shape.r))
            else
                error("unknown shape.type " .. (type or "<nil>"))
            end
            
            local fixture = body:createFixture(fixtureDef)
            fixture.tag = fixtureConfig.tag
            table.insert(body.fixtures, fixture)
			end
        end
		if body.isSlave then
			moveToHell(body)
		end
        body.sprite = sprite
        bodies[isMirrored] = body
    end
    
    if enableMirroring then
        sprite.bodies = bodies
    end
    sprite.body = bodies[false]
    sprite.world = self
	local eventName = isSlave and "updateSlaves" or "updateMasters"
	self:addEventListener(eventName, updatePhysics, sprite)
end

function World:tick(deltaTime)
	local a = accelerometer
	self.physicsWorld:setGravity(a.fy * 40, a.fx * 40)
	
	local physicsDt = 1.0/application:getFps()
	physicsDt = physicsDt / 1
	self.physicsWorld:step(physicsDt, 4, 8) -- 1. physics step
	
	self:dispatchEvent(Event.new("updateMasters")) -- 2. update master bodies

	local tickEvent = Event.new("tick")
	tickEvent.deltaTime = deltaTime
	self:dispatchEvent(tickEvent) -- 3. tick event
	
	local x, y = self.ninja:getPosition()
	--self:setPosition(-x +200, -y + 100)

	self:dispatchEvent(Event.new("updateSlaves")) -- 4. update slave bodies
	
	--print ("memory used 1:"..collectgarbage("count")) 
end