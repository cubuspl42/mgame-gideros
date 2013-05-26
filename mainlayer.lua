MainLayer = gideros.class(Sprite)

function MainLayer:test_addPhysicsSprite()
	local v = {10, 10, 100, 10, 100, 50, 10, 50}
	
	local shapeDef = {
		type = b2.DYNAMIC_BODY, lock = false,
		subshapes = {
			{ vertices = v, fixture = {} }
		}
	}
	
	local shape = Shape.new()
	shape:setLineStyle(2, 0)
	shape:beginPath()
    for i=1,#v,2 do
        local x, y = v[i], v[i + 1]
        shape:lineTo(x, y)
    end
    shape:closePath();
    shape:endPath();
	
	local ps = PhysicsSprite.new(shape, shapeDef)
	self:addChild(ps)	
end

function MainLayer:init()
    self:addEventListener("logic", MainLayer.onLogic, self)
    
    world = b2.World.new(0, 1)
	world.parent = self
    local debugDraw = b2.DebugDraw.new()
    world:setDebugDraw(debugDraw)
    
    --self:test_addPhysicsSprite()
    
    for i = 1,2 do
        a = Shape.new()
        a:setLineStyle(3, 1)
        a:beginPath()
        a:moveTo(0, 0)
        a:lineTo(i==2 and 0 or 200, i==1 and 0 or 200)
        a:endPath()
        self:addChild(a)
    end
    
    --self.ninja = Ninja.new(); self:addChild(self.ninja)
    
    self:addChild(debugDraw)
    prefix = "data/monster-kopia/"
    local scml = SCMLParser.new(prefix .. "Example2.SCML", function(filename) 
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
    self.monster = scml:createEntity(0)
    self.monster:setAnimation("Jump") -- TEMP
    self:addChild(self.monster)
	
	local monster2 = scml:createEntity(0)
	monster2:setAnimation("Idle")
	monster2:setX(200)
	self:addChild(monster2)
	
    local scale = 1.2
    self:setPosition(150, 300); self:setScale(scale, scale)
    
    
end

function MainLayer:onLogic()
    --print("physics step")
    world:step(1.0/application:getFps(), 4, 8)
    
end
