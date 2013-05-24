Ninja = Core.class(Sprite)

function Ninja:init()
    self:addEventListener("logic", self.onLogic, self)
    
    self.shape = PhysicsShape.new{
        lock = false, fixedRotation = true,
        subshapes = { { radius = 30, fixture = {} } }
    }
    self:addChild(self.shape)
    
end

function Ninja:onLogic()
    
end

