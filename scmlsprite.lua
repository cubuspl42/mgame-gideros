SCMLSprite = Core.class(Sprite)

function SCMLSprite:init(sprite)
    if not sprite then return end
    self.sprite = sprite
    self:addChild(sprite)
end

function SCMLSprite:setParam(k, v)
    if not self.sprite and k == "scaleX" or k == "scaleY" then return end
    if k == "pivotX" or k == "pivotY" then
        local s = self.sprite
        if s then
            local a = (k == "pivotX" and "x") or "y"
            local f = (k == "pivotX" and "getWidth") or "getHeight"
            if k == "pivotY" then v = 1 - v end
            s:set(a, (-s[f](s)*v))
        end
        return
    end
    if not self["set" .. string.firstToUpper(k)] then
        print("cannot set param " .. k)
        return
    end
    if k == "y" or k == "rotation" then v = -v end
    self:set(k, v)
end