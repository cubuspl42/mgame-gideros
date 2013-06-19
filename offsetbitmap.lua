OffsetBitmap = Core.class(Bitmap)

-- This class adds 1 physical pixel offset to Bitmap

function OffsetBitmap:init(texture, ox, oy)
	rx = application:getDeviceWidth()/application:getLogicalWidth()
	ry = application:getDeviceHeight()/application:getLogicalHeight()
	--self:setPosition(-rx * (ox or 1), -ry * (oy or 1))
	self:setAnchorPoint(1/texture:getWidth(), 1/texture:getHeight())
end