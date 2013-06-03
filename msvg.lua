local msvg = {} -- API
local supportedTags = { svg = true, g = true, path = true, rect = true }
local path = {
	arc = require 'path_svgarc',
	line = require 'path_line',
	bezier2 = require 'path_bezier2',
}
local affine = require 'affine'

---- local functions ----

-- parsers --

local function parsePathDef(dString)
	if dString then
		local s, d = dString, {}
		for n, args in s:gmatch"(%a+)(%A*)" do
			local comm = {name = n}
			for val in args:gmatch"([%-]?[%d%.]+)" do		
				table.insert(comm, tonumber(val))
			end
			table.insert(d, comm)
		end
		return d
	end
end

local function parseTransform(transformString)
	local transform = {}
	--= affine.matrix()
	--print(transformString)
	if transformString then
		local s = transformString
		for f, args in s:gmatch"(%a+)%((%A*)%)" do
			--print("f=", f, args)
			local fn = {name = f}
			for val in args:gmatch"([%-]?[%d%.]+)" do
				--print("val=", val)
				table.insert(fn, tonumber(val))
			end
			table.insert(transform, fn)
		end	
	end
	return transform
end

local function parseStyle(styleString) --> style table
	local style = {}
	if styleString then
		--print("parseStyle", styleString)
		local s, d = styleString, {}
		for a, v in s:gmatch(";?([^;^:]+):([^;^:]+)") do
			style[a] = v
		end
	end
	return style
end

-- path commands --

local pathCommands = {}

local function absolute(rel, cx, cy, x, y, ...)
		if rel then
			x, y = cx + x, cy + y
		end
		return x, y, (... and absolute(rel, cx, cy, ...))
end

function pathCommands.moveto(rel, v, cx, cy, x, y, ...)
	cx, cy = absolute(rel, cx, cy, x, y)
	if ... then
		return pathCommands.lineto(rel, v, cx, cy, ...)
	end
	return cx, cy
end

function pathCommands.lineto(rel, v, cx, cy, x, y, ...)
	local px, py = get(v, -2), get(v, -1)
	if px ~= cx or py ~= cy then
		table.insertall(v, cx, cy)
	end
	cx, cy = absolute(rel, cx, cy, x, y)
	table.insertall(v, cx, cy)
	if ... then
		return pathCommands.lineto(rel, v, cx, cy, ...)
	end
	return cx, cy
end

function pathCommands.curveto(rel, v, cx, cy, x1, y1, x2, y2, x, y, ...)
	local px, py = get(v, -2), get(v, -1)
	if px ~= cx or py ~= cy then
		table.insertall(v, cx, cy)
	end
	x1, y1, x2, y2, cx, cy = absolute(rel, cx, cy, x1, y1, x2, y2, x, y)
	-- push vertices from curve
	if ... then
		return pathCommands.curveto(rel, v, cx, cy, ...)
	end
	return cx, cy
end

table.merge(pathCommands, {
	M = pathCommands.moveto,
	L = pathCommands.lineto,
})

-- base functions --

-- create new svgElement from xml tag
-- should take parent matrix?
local function newSvgElement(tag) --> svgElement
	if not supportedTags[tag:name()] then return end
	local svgElement = {
		-- a lot of these will be nil. who cares
		name = tag:name(),
		id = tonumber(tag['@id']),
		label = tag['@inkscape:label'],
		title = tag.title and tag.title[1]:value(),
		desc = tag.desc and tag.desc[1]:value(),
		style = parseStyle(tag['@style']),
		transform = parseTransform(tag['@transform']),
		children = {},
		
		width = tonumber(tag['@width']), -- svg, rect
		height = tonumber(tag['@height']),  -- svg, rect
		x = tonumber(tag['@x']), -- rect
		y = tonumber(tag['@y']), -- rect
		d = parsePathDef(tag['@d']) -- path
	}
	for _, childTag in ipairs(tag:children()) do
		local svgChildElement = newSvgElement(childTag)
		if svgChildElement then
			table.insert(svgElement.children, svgChildElement)
		end
	end
	return svgElement
end

local function simplifyElement(svgElement) --> nil
	print("simplifyElement")
	local e = svgElement
	if e.name == "path" then
		local v = { close = false }
		e.vertices = v
		local cx, cy = 0, 0
		for i, comm in ipairs(e.d) do
			local n = comm.name
			local N = string.upper(n)
			local commandFn = pathCommands[N]
			if commandFn then
				cx, cy = commandFn(n ~= N, v, cx, cy, unpack(comm))
				-- cx? cy? 'z'?
			else 
				print("unimplemented path command: ", N)
			end
		end
	elseif e.name == "rect" then
		local w, h = e.width, e.height
		e.vertices = {  e.x, e.y, e.x + w, e.y, 
						e.x + w, e.y + h, e.x, e.y + h,
						close = true }
	else 
		print("not simplifying ", e.name)
	end
	for _, child in ipairs(svgElement.children) do
		--[[ multiply matrices... here?
		local t, ct = svgElement.transform, child.transform
		if t and ct then
			ct = ct * t
		end
		--]]
		simplifyElement(child)
	end
end

local function loadFile(svgTree, filename) 
	local xmlDoc = xml.newParser():loadFile(filename)
	svgTree.root = newSvgElement(xmlDoc:children()[1])
end

local function loadString(svgTree, s)
	local xmlDoc = xml.newParser():ParseXmlText(s)
	svgTree.root = newSvgElement(xmlDoc:children()[1])
end

local function simplifyTree(svgTree)
	simplifyElement(svgTree.root)
end

function msvg.newTree()
	return {
		loadFile = loadFile,
		loadString = loadString,
		simplify = simplifyTree,
	}
end

return msvg
