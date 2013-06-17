--[[
  [set remote debugging](macro:shell(ide.config.gideros = {remote = "192.168.1.100"}))
  [set local debugging](macro:shell(ide.config.gideros = nil))
--]]
-- TODO: cleanup

print("-----------------------------------------------------------------------------| ", os.date(), " |--------->")
--require("mobdebug").start()

local lfs = require 'lfs'

application:setBackgroundColor(0xFFFFFF)
application:setKeepAwake(true)

-- Load data
data = {}

for entity in lfs.dir "data/entities" do
    if lfs.attributes(entity, "mode") == "directory" then
		print(entity)
		data[entity] = {}
		
    end
end

-- Logical dimensions
local ppi = application:getScreenDensity() -- pixels per inch
ppi = ppi or 150
--ppi = 400
local bmmpp = 0.04 -- base mm per pixel (7 mm / 100 px)
bmmpp = 0.035
local mmpp = (1/ppi)*25.4 -- mm per pixel (25.4 mm / 1 inch)
local w, h = application:getDeviceWidth(), application:getDeviceHeight()
local ratio = mmpp/bmmpp
print("bmmpp, mmpp, w, h, ratio", bmmpp, mmpp, w, h, ratio)
application:setLogicalDimensions(ratio * w, ratio * h)
print("logical w, h", application:getLogicalWidth(), application:getLogicalHeight())

-- Scene management
local sceneManager = SceneManager.new {
    gameplay = GameplayScene,
}
stage:addChild(sceneManager)
sceneManager:changeScene("gameplay", nil, nil, nil, {userData = "0/1"}) -- pass level?
