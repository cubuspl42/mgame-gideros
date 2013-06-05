--[[
 Delaunay Triangulation Code, by Joshua Bell
 http://www.travellermap.com/tmp/delaunay.js
 Ported to Lua by Daniel Levy
 
 Inspired by: http:www.codeguru.com/cpp/data/mfc_database/misc/article.php/c8901/

 This work is hereby released into the Public Domain. To view a copy of the public 
 domain dedication, visit http:creativecommons.org/licenses/publicdomain/ or send 
 a letter to Creative Commons, 171 Second Street, Suite 300, San Francisco, 
 California, 94105, USA.
--]]

local EPSILON = 1.0e-6

--------------------------------------------------------------
-- Vertex class
--------------------------------------------------------------
local vertex_mt = {__eq = function(a, b) return a.x and b.x and (a.x == b.x) and a.y and b.y and (a.y == b.y) end
	,__lt = function(a, b) return a.x and b.x and a.y and b.y and (a.x < b.x or a.x == b.x and a.y < b.y) end}

function Vertex( x, y )
	local this = {}
	this.x = x
	this.y = y
	setmetatable(this, vertex_mt)
	return this
end -- Vertex

--------------------------------------------------------------
-- Triangle class
--------------------------------------------------------------

local triangle_mt = {__eq = function(a, b)
if not (a.v0 and b.v0 and a.v1 and b.v1 and a.v2 and b.v2) then return false end
return (a.v0 == b.v0 and a.v1 == b.v1 and a.v2 == b.v2) or
       (a.v0 == b.v0 and a.v1 == b.v2 and a.v2 == b.v1) or
       (a.v0 == b.v1 and a.v1 == b.v0 and a.v2 == b.v2) or
       (a.v0 == b.v1 and a.v1 == b.v2 and a.v2 == b.v0) or
       (a.v0 == b.v2 and a.v1 == b.v0 and a.v2 == b.v1) or
       (a.v0 == b.v2 and a.v1 == b.v1 and a.v2 == b.v0)
end}

function Triangle( v0, v1, v2 )
	local this = {}
	this.v0 = v0
	this.v1 = v1
	this.v2 = v2
	
	CalcCircumcircle(this)
	setmetatable(this, triangle_mt)
	return this
end -- Triangle

function CalcCircumcircle(this)
	-- From: http:--www.exaflop.org/docs/cgafaq/cga1.html
	
	local A = this.v1.x - this.v0.x 
	local B = this.v1.y - this.v0.y 
	local C = this.v2.x - this.v0.x 
	local D = this.v2.y - this.v0.y 
	
	local E = A*(this.v0.x + this.v1.x) + B*(this.v0.y + this.v1.y) 
	local F = C*(this.v0.x + this.v2.x) + D*(this.v0.y + this.v2.y) 
	
	local G = 2.0*(A*(this.v2.y - this.v1.y)-B*(this.v2.x - this.v1.x)) 
	
	local dx, dy
	
	if math.abs(G) < EPSILON then
		-- Collinear - find extremes and use the midpoint
		
		local minx = math.min( this.v0.x, this.v1.x, this.v2.x )
		local miny = math.min( this.v0.y, this.v1.y, this.v2.y )
		local maxx = math.max( this.v0.x, this.v1.x, this.v2.x )
		local maxy = math.max( this.v0.y, this.v1.y, this.v2.y )
		
		this.center = Vertex( ( minx + maxx ) / 2, ( miny + maxy ) / 2 )
		
		dx = this.center.x - minx
		dy = this.center.y - miny
	else
		local cx = (D*E - B*F) / G 
		local cy = (A*F - C*E) / G
		
		this.center = Vertex( cx, cy )
		
		dx = this.center.x - this.v0.x
		dy = this.center.y - this.v0.y
	end
	
	this.radius_squared = dx * dx + dy * dy
	this.radius = math.sqrt( this.radius_squared )
end -- CalcCircumcircle

function InCircumcircle( this, v )
	local dx = this.center.x - v.x
	local dy = this.center.y - v.y
	local dist_squared = dx * dx + dy * dy
	
	return ( dist_squared <= this.radius_squared )
end -- InCircumcircle


--------------------------------------------------------------
-- Edge class
--------------------------------------------------------------
local edge_mt = {__eq = function(a, b) return a.v0 and b.v0 and a.v1 and b.v1 and ((a.v0 == b.v0 and a.v1 == b.v1) or (a.v0 == b.v1 and a.v1 == b.v0)) end}

function Edge( v0, v1 )
	local this = {}
	if v0 > v1 then v0, v1 = v1, v0 end
	this.v0 = v0
	this.v1 = v1
	setmetatable(this, edge_mt)
	return this
end -- Edge


