GameplayScene = Core.class(Sprite)

function GameplayScene:init(levelCode) -- levelCode: e.g. "0/1"
    self:addEventListener("enterBegin", self.onTransitionInBegin, self)
    self:addEventListener("enterEnd", self.onTransitionInEnd, self)
    self:addEventListener("exitBegin", self.onTransitionOutBegin, self)
    self:addEventListener("exitEnd", self.onTransitionOutEnd, self)
    
    self:addEventListener("enterFrame", self.onEnterFrame, self)
    self:addEventListener("logic", self.onLogic, self)
    self:addEventListener("touchesMove", self.onTouch, self)
    self:addEventListener("touchesEnd", self.onTouchEnd, self)
    
    self.paused = false
    self.contactListeners = {}
    local debugDraw = b2.DebugDraw.new()
    
    self.world = b2.World.new(0, 10)
    self.world:setDebugDraw(debugDraw)
    self.world.parent = self
    
    self.world:addEventListener("preSolve", self.onPreSolve, self)
    self.world:addEventListener("beginContact", self.onBeginContact, self)
    
    
    self:loadLevel(levelCode)
    self:test_physicsSprite()
    
    self:addChild(debugDraw)
    --self.mainlayer = MainLayer.new(); self:addChild(self.mainlayer)
    --self:addChild(HUDLayer.new())
    
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

local function test_newShapeFromVertices(points, color, alpha)
    local s = Shape.new()
    --s:setLineStyle(2)
    s:setFillStyle(Shape.SOLID, color, alpha)
    s:beginPath()
    s:moveTo(points[1], points[2])
    for i=3,#points,2 do
        local px, py = points[i], points[i+1]
        s:lineTo(px, py)
        --print("test_newShapeFromVertices i, px, py ", i, px, py)
    end
    s:closePath()
    s:endPath()
    return s
end

local msvg = require 'msvg'

function GameplayScene:test_addNinja2()
    local ninja = Entity.new("ninja", self.world)
    ninja.scml:setAnimation("Run")
    self:addChild(ninja)
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

function GameplayScene:loadLevel(levelCode)
    print("loading level " .. levelCode)
    local prefix = "data/levels/" .. levelCode
    
    local s = 1
    --s = 1.5
    --s = 4
    self:setScale(s, s)
    
    local svg = msvg.loadFile(prefix .. "/level.svg")
    msvg.simplifyTree(svg)
    
    local function hex_color(s)
        if s:find'^#' then
            return tonumber(s:sub(2), 16)
        end
    end
    
    -- Walk through SVG tree
    local function walk(e)
        if e.vertices then
            if e.vertices.close then
                local alpha = tonumber(e.style.fill_opacity)
                local m = SimpleMesh.new(e.vertices, hex_color(e.style.fill), alpha, 1.9)
                self:addChild(m)
            end
        end
        for c in all(e.children) do walk(c) end
    end
    walk(svg)
    
    self:test_screenshot()
    self:test_addNinja2()
    
    
    local config = xmlFromFile(prefix .. "/level.xml")
    
    self:loadConfig(config)
    self:loadMap(svg)
end

function GameplayScene:loadConfig(xmlConfig)
    
end

function GameplayScene:loadMap(svgLevel)
    -- self.map = MapLoader.loadMap(svgLevel.svg[1])
    
end

function GameplayScene:setPaused(flag)
    self.paused = flag
end

function GameplayScene:onLogic()
    
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
        local logic = Event.new("logic")
        logic.broadcast = true
        dispatchEvent(self, logic)
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
