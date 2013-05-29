cache = {}

-- should support Texture, SCMLParser
function getTexture(filename)
    if not cache[filename] then
        cache[filename] = Texture.new(filename, true)
    end
    return cache[filename]
end

function getSCMLParser(filename)
    if not cache[filename] then
        cache[filename] = SCMLParser.new(filename) -- create loaderFunction...
    end
    return cache[filename]
end