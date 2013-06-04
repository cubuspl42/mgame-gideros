SimpleMesh = Core.class(Sprite)

local va = require 'vertexarray'

function SimpleMesh:init(vertices)
	local vertexArray = table.copy(vertices)
	local t = triangulate(vertexArray) -- it may rearrange v
	local m = Mesh.new()
	self.mesh = m
	
	
	
	colorArray, indexArray = {}, {}
	for x, y, i in va.iter(vertexArray) do
		
	end
end