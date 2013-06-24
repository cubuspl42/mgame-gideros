GameplayScene = Core.class(Sprite)

local msvg = require 'msvg'

local function loadLevel(levelCode)
    print("Loading level " .. levelCode)
    local prefix = "data/levels/" .. levelCode
    local svgTree = msvg.loadFile(prefix .. "/level.svg")
    msvg.simplifyTree(svgTree)
    return svgTree
end

function GameplayScene:init(levelCode) -- levelCode: e.g. "0/1"
    self:addEventListener("enterBegin", self.onTransitionInBegin, self)
    self:addEventListener("enterEnd", self.onTransitionInEnd, self)
    self:addEventListener("exitBegin", self.onTransitionOutBegin, self)
    self:addEventListener("exitEnd", self.onTransitionOutEnd, self)
    
    self:addEventListener("enterFrame", self.onEnterFrame, self)
    
    
    self.paused = false
    
    self.svgTree = loadLevel(levelCode)
    self:restartLevel()
end

function GameplayScene:restartLevel()
    if self.world then self:removeChild(self.world) end
    self.world = World.new(self.svgTree)
    self:addChild(self.world)
end

function GameplayScene:test_screenshot()
    local b = Bitmap.new(Texture.new("data/gfx/0.png", true))
    local s = 3.5
    s = 2.5
    --s = 4.76
    b:setScale(s)
    self:addChild(b)
end

function GameplayScene:test_physicsSprite()
    do return end
    local ps = PhysicsSprite.new(nil, {
            lock = false, fixedRotation = true,
            subshapes = { { cx = 50, cy = 50, radius = 50, fixture = {} } }
    }, self.world)
end



function GameplayScene:test_addNinja()
    -- SCML
    local scmlprefix = "data/entities/ninja"
    local scml = SCMLParser.loadFile(scmlprefix .. "/anim.scml")
    local dbg = false
    local function loader(filename)
        local ok, b 
        if filename then
            filename = filename:gsub("dev_", "")
            ok, b = pcall(function()
                    return OffsetBitmap.new(Texture.new(scmlprefix .. filename, true))
            end)
            if not ok then b = nil end
        end
        local s = SCMLSprite.new(b, 4)
        if dbg then 
            for i = 1,2 do
                a = Shape.new()
                a:setLineStyle(3, i==1 and 0xFF0000 or 0x00FF00)
                a:beginPath()
                a:moveTo(0, 0)
                a:lineTo(i==2 and 0 or 30, i==1 and 0 or 30)
                a:endPath()
                s:addChild(a)
            end
        end
        return s
    end
    
    
    local ninja = scml:createEntity(0, loader)
    local x, y = 2000, 3180
    x, y = 100, 100
    ninja:setPosition(x, y)
    ninja:setAnimation("Run") -- TEMP
    ninja.anim.paused = true
    self:addChild(ninja)
end

function GameplayScene:loadConfig(xmlConfig)
    
end

function GameplayScene:setPaused(flag)
    self.paused = flag
end

function GameplayScene:onTouch(e)
    if e.touch.id ~= 1 then return end
    local x, y = e.touch.rx, e.touch.ry
    --print("onTouch x, y", x, y)
    if self.prevTouchX then
        local px, py = self:getPosition()
        local dx, dy = x - self.prevTouchX, y - self.prevTouchY
        --print("dx, dy", dx, dy)
        self:setPosition(px + dx, py + dy)
    end
    self.prevTouchX, self.prevTouchY = x, y
end

function GameplayScene:onTouchEnd(e)
    if e.touch.id ~= 1 then return end
    self.prevTouchX, self.prevTouchY = nil, nil
end

function GameplayScene:onEnterFrame()
    if not self.paused then
        local tickEvent = Event.new("tick")
        self.world:dispatchEvent(tickEvent)
    end
end

function GameplayScene:onBeginContact()
    
end

function GameplayScene:onEndContact()
    
end

function GameplayScene:onPreSolve()
    
end

function GameplayScene:onPostSolve()
    
end

function GameplayScene:onTransitionInBegin()
    print("GameplayScene - enter begin")
end

function GameplayScene:onTransitionInEnd()
    print("GameplayScene - enter end")
end

function GameplayScene:onTransitionOutBegin()
    print("GameplayScene - exit begin")
end

function GameplayScene:onTransitionOutEnd()
    print("GameplayScene - exit end")
end
