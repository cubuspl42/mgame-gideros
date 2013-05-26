PhysicsSprite = Core.class(Sprite)

-- init, initWithShapeDef, initWithSvg?
function PhysicsSprite:init(sprite, shapeDef)
    self:addEventListener("enterFrame", self.onEnterFrame, self)
    
    if sprite then self:addChild(sprite) end
    
    local bodyDef = {
        x = shapeDef.x, y = shapeDef.y,
        type = shapeDef.type or b2.STATIC_BODY,
        fixedRotation = shapeDef.fixedRotation,
        active = true
    }
    
    self.body = world:createBody(bodyDef)
    self.lock = (shapeDef.lock == nil and true) or shapeDef.lock
    
    for i, subshapeDef in ipairs(shapeDef.subshapes) do
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
    if not world or not self:getParent() then return end
    if self.lock then -- force physics body to transorm
        local x, y = self:localToGlobal(0, 0)
        x, y = world.parent:globalToLocal(x, y)
        self.body:setPosition(x, y)
        self.body:setAngle(self:getWorldRotation() * math.pi / 180) -- we assume that MainLayer doesn't rotate
    else -- transorm sprite according to body
        local x, y = self.body:getPosition()
        x, y = world.parent:localToGlobal(x, y)
        x, y = self:getParent():globalToLocal(x, y)
        self:setPosition(x, y)
        self:setWorldRotation(self.body:getAngle() * 180 / math.pi)
    end
end