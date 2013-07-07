ShapePoint = Core.class(Shape)

function ShapePoint:init(color)
	self:setFillStyle(Shape.SOLID, color or 0xFF0000, 1)
    self:beginPath()
    self:moveTo(-1, -1)
    self:lineTo(1, -1)
	self:lineTo(1, 1)
	self:lineTo(-1, 1)
    self:closePath()
    self:endPath()
	
	local s = 3
	self:setScale(s, s)
end