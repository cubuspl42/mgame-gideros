MapLoader = {}
local tag = {}

local function visitTag(p, t)
	if tag[t:name()] then
		local item = tag[t:name()](t)
		if item then	
			p:addChild(item)
		end
	end
	
end

function tag.g(t)
	local g = Sprite.new()
	local transform = t['@transform']
	print("transform = ", transform)
	if transform then
		local global = preserve("matrix", "translate")
	
		function matrix(...)
			print("matrix called with ", ...)
			g:setMatrix(Matrix.new(...))
		end
	
		function translate(...)
			print("translate called with ", ...)
			g:setPosition(...)
		end
		
		local chunk = loadstring(transform)
		if chunk then
			chunk()
		end
	
		revert(global)
	end
	for i, child in ipairs(t:children()) do
		visitTag(g, child)
	end
end

function tag.path(t)
	print "visit path"
end

function MapLoader.loadMap(svgTag)
	local mapLayer = Sprite.new()
    for i, child in ipairs(svgTag:children()) do
		visitTag(mapLayer, child)
	end
	return mapLayer
end