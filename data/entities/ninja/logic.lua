bodyDef = {
    type = b2.DYNAMIC_BODY,
    isSlave = false,
	--fixedRotation = true,
}

fixtureDefs = {{
        shape = b2.CircleShape.new(50, 50, 50),
		density = 1,
		restitution = 0.5,
		
		-- TODO: tag = "circle"
}}

function on_init(self, e)
    
end

function on_tick(self, e)
    
end

function on_collision(self, e) -- preSolve?
    --e.myTag
    --e.otherTag
    
end