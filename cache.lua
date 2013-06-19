local cache = {} -- API
local cacheTable = {}

function cache.get(class, args)
    local filename = args[args.index or 1]
    cacheTable[class] = cacheTable[class] or {}
    if cacheTable[class][filename] ~= nil then
        return cacheTable[filename]
    else
        cacheTable[class][filename] = class.new(unpack(args))
    end
end

return cache