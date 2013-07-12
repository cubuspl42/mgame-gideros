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
    self.scmlEntity:setAnimation("jump")
end

local i = 0

function on_tick(self, event)

    local body = self.body
	local scmlEntity = self.scmlEntity

    local scaleX = 0
    local angle = nil
	local scmlDeltaTime = event.deltaTime * 1000
	local force = Vector.new(0, 0)

	local animName = scmlEntity.animName
	local prev_animName = animName
	
	local prev_state = self.state
    local state = prev_state

    local velocity = Vector.new(self.body:getLinearVelocity())
	local velocity_sgn = math.sgn(velocity.x)
	local max_velocity = 5

    local direction = event.direction
	
	status:append(velocity.x, velocity.y)
    
	-- try to get angle between ninja and wall
    local wallMesh = self.wallMesh
    if wallMesh then -- if we remember some wall
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
            self.wallMesh = nil -- he's too far, let's forget about that wall
        end
    end
    
    if angle then -- we've found that angle...
        if abs(angle) < 90 then -- ninja is on his feet
            state = "on_ground"        
        elseif abs(angle) == 90 then -- ninja could be sliding on the wall
			-- if he is going toward that wall
            if math.sgn(angle) == -direction and velocity.y > 0 then
                state = "on_wall"
            elseif prev_state ~= "on_wall" then -- ...but he is not
                state = "in_air"
            end
        else -- ninja is touching wall with his head or not touching any wall at all
			state = "in_air"
		end
    else
        state = "in_air"
    end
		
	if state == "in_air" then -- we don't honor angle between a wall and ninja
		angle = scmlEntity:getRotation()
		-- to zero...
		force.x = 1
	else
		force.x = 5
	end
	
	if direction == 0 then
		if abs(velocity.x) > force.x then
			force.x = -velocity_sgn * force.x
		end
	else
		force.x = force.x * direction
	end
	    
    if state == "on_wall" then
        scaleX = -math.sgn(angle)
		angle = angle - math.sgn(angle) * 90
    elseif abs(velocity.x) > 0.001 or velocity_sgn == direction then
		scaleX = math.sgn(velocity.x)
    end
	
	if scaleX ~= 0 then
        scmlEntity:setScaleX(scaleX)
    end
    scmlEntity:setRotation(angle)
    
    if state == "on_ground" then
		if direction ~= 0 then
			if direction == velocity_sgn and abs(velocity.x) > 0.000001 then
				animName = "run"
				scmlDeltaTime = scmlDeltaTime * (velocity:len() / max_velocity)
			else
				animName = "brake"
			end
		else
			if abs(velocity.x) > 0.001 then
				animName = "brake"
			else
				animName = "idle"
			end
		end
	end
    
	if prev_animName ~= animName then
		scmlEntity:setAnimation(animName)
	end
	scmlEntity:step(scmlDeltaTime)
	
	if abs(velocity.x) > max_velocity then
		velocity.x = velocity_sgn * max_velocity
	end
	
	body:setLinearVelocity(velocity:unpack())
	if direction ~= 0 then
		body:applyForce(force.x, force.y, body:getWorldCenter())
	end
	
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
            self.wallMesh = e.otherSprite -- let's remember that wall
        end
    end
end

function on_beginContact(self, e)
    
end

function on_endContact(self, e)
    
end

