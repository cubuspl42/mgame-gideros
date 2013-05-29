Ground = Core.class(Sprite)

local groundColor = 0xC0C0C0 -- this is grey?

function Ground:init(vertices) -- we assume this is polygon
    -- we need poly2tri to convert this polygon to triangles (mesh)
    -- self.mesh = Mesh.new()
    
    self.shape = Shape.new() -- we can use Shape for now
end