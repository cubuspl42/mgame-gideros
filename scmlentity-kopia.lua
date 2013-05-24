SCMLEntity = Core.class(Sprite)

function SCMLEntity:init()
    self:addEventListener("enterFrame", self.onEnterFrame, self)
    
    self._time = 0
end

function SCMLEntity:setAnimation(animName)
    if self._anim then self:removeChild(self._anim) end
    self._anim = self._animations[animName]
    self:addChild(self._anim)
    
end

function SCMLEntity:nextKeyAndTime(object, index)
    local nextKey = object.keys[index + 1]
    local nextTime
    if not nextKey then
        nextKey = object.keys[1]
        nextTime = self._anim.length
    else nextTime = nextKey.time end
    
    return nextKey, nextTime
end

local function linearInterpolation(v1, v2, t1, t2, t)
    local r = v1 + (v2 - v1) * (t - t1) / (t2 - t1)
    --print(r)
    return r
end

function SCMLEntity:onEnterFrame()
    self._time = self._time + application:getMspf()
    local anim = self._anim
    
    if self._time >= anim.length then
        if not anim.looping then return end
        for _, object in ipairs(anim.objects) do
            object.index = 1
        end
        while self._time >= anim.length do
            self._time = self._time - anim.length
        end
    end
    local time = self._time
    
    for _, object in ipairs(anim.objects) do
        local key = object.keys[object.index]
        local nextKey, nextTime = self:nextKeyAndTime(object, object.index)
        if nextKey.time > key.time or anim.looping then
            while time >= nextTime do
                object.index = object.index + 1
                key = nextKey
                nextKey, nextTime = self:nextKeyAndTime(object, object.index)
            end
            
            if object.sprite ~= key.sprite then
                if object.sprite then object:removeChild(object.sprite) end
                object.sprite = key.sprite
                object:addChild(object.sprite)
            end
            local params = table.copy(key.params)
            for k, _ in pairs(key.params) do
                -- move object cx, cy? TODO
                local nextParam = nextKey.params[k]
                local spin = -key.spin
                if k == "rotation" and (nextParam - key.params[k]) * spin < 0 then
                    nextParam = nextParam + spin * 360
                end
                params[k] = linearInterpolation(key.params[k], nextParam, key.time, nextTime, time)
                --if(object.name == "torso_0") then
                --print(index, key.params[k], nextKey.params[k], key.time, nextTime, time)
                --print("object " .. object.name .. ": " .. k .. " = " .. params[k])
                --end
                if object["set".. string.firstToUpper(k)] then
                    if k ~= "scaleX" and k~= "scaleY" then
                        object:set(k, params[k])
                    end
                end
            end
            if object.sprite then object.sprite:setAnchorPoint(params.pivotX, 1 - params.pivotY) end
        end
    end
    
end
