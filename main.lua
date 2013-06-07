--[[
  [set remote debugging](macro:shell(ide.config.gideros = {remote = "192.168.1.100"}))
  [set local debugging](macro:shell(ide.config.gideros = nil))
--]]
-- TODO: cleanup

print("-----------------------------------------------------------------------------| ", os.date(), " |--------->")
--require("mobdebug").start()

application:setBackgroundColor(0xFFFFFF)
application:setKeepAwake(true)

-- Logical dimensions
local ppi = application:getScreenDensity() -- pixels per inch
ppi = ppi or 135
local bmmpp = 0.07 -- base mm per pixel (7 mm / 100 px)
local mmpp = (1/ppi)*25.4 -- mm per pixel (25.4 mm / 1 inch)
local w, h = application:getDeviceWidth(), application:getDeviceHeight()
local ratio = mmpp/bmmpp
print("bmmpp, mmpp, w, h, ratio", bmmpp, mmpp, w, h, ratio)
application:setLogicalDimensions(ratio * w, ratio * h)
print("logical w, h", application:getLogicalWidth(), application:getLogicalHeight())

-- Scene managment
local sceneManager = SceneManager.new {
    gameplay = GameplayScene,
}
stage:addChild(sceneManager)
sceneManager:changeScene("gameplay", nil, nil, nil, {userData = "0/1"}) -- pass level?
