SVG = {}

function SVG.parseStyle(styleString) -- return table
    
end

function SVG.pathToVertices(pathTag) -- <path d="defString" />
    
end

function SVG.rectToVertices(rectTag) 
    
end

function SVG.pathDefToVertices(d)
    
end

function SVG.triangulatePolygon(vertices) -- {{x=X,y=Y}...}
    return delaunay(vertices)
end




