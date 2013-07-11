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

local dotScale = 2
local redDot = ShapePoint.new(0xFF0000, dotScale)

function on_init(self, e)
    if dbg > 0 then
        self.world:addChild(redDot)
    end
    
    self.state = "on_ground"
    self.scmlEntity:setAnimation("run")
end

local i = 0

function on_tick(self, event)
    local angle = nil
    local velocity = Vector.new(self.body:getLinearVelocity())
    local body = self.body
    local prev_state = self.state
    local state = prev_state
    local direction = event.direction
    
    local wallMesh = self.wallMesh
    if wallMesh then
        local x, y = self:getPosition()
        local positionVector = Vector.new(x, y)
        local _, x0, y0 = path.hit(x, y, wallMesh.pathData, wallMesh.pathMatrix)
        local hitPoint = Vector.new(x0, y0)
        
        local d = (positionVector - hitPoint):len()
        local r = bodyConfig.fixtureConfigs[1].shape.r
        local dmax = r + 3
        
        -- we consider them still touching if d < dmax, although box2d does not
        if d < dmax then
            local vector = positionVector:clone()
            vector = vector - hitPoint
            angle = vector:normal():angle()
        else
            self.wallMesh = nil -- we're too far; let's forget about that wall
        end
    end
    
    if angle then
        if abs(angle) < 90 then -- ninja is on his feet
            state = "on_ground"        
        elseif abs(angle) == 90 then -- ninja could be sliding on the wall
			-- if he is going toward that wall
            if math.sgn(angle) == -direction and velocity.y > 0 then
                state = "on_wall"
            elseif prev_state ~= "on_wall" then -- ...but he is not
                state = "in_air"
            end
        end -- ninja is touching wall with his head or not touching any wall at all
    else
        angle = self.scmlEntity:getRotation()
        state = "in_air"
    end
	    
    local scaleX = 0
    if state == "on_wall" then
        scaleX = -math.sgn(angle)
		angle = angle - math.sgn(angle) * 90
    else
		if abs(velocity.x) > 0.2 then
			scaleX = math.sgn(velocity.x)
		end
    end
	
	if state == "in_air" then
		
	end
	
    if scaleX ~= 0 then
        self.scmlEntity:setScale(scaleX, 1)
    end

    self.scmlEntity:setRotation(angle)
    
    if direction ~= 0 then
        local force = Vector.new(0, 0)
        if state == "on_ground" then
            force.x = 50
        else
            force.x = 5
        end
        force.x = force.x * direction
        body:applyForce(force.x, force.y, body:getWorldCenter())
    end
	
	local max_velocity = 15
	if abs(velocity.x) > max_velocity then
		velocity.x = math.sgn(velocity.x) * max_velocity
	end
    
    if state == "on_ground" then
        
    elseif state == "on_wall" then
        
    elseif state == "in_air" then
        
    else error(state) end
    
	body:setLinearVelocity(velocity:unpack())
    self.state = state
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

