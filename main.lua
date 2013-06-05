--[[
  [set remote debugging](macro:shell(ide.config.gideros = {remote = "192.168.1.100"}))
  [set local debugging](macro:shell(ide.config.gideros = nil))
--]]

print("------------------------------------------------------| ", os.date(), " |--------->")
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
0, 0, 400, 0, 700,200, 400, 400, 0, 400
}

--local tri = triangulate(v)
local va = require 'vertexarray'

--[[
for i, t in ipairs(tri) do
	print(t[1], t[2], t[3])
	print(va.get(v, t[1]))
	print(va.get(v, t[2]))
	print(va.get(v, t[3]))
end
--]]

local m = SimpleMesh.new(v)
m:setPosition(20, 20)
stage:addChild(m)

--tprint(triangulate(v))