--------------------------------------------------------------
-- Triangulate
--
-- Perform the Delaunay Triangulation of a set of vertices.
--
-- vertices: Array of Vertex objects
--
-- returns: Array of Triangles
--------------------------------------------------------------
function Triangulate( vertices )
	local triangles = {}
	
	-- First, create a "supertriangle" that bounds all vertices
	local st = CreateBoundingTriangle( vertices )
	table.insert(triangles, st )
	
	-- Next, begin the triangulation one vertex at a time
	for _, vertex in ipairs(vertices) do
	
		-- NOTE: This is O(n^2) - can be optimized by sorting vertices
		-- along the x-axis and only considering triangles that have 
		-- potentially overlapping circumcircles

		AddVertex( vertex, triangles )
	end

	-- Remove triangles that shared edges with "supertriangle"
	for i = #triangles, 1, -1 do
		local triangle = triangles[i]
		
		if triangle.v0 == st.v0 or triangle.v0 == st.v1 or triangle.v0 == st.v2 or
			triangle.v1 == st.v0 or triangle.v1 == st.v1 or triangle.v1 == st.v2 or
			triangle.v2 == st.v0 or triangle.v2 == st.v1 or triangle.v2 == st.v2 then
			
			table.remove(triangles, i)
		end
	end

	return triangles
end -- Triangulate


-- Internal: create a triangle that bounds the given vertices, with room to spare
function CreateBoundingTriangle( vertices )

	-- NOTE: There's a bit of a heuristic here. If the bounding triangle 
	-- is too large and you see overflow/underflow errors. If it is too small 
	-- you end up with a non-convex hull.
	
	local minx, miny, maxx, maxy
	for _, vertex in ipairs(vertices) do
	
		--local vertex = vertices[i]
		if not minx or vertex.x < minx then  minx = vertex.x end
		if not miny or vertex.y < miny then  miny = vertex.y end
		if not maxx or vertex.x > maxx then  maxx = vertex.x end
		if not maxy or vertex.y > maxy then  maxy = vertex.y end
	end

	local dx = ( maxx - minx ) * 10
	local dy = ( maxy - miny ) * 10
	
	local stv0 = Vertex( minx - dx, miny - dy*3 )
	local stv1 = Vertex( minx - dx, maxy + dy )
	local stv2 = Vertex( maxx + dx*3, maxy + dy )

	return Triangle( stv0, stv1, stv2 )
	
end -- CreateBoundingTriangle


-- Internal: update triangulation with a vertex 
function AddVertex( vertex, triangles )
	local edges = {}
	
	-- Remove triangles with circumcircles containing the vertex
	local i
	for i = #triangles, 1, -1 do
		local triangle = triangles[i]
		
		if InCircumcircle( triangle, vertex ) then
			table.insert(edges, Edge( triangle.v0, triangle.v1 ) )
			table.insert(edges, Edge( triangle.v1, triangle.v2 ) )
			table.insert(edges, Edge( triangle.v2, triangle.v0 ) )
			table.remove(triangles, i)
		end
	end
	
	edges = UniqueEdges( edges )
	
	-- Create triangles from the unique edges and vertex
	for _, edge in ipairs(edges) do
		table.insert(triangles, Triangle( edge.v0, edge.v1, vertex ) )
	end
end -- AddVertex


-- Internal: remove duplicate edges from an array
function UniqueEdges( edges )
	-- TODO: This is O(n^2), make it O(n) with a hash or some such
	local uniqueEdges = {}
	for i, edge1 in ipairs(edges) do
		local unique = true
		for j, edge2 in ipairs(edges) do
			if i ~= j and edge1 == edge2 then
				unique = false
				break
			end
		end
		
		if unique then
			table.insert(uniqueEdges, edge1 )
		end
	end

	return uniqueEdges
	
end -- UniqueEdges


-- TODO: This is only relative network graph
function beta_skeleton(triangles, beta)
	local edges = {}
	for _, tri in ipairs(triangles) do
		table.insert(edges, Edge(tri.v0, tri.v1))
		table.insert(edges, Edge(tri.v1, tri.v2))
		table.insert(edges, Edge(tri.v2, tri.v0))
	end
	
	for i, e1 in ipairs(edges) do
		for j = #edges, i+1, -1 do
			if e1 == edges[j] then table.remove(edges[j]) end
		end
	end
	
	for _, tri in ipairs(triangles) do
		local t = {tri.v0, tri.v1, tri.v2}
		for i = 1, 3 do
			local v1 = t[i]
			local v2 = t[m_i(i+1, 3)]
			local v3 = t[m_i(i+2, 3)]
			
			
			local c = Vertex( (v1.x+v2.x)/2, (v1.y+v2.y)/2 )
			local r = math.sqrt(dist_squared(v1, v2))/2 * beta
			
			local dx, dy = (v1.x-v2.x)/2, (v1.y-v2.y)/2
			local c1 = Vertex(c.x+dx*(beta-1), c.y+dy*(beta-1))
			local c2 = Vertex(c.x-dx*(beta-1), c.y-dy*(beta-1))
			
			if r > math.sqrt(dist_squared(c1, v3)) and r > math.sqrt(dist_squared(c2, v3)) then
				local e = Edge(v1, v2)
				for i = #edges, 1, -1 do
					if edges[i] == e then table.remove(edges, i) end
				end
			end
		end
	end
	return edges
end

function dist_squared(v0, v1)
	local dx = v0.x - v1.x
	local dy = v0.y - v1.y
	return dx*dx + dy*dy
end

function m_i(i, n)
	return (i+n-1)%n+1
end