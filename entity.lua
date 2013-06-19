Entity = Core.class(Sprite)

function Entity:init(name, world)
	local e = data.entities[name]
	if not e then error("No entity named " .. name) end
	
	if e.scml then
		print("Loading scml for " .. name)
		local function scmlLoader(filename)
			local bitmap = nil
			if filename then
				local objectName = filename:match("dev_img/([^/]+)/")
				--print("objectName", objectName)
				ok, bitmap = pcall(function()
						-- is pcall needed? dev_ layers?
						-- Physics Sprite
						return OffsetBitmap.new(e.layers[objectName].texture)
				end)
				if not ok then 
					bitmap = nil
					print("Warning: Couldn't load bitmap for " .. filename)
				end
			end
			return SCMLSprite.new(bitmap, 1/4)
		end
		self.scml = e.scml:createEntity(0, scmlLoader)
		self:addChild(self.scml)
	end
	
	if e.logic then
		local l = e.logic
		if l.on_tick then
			self:addEventListener("enterFrame", l.on_tick, self)
		end
		if l.on_colision then
			world:addEventListener("preSolve", function(e)
				
				l.on_colision(self) --...
			end)
		end
		if l.on_init then
			l.on_init(self)
		end
		self.logic = l
	end
end
