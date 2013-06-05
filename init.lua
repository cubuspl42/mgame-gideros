package.path = package.path .. ";./lib/?.lua" -- add lib folder
require 'box2d' -- b2 API
require 'vector' -- global 'Vector'

function all(t)
    local i = 0
    local n = table.getn(t)
    return function ()
        i = i + 1
        if i <= n then return t[i] end
    end
end

function run(untrusted_code, env)
    if untrusted_code:byte(1) == 27 then return nil, "binary bytecode prohibited" end
    local untrusted_function, message = loadstring(untrusted_code)
    if not untrusted_function then return nil, message end
    setfenv(untrusted_function, env)
    return pcall(untrusted_function)
end

function get(array, i)
    if i < 0 then return array[table.getn(array) + i + 1]
    elseif i > 0 then return array[i] end
end

function toboolean(v)
    return (type(v) == "string" and v == "true") or (type(v) == "number" and v ~= 0) or (type(v) == "boolean" and v)
end

function tprint (tbl, depth, indent) -- print table
    if not depth then depth = -1 end
    if not indent then indent = 0 end
    for k, v in pairs(tbl) do
        formatting = string.rep("  ", indent) .. k .. ": "
        if depth ~= 0 and type(v) == "table" then
            print(formatting)
            tprint(v, depth - 1, indent+1)
        else
            print(formatting .. tostring(v))
        end
    end
end

function xmlFromFile(filename)
    return xml.newParser():loadFile(filename)
end

-- one should use env?
function preserve(...)
    local global = {}
    for _, v in pairs(arg) do
        if type(v) == "string" then
            global[v] = _G[v]
            _G[v] = nil
        end
    end
    return global
end

function revert(global)
    for k, v in pairs(global) do
        _G[k] = v
    end
end