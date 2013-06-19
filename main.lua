--[[
  [set remote debugging](macro:shell(ide.config.gideros = {remote = "192.168.1.100"}))
  [set local debugging](macro:shell(ide.config.gideros = nil))
--]]
-- TODO: cleanup

print("-----------------------------------------------------------------------------| ", os.date(), " |--------->")
--require("mobdebug").start()

local lfs = require 'lfs'
local msvg = require 'msvg'

application:setBackgroundColor(0xFFFFFF)
application:setKeepAwake(true)

-- Load data
data = {
	entities = {}
}
for entity in lfs.dir "data/entities" do
	if entity:sub(1, 1) ~= '.' then
		local path = "data/entities/"..entity
		local mode = lfs.attributes(path, "mode")
		if mode == "directory" then
			-- We found an entity
			local e = { img = {}, bodyDef = {}, fixtures = {} }
			data.entities[entity] = e
			-- Add anim
			e.scml = SCMLParser.loadFile(path .. "/anim.scml") -- can be nil
			local logicFile = io.open(path .. "/logic.lua")
			if logicFile then
				-- logic.lua can read global vars, but can't create them
				local env = setmetatable({}, {__index = _G})
				local ok, msg = run(logicFile:read("*a"), env)
				if not ok then 
					print("Could not run file " .. path .. "/logic.lua", msg)
				else
					-- Add logic
					e.logic = env
				end
			end
			-- Add textures
			for folder in lfs.dir(path .. "/img") do
				if folder:sub(1, 1) ~= "." then
					local imgpath = path .. "/img/" .. folder
					--print("Loading texture...")
					-- AIR will pick the right size
					e.img[folder] = Texture.new(imgpath .. "/img.png", true)
					local offsetFile = io.open(imgpath .. "/offset.lua")
					if offsetFile then
						local env = {}
						local ok, msg = run(offsetFile:read("*a"), env)
						if not ok or not env.x or not env.y then
							error("Error running " .. imgpath .. "/offset.lua: ", msg)
						else
							e.x, e.y = env.x, env.y
						end
					else 
						print("No offset file for " .. folder)
					end
				end
			end
			-- Add bodyDef
			e.base = msvg.loadFile(path .. "/dev_base.svg") -- TODO: dev_base -> base!
			msvg.simplifyTree(e.base)
			for layer in all(e.base.children) do
				if layer.name == "g" and layer.desc then
					local l = layer.label
					local env = setmetatable({}, {__index = _G})
					local ok, ret = run("return " .. layer.desc, env)
					if not ok then 
						error("Could not run 'desc' of layer with id " .. c.id, ret)
					else
						print("Adding bodyDef for " .. l)
						e.bodyDef[l] = ret
						e.fixtures[l] = {}
					end
				
					for c in all(layer.children) do
						if c.desc then
							local env = setmetatable({}, {__index = _G})
							local ok, ret = run("return " .. c.desc, env)
							if not ok then 
								error("Could not run 'desc' of element with id " .. l.id, ret)
							else
								table.insert(e.fixtures[l], ret)
							end
						end
					end
				end
			end
		end
	end
end

-- Logical dimensions
local ppi = application:getScreenDensity() -- pixels per inch
ppi = ppi or 150
--ppi = 400
local bmmpp = 0.04 -- base mm per pixel (7 mm / 100 px)
bmmpp = 0.035
--bmmpp = 0.1
local mmpp = (1/ppi)*25.4 -- mm per pixel (25.4 mm / 1 inch)
local w, h = application:getDeviceWidth(), application:getDeviceHeight()
local ratio = mmpp/bmmpp
application:setLogicalDimensions(ratio * w, ratio * h)
--print("bmmpp, mmpp, w, h, ratio", bmmpp, mmpp, w, h, ratio)
--print("logical w, h", application:getLogicalWidth(), application:getLogicalHeight())

-- Scene management
local sceneManager = SceneManager.new {
    gameplay = GameplayScene,
}
stage:addChild(sceneManager)
sceneManager:changeScene("gameplay", nil, nil, nil, {userData = "0/1"}) -- pass level?
