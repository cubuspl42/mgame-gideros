SVG = {}

function SVG.parseStyle(styleString) -- return table
    
end

function SVG.pathToVertices(pathTag) -- <path d="defString" />
    
end

function SVG.rectToVertices(rectTag) 
    
end

function SVG.pathDefToVertices(d)
    
end

local function cross(vx, vy, ovx, ovy)
    return vx * ovy - vy * ovx
end

function SVG.triangulatePolygon(vertices) -- {{x,y}...}
    local n = numVertices(vertices)
    local ret = {}
    while #vertices > 3 do
        for i, vertex in ipairs(vertices) do
            local x, y = vertex[0], vertex[1]
            local j = (i + 2) % #vertices
            local x1, y1 = vertices[j][0], vertices[j][1]
            local vx, vy = x1 - x, y1 - y
            
        end
    end
end




