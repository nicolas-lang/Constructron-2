-- class Type Debug, nil members exist just to describe fields
local Debug = {
    class_name = "Debug",
    debug = true,
    logfileName = "constructron.log"
}
Debug.__index = Debug

setmetatable(
    Debug,
    {
        __call = function(cls, ...)
            local self = setmetatable({}, cls)
            self:new(...)
            return self
        end
    }
)

-- Debug Constructor
function Debug:new(scope) -- luacheck: ignore
end

function Debug:log(o)
    if self and self.debug then
        local msg = ""
        if type(o) == "string" then
            msg = " " .. o
        elseif o then
            msg = " " .. serpent.block(o)
        end
        local func = (debug.getinfo(2, "n").name) or ""
        local file = (debug.getinfo(2, "S").source) or ""
        local line = (debug.getinfo(2, "S").linedefined) or ""
        local logMessage = self.class_name .. ":" .. func .. " " .. msg
        logMessage = file .. " (" .. line .. ") " .. logMessage
        log(logMessage)
    -- game.write_file(self.logfileName, logMessage .. "\r\n", true)
    end
end

return Debug
