--math for 2D svg-style elliptic arcs defined as:
--  (x1, y1, radius_x, radius_y, rotation, large_arc_flag, sweep_flag, x2, y2, [matrix], [segment_max_sweep])
--conversion to elliptic arcs adapted from antigrain library @ agg/src/agg_bezier_arc.cpp by Cosmin Apreutesei.

local elliptic_arc_to_bezier3 = require'path_elliptic_arc'.to_bezier3
local elliptic_arc_point      = require'path_elliptic_arc'.point
local elliptic_arc_hit        = require'path_elliptic_arc'.hit
local elliptic_arc_split      = require'path_elliptic_arc'.split
local elliptic_arc_to_svgarc  = require'path_elliptic_arc'.to_svgarc

local line_to_bezier3   = require'path_line'.to_bezier3
local line_point        = require'path_line'.point
local line_hit          = require'path_line'.hit

local sin, cos, abs, sqrt, acos, radians, degrees, pi =
	math.sin, math.cos, math.abs, math.sqrt, math.acos, math.rad, math.deg, math.pi

--if endpoints coincide or one of the radii is 0, the parametrization is invalid.
local function invalid(x1, y1, x2, y2, rx, ry)
	return (x1 == x2 and y1 == y2) or rx == 0 or ry == 0
end

local function to_elliptic_arc(x0, y0, rx, ry, rotation, large_arc_flag, sweep_flag, x2, y2, ...)
	if invalid(x0, y0, x2, y2, rx, ry) then return end

	rx, ry = abs(rx), abs(ry)

	-- Calculate the middle point between the current and the final points
	local dx2 = (x0 - x2) / 2
	local dy2 = (y0 - y2) / 2

	local a = radians(rotation or 0)
	local cos_a = cos(a)
	local sin_a = sin(a)

	-- Calculate (x1, y1)
	local x1 =  cos_a * dx2 + sin_a * dy2
	local y1 = -sin_a * dx2 + cos_a * dy2

	-- Ensure radii are large enough
	local prx = rx * rx
	local pry = ry * ry
	local px1 = x1 * x1
	local py1 = y1 * y1

	-- Check that radii are large enough
	local radii_check = px1/prx + py1/pry
	if radii_check > 1 then
		rx = sqrt(radii_check) * rx
		ry = sqrt(radii_check) * ry
		prx = rx * rx
		pry = ry * ry
	end

	-- Calculate (cx1, cy1)
	local sign = large_arc_flag == sweep_flag and -1 or 1
	local sq   = (prx*pry - prx*py1 - pry*px1) / (prx*py1 + pry*px1)
	local coef = sign * sqrt(sq < 0 and 0 or sq)
	local cx1  = coef *  ((rx * y1) / ry)
	local cy1  = coef * -((ry * x1) / rx)

	-- Calculate (cx, cy) from (cx1, cy1)
	local sx2 = (x0 + x2) / 2
	local sy2 = (y0 + y2) / 2
	local cx = sx2 + (cos_a * cx1 - sin_a * cy1)
	local cy = sy2 + (sin_a * cx1 + cos_a * cy1)

	-- Calculate the start_angle (angle1) and the sweep_angle (dangle)
	local ux =  (x1 - cx1) / rx
	local uy =  (y1 - cy1) / ry
	local vx = (-x1 - cx1) / rx
	local vy = (-y1 - cy1) / ry
	local p, n

	-- Calculate the angle start
	n = sqrt(ux*ux + uy*uy)
	p = ux -- (1 * ux) + (0 * uy)
	sign = uy < 0 and -1 or 1
	local v = p / n
	if v < -1 then v = -1 end
	if v >  1 then v =  1 end
	local start_angle = sign * acos(v)

	-- Calculate the sweep angle
	n = sqrt((ux*ux + uy*uy) * (vx*vx + vy*vy))
	p = ux * vx + uy * vy
	sign = ux * vy - uy * vx < 0 and -1 or 1
	v = p / n
	if v < -1 then v = -1 end
	if v >  1 then v =  1 end
	local sweep_angle = sign * acos(v)

	if sweep_flag == 0 and sweep_angle > 0 then
		sweep_angle = sweep_angle - 2*pi
	elseif sweep_flag == 1 and sweep_angle < 0 then
		sweep_angle = sweep_angle + 2*pi
	end

	return cx, cy, rx, ry, degrees(start_angle), degrees(sweep_angle), rotation, x2, y2, ...
