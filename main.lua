--[[
  [set remote debugging](macro:shell(ide.config.gideros = {remote = "192.168.1.100"}))
  [set local debugging](macro:shell(ide.config.gideros = nil))
--]]

require "box2d"
xml = require "xmlSimple"
--require("mobdebug").start()

application:setBackgroundColor(0xFFFFFF)

function tprint (tbl, depth, indent)
	if not depth then depth = -1 end
    if not indent then indent = 0 end
    for k, v in pairs(tbl) do
        formatting = string.rep("  ", indent) .. k .. ": "
        if depth ~= 0 and type(v) == "table" then
            print(formatting)
            tprint(v, depth - 1, indent+1)
        else
            print(formatting .. tostring(v))
        end
    end
end

local function xmlFromFile(filename)
    return xml.newParser():loadFile(filename)
end

-- events: "transitionBegin", "transitionEnd"
local sceneManager = SceneManager.new {
    gameplay = GameplayScene,
    --["scene2"] = Scene2,
}
stage:addChild(sceneManager)

sceneManager:changeScene("gameplay", "0/1") -- pass level?

