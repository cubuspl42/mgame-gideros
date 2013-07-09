local va = require 'vertexarray'
local Polygon = require 'polygon'

local defaultColor = 0x4169E1

SimpleMesh = Core.class(Sprite)

local dbg = dbg >= 3

-- Input:
-- vertices = table (e.g. {<x1>, <y1>, <x2>, <y2>, <...>})
-- color = numer (e.g. 0xABCDEF)
-- alpha = number (e.g. 0.123)
-- d = number (e.g. 1.123) [antialiased border]

function SimpleMesh:init(vertices, color, alpha, d)
    local vertices = table.copy(vertices)
	
	local map = {}
	for x, y, i in va.iter(vertices) do
		map[x] = map[x] or {}
		local j = map[x][y]
		assert(not j, "Point duplicated! Previous: "..tostring(j).." Current: "..tostring(i))
		map[x][y] = i
    end
	
	if false then -- not necessary any more? lib 'path' gives no repeated points?
		for i, _ in ipairs(vertices) do 
			-- (probably) remove repeated points
			vertices[i] = vertices[i] + 0.0000000001 * math.random(10000) -- HACK
			-- God, I'm so sorry for this dirty hack
		end
	end
    
    local m = Mesh.new()
    self:addChild(m)
    self.mesh = m
    
    color = color or defaultColor
    alpha = alpha or 1
    d = d or 1.5
    d = d * (dbg and 2 or 1)
    local n = #vertices/2 -- initial vertices' size
    
    local polygon = Polygon.new(unpack(vertices))
    local t = Polygon.triangulate(polygon)
    
    vertices = { Polygon.unpack(polygon) }
	
	self.isReversed = Polygon.isReversed(polygon)
    
    local vertexArray = table.copy(vertices)
    local colorArray = {}
    local indexArray = {}
    
    for i=1,n do
        table.insertall(colorArray, dbg and math.random(0xffffff) or color, (dbg and 0.9) or alpha)
    end
    
    for tri in all(t) do
        for i=1,3 do 
            local p = tri.vertices[i]
            local found = false
            for x, y, j in va.iter(vertices) do
                if x == p.x and y == p.y then
                    table.insert(indexArray, j)
                    found = true
                    break
                end
            end
            assert(found, "point 'p' not in 'vertices'")
        end
    end
    
    --tprint(vertices)
    for x, y, i in va.iter(vertices) do
        local px, py = va.get(vertices, i - 1) -- previus point
        local nx, ny = va.get(vertices, i + 1) -- next point
        --print(px, py, x, y, nx, ny)
        local v1 = Vector.newFromObjects({x = nx, y = ny}, {x = x, y = y}) -- cur vector
        local v2 = Vector.newFromObjects({x = px, y = py}, {x = x, y = y}) -- prev vector
        local v1r = Vector(-v1.y, v1.x) -- rotated v1
        local v2r = Vector(v2.y, -v2.x) -- rotated v2
        --print("v1, v1r, v2, v2r", v1, v1r, v2, v2r)
        local s1, s2 = v1:scalarProjectOn(v2r), v2:scalarProjectOn(v1r)
        v1 = v1 / (s1 / d)
        v2 = v2 / (s2 / d)
        --print("v1, v2, s1, s2", v1, v2, s1, s2)
        local p = Vector(x, y) + v1 + v2
        --print("p: ", p)
        
        table.insertall(vertexArray, x, y, p.x, p.y)
        table.insertall(colorArray, color, alpha, color, dbg and 1 or 0)
    end
    
    local n2 = 2*n
    for i=1,2*n,2 do
        local a, b, c, d = n + i, n + 1 + (i)%(n2), n + 1 + (i + 1)%(n2), n + 1 + (i + 2)%(n2)
        --print("abcd, i", a, b, c, d, ",", i)
        table.insertall(indexArray, a, b, c)
        table.insertall(indexArray, b, c, d)
    end
    
    m:setVertexArray(vertexArray)
    m:setColorArray(colorArray)
    m:setIndexArray(indexArray)
    
end