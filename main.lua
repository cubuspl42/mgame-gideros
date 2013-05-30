--[[
  [set remote debugging](macro:shell(ide.config.gideros = {remote = "192.168.1.100"}))
  [set local debugging](macro:shell(ide.config.gideros = nil))
--]]


require "box2d"
xml = require "xmlSimple"
--require("mobdebug").start()

application:setBackgroundColor(0xFFFFFF)

-- events: "transitionBegin", "transitionEnd"
local sceneManager = SceneManager.new {
    gameplay = GameplayScene,
    --["scene2"] = Scene2,
}
stage:addChild(sceneManager)

sceneManager:changeScene("gameplay", nil, nil, nil, {userData = "0/1"}) -- pass level?

