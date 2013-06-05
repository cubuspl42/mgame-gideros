GameplayScene = Core.class(Sprite)

function GameplayScene:init(levelCode) -- levelCode: i.e. "0/1"
    self:addEventListener("enterBegin", self.onTransitionInBegin, self)
    self:addEventListener("enterEnd", self.onTransitionInEnd, self)
    self:addEventListener("exitBegin", self.onTransitionOutBegin, self)
    self:addEventListener("exitEnd", self.onTransitionOutEnd, self)
    self:addEventListener("enterFrame", self.onEnterFrame, self)
    self:addEventListener("logic", self.onLogic, self)
    self.paused = false; -- true?
    
    self:loadLevel(levelCode)
    --self.mainlayer = MainLayer.new(); self:addChild(self.mainlayer)
    --self:addChild(HUDLayer.new())
    
end

local function test_newShapeFromVertices(x, y, ...)
    local s = Shape.new()
    s:setLineStyle(2)
    s:setFillStyle(Shape.SOLID, 0xC0C0C0)
    s:beginPath()
    s:moveTo(x, y)
    local points = {...}
    for i=1,#points,2 do
        local px, py = points[i], points[i+1]
        s:lineTo(px, py)
        --print("test_newShapeFromVertices i, px, py ", i, px, py)
        
    end
    s:closePath()
    s:endPath()
    return s
end

local msvg = require 'msvg'

function GameplayScene:loadLevel(levelCode)
    print("loading level " .. levelCode)
    local prefix = "data/levels/" .. levelCode
    
    local s = 0.6
    self:setScale(s, s)
    local svg = msvg.newTree()
    svg:loadFile(prefix .. "/level.svg")
    svg:simplify()
    
    local function hex_color(s)
        if not s:find'^#' then return end
        return tonumber(s:sub(2), 16)
    end
    
    local function walk(e)
        if e.vertices then
            if e.vertices.close then
                local alpha = tonumber(e.style.fill_opacity)
                local m = SimpleMesh.new(e.vertices, hex_color(e.style.fill), alpha)
                self:addChild(m)
                --self:addChild(test_newShapeFromVertices(unpack(e.vertices)))
            end
        end
        for c in all(e.children) do walk(c) end
    end
    walk(svg.root)
    
    -- SCML
    
    prefix = "data/entities/ninja"
    local scml = SCMLParser.new(prefix .. "/anim.scml")
    local dbg = false
    local function loader(filename)
        local ok, b 
        if filename then
            filename = filename:gsub("dev_", "")
            ok, b = pcall(function()
                    return Bitmap.new(Texture.new(prefix .. filename, true))
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
    ninja:setAnimation("Idle") -- TEMP
    self:addChild(ninja)
    
    -- CONFIG ...
    
    --tprint(svg)
    
    --local svg = xmlFromFile(prefix .. "/level.svg")
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

function GameplayScene:onEnterFrame()
    if not self.paused then
        --print("onEnterFrame")
        local logic = Event.new("logic")
        logic.broadcast = true
        dispatchEvent(self, logic)
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
