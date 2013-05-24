SCMLFile = Core.class()

local function attribValue(tag, attrib, default)
    return tag["@"..attrib] or default
end

local function toLuaIndex(index)
    if index then return tonumber(index) + 1 end
end

function SCMLFile:init(filename, loaderFunction)
    self.entities = {}
    
    local scml = xml.newParser():loadFile(filename)
    scml = scml.spriter_data
    if not scml then
        print ("File ".. filename .." is not SCML file")
        return
    end
    
    print("loading scml " .. filename)
    scml:createTable("entity")
    scml:createTable("folder")
    for i, folderTag in ipairs(scml.folder) do
        folderTag:createTable("file")
    end
    
    for i, entityTag in ipairs(scml.entity) do
        -- Load entity
        entityTag:createTable("animation")
        
        print("loading entity " .. entityTag["@name"])
        
        local entity = SCMLEntity.new()
        entity.name = attribValue(entityTag, "name", "<unanmed>")
        entity.animations = {}
        self.entities[i] = entity
        
        for l, animationTag in ipairs(entityTag.animation) do
            -- Load animation
            local animationName = attribValue(animationTag, "name", "<unnamed>")
            
            local anim = Sprite.new()
            anim.objects = {} -- timeline objects
            anim.looping = toboolean(animationTag["@looping"] or 1)
            anim.length = tonumber(animationTag["@length"] or 1000)
            entity.animations[animationName] = anim
            print("loading animation " .. animationName)
            
            -- Load timeline
            for j, timelineTag in ipairs(animationTag.timeline) do
                timelineName = timelineTag["@name"] or "object-" .. timelineTag["@id"]
                print ("adding timeline (object) " .. timelineName)
                
                local object = Sprite.new()
                object.name = timelineName
                object.keys, object.sprites = {}, {}				
                anim.objects[j] = object
                
                -- Load keys
                timelineTag:createTable("key")
                for k, keyTag in ipairs(timelineTag.key) do
                    
                    print ("adding key " .. keyTag["@id"])
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
                    if objectTag["@folder"] then
                        local folderIndex = objectTag["@folder"] + 1
                        local fileIndex = objectTag["@file"] + 1
                        local spriteName = scml.folder[folderIndex].file[fileIndex]["@name"]
                        if not object.sprites[spriteName] then
                            print("loading sprite " .. spriteName)
                            object.sprites[spriteName] = loaderFunction(spriteName) -- change name of loader?
                        end
                        key.sprite = object.sprites[spriteName] -- can be nil?
                    else
                        key.sprite = loaderFunction()
                    end
                    
                end
            end
            
            -- Load mainline
            anim.keys = {} -- mainline keys
            animationTag.mainline:createTable("key")
            for j, keyTag in ipairs(animationTag.mainline.key) do
                local key = { refs = {} }
                key.time = tonumber(keyTag["@time"] or 0)
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
    end
end