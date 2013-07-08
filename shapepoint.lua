ShapePoint = Core.class(Shape)

function ShapePoint:init(color, scale)
	self:setFillStyle(Shape.SOLID, color or 0xFF0000, 1)
    self:beginPath()
    self:moveTo(-1, -1)
    self:lineTo(1, -1)
	self:lineTo(1, 1)
	self:lineTo(-1, 1)
    self:closePath()
    self:endPath()
	
	self:setScale(scale or 5, scale or 5)
end