SCMLEntity = Core.class(Sprite)

function SCMLEntity:init()
    self:addEventListener("enterFrame", self.onEnterFrame, self)
end

function SCMLEntity:setAnimation(animName)
    if self.anim then self:removeChild(self.anim) end
    self.anim = self.animations[animName]
    self.anim.index = 0
    self:addChild(self.anim)
    self.starttime = os.timems()
end

function SCMLEntity:nextKeyAndTime(object)
    local nextKey = object.keys[object.index + 1]
    local nextTime
    if not nextKey then
        nextKey = object.keys[1]
        nextTime = self.anim.length
    else nextTime = nextKey.time end
    return nextKey, nextTime
end

local function linearInterpolation(v1, v2, t1, t2, t)
    local r = v1 + (v2 - v1) * (t - t1) / (t2 - t1)
    return r
end

function SCMLEntity:onEnterFrame()
    local anim = self.anim
    if not anim then return end -- TODO: or anim paused?
    
    -- Looping
    local time = os.timems() - self.starttime
    if time >= anim.length then
        if not anim.looping then return end
        anim.index = 1
        while time >= anim.length do
            time = time - anim.length
        end
        self.starttime = os.timems()
    end
    
    local mainKey = anim.keys[anim.index]
    local prevMainKey = mainKey
    
    -- Move to next frame?
    local nextMainKey, nextMainTime = self:nextKeyAndTime(anim)
    while time >= nextMainTime do
        mainKey = nextMainKey
        anim.index = anim.index + 1
        nextMainKey, nextMainTime = self:nextKeyAndTime(anim)
    end
    
    -- Recreate hierarchy
    if prevMainKey ~= mainKey then 
        for _, object in ipairs(anim.objects) do
            if object:getParent() == anim then
                anim:removeChild(object)
            end
        end
        for _, ref in ipairs(mainKey.refs) do
            anim:addChild(ref.object)
        end
    end
    
    -- Update objects
    for _, ref in ipairs(mainKey.refs) do
        local object = ref.object
        object.index = ref.index
        local key = object.keys[object.index]
        local nextKey, nextTime = self:nextKeyAndTime(object)
        if nextKey.time < time and not anim.looping then nextKey = key end
        
        -- Swap sprite
        if object.sprite ~= key.sprite then
            if object.sprite then 
                object:removeChild(object.sprite)
                object:addChild(key.sprite) 
            end
            object.sprite = key.sprite
        end
        
        -- Perform linear linerpolation
        local params = {}
        object.params = params
        for k, param in pairs(key.params) do
            local nextParam = nextKey.params[k]
            local spin = key.spin
            if k == "rotation" and (nextParam - param) * spin < 0 then
                nextParam = nextParam + spin * 360
            end
            params[k] = linearInterpolation(param, nextParam, key.time, nextTime, time)
        end
        
        -- Parentness
        local p = params
        if ref.parent then
            local pp = ref.parent.params -- it should have been already created
            p.scaleX = p.scaleX * pp.scaleX
            p.scaleY = p.scaleY * pp.scaleY
            p.rotation = p.rotation + pp.rotation
            p.x = p.x * pp.scaleX
            p.y = p.y * pp.scaleY
            local s = math.sin(pp.rotation * math.pi / 180)
            local c = math.cos(pp.rotation * math.pi / 180)
            local px, py = p.x, p.y
            p.x = (px * c) - (py * s)
            p.y = (px * s) + (py * c)
            p.x = p.x + pp.x
            p.y = p.y + pp.y
        end
        for k, v in pairs(params) do
            if object.sprite then object.sprite:setParam(k, v) end
        end 
    end
end
