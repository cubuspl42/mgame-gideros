-- visual debug library for Gideros

gdebug = Sprite.new()

--* take over enterFrame *--
do
    local skipped_time = 0 -- number of skipped time
    local skipped_frames = 0
    local slowdown_multiplier = 1 -- when slowdown_multiplier == n, game slows down n times
    
    stage:addEventListener(Event.TOUCHES_BEGIN, function(event)
            print(event.touch.id)
    end)
    
    local function dispatchEventRecursively(sprite, event)
        sprite:dispatchEvent(event)
        for i=1,sprite:getNumChildren() do
            dispatchEventRecursively(sprite:getChildAt(i), event)
        end
    end
    
    stage:addEventListener("enterFrame", function(event)
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
        assert(event:getType() ~= "enterFrame", "gdebug: dispatching 'enterFrame' manually is not allowed")
        dispatchEvent(self, event)
    end
end

--* add performance graph *--
--for _ in pairs{} 
do
	local performance_graph = Shape.new()
	gdebug:addChild(performance_graph)
    local performance_history = {}
    local performance_history_length = 2 -- seconds
	local min_frame_time = 1/application:getFps()
	local max_frame_time = 4 * min_frame_time
	local n = performance_history_length * application:getFps()
	
    for i=1,n do
        performance_history[i] = 0
    end
    
    local i = 1
	stage:addEventListener("enterFrame", function(event)
		--do return end
		if i > n then i = 1 end
		performance_history[i] = event.deltaTime - min_frame_time
		performance_graph:clear()
		performance_graph:setLineStyle(1, 0xFF0000, 1)
		performance_graph:beginPath()
		
		local j = i + 1
		local k = 1
		while true do
			if j > n then j = 1 end
			if j == i then break end
			local v = performance_history[j]
			local x = k/n * application:getContentWidth()
			local h = application:getContentHeight()
			local y = (-v/max_frame_time * h) + h
			performance_graph:lineTo(x, y)
			k = k + 1
			j = j + 1
		end
		
		performance_graph:endPath()
		i = i + 1
	end)
end






