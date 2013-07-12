Entity = Core.class(Sprite)

function Entity:init(name, world, x, y, userData)
    local enityData = data.entities[name]
    if not enityData then error("No entity named " .. name) end
    
    self.world = world
    world:addChild(self)
    
    if enityData.scml then
        print("Loading scml for " .. name)
        local function scmlLoader(filename)
            local bitmap = Sprite.new()
            bitmap.objectName = "<bone>"
            -- if filename is nil, it's (probably) bone
            if filename then
                local objectName = assert(filename:match("dev_img/([^/]+)/"))
                --print("objectName", objectName)
                -- errors on unexisting dev_ layers
                local ok, msg = pcall(function()
                        bitmap = OffsetBitmap.new(enityData.layers[objectName].texture)
                        bitmap.objectName = objectName
                end)
                if not ok then 
                    print("Warning: Couldn't load bitmap for " .. filename)
                end
                local fixtureConfigs = enityData.layers[objectName].fixtureConfigs
                if #fixtureConfigs > 0 then
                    print("Attaching fixtures to " .. objectName)
                    local bodyConfig = {
                        type = b2.DYNAMIC_BODY,
                        isSlave = true,
                        enableMirroring = true,
                        fixtureConfigs = fixtureConfigs,
                    }
                    world:attachBody(bitmap, bodyConfig)
                    for eventName in all{"preSolve", "postSolve", "beginContact", "endContact"} do
                        local on_event = enityData.logic["on_" .. eventName]
                        if on_event then
                            world:addCollisionListener(eventName, bitmap, on_event, self)
                        end
                    end
                end
            end
            bitmap.entity = self
            return SCMLSprite.new(bitmap, 1/4)
        end
        self.scmlEntity = enityData.scml:createEntity(0, scmlLoader)
        self:addChild(self.scmlEntity)
    end
    
    if enityData.logic then
        if enityData.logic.on_tick then
            world:addEventListener("tick", enityData.logic.on_tick, self)
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
    
    local bodyConfig = enityData.logic.bodyConfig
    if bodyConfig then
        self.entity = self
        bodyConfig.position = bodyConfig.position or {}
        bodyConfig.position.x = (bodyConfig.position.x or 0) + x
        bodyConfig.position.y = (bodyConfig.position.y or 0) + y
        
        world:attachBody(self, bodyConfig)
        for eventName in all{"preSolve", "postSolve", "beginContact", "endContact"} do
            local on_event = enityData.logic["on_" .. eventName]
            if on_event then
                world:addCollisionListener(eventName, self, on_event, self)
            end
        end
    end
end