end

local function transform_endpoints(mt, x1, y1, x2, y2)
	if mt then
		x1, y1 = mt(x1, y1)
		x2, y2 = mt(x2, y2)
	end
	return x1, y1, x2, y2
end

local function to_bezier3(write, x1, y1, rx, ry, rotation, large_arc_flag, sweep_flag, x2, y2, mt, ...)
	if invalid(x1, y1, x2, y2, rx, ry) then
		x1, y1, x2, y2 = transform_endpoints(mt, x1, y1, x2, y2)
		write('curve', select(3, line_to_bezier3(x1, y1, x2, y2)))
		return
	end
	elliptic_arc_to_bezier3(write, to_elliptic_arc(x1, y1, rx, ry, rotation, large_arc_flag, sweep_flag, x2, y2, mt, ...))
end

local function point(t, x1, y1, rx, ry, rotation, large_arc_flag, sweep_flag, x2, y2, mt, ...)
	if invalid(x1, y1, x2, y2, rx, ry) then
		x1, y1, x2, y2 = transform_endpoints(mt, x1, y1, x2, y2)
		return line_point(t, x1, y1, x2, y2)
	end
	return elliptic_arc_point(t, to_elliptic_arc(x1, y1, rx, ry, rotation, large_arc_flag, sweep_flag, x2, y2, mt, ...))
end

local function hit(x0, y0, x1, y1, rx, ry, rotation, large_arc_flag, sweep_flag, x2, y2, mt, ...)
	if invalid(x1, y1, x2, y2, rx, ry) then
		x1, y1, x2, y2 = transform_endpoints(mt, x1, y1, x2, y2)
		return line_hit(x0, y0, x1, y1, x2, y2)
	end
	return elliptic_arc_hit(x0, y0, to_elliptic_arc(x1, y1, rx, ry, rotation, large_arc_flag, sweep_flag, x2, y2, mt, ...))
end

local function split(t, x1, y1, rx, ry, rotation, large_arc_flag, sweep_flag, x2, y2)
	if invalid(x1, y1, x2, y2, rx, ry) then
		local x3, y3 = line_point(t, x1, y1, x2, y2)
		return
			x1, y1, rx, ry, rotation, large_arc_flag, sweep_flag, x3, y3,
			x3, y3, rx, ry, rotation, large_arc_flag, sweep_flag, x2, y2
	end
	local
		cx1, cy1, rx1, ry1, start_angle1, sweep_angle1, rotation1,
		cx2, cy2, rx2, ry2, start_angle2, sweep_angle2, rotation2, x2, y2 =
			elliptic_arc_split(t, to_elliptic_arc(x1, y1, rx, ry, rotation, large_arc_flag, sweep_flag, x2, y2))
	local
		x11, y11, rx1, ry1, rotation1, large_arc_flag1, sweep_flag1, x12, y12 =
			elliptic_arc_to_svgarc(cx1, cy1, rx1, ry1, start_angle1, sweep_angle1, rotation1)
	local
		x21, y21, rx2, ry2, rotation2, large_arc_flag2, sweep_flag2, x22, y22 =
			elliptic_arc_to_svgarc(cx2, cy2, rx2, ry2, start_angle2, sweep_angle2, rotation2, x2, y2)
	x11, y11 = x1, y1
	return
		x11, y11, rx1, ry1, rotation1, large_arc_flag1, sweep_flag1, x12, y12,
		x21, y21, rx2, ry2, rotation2, large_arc_flag2, sweep_flag2, x22, y22
end

if not ... then require'path_svgarc_demo' end

return {
	to_elliptic_arc = to_elliptic_arc,
	--path API
	to_bezier3 = to_bezier3,
	point = point,
	hit = hit,
	split = split,
}

