GameplayScene = Core.class(Sprite)

local msvg = require 'msvg'

local function loadLevel(levelCode)
    print("Loading level " .. levelCode)
    local prefix = "data/levels/" .. levelCode
    local svgTree = msvg.loadFile(prefix .. "/level.svg")
    --msvg.simplifyTree(svgTree)
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

function GameplayScene:onEnterFrame(event)
    if not self.paused then
        self.world:tick(event.deltaTime)
    end
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
