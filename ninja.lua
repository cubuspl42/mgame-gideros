Ninja = Core.class(Sprite)

function Ninja:init()
	local world = nil
    self:addEventListener("logic", self.onLogic, self)
    
    self.circle = PhysicsSprite.new(nil, {
        lock = false, fixedRotation = true,
        subshapes = { { cx = 50, cy = 50, radius = 50, fixture = {} } }
    }, world)
    self:addChild(self.shape)
    
end

function Ninja:onLogic()
    
end

