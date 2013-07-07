local abs = math.abs

bodyConfig = {
    type = b2.DYNAMIC_BODY,
    --enableMirroring = true,
    allowSleep = false,
    isSlave = false,
    fixedRotation = true,
    fixtureConfigs = {{
            type = "circle",
            shape = {
                r = 48
            },
            density = 1,
            friction = 0.06,
            restitution = 0,
            tag = "circle",
    }}
}

local aDot = ShapePoint.new()
local bDot = ShapePoint.new(0x00FF00)
local pointDot = ShapePoint.new(0x0000FF)

function on_init(self, e)
	if dbg > 0 then
		self.world:addChild(pointDot)
		self.world:addChild(aDot)
		self.world:addChild(bDot)
	end



	
    --self.scmlEntity:setScale(-1, 1)
    self.scmlEntity:setAnimation("Idle")
end

function on_tick(self, e)
    if self.wallRotation then
        self.scmlEntity:setRotation(self.wallRotation)
    end
    self.wallRotation = nil
end

local i = 0

function on_preSolve(self, e) -- preSolve?
    --i = i + 1; print("on_preSolve", i, e.tag, e.otherTag)
    
end

local path = require 'path'

function on_postSolve(self, e) -- preSolve?
    if e.tag == "circle" and e.otherTag == "wall" then
		local mesh = e.otherSprite
        local pathData = mesh.pathData
		
		local point = e.points[1]
		point = Vector.new(point.x, point.y)
		local normalVector = Vector.new(e.normal.x, e.normal.y)
		--normalVector = normalVector * 100
		--normalVector:normalize()
		pointDot:setPosition(point.x, point.y)
			
		-- hit path
		local m = 10
		local a = point + normalVector:normal() * m
		local b = point + normalVector:normal() * -m
		local d1, x1, y1, i = path.hit(a.x, a.y, pathData, mesh.pathMatrix)
		local d2, x2, y2, j = path.hit(b.x, b.y, pathData, mesh.pathMatrix)

		aDot:setPosition(x1, y1)
		bDot:setPosition(x2, y2)
		
        self.wallRotation = self.wallRotration or 180
        
        local angle 
		if i == j then
			angle = Vector.new(x2 - x1, y2 - y1):angle()
		else
			angle = (normalVector:normal() * -1):angle()
		end
        if angle < -180 then
            angle = angle + 360
        end
        
        --i = i + 1;print(i, angle)
        
        if abs(angle) < abs(self.wallRotation) then
            self.wallRotation = angle
        end
        
    end
end

function on_beginContact(self, e)
    --i = i + 1;print("on_beginContact", i, e.tag, e.otherTag)
    
end

local j = 0
function on_endContact(self, e)
	if e.tag == "circle" then
		j = j + 1
		--print(j, "on_endContact", e.tag, e.otherTag)
	end
end

