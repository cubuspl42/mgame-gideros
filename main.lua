--[[
This code is MIT licensed, see http://www.opensource.org/licenses/mit-license.php
(C) 2010 - 2011 Gideros Mobile 
]]
--[[
  [set remote debugging](macro:shell(ide.config.gideros = {remote = "192.168.1.100"}))
  [set local debugging](macro:shell(ide.config.gideros = nil))
--]]

require "box2d"
xml = require "xmlSimple"
--require("mobdebug").start()

application:setBackgroundColor(0xFFFFFF)

function tprint (tbl, indent)
    if not indent then indent = 0 end
    for k, v in pairs(tbl) do
        formatting = string.rep("  ", indent) .. k .. ": "
        if type(v) == "table" then
            print(formatting)
            tprint(v, indent+1)
        else
            print(formatting .. tostring(v))
        end
    end
end

-- events: "transitionBegin", "transitionEnd"
local sceneManager = SceneManager.new({
        gameplay = GameplayScene,
        --["scene2"] = Scene2,
})

stage:addChild(sceneManager)
sceneManager:changeScene("gameplay")

