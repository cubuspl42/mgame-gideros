--[[
 
Copyright (c) 2010 David Ng
 
Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
 
The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.
 
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
 
Based of the work of  Paul Bourke (1989), Efficient Triangulation 
Algorithm Suitable for Terrain Modelling.
http://local.wasp.uwa.edu.au/~pbourke/papers/triangulate/index.html
 
--]]

function delaunay(points_list)
    local triangle_list = {}
    local numpoints = #points_list
    
    --Insertion sort by x
    local w = points_list[1].x
    for i = 1, numpoints do
        local p = points_list[i]
        local x = p.x
        if x < w then
            local j = i
            while j>1 and points_list[j -1].x > x do
                points_list[j] = points_list[j - 1]
                j = j - 1
            end    
            points_list[ j ] = p;
        else
            w = x
        end    
    end
    
    
    --Create Supertriangle
    table.insert(points_list, {x = -5000, y = -5000})
    table.insert(points_list, {x = 5000, y = 0})
    table.insert(points_list, {x = 0, y = 5000})
    table.insert(triangle_list, {numpoints+1,numpoints+2,numpoints+3})
    
    local function inCircle(point, triangle_counter)
        --[[
                '''Series of calculations to check if a certain point lies inside lies inside the circumcircle
                made up by points in triangle (x1,y1) (x2,y2) (x3,y3)'''
                #adapted from Dimitrie Stefanescu's Rhinoscript version
                
                #Return TRUE if the point (xp,yp) 
                #The circumcircle centre is returned in (xc,yc) and the radius r
                #NOTE: A point on the edge is inside the circumcircle --]]
        if triangle_list[triangle_counter].done then
            return false
        end    
        
        local xp = point.x
        local yp = point.y
        
        if  triangle_list[triangle_counter].r then
            
            
            local r = triangle_list[triangle_counter].r
            local xc = triangle_list[triangle_counter].xc
            local yc = triangle_list[triangle_counter].yc
            
            local dx = xp - xc
            local dy = yp - yc
            local rsqr = r*r
            local drsqr = dx * dx + dy * dy
            
            if xp > xc + r then
                triangle_list[triangle_counter].done = true
            end    
            
            if drsqr <= rsqr then
                return true
            else
                return false
            end
        end     
        
        local x1 = points_list[triangle_list[triangle_counter][1]].x
        local y1 = points_list[triangle_list[triangle_counter][1]].y
        local x2 = points_list[triangle_list[triangle_counter][2]].x
        local y2 = points_list[triangle_list[triangle_counter][2]].y
        local x3 = points_list[triangle_list[triangle_counter][3]].x
        local y3 = points_list[triangle_list[triangle_counter][3]].y
        local eps = 0.0001
        
        if math.abs(y1-y2) < eps and math.abs(y2-y3) < eps then 
            return false    
        end
        
        if math.abs(y2-y1) < eps then
            m2 = -(x3 - x2) / (y3 - y2)
            mx2 = (x2 + x3) / 2
            my2 = (y2 + y3) / 2
            xc = (x2 + x1) / 2
            yc = m2 * (xc - mx2) + my2
        elseif math.abs(y3-y2) < eps then
            
            m1 = -(x2 - x1) / (y2 - y1)
            
            mx1 = (x1 + x2) / 2
            my1 = (y1 + y2) / 2
            xc = (x3 + x2) / 2
            yc = m1 * (xc - mx1) + my1
        else
            m1 = -(x2 - x1) / (y2 - y1)
            m2 = -(x3 - x2) / (y3 - y2)
            mx1 = (x1 + x2) / 2
            mx2 = (x2 + x3) / 2
            my1 = (y1 + y2) / 2
            my2 = (y2 + y3) / 2
            xc = (m1 * mx1 - m2 * mx2 + my2 - my1) / (m1 - m2)
            yc = m1 * (xc - mx1) + my1
        end
        
        
        dx = x2 - xc
        dy = y2 - yc
        rsqr = dx * dx + dy * dy
        r = math.sqrt(rsqr)
        
        triangle_list[triangle_counter].r = r
        triangle_list[triangle_counter].xc = xc
        triangle_list[triangle_counter].yc = yc
        
        dx = xp - xc
        dy = yp - yc
        drsqr = (dx * dx) + (dy * dy)
        
        if drsqr <= rsqr then
            return true
        else
            return false
        end     
    end     
    
    for i = 1, numpoints do
        local edges = {}
        local point = points_list[i]
        
        local triangles_remain = true
        local j = 1
        
        while triangles_remain do
            
            if inCircle(point, j) then
                table.insert(edges, {triangle_list[j][1],triangle_list[j][2]})
                table.insert(edges, {triangle_list[j][2],triangle_list[j][3]})
                table.insert(edges, {triangle_list[j][3],triangle_list[j][1]})
                table.remove(triangle_list,j)
                j = j - 1
            end
            
            j = j + 1
            if j == (#triangle_list + 1) then
                triangles_remain = false
            end    
        end
        
        
        --Remove duplicates
        local k = 1
        while k < #edges do
            l = k + 1
            while l <= #edges do
                if edges[k][1] == edges[l][2] and edges[k][2] == edges[l][1] then
                    edges[k][1] = nil
                    edges[k][2] = nil
                    edges[l][1] = nil
                    edges[l][2] = nil
                end
                l = l + 1    
            end
            k = k + 1
        end            
        
        -- Make triangles from edges
        for k = 1, #edges do
            if edges[k][1] then 
                table.insert(triangle_list, {i,edges[k][1],edges[k][2]})
            end
        end
    end
    
    --remove Super Triangle and its verticies
    local i = 1
    while i < #triangle_list + 1 do    
        if triangle_list[i][1] > numpoints   then
            table.remove(triangle_list,i)
            i = i-1    
        elseif triangle_list[i][2] > numpoints then
            table.remove(triangle_list,i)
            i = i-1 
        elseif triangle_list[i][3] > numpoints then
            table.remove(triangle_list,i)
            i = i-1 
        end
        i = i+1
    end
    points_list[numpoints+1] = nil
    points_list[numpoints+2] = nil    
    points_list[numpoints+3] = nil  
    
    return triangle_list
end