PhysicsSprite = Core.class(EventDispatcher)
-- It assumes that world.parent is not rotated

-- Switch to bodyDef!

function addPhysics(sprite, bodyDef, world, physicsMode, bodyVariableName)
    physicsMode = physicsMode or "slave"
    bodyVariableName = bodyVariableName or "body"
    
    local physicsIsSlave = false
    if physicsMode == "slave" then
        physicsIsSlave = true
    elseif physicsMode ~= "master" then
        error("physicsMode cannot be " .. physicsMode)
    end
    
    local body = world:createBody(bodyDef)
    local spriteParent = sprite:getParent()
    sprite[bodyVariableName] = body
    
    sprite:addEventListener("enterFrame", function()
            if physicsIsSlave then -- force physics body to transorm
                local x, y = sprite:localToGlobal(0, 0)
                x, y = world.parent:globalToLocal(x, y)
                body:setPosition(x, y)
                body:setAngle(sprite:getWorldRotation() * math.pi / 180) -- we assume that world.parent doesn't rotate
            else  -- transorm sprite according to body
                local x, y = body:getPosition()
                x, y = world.parent:localToGlobal(x, y)
                x, y = spriteParent:globalToLocal(x, y)
                sprite:setPosition(x, y)
                sprite:setWorldRotation(body:getAngle() * 180 / math.pi)
            end 
    end)
end
