Ground = Core.class(Sprite)

function Ground:init(vertices) -- we assume this is polygon
	-- we need poly2tri to convert this polygon to triangles
	self.mesh = Mesh.new()
end