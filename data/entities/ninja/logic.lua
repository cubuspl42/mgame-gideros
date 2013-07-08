local path = require 'path'
local abs = math.abs

bodyConfig = {
    type = b2.DYNAMIC_BODY,
    --enableMirroring = true,
    allowSleep = false,
    isSlave = false,
    fixedRotation = true,
	inheritRotation = false,
    fixtureConfigs = {
		{
            type = "circle",
            shape = {
                r = 48
            },
            density = 1,
            friction = 0.1,
            restitution = 0,
            tag = "circle",
		},
	}
}

local dotScale = 0.5
local aDot = ShapePoint.new(0xFF0000, dotScale)
local bDot = ShapePoint.new(0x00FF00, dotScale)
local pointDot = ShapePoint.new(0x0000FF, dotScale)

function on_init(self, e)
	if dbg > 0 then
		self.world:addChild(aDot)
		self.world:addChild(bDot)
		--self.world:addChild(pointDot)
	end



	
    --self.scmlEntity:setScale(-1, 1)
    self.scmlEntity:setAnimation("Idle")
end

local i = 0

function on_tick(self, e)
	local velocityEps = 0.01
	local velocity = Vector.new(self.body:getLinearVelocity())
	if abs(velocity.x) > velocityEps then
		local scaleX = 1
		if velocity.x < 0 then scaleX = -scaleX end
		self.scmlEntity:setScaleX(scaleX) 
	end
	
	local mesh = self.wallMesh
	if mesh then
		local x, y = self:getPosition()
		local positionVector = Vector.new(x, y)
		local d0, x0, y0 = path.hit(x, y, mesh.pathData, mesh.pathMatrix)
		local hitPoint = Vector.new(x0, y0)
		local d = (positionVector - hitPoint):len()
		local r = bodyConfig.fixtureConfigs[1].shape.r
		local d1 = r + 5
		
		aDot:setPosition(x0, y0)
		print(d0, d, d1)
		
		if d < d1 then
			local vector = positionVector:clone()
			vector = vector - hitPoint
			vector = vector:normal()
			self.scmlEntity:setRotation(vector:angle())
		else
			self.wallMesh = nil
		end
	end
	self.wallRotation = nil
end

function on_preSolve(self, e)
    if e.tag == "circle" and e.otherTag == "wall" then
	end    
end

local path = require 'path'

function on_postSolve(self, e)
    if e.tag == "circle" and e.otherTag == "wall" then
	    self.wallRotation = self.wallRotation or 181
		local normal = Vector.new(e.normal.x, e.normal.y)
        local angle = (normal:normal() * -1):angle()
		
        if angle < -180 then
            angle = angle + 360
        end
		assert(abs(angle) <= 180)

        if abs(angle) < abs(self.wallRotation) then
            self.wallRotation = angle
			self.wallMesh = e.otherSprite
        end
    end
end

function on_beginContact(self, e)
    
end

function on_endContact(self, e)

end

