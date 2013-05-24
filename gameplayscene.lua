GameplayScene = gideros.class(Sprite)

function GameplayScene:init(t)
    if t then
        print("Scene1: ", t)
    end
    
    self:addEventListener("enterBegin", self.onTransitionInBegin, self)
    self:addEventListener("enterEnd", self.onTransitionInEnd, self)
    self:addEventListener("exitBegin", self.onTransitionOutBegin, self)
    self:addEventListener("exitEnd", self.onTransitionOutEnd, self)
    self:addEventListener("enterFrame", self.onEnterFrame, self)
    self:addEventListener("logic", self.onLogic, self)
    
    self._paused = false; --true
    
    self:addChild(MainLayer.new())
    --self:addChild(HUDLayer.new())
    
end

function GameplayScene:setPaused(flag)
    
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
