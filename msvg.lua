-- msvg - micro svg library for loading and simplifying Inkscape SVG files

local matrix = require 'affine2d'
local path = require 'path'

local msvg = {} -- API
local supportedTags = { svg = true, g = true, path = true, rect = true }
local arcStepConst = 7 -- experimental values; unit: svg px
local curveStepConst = 5

---- local functions ----

-- path commands implementations --

local pathCommands = {}

local path_cmd = {
        m = 'rel_move',
        M = 'move',
        l = 'rel_line',
        L = 'line',
        z = 'close',
        Z = 'close',
        h = 'rel_hline',
        H = 'hline',
        v = 'rel_vline',
        V = 'vline',
        c = 'rel_curve',
        C = 'curve',
        s = 'rel_symm_curve',
        S = 'symm_curve',
        q = 'rel_quad_curve',
        Q = 'quad_curve',
        t = 'rel_symm_quad_curve',
        T = 'symm_quad_curve',
        a = 'rel_svgarc',
        A = 'svgarc',
}

local path_argc = {
        rel_move = 2,
        move = 2,
        rel_line = 2,
        line = 2,
        close = 0,
        rel_hline = 1,
        hline = 1,
        rel_vline = 1,
        vline = 1,
        rel_curve = 6,
        curve = 6,
        rel_symm_curve = 4,
        symm_curve = 4,
        rel_quad_curve = 4,
        quad_curve = 4,
        rel_symm_quad_curve = 2,
        symm_quad_curve = 2,
        rel_svgarc = 7,
        svgarc = 7,
}

-- parsers --

local function processCommand(i, pathData, s, ...)
	if s ~= 'close' and not ... then return end
	local n = path_argc[s]
	local cmd_name = s
	if i == 1 and s == 'rel_move' then
		cmd_name = 'move'
	end
	path.append_cmd(pathData, cmd_name, unpack({...}, 1, n))
	
	if s == 'close' then return end
	if s == 'move' then s = 'line' end
	if s == 'rel_move' then s = 'rel_line' end
	processCommand(i + 1, pathData, s, select(n + 1, ...))
end

local function parsePathData(dString)
    if dString then
        local pathData = {}
        for s, argsString in dString:gmatch"([a-df-zA-DF-Z])([^a-df-zA-DF-Z]*)" do
			s = path_cmd[s]
            local args = {}
            for number in argsString:gmatch"([%-]?[%deE.%-]+)" do		
                table.insert(args, tonumber(number))
            end
			processCommand(1, pathData, s, unpack(args))
        end
        return pathData
    end
end

local function parseTransform(transformString, parentTransform) --> affine matrix
    local mt = parentTransform and parentTransform:copy() or matrix()
    if transformString then
        local env = {}
        function env.matrix(...)
            mt:set(...)
        end
        function env.translate(...)
            mt:translate(...)
        end
        local ok = run(transformString, env)
        -- do we care if ok?
    end
    return mt
end

local function parseStyle(styleString, parentStyle) --> style table
    local style = table.copy(parentStyle or {})
    if styleString then
        for attr, val in styleString:gmatch(";?([^;^:]+):([^;^:]+)") do
            style[attr] = val
        end
    end
    return style
end

-- create new svgElement from xml tag
local function newSvgElement(tag, parentElement) --> svgElement
    if not supportedTags[tag:name()] then return end
    local svgElement = {
        -- a lot of these will be nil, depending on actual tag - who cares
        children = {},
        name = tag:name(),
        id = tag['@id'],
        label = tag['@label'],
        
        title = tag.title and tag.title[1]:value(),
        desc = tag.desc and tag.desc[1]:value(),
        
        style = parseStyle(tag['@style'], parentElement and parentElement.style or {}),
        transform = parseTransform(tag['@transform'], parentElement and parentElement.transform),
		d = parsePathData(tag['@d']), -- path
        
        width = tonumber(tag['@width']), -- svg, rect
        height = tonumber(tag['@height']),  -- svg, rect
        x = tonumber(tag['@x']), -- rect
        y = tonumber(tag['@y']), -- rect
    }
	
    for childTag in all(tag:children()) do
        local svgChildElement = newSvgElement(childTag, svgElement)
        if svgChildElement then
            table.insert(svgElement.children, svgChildElement)
        end
    end
	
    return svgElement
end

local curve_ai = require 'path_bezier3_ai'
local quad_curve_ai = require 'path_bezier2_ai'

-- return pathData simplified down to 'move', 'line', 'close' commands
function msvg.simplifyElement(svgElement, mt) --> simplifiedPath
	if not svgElement.d then return end -- TODO: support 'rect'!
	local pathData = svgElement.d
	local simplifiedPathData = {}

	local transform = svgElement.transform -- can be nil
	if transform and mt then
		transform = mt * transform
	end
	
	local approximation_scale = 1
	local transform_points = path.transform_points
	
	local function write(s, ...)
		path.append_cmd(simplifiedPathData, s, ...)
	end
	local function processor(write, mt, i, s, ...)
		if s == "curve" or s == "quad_curve" then
			local args = { write, transform_points(transform, ...) }
			table.insert(args, approximation_scale)
			local ai = (s == "curve") and curve_ai or quad_curve_ai
			ai(unpack(args))
		elseif s == "line" then
			write(s, transform_points(transform, select(3, ...)))
		elseif s == "move" then
			write(s, transform_points(transform, ...))
		elseif s == "close" then
			local cpx, cpy, spx, spy = transform_points(transform, ...)
			if cpx ~= spx or cpy ~= spy then
                write('line', spx, spy)
			end
			write('close')
		else return false end
	end
	
	path.decode_recursive(processor, write, pathData)
	return simplifiedPathData
end

function msvg.loadFile(filename) 
    local svgFile = io.open(filename)
    if svgFile then
        return msvg.loadString(svgFile:read("*a"))
    end
end

function msvg.loadString(s)
    local xmlDoc = xml.newParser():ParseXmlText(s)
    return newSvgElement(xmlDoc:children()[1])
end

return msvg
