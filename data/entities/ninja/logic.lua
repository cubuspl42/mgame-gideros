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

function on_init(self, e)
    self.scmlEntity:setScale(-1, 1)
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

function on_postSolve(self, e) -- preSolve?
    if e.tag == "circle" and e.otherTag == "wall" then
        
        self.wallRotation = self.wallRotation or 180
        
        local angle = Vector.new(e.normal):angle() - 90
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
		print(j, "on_endContact", e.tag, e.otherTag)
	end
end

