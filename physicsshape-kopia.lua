PhysicsShape = Core.class(Shape)

function PhysicsShape:init(shape, fill, stroke, bodyDef)
    self:addEventListener("enterFrame", self.onEnterFrame, self)
    
    fill = fill or {}
    stroke = stroke or {}
    bodyDef = bodyDef or {type = b2.DYNAMIC_BODY, active = true}
    self:setFillStyle(Shape.SOLID, fill.color or 0xFFFFFF, fill.alpha) 
    self:setLineStyle(stroke.width or 1, stroke.color or 0xC0C0C0, stroke.alpha)
    
    self.lock = true
    self.body = world:createBody(bodyDef)
    
    if shape.vertex ~= nil then -- simple path or polygon
        self.vertex = shape.vertex
        self:initVertex()
    elseif shape.radius ~= nil then -- circle
        self.radius = shape.radius
        self:initCircle()
    end
end

function PhysicsShape:initVertex()
    print("initVertex")
    local s = b2.PolygonShape.new()
    s:set(unpack(self.vertex))
    self.body:createFixture({shape = s, density =  1})
    
    self:beginPath()
    for i=1,#self.vertex,2 do
        local x, y = self.vertex[i], self.vertex[i + 1]
        print("x, y = ", x, y)
        self:lineTo(x, y)
    end
    
    self:closePath();
    self:endPath();
end

function PhysicsShape:initCircle()
    print("initCircle")
    local s = b2.CircleShape.new(0, 0, self.radius)
    self.body:CreateFixture({shape = s})
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