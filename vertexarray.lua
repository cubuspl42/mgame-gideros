-- functions for accessing vertex arrays
-- in form {<x1>, <y1>, <x1>, <y1>, <...>, <xn>, <yn>}

local function get(array, i) -- 0 is last, -1 is one before last, etc.
    if i <= 0 then
        i = #array/2 + i
    end
    while i > #array/2 do
        i = i - #array/2
    end
    return array[2*i-1], array[2*i]
end

local function set(array, i, x, y)
    array[2*i-1], array[2*i] = x, y
end

local function iter(array)
    local i = 0
    local n = #array/2
    return function()
        i = i + 1
        if i <= n then
            local x, y = get(array, i)
            return x, y, i
        end
    end
end

return {
    get = get,
    set = set,
    iter = iter,
}