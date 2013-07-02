SCMLParser = Core.class()

local function attribValue(tag, attrib, default)
    return tag["@"..attrib] or default
end

local function toLuaIndex(index)
    if index then return tonumber(index) + 1 end
end

function SCMLParser.loadFile(filename)
    local ok, ret = pcall(function() 
            return xml.newParser():loadFile(filename)
    end)
    if ok then
        local spriter_data = (ret.spriter_data or {})[1]
        if not spriter_data then
            print(filename .. " is not SCML file")
            return nil
        end
        -- pcall?
        return SCMLParser.new(spriter_data)
    else
        print("Could not load " .. filename .. " - " .. ret)
        return nil
    end
end

function SCMLParser:init(spriter_data)
    self.scml = spriter_data
end

function SCMLParser:createEntity(id, loaderFunction)
    local scml = self.scml
    --tprint(scml, 1)
    --print(scml.entity)
    if not scml or not scml.entity then return end
    local entityTag = scml.entity[id + 1]
    
    -- Load entity
    print("Loading scml entity " .. entityTag["@name"])
    
    local entity = SCMLEntity.new()
    entity.name = attribValue(entityTag, "name", "<unnamed>")
    entity.animations = {}
    
    for l, animationTag in ipairs(entityTag.animation) do
        -- Load animation
        local animationName = attribValue(animationTag, "name", "<unnamed>")
        
        local anim = Sprite.new()
        anim.objects = {} -- timeline objects
        anim.looping = toboolean(animationTag["@looping"] or 1)
        anim.length = tonumber(animationTag["@length"]) or 1000
        entity.animations[animationName] = anim
        --print("loading animation " .. animationName)
        
        -- Load timeline
        for j, timelineTag in ipairs(animationTag.timeline) do
            timelineName = timelineTag["@name"] or "object-" .. timelineTag["@id"]
            --print ("adding timeline (object) " .. timelineName)
            
            local object = Sprite.new()
            object.name = timelineName
            object.keys = {}
            --object.sprites = {}				
            anim.objects[j] = object
            
            -- Load keys
            for k, keyTag in ipairs(timelineTag.key) do
                --print ("adding key " .. keyTag["@id"])
                -- it's actually either 'object' or 'bone', they don't differ much
                local objectTag = keyTag:children()[1]
                
                -- Load key params
                local key = {
                    time = tonumber(keyTag["@time"]) or 0,
                    spin = tonumber(keyTag["@spin"]) or 1,
                    params = {
                        x = tonumber(objectTag["@x"]) or 0,
                        y = tonumber(objectTag["@y"]) or 0,
                        rotation = tonumber(objectTag["@angle"]) or 0,
                        scaleX = tonumber(objectTag["@scale_x"]) or 1,
                        scaleY = tonumber(objectTag["@scale_y"]) or 1,
                        pivotX = tonumber(objectTag["@pivot_x"]) or 0,
                        pivotY = tonumber(objectTag["@pivot_y"]) or 1,
                    }
                }
                object.keys[k] = key
                
                -- Load sprite
                local spriteFilename = nil
                if objectTag["@folder"] then
                    local folderIndex = objectTag["@folder"] + 1
                    local fileIndex = objectTag["@file"] + 1
                    spriteFilename = scml.folder[folderIndex].file[fileIndex]["@name"]
                end
                key.sprite = loaderFunction(spriteFilename)
            end
        end
        
        -- Load mainline
        anim.keys = {} -- mainline keys
        for j, keyTag in ipairs(animationTag.mainline[1].key) do
            local key = { refs = {} }
            key.time = tonumber(keyTag["@time"]) or 0
            anim.keys[j] = key
            
            for k, refTag in ipairs(keyTag:children()) do
                local ref = {}
                key.refs[k] = ref
                local timelineId = refTag["@timeline"] + 1
                local keyId = refTag["@key"] + 1
                ref.object = anim.objects[timelineId]
                ref.index = keyId
                local parentBoneRefId = toLuaIndex(refTag["@parent"])
                if parentBoneRefId then
                    ref.parent = key.refs[parentBoneRefId].object
                end
            end
        end
    end
    return entity
end
