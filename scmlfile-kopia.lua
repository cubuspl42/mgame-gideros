SCMLFile = Core.class()

function SCMLFile:init(filename, loaderFunction)
    self.entities = {}
    
    local scml = xml.newParser():loadFile(filename)
    if(scml.spriter_data) then
        scml = scml.spriter_data
    else 
        print ("File ".. filename .." is not SCML file")
    end
    
    print("loading scml " .. filename )
    scml:createTable("entity")
    scml:createTable("folder")
    for i, folderTag in ipairs(scml.folder) do
        folderTag:createTable("file")
    end
    
    -- LOAD ENTITY
    for i, entityTag in ipairs(scml.entity) do
        entityTag:createTable("animation")
        print("loading entity " .. entityTag["@name"])
        local entity = SCMLEntity.new()
        entity._animations = {}
        self.entities[i] = entity
        
        --stage:addChild(entity) -- TEMP
        
        -- LOAD ANIMATION
        for l, animationTag in ipairs(entityTag.animation) do
            local animationName = animationTag["@name"]
            
            local animation = Sprite.new()
            animation.objects = {}
            animation.looping = animationTag["@looping"] or 1
            animation.looping = toboolean(animation.looping)
            animation.length = tonumber(animationTag["@length"])
            entity._animations[animationName] = animation
            print("loading animation " .. animationName)
            
            -- LOAD TIMELINE
            for j, timelineTag in ipairs(animationTag.timeline) do
                timelineName = timelineTag["@name"] or timelineTag["@id"]
                print ("adding timeline (object) " .. timelineName)
                local object = Sprite.new()
                object.index = 1
                animation.objects[j] = object
                
                object.name = timelineName
                --animation:addChild(object) -- TEMP
                object.keys, object.sprites = {}, {}
                
                -- LOAD KEYS
                for k, keyTag in ipairs(timelineTag.key) do
                    print ("adding key " .. keyTag["@id"])
                    local objectTag = keyTag:children()[1]
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
                    for _, k in pairs{ "y", "rotation" } do
                        if key.params[k] then key.params[k] = -key.params[k] end
                    end
                    
                    if objectTag["@folder"] then
                        local folder_index = objectTag["@folder"] + 1
                        local file_index = objectTag["@file"] + 1
                        local sprite_name = scml.folder[folder_index].file[file_index]["@name"]
                        if not object.sprites[sprite_name] then
                            print("loading sprite " .. sprite_name)
                            object.sprites[sprite_name] = loaderFunction(sprite_name)
                            print(object.name .. " will be a parent of sprite " .. sprite_name)
                            --object:addChild(object.sprites[sprite_name])
                        end
                        object.keys[k].sprite = object.sprites[sprite_name] -- can be nil
                    end
                    
                end
            end
            
            
            -- CREATE HIERARCHY
            animationTag.mainline:createTable("key")
            local mainlineChildren = animationTag.mainline.key[1]:children()
            for j, refTag in ipairs(mainlineChildren) do
                local objectId = refTag["@timeline"] + 1
                local parentId = refTag["@parent"]
                local object = animation.objects[objectId]
                if not parentId then
                    animation:addChild(object)
                else
                    local parentObjectId = mainlineChildren[parentId + 1]["@timeline"] + 1
                    local parentObject = animation.objects[parentObjectId]
                    print(parentObject.name .." will be a parent of " .. object.name)
                    parentObject:addChildAt(object, 1)
                end
            end
        end
    end
    
    
    
end