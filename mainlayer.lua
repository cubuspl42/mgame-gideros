MainLayer = gideros.class(Sprite)

function MainLayer:init()
    self:addEventListener("logic", MainLayer.onLogic, self)
    
    world = b2.World.new(0, 10)
    local debugDraw = b2.DebugDraw.new()
    world:setDebugDraw(debugDraw)
    
    --[[test body
	self.phSh = PhysicsShape.new {
		lock = true,
		subshapes = {
			{ vertices = { 0,0, 100,0, 100,100, 0, 50 }, fixture = {} },
			{ vertices = { 30,30, 200,0, 200,100, 30, 50 }, fixture = nil },
			{ radius = 30, cx = 100, cy = 100, fixture = {} }
		}
	}
	self:addChild(self.phSh)
	--]]
    
    for i = 1,2 do
        a = Shape.new()
        a:setLineStyle(5, 1)
        a:beginPath()
        a:moveTo(0, 0)
        a:lineTo(i==2 and 0 or 200, i==1 and 0 or 200)
        a:endPath()
        self:addChild(a)
    end
    
    self.ninja = Ninja.new(); self:addChild(self.ninja)
    
    self:addChild(debugDraw)
    prefix = "data/monster-kopia/"
    local scml = SCMLFile.new(prefix .. "Example2.SCML", function(filename) 
            local b 
            if filename then b = Bitmap.new(Texture.new(prefix .. filename, true)) end
            local s = SCMLSprite.new(b)
            for i = 1,2 do
                a = Shape.new()
                a:setLineStyle(3, i==1 and 0xFF0000 or 0x00FF00)
                a:beginPath()
                a:moveTo(0, 0)
                a:lineTo(i==2 and 0 or 30, i==1 and 0 or 30)
                a:endPath()
                s:addChild(a)
            end
            return s
    end)
    self.monster = scml.entities[1]
    self.monster:setAnimation("Jump") -- TEMP
    
    self:addChild(self.monster)
    local scale = 0.7
    self:setPosition(150, 300); self:setScale(scale, scale)
    
    
end

function MainLayer:onLogic()
    --print("physics step")
    world:step(1/application:getFps(), 4, 8)
    
end
