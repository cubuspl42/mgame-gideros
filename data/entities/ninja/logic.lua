bodyConfig = {
    type = b2.DYNAMIC_BODY,
    --enableMirroring = true,
    isSlave = false,
    fixedRotation = true,
    fixtureConfigs = {{
            type = "circle",
            shape = {
                --cx = 0, cy = 0,
                r = 50
            },
            --[[
		type = "polygon",
		shape = {
			vertices = 
		},
		--]]
            density = 1,
            restitution = 0.5,
            tag = "circle",
    }}
}

function on_init(self, e)
    --self.scmlEntity:setScale(-1, 1)
end

function on_tick(self, e)
    
end

local i = 0

function on_preSolve(self, e) -- preSolve?
    i = i + 1
    --print("on_preSolve", i, e.tag, e.otherTag)
    
end