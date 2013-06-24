Entity = Core.class(Sprite)

function Entity:init(name, world, x, y)
    local e = data.entities[name]
    if not e then error("No entity named " .. name) end
    
    self.world = world
    
    if e.scml then
        print("Loading scml for " .. name)
        local function scmlLoader(filename)
            local bitmap = Sprite.new()
            if filename then
                local objectName = assert(filename:match("dev_img/([^/]+)/"))
                --print("objectName", objectName)
                ok = pcall(function()
                        -- is pcall needed? dev_ layers?
                        bitmap = OffsetBitmap.new(e.layers[objectName].texture)
                        bitmap.objectName = objectName
                end)
                if not ok then 
                    print("Warning: Couldn't load bitmap for " .. filename)
                end
                local fixtures = e.layers[objectName].fixtures
                if #fixtures > 0 then
                    print("Attaching fixtures to " .. objectName)
                    local bodyDef = {
                        type = b2.DYNAMIC_BODY,
                        isSlave = true,
                    }
                    local body = world:addSprite(bitmap, bodyDef)
                    for eventName in all{"preSolve", "postSolve", "beginContact", "endContact"} do
                        local on_event = e.logic["on_" .. eventName]
                        if on_event then
                            world:addCollisionListener(eventName, bitmap, on_event, self)
                        end
                    end
                    for fixture in all(fixtures) do
                        local fixtureInstance = body:createFixture {
                            shape = fixture.shape,
                            isSensor = true
                        }
                        fixtureInstance.tag = fixture.tag
                    end
                end
            end
            
            return SCMLSprite.new(bitmap, 1/4)
        end
        self.scml = e.scml:createEntity(0, scmlLoader)
        self:addChild(self.scml)
    end
    
    if e.logic then
        if e.logic.on_tick then
            world:addEventListener("tick", e.logic.on_tick, self)
        end
        if e.logic.on_collision then
            
        end
        if e.logic.on_init then
            e.logic.on_init(self)
        end
        self.logic = e.logic
    end
	
	local bodyDef = e.logic.bodyDef
	x = x or 0
	y = y or 0
	self:setPosition(x, y)
	if bodyDef then
		bodyDef.position = bodyDef.position or {}
		bodyDef.position.x = (bodyDef.position.x or 0) + x
		bodyDef.position.y = (bodyDef.position.y or 0) + y
	end
    local body = world:addSprite(self, bodyDef)
	if body then
		for fixtureDef in all(e.logic.fixtureDefs or {}) do
			body:createFixture(fixtureDef)
		end
	end
end
