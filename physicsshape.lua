PhysicsShape = Core.class(Sprite)

-- init, initWithShapeDef, initWithSvg?
function PhysicsShape:init(shapeDef)
    self:addEventListener("enterFrame", self.onEnterFrame, self)
    
    local bodyDef = {
        type = shapeDef.type or b2.DYNAMIC_BODY,
        fixedRotation = shapeDef.fixedRotation,
        active = true
    }
    self.body = world:createBody(bodyDef)
    self.lock = (shapeDef.lock == nil and true) or shapeDef.lock
    
    for i, subshapeDef in ipairs(shapeDef.subshapes) do
        self:createSubshape(subshapeDef)
    end
end

function PhysicsShape:createSubshape(subshapeDef)
    local fill = subshapeDef.fill or {}
    local stroke = subshapeDef.stroke or {}
    shape = Shape.new()
    shape:setFillStyle(Shape.SOLID, fill.color or 0xFFFFFF, fill.alpha) 
    shape:setLineStyle(stroke.width or 1, stroke.color or 0, stroke.alpha or 1)
    if subshapeDef.vertices then
        self:createPolygon(subshapeDef, shape)
    elseif subshapeDef.radius then
        self:createCircle(subshapeDef, shape)
    end
    self:addChild(shape)
    
end

function PhysicsShape:createPolygon(subshapeDef, shape)
    local fixture = subshapeDef.fixture
    local vertices = subshapeDef.vertices
    if fixture then
        local s = b2.PolygonShape.new()
        s:set(unpack(vertices))
        self.body:createFixture {
            shape = s,
            density = fixture.density or 1,
            friction = fixture.friction,
            restitution = fixture.restitution
        }
    end
    
    shape:beginPath()
    for i=1,#vertices,2 do
        local x, y = vertices[i], vertices[i + 1]
        print("x, y = ", x, y)
        shape:lineTo(x, y)
    end
    shape:closePath();
    shape:endPath();
end

function PhysicsShape:createCircle(subshapeDef, shape)
    local fixture = subshapeDef.fixture
    local r = subshapeDef.radius
    if fixture then
        local s = b2.CircleShape.new(subshapeDef.cx or 0, subshapeDef.cy or 0, r)
        self.body:createFixture {
            shape = s,
            density = fixture.density or 1,
            friction = fixture.friction,
            restitution = fixture.restitution
        }
    end
    
    -- Shape - visual?
end

function PhysicsShape:onEnterFrame()
    if self.lock then -- force physics body to transorm
        self.body:setPosition(self:localToGlobal(0, 0))
        self.body:setAngle(self:getWorldRotation() * math.pi / 180)
    else -- transorm sprite according to body
        self:setPosition(
            --self:globalToLocal(
            self.body:getPosition()
            --)
        )
        self:setWorldRotation(self.body:getAngle() * 180 / math.pi)
    end
end