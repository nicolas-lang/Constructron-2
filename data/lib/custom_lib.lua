local me = {}

function string:split(inSplitPattern) -- luacheck: ignore
    local outResults = {}
    local theStart = 1
    local theSplitStart, theSplitEnd = string.find(self, inSplitPattern, theStart)
    while theSplitStart do
        table.insert(outResults, string.sub(self, theStart, theSplitStart - 1))
        theStart = theSplitEnd + 1
        theSplitStart, theSplitEnd = string.find(self, inSplitPattern, theStart)
    end
    table.insert(outResults, string.sub(self, theStart))
    return outResults
end

me.table_has_value = function(tab, val)
    if val == nil then
        return false
    end
    if not tab then
        return false
    end
    for index, value in ipairs(tab) do
        if value == val then
            return true
        end
    end
    return false
end

function me.table_length(T)
    local count = 0
    for _ in pairs(T) do
        count = count + 1
    end
    return count
end

function me.merge(a, b)
    if type(a) == "table" and type(b) == "table" then
        for k, v in pairs(b) do
            if type(v) == "table" and type(a[k] or false) == "table" then
                me.merge(a[k], v)
            else
                a[k] = v
            end
        end
    end
    return a
end

function me.merge_add(a, b)
    if type(a) == "table" and type(b) == "table" then
        for k, v in pairs(b) do
            if type(v) == "table" and type(a[k] or false) == "table" then
                me.merge_add(a[k], v)
            else
                if type(v or false) == "number" and type(a[k] or false) == "number" then
                    a[k] = (a[k] or 0) + v
                elseif type(v or false) == "string" or type(a[k] or false) == "string" then
                    a[k] = tostring(a[k] or "") .. tostring(v)
                end
            end
        end
    end
    return a
end

return me
