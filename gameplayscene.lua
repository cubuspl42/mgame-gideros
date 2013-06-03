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

function GameplayScene:loadLevel(levelCode)
	print("loading level " .. levelCode)
    local prefix = "data/levels/" .. levelCode
	
	local svg = require('msvg').newTree()
	svg:loadFile(prefix .. "/level.svg")
	svg:simplify()
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
    print("scene1 - enter begin")
end

function GameplayScene:onTransitionInEnd()
    print("scene1 - enter end")
end

function GameplayScene:onTransitionOutBegin()
    print("scene1 - exit begin")
end

function GameplayScene:onTransitionOutEnd()
    print("scene1 - exit end")
end
