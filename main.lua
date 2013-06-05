--[[
  [set remote debugging](macro:shell(ide.config.gideros = {remote = "192.168.1.100"}))
  [set local debugging](macro:shell(ide.config.gideros = nil))
--]]

print("-----------------------------------------------------------------------------| ", os.date(), " |--------->")
-- TODO: cleanup

xml = require "xmlSimple"
lpeg = require "lpeg.re"
--require("mobdebug").start()

application:setBackgroundColor(0xFFFFFF)

-- events: "transitionBegin", "transitionEnd"
local sceneManager = SceneManager.new {
    gameplay = GameplayScene,
    --["scene2"] = Scene2,
}
stage:addChild(sceneManager)

sceneManager:changeScene("gameplay", nil, nil, nil, {userData = "0/1"}) -- pass level?

local v = {
    0, 0, 400, 0, 700,200, 800, 200, 600, 300, 0, 400
}

if false then
    local m = SimpleMesh.new(v)
    m:setPosition(20, 20)
    stage:addChild(m)
end
