-- visual debug library for Gideros
-- it d

gdebug = Sprite.new()

--* take over enterFrame *--
for _ in pairs{} 
do
    local skipped_time = 0 -- number of skipped time
    local skipped_frames = 0
    local slowdown_multiplier = 1 -- when slowdown_multiplier == n, game slows down n times
    
    stage:addEventListener(Event.TOUCHES_BEGIN, function(event)
            print(event.touch.id)
    end)
    
    local function dispatchEventRecursively(sprite, event)
		print("sprite:dispatchEvent")
        sprite:dispatchEvent(event)
        for i=1,sprite:getNumChildren() do
            dispatchEventRecursively(sprite:getChildAt(i), event)
        end
    end
    
    stage:addEventListener("enterFrame", function(event)
			print("enterFrame listener")
            if event.frameCount % slowdown_multiplier == 0 then		
                local _event = Event.new("_enterFrame")
                _event.deltaTime = event.deltaTime
                _event.time = event.time - skipped_time
                _event.frameCount = event.frameCount - skipped_frames
                dispatchEventRecursively(stage, _event)
            else
                skipped_frames = skipped_frames + 1
                skipped_time = skipped_time + event.deltaTime
            end
    end)
    
    for _, method in pairs {
        "addEventListener",
        "hasEventListener",
        "removeEventListener"
    } do
        local _method = EventDispatcher[method]
        EventDispatcher[method] = function(self, type, ...)
            return _method(self, type == "enterFrame" and "_enterFrame" or type, ...)
        end
    end
    
    local dispatchEvent = EventDispatcher.dispatchEvent
    function EventDispatcher:dispatchEvent(event)
        assert(event:getType() ~= "enterFrame", "gdebug: dispatching 'enterFrame' manually is not supported")
        dispatchEvent(self, event)
    end
end

