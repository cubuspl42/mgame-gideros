World = Core.class(Sprite)
--[[
	events:
	
]]--

function World:init(svgTree)
    local debugDraw = b2.DebugDraw.new()
    self.physicsWorld = b2.World.new(0, 10)
    self.physicsWorld:setDebugDraw(debugDraw)
	
	
	self:addChild(debugDraw)
end

local function updatePhysics(data)
    local world, sprite, body = unpack(data)
    if body.isSlave then
        local x, y = sprite:localToGlobal(0, 0)
        x, y = world:globalToLocal(x, y)
        body:setPosition(x, y)
        body:setAngle(sprite:getWorldRotation() * math.pi / 180) -- we assume that world doesn't rotate
    else  -- transorm sprite according to body
        local x, y = body:getPosition()
        x, y = world:localToGlobal(x, y)
        x, y = sprite:getParent():globalToLocal(x, y)
        sprite:setPosition(x, y)
        sprite:setWorldRotation(body:getAngle() * 180 / math.pi)
    end 
end

function World:addSprite(sprite, bodyDef) --> body or nil
	local body
    if bodyDef then
		local type = bodyDef.type or b2.STATIC_BODY
        body = self.physicsWorld:createBody(bodyDef)
        body.isSlave = (type == b2.STATIC_BODY)
        local data = { self, sprite, body }
		sprite.body = body
        sprite:addEventListener("enterFrame", updatePhysics, data)
    end
    self:addChild(sprite)
	return body
end