bodyDef = {
    type = b2.DYNAMIC_BODY,
    isSlave = false,
    fixedRotation = true,
	fixtureDefs = {{
        shape = b2.CircleShape.new(50, 50, 50),
        density = 1,
        restitution = 0.5,
        tag = "circle"
	}}
}

function on_init(self, e)
	--self:setScale(-1, 1)
end

function on_tick(self, e)
    
end

local i = 0

function on_preSolve(self, e) -- preSolve?
	i = i + 1
    --print("on_preSolve", i, e.tag, e.otherTag)
    
end