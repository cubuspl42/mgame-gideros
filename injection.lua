require 'Matrix'

function string.firstToUpper(str)
    return (str:gsub("^%l", string.upper))
end

function string.starts(String,Start)
    return string.sub(String,1,string.len(Start))==Start
end

function table.contains(t, k)
    return t[k] ~= nil
end

function table.copy(t)
    local t2 = {}
    for k,v in pairs(t) do
        t2[k] = v
    end
    return t2
end

function table.reversed(tab)
    local size = #tab
    local newTable = {}
    
    for i,v in ipairs (tab) do
        newTable[size-i+1] = v
    end
    
    return newTable
end

function table.merge(t1, t2)
    for k,v in pairs(t2) do t1[k] = v end
end

function table.insertall(t, ...)
    for _, v in ipairs(arg) do
        table.insert(t, v)
    end
end

function Application:getSpf()
    return 1/self:getFps()
end

function Application:getMspf()
    return 1000/self:getFps()
end

function os.timems()
    return os.timer() * 1000
end

local super_stopPropagation = Event.stopPropagation
function Event:stopPropagation()
    if self.broadcast ~= nil then
        self.broadcast = false
    end
    super_stopPropagation(self)
end

local super_dispatchEvent = EventDispatcher.dispatchEvent
function dispatchEvent(self, event)
    --print (tostring(self), "_dispatchEvent", event:getType())
    super_dispatchEvent(self, event)
    if event.broadcast ~= nil then -- we have custom 
        for i=1, self:getNumChildren() do
            if not event.broadcast then break end
            local c = self:getChildAt(i)
            dispatchEvent(c, event)
        end
    end
end

function Sprite:getWorldRotation()
    local parent = self:getParent()
    local r = self:getRotation()
    while parent do
        r = r + parent:getRotation()
        parent = parent:getParent()
    end
    return r
end

function Sprite:setWorldRotation(r)
    local family = {}
    local parent = self:getParent()
    while parent do
        table.insert(family, 1, parent)
        parent = parent:getParent()
    end
    for i, v in ipairs(family) do
        r = r - v:getRotation();
    end
    self:setRotation(r)
end

function Sprite:rotateAroundPoint(cx, cy, angle)
    s = math.sin(-angle * math.pi / 180); -- CCW -> CW
    c = math.cos(-angle * math.pi / 180);
    self:setRotation(self:getRotation() + angle)
    
    x, y = self:getPosition()
    x = (x - cx) * c - (y - cy) * s + cx;
    y = (x - cx) * s + (y - cy) * c + cy;
    self:setPosition(x, y)
end
