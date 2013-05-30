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