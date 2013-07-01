OffsetBitmap = Core.class(Bitmap)

-- This class adds 1 physical pixel offset to Bitmap

function OffsetBitmap:init(texture, ox, oy)
    rx = application:getDeviceWidth()/application:getLogicalWidth()
    ry = application:getDeviceHeight()/application:getLogicalHeight()
    self:setAnchorPoint(1/texture:getWidth(), 1/texture:getHeight())
end