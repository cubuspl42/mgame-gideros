Entity = Core.class(Sprite)

function Entity:init(name, world, x, y, userData)
    local enityData = data.entities[name]
    if not enityData then error("No entity named " .. name) end
    
    self.world = world
    
    if enityData.scml then
        print("Loading scml for " .. name)
        local function scmlLoader(filename)
            local bitmap = Sprite.new()
			bitmap.objectName = "<object_name>"
			bitmap.entity = self
			-- if filename is nil, it's (probably) bone
            if filename then
                local objectName = assert(filename:match("dev_img/([^/]+)/"))
                --print("objectName", objectName)
                local ok = pcall(function()
                        -- is pcall needed? dev_ layers?
                        bitmap = OffsetBitmap.new(enityData.layers[objectName].texture)
						bitmap.objectName = objectName
                end)
                if not ok then 
                    print("Warning: Couldn't load bitmap for " .. filename)
                end
                local fixtureDefs = enityData.layers[objectName].fixtureDefs
                if #fixtureDefs > 0 then
                    print("Attaching fixtures to " .. objectName)
                    local bodyDef = {
                        type = b2.DYNAMIC_BODY,
                        isSlave = true,
						fixtureDefs = fixtureDefs,
                    }
                    local body = world:addSprite(bitmap, {bodyDef})
                    for eventName in all{"preSolve", "postSolve", "beginContact", "endContact"} do
                        local on_event = enityData.logic["on_" .. eventName]
                        if on_event then
                            world:addCollisionListener(eventName, bitmap, on_event, self)
                        end
                    end
                end
            end
            return SCMLSprite.new(bitmap, 1/4)
        end
        self.scmlEntity = enityData.scml:createEntity(0, scmlLoader)
        self:addChild(self.scmlEntity)
    end
    
    if enityData.logic then
        if enityData.logic.on_tick then
            self:addEventListener("tick", enityData.logic.on_tick, self)
        end
        if enityData.logic.on_touch then
            self:addEventListener("mouseDown", enityData.logic.on_touch, self)
        end
        if enityData.logic.on_init then
            enityData.logic.on_init(self, userData)
        end
        self.logic = enityData.logic
    end
    
    x = x or 0
    y = y or 0
    self:setPosition(x, y)
    
    local bodyDef = enityData.logic.bodyDef
    if bodyDef then
        bodyDef.position = bodyDef.position or {}
        bodyDef.position.x = (bodyDef.position.x or 0) + x
        bodyDef.position.y = (bodyDef.position.y or 0) + y
    end
    
    local body = world:addSprite(self, {bodyDef})
    if body then
        for eventName in all{"preSolve", "postSolve", "beginContact", "endContact"} do
            local on_event = enityData.logic["on_" .. eventName]
            if on_event then
                world:addCollisionListener(eventName, self, on_event, self)
            end
        end
    end
end
