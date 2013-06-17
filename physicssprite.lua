PhysicsSprite = Core.class(Sprite)

-- PhysicsSprite [PS] can be inserted into Sprite tree
-- It assumes that world.parent is not rotated

-- If PS is unlocked, its child sprite is slave and body is master
-- If PS is locked, its body is master and child sprite is slave
-- all child sprites should be in world.parent's Sprite tree

--[[ example shapeDef and (default values)
{
	x = 10, -- (nil)
	y = 20, -- (nil)
	type = b2.DYNAMIC_BODY, -- (b2.STATIC_BODY),
	fixedRotation = false, -- (nil)
	subshapes = {
		{
			vertices = {0, 0, 10, 0, 10, 10} -- for polygon; clockwise!
			-- OR
			radius = 5 -- for circle
			cx = 2 (0)
			cy = 2 (0)
			
			fixture = {
				density = 20, -- (1)
				friction = 10, -- (nil)
				restitution = 5, -- (nil)
			}
		}, -- ...
	}
}
--]]

function PhysicsSprite:init(childSprite, shapeDef, world)
    self:addEventListener("enterFrame", self.onEnterFrame, self)
    if childSprite then self:addChild(childSprite) end
    
    local bodyDef = {
        x = shapeDef.x, y = shapeDef.y,
        type = shapeDef.type or b2.STATIC_BODY,
        fixedRotation = shapeDef.fixedRotation,
        active = true
    }
    
	self.world = world
    self.body = world:createBody(bodyDef)
	
	-- change naming to shapeDef.physicsMode = "master"|"slave"?
    self.lock = (shapeDef.lock == nil and true) or shapeDef.lock
    
    for subshapeDef in all(shapeDef.subshapes) do
        self:createSubshape(subshapeDef)
    end
end

function PhysicsSprite:createSubshape(subshapeDef)
    if subshapeDef.vertices then
        self:createPolygon(subshapeDef, shape)
    elseif subshapeDef.radius then
        self:createCircle(subshapeDef, shape)
    end
end

function PhysicsSprite:createPolygon(subshapeDef)
    local fixture = subshapeDef.fixture or {}
    local vertices = subshapeDef.vertices
    local s = b2.PolygonShape.new()
    s:set(unpack(vertices))
    self.body:createFixture {
        shape = s,
        density = fixture.density or 1,
        friction = fixture.friction,
        restitution = fixture.restitution
    }
end

function PhysicsSprite:createCircle(subshapeDef)
    local fixture = subshapeDef.fixture or {}
    local r = subshapeDef.radius
    local s = b2.CircleShape.new(subshapeDef.cx or 0, subshapeDef.cy or 0, r)
    self.body:createFixture {
        shape = s,
        density = fixture.density or 1,
        friction = fixture.friction,
        restitution = fixture.restitution
    }
end

function PhysicsSprite:onEnterFrame()
	local world = self.world
    if not world or not self:getParent() then return end
    if self.lock then -- force physics body to transorm
        local x, y = self:localToGlobal(0, 0)
        x, y = world.parent:globalToLocal(x, y)
        self.body:setPosition(x, y)
        self.body:setAngle(self:getWorldRotation() * math.pi / 180) -- we assume that world.parent doesn't rotate
    else -- transorm sprite according to body
        local x, y = self.body:getPosition()
        x, y = world.parent:localToGlobal(x, y)
        x, y = self:getParent():globalToLocal(x, y)
        self:setPosition(x, y)
        self:setWorldRotation(self.body:getAngle() * 180 / math.pi)
    end
end