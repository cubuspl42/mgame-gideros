SimpleMesh = Core.class(Sprite)

local va = require 'vertexarray'

function SimpleMesh:init(vertices)
	local m = Mesh.new()
	self.mesh = m
	self:addChild(m)
	local color = 0x4169E1 -- temp
	local n = #vertices/2 -- initial vertices' size
	
	--- Set vertex array
	
	local vertexArray = table.copy(vertices)
	local t = triangulate(vertexArray) -- it may rearrange array!
	
	for x, y in va.iter(vertices) do
		--table.insertall(vertexArray, x, y)
	end
	
	tprint(vertices)
	for x, y, i in va.iter(vertices) do
		local px, py = va.get(vertices, i - 1) -- previus point
		local nx, ny = va.get(vertices, i + 1) -- next point
		print(px, py, x, y, nx, ny)
		local pV = Vector.newFromObjects({x = px, y = py}, {x = x, y = y}) -- prev vector
		local V = Vector.newFromObjects({x = nx, y = ny}, {x = x, y = y}) -- cur vector
		V = V * -1
		local nV = (pV - V)/2 -- new vector
		nV:Normalize()
		nV = nV * 3
		print("vertices iter: i, pv, V, nV, x, y", i, pV, V, nV, x, y)
		local pos = Vector(x, y) + nV
		
		table.insertall(vertexArray, x, y, pos.x, pos.y)
	end
	
	m:setVertexArray(vertexArray)
	
	-- Set colors
	
	local colorArray = {}

		for j=1,n do
			--print("colorArray: x, y, j, i ", x, y, j, i)
			table.insertall(colorArray, 
			--0xC0C0C0
			color
			, 1)
		end
	
	for i=1,n do
		table.insertall(colorArray, color,1,color, 0)
	end
	
	m:setColorArray(colorArray)
	
	print("c, v", #colorArray, #vertexArray)
	
	-- Set indices
	
	local indexArray = {}
	for tri in all(t) do
		table.insertall(indexArray, tri[1], tri[2], tri[3])
	end
	
	for i=1,2*n,2 do
		local m = 2*n
		local a, b, c, d = n + i, n + 1 + (i)%(m), n + 1 +(i + 1)%(m), n + 1 + (i + 2)%(m)
		print("abcd, i", a, b, c, d, i)
		table.insertall(indexArray, a, b, c) -- WIP!!!
		table.insertall(indexArray, a, c, d)
		table.insertall(colorArray, 1, colorArray, 0)
	end
	
	m:setIndexArray(indexArray)
	
end