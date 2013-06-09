OffsetTexture = Core.class(Sprite)

function OffsetTexture:init(filename, filtering, ox, oy, options)
	self.texture = Texture.new(filename, filtering, options)
	ox = ox or 1
	oy = oy or 1
	rx = application:getDeviceWidth()/application:getLogicalWidth()
	ry = application:getDeviceHeight()/application:getLogicalHeight()
	self.texture:setPosition(-rx * ox, -ry * oy)
	self:addChild(self.texture)
end