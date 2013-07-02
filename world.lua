local va = require 'vertexarray'
local Polygon = require 'Polygon'

World = Core.class(Sprite)

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
    
    self:addChild(debugDraw)
    
    local s = 0.23
    s = 0.6
    s = 1.2
    --s = 1
    self:setScale(s, s)
end

function World:test_addNinja2()
    self.ninja = Entity.new("ninja", self, 150, 300)
    self.ninja.scmlEntity:setAnimation("Yes")
end

function World:addCollisionListener(name, sprite, listener, data)
    self.collisionListeners[name][sprite] = self.collisionListeners[name][sprite] or {}
    table.insert(self.collisionListeners[name][sprite], { listener, data })
end

function World:onPhysicsEvent(e)
    --print("World:onPhysicsEvent", e:getType())
    local normal = e.contact:getWorldManifold().normal
    local sprites = { 
        e.fixtureA:getBody().sprite,
        e.fixtureB:getBody().sprite
    }
    local tags = {
        e.fixtureA.tag,
        e.fixtureB.tag
    }
    for i=1,2 do
        local j = i%2 + 1
        local event = {
            sprite = sprites[i],
            otherSprite = sprites[j],
            tag = tags[i],
            otherTag = tags[j],
            --TODO: normal! reverse it?
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
        if e.vertices then
            if e.vertices.close then
                local alpha = tonumber(e.style.fill_opacity)
                local mesh = SimpleMesh.new(e.vertices, hex_color(e.style.fill), alpha, 1.9)
                local shape = { vertices = e.vertices }
                self:addChild(mesh)
                self:attachBody(mesh, { fixtureConfigs = {{ type = 'chain', shape = shape }}, })
                print("Adding simple mesh", e.vertices[1], e.vertices[2])
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
    end
    
    if bodies and sprite.body ~= bodies[mirrored] then
		local oldBody = sprite.body
		sprite.body = bodies[mirrored]
		local body = sprite.body
		body:setActive(true)
		body:setLinearVelocity(oldBody:getLinearVelocity())
		-- linear damping?
		moveToHell(oldBody)
    end
    
    local body = sprite.body
    
    if body.isSlave then
        body:setLinearVelocity(0, 0)
        local x, y = sprite:localToGlobal(0, 0)
        x, y = world:globalToLocal(x, y)
        body:setPosition(x, y)
        body:setAngle(rotation * math.pi / 180)
    else  -- transorm sprite according to body
        local x, y = body:getPosition()
        x, y = world:localToGlobal(x, y)
        x, y = sprite:getParent():globalToLocal(x, y)
        sprite:setPosition(x, y)
        sprite:setRotation((body:getAngle() * 180 / math.pi) - rotation)
    end
end

function World:addSprite_(sprite, bodyDefs) --> bodies
    self:addChild(sprite)
    local bodies = {}
    if bodyDefs then
        for bodyDef in all(bodyDefs) do
            local body = self.physicsWorld:createBody(bodyDef)
            body.isSlave = (bodyDef.isSlave ~= false)
            body.fixtures = {}
            local fixtureDefs = bodyDef.fixtureDefs
            for fixtureDef in all(fixtureDefs or {}) do
                local fixture = body:createFixture(fixtureDef)
                fixture.tag = fixtureDef.tag
                table.insert(body.fixtures, fixture)
            end
            body.sprite = sprite
            table.insert(bodies, body)
        end
    end
    sprite.bodies = bodies
    return bodies
end

-- Attach a physics body to a sprite. bodyConfig is a superset of bodyDef.
-- fixtureConfig is similar to fixtureDef, but has another shape handling.
function World:attachBody(sprite, bodyConfig)
    local enableMirroring = bodyConfig.enableMirroring or nil
    local bodies = {}
    for isMirrored in all{ false, enableMirroring } do
        local body = self.physicsWorld:createBody(bodyConfig)
        body.isSlave = (bodyConfig.isSlave ~= false)
        body.fixtures = {}
        local fixtureConfigs = bodyConfig.fixtureConfigs
        for fixtureConfig in all(fixtureConfigs or {}) do
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
                local polygon = Polygon.new(unpack(shape.vertices))
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
        body.sprite = sprite
        bodies[isMirrored] = body
    end
    
    if enableMirroring then
        sprite.bodies = bodies
    end
    sprite.body = bodies[false]
    sprite.world = self
	self:addEventListener("updatePhysics", updatePhysics, sprite)
end

function World:tick(deltaTime)
    self.physicsWorld:step(1.0/application:getFps(), 4, 8)
	local tickEvent = Event.new("tick")
	tickEvent.deltaTime = deltaTime
	self:dispatchEvent(tickEvent)
	
	local updatePhysicsEvent = Event.new("updatePhysics")
	self:dispatchEvent(updatePhysicsEvent)
	
    local function walk(sprite)
        for i=1,sprite:getNumChildren() do
            local childSprite = sprite:getChildAt(i)
            --childSprite:dispatchEvent(tickEvent)
            if childSprite.body then
                updatePhysics(self, childSprite)
            end
            walk(childSprite)
        end
    end
    --walk(self)
end