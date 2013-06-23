--[[
  [set remote debugging](macro:shell(ide.config.gideros = {remote = "192.168.1.100"}))
  [set local debugging](macro:shell(ide.config.gideros = nil))
--]]
-- TODO: cleanup

print("-----------------------------------------------------------------------------| ", os.date(), " |--------->")
--require("mobdebug").start()

local lfs = require 'lfs'
local msvg = require 'msvg'
local Polygon = require 'polygon'

local function loadData()
    -- Load data
    data = {
        entities = {}
    }
    for entity in lfs.dir "data/entities" do
        local path = "data/entities/"..entity
        local mode = lfs.attributes(path, "mode")
        if mode == "directory" and entity:sub(1, 1) ~= '.' then
            print("Loading data for " .. entity)
            -- We found an entity
            local e = { layers = {} }
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
            for layer in lfs.dir(path .. "/img") do
                if layer:sub(1, 1) ~= "." then
                    e.layers[layer] = e.layers[layer] or {}
                    local imgpath = path .. "/img/" .. layer
                    --print("Loading texture...")
                    -- AIR will pick the right size
                    e.layers[layer].texture = Texture.new(imgpath .. "/img.png", true)
                    local offsetFile = io.open(imgpath .. "/offset.lua")
                    if offsetFile then
                        local env = {}
                        local ok, msg = run(offsetFile:read("*a"), env)
                        if not ok or not env.x or not env.y then
                            error("Error running " .. imgpath .. "/offset.lua: ", msg)
                        else
                            e.layers[layer].offsetX, e.layers[layer].offsetY = env.x, env.y
                        end
                    else 
                        print("No offset file for " .. folder)
                    end
                end
            end
            -- Add fixtures
            local base = assert(msvg.loadFile(path .. "/dev_base.svg")) -- TODO: dev_base -> base!
            msvg.simplifyTree(base)
            for layer in all(base.children) do
                if layer.name == "g" then
                    local label = layer.label
                    print("Loading fixtures for " .. label)
                    e.layers[label] = e.layers[label] or {}
                    e.layers[label].fixtures = {}
                    for object in all(layer.children) do
                        if object.title then
                            print("Loading object " .. object.id)
                            local fixture = {
                                tag = object.title,
                                shape = b2.PolygonShape.new()
                            }
                            -- We create Polygon because it will make sure that the order is CW
                            local polygon = Polygon.new(unpack(object.vertices))
                            Polygon.move(polygon, -e.layers[label].offsetX, -e.layers[label].offsetY)
                            fixture.shape:set(Polygon.unpack(polygon))
                            --fixture.shape:set(0, 0, 10, 0, 0, 10)
                            table.insert(e.layers[label].fixtures, fixture)
                        end
                    end
                end
            end
        end
    end
end

local function setLogicalDimensions()
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
end

application:setBackgroundColor(0xFFFFFF)
application:setKeepAwake(true)

loadData()
--setLogicalDimensions()

-- Scene management
local sceneManager = SceneManager.new {
    gameplay = GameplayScene,
}

stage:addChild(sceneManager)
sceneManager:changeScene("gameplay", nil, nil, nil, {userData = "0/1"}) -- pass level?
