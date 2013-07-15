-- version 0.1
-- This code is MIT licensed, see http://www.opensource.org/licenses/mit-license.php
-- (C) 2013 Jakub Trzebiatowski

-- PerformanceGraph draws a graph of perfomance in last few seconds.
-- Add this code at the end of your main.lua (or other appropriate place):

--[[
local graph = PerformanceGraph.new {
	history_length = <width of the graph in seconds, default: 2>,
	min_frame_time = <min value of deltaTime the graph can show, default: 1/application:getFps()>,
	max_frame_time = <max value of deltaTime the graph can show, default: 3*self.min_frame_time>,
	color = <color of graph, default: 0xFF0000 (red)>,
	alpha = <alpha value of graph, default: 0.7>
}
graph:setY(application:getContentHeight())
stage:addChild(graph)
--]]

PerformanceGraph = Core.class(Sprite)

function PerformanceGraph:init(config)
	config = config or {}
    self.graph = Sprite.new()
    self:addChild(self.graph)
    
    self.graph:setX(application:getContentWidth())
    self.graph:setScaleY(-1)
    
    self.history_length = config.history_length or 2
    self.min_frame_time = config.min_frame_time or 1/application:getFps()
    self.max_frame_time = config.max_frame_time or 3*self.min_frame_time
    
    self.color = config.color or 0xFF0000
    self.alpha = config.alpha or 0.7
    
    self.x = 0
    self.y = 0
    
    stage:addEventListener("enterFrame", self.onEnterFrame, self)
end

function PerformanceGraph:onEnterFrame(event)
    local n = self.history_length * application:getFps()
    local w = application:getContentWidth()
    local h = application:getContentHeight()
    local dx = 1/n * w
    
    local x, y = self.x, self.y
    
    if self.graph:getNumChildren() > n then
        self.graph:removeChildAt(1)
    end
    
    local mesh = Mesh.new()
    self.graph:addChild(mesh)
    
    local c, a = self.color, self.alpha
    mesh:setColorArray(c, a, c, a, c, a, c, a)
    mesh:setIndexArray(1, 2, 3, 1, 3, 4)
    mesh:resizeVertexArray(4)
    mesh:setVertices(1, x, 0, 2, x, y)
    
    local dt  = event.deltaTime - self.min_frame_time
    x = x + dx
    y = dt/self.max_frame_time * h
    
    mesh:setVertices(3, x, y, 4, x, 0)
	
    self.graph:setX(self.graph:getX() - dx)
    self.x, self.y = x, y
end
