local affine = require 'affine'
local path = {
	arc = require 'path_svgarc',
	line = require 'path_line',
	bezier2 = require 'path_bezier2',
	bezier3 = require 'path_bezier3',
	point = require 'path_point',
}

local msvg = {} -- API
local supportedTags = { svg = true, g = true, path = true, rect = true }
local arcStepConst = 10

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
	local transform = affine.matrix()
	if transformString then
		local s = transformString
		local env = {}
		function env.matrix(...)
			transform = affine.matrix(...) * transform
		end
		function env.translate(...)
			transform = affine.trans(...) * transform
		end
		local ok = run(transformString, env)
		-- do we care if ok?
	end
	return transform
end

local function parseStyle(styleString) --> style table
	local style = {}
	if styleString then
		--print("parseStyle", styleString)
		local s, d = styleString, {}
		for a, v in s:gmatch(";?([^;^:]+):([^;^:]+)") do
			a = a:gsub("-", "_")
			style[a] = v
		end
	end
	return style
end

-- path commands implementations --

-- converts relative coords to absolute, if necessary
local function absolute(rel, cx, cy, x, y, ...)
		if not x then return end -- because of recursion
		if rel then
			x, y = cx + x, cy + y
		end
		return x, y, absolute(rel, cx, cy, ...)
end

local pathCommands = {}

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
		--print("lineto preinsert cx, cy: ", cx, cy)
		table.insertall(v, cx, cy)
	end
	-- this logic above is in every pathCommand, make it common?
	x, y = absolute(rel, cx, cy, x, y)
	--print("lineto insert cx, cy: ", cx, cy)
	table.insertall(v, x, y)
	if ... then
		return pathCommands.lineto(rel, v, x, y, ...)
	end
	return x, y
end

function pathCommands.curveto(rel, v, cx, cy, x1, y1, x2, y2, x, y, ...)
	--print("curveto")
	local px, py = get(v, -2), get(v, -1)
	if px ~= cx or py ~= cy then
		table.insertall(v, cx, cy)
	end
	x1, y1, x2, y2, x, y = absolute(rel, cx, cy, x1, y1, x2, y2, x, y)
	-- push vertices from curve
	local l = path.bezier3.length(1, cx, cy, x1, y1, x2, y2, x, y)
	local steps = l/15 -- experimental value; unit: svg px
	for i=1,steps do
		local tx, ty = path.bezier3.point(i/steps, cx, cy, x1, y1, x2, y2, x, y)
		table.insertall(v, tx, ty)
	end
	if ... then
		return pathCommands.curveto(rel, v, x, y, ...)
	end
	return x, y
end

function pathCommands.arc(rel, v, cx, cy, rx, ry, x_axis_rotation, large_arc_flag, sweep_flag, x, y, ...)
	--print("arc")
	local px, py = get(v, -2), get(v, -1)
	if px ~= cx or py ~= cy then
		table.insertall(v, cx, cy)
	end
	x, y = absolute(rel, cx, cy, x, y)
	local l = path.point.distance(cx, cy, x, y) -- there is no path.arc.length, so we use distance instead
	local steps = l/arcStepConst -- experimental value; unit: svg px
	for i=1,steps do
		local tx, ty = path.arc.point(i/steps, cx, cy, rx, ry, x_axis_rotation, large_arc_flag, sweep_flag, x, y)
		table.insertall(v, tx, ty)
	end
	if ... then
		return pathCommands.arc(rel, v, x, y, ...)
	end
	return x, y
end

function pathCommands.close(rel, v)
	v.close = true
end

table.merge(pathCommands, {
	M = pathCommands.moveto,
	L = pathCommands.lineto,
	C = pathCommands.curveto,
	Z = pathCommands.close,
	A = pathCommands.arc,
})

-- base functions --

-- create new svgElement from xml tag
local function newSvgElement(tag) --> svgElement
	if not supportedTags[tag:name()] then return end
	local svgElement = {
		-- a lot of these will be nil - who cares
		children = {},
		name = tag:name(),
		id = tag['@id'],
		label = tag['@label'],
		
		title = tag.title and tag.title[1]:value(),
		desc = tag.desc and tag.desc[1]:value(),
		
		style = parseStyle(tag['@style']),
		transform = parseTransform(tag['@transform']),
		
		width = tonumber(tag['@width']), -- svg, rect
		height = tonumber(tag['@height']),  -- svg, rect
		x = tonumber(tag['@x']), -- rect
		y = tonumber(tag['@y']), -- rect
		d = parsePathDef(tag['@d']) -- path
	}
	print("element: ", svgElement.name)
	tprint(svgElement.transform)
	for childTag in all(tag:children()) do
		local svgChildElement = newSvgElement(childTag)
		if svgChildElement then
			table.insert(svgElement.children, svgChildElement)
		end
	end
	return svgElement
end

local function simplifyElement(svgElement) --> nil
	local e = svgElement
	-- Inkscape doesn't seem to export tags other then 'path' and 'rect'
	if e.name == "path" then
		local v = { close = false }
		e.vertices = v
		local cx, cy = 0, 0 -- current x, y
		for comm in all(e.d) do
			local n = comm.name
			local N = string.upper(n)
			local commandFn = pathCommands[N]
			if commandFn then
				cx, cy = commandFn(n ~= N, v, cx, cy, unpack(comm))
				if not cx then break end -- 'path is closed (z)'
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
		--print("not simplifying ", e.name)
	end
	local v = e.vertices
	if v then
		for i=1,#v,2 do
			-- apply transform
			v[i], v[i+1] = e.transform(v[i], v[i+1])
		end
	end
	for child in all(e.children) do
		-- apply child transform
		child.transform = e.transform * child.transform
		simplifyElement(child)
	end
end

local function meta_load(method)
	return function (svgTree, filename)
		local p = xml.newParser()
		local xmlDoc = p[method](p, filename)
		svgTree.root = newSvgElement(xmlDoc:children()[1])
	end
end

-- next two are replaced with meta function above
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
		loadFile = meta_load('loadFile'),
		loadString = meta_load('loadString'),
		simplify = simplifyTree,
	}
end

return msvg
