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
	print("tick")
    if self.wallRotation then
        self.scmlEntity:setRotation(self.wallRotation)
    end
    self.wallRotation = nil
end

local i = 0

function on_preSolve(self, e)
	if e.tag == "outercircle" then
		e.contact:setEnabled(false)
	end
    --i = i + 1; print("on_preSolve", i, e.tag, e.otherTag)
    
end

local path = require 'path'

function on_postSolve(self, e)
    if e.tag == "circle" and e.otherTag == "wall" then
		print("post")
		local mesh = e.otherSprite
        local pathData = mesh.pathData
		
		assert(#e.points == 1)
		local point = e.points[1]
		point = Vector.new(point.x, point.y)
		local normalVector = Vector.new(e.normal.x, e.normal.y)
		-- normalize normalVector?

		pointDot:setPosition(point.x, point.y)
			
		-- hit path
		local m = 2 -- multiplier, dist from actual colision point
		local a = point + normalVector:normal() * m
		local b = point + normalVector:normal() * -m
		
		local d1, x1, y1, i = path.hit(a.x, a.y, pathData, mesh.pathMatrix)
		local d2, x2, y2, j = path.hit(b.x, b.y, pathData, mesh.pathMatrix)
		local d0, x0, y0, k = path.hit(point.x, point.y, pathData, mesh.pathMatrix)


		aDot:setPosition(x1, y1)
		bDot:setPosition(x2, y2)
		
        self.wallRotation = 180
        
        local angle 
		if i == j then -- casual situation
			angle = Vector.new(x2 - x1, y2 - y1):angle()
		else -- we are on a "corner", a place where two commands connect
			-- we fallback to colision's normal
			--angle = (normalVector:normal() * -1):angle()
			local vector = Vector.new(self:getPosition())
			vector = vector - point --Vector.new(x0, y0)
			vector = vector:normal()
			angle = vector:angle()
		end -- this is a bit hackish...
		
        if angle < -180 then
            angle = angle + 360
        end
        
        if abs(angle) < abs(self.wallRotation) then
            self.wallRotation = angle
        end
        
    end
end

function on_beginContact(self, e)
    
end

function on_endContact(self, e)

end

