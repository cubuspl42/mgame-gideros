OffsetBitmap = Core.class(Sprite)

function OffsetBitmap:init(texture)
	self.bitmap = Bitmap.new(texture)
	ox = ox or 1
	oy = oy or 1
	rx = application:getDeviceWidth()/application:getLogicalWidth()
	ry = application:getDeviceHeight()/application:getLogicalHeight()
	self.bitmap:setPosition(-rx * ox, -ry * oy)
	self:addChild(self.bitmap)
end