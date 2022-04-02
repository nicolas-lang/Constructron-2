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

function Debug:attach_text(entity, message, offset, ttl)
    if self and self.debug then
        if not entity or not entity.valid then
            return
        end
        if not offset then
            offset = 0
        end
        if not ttl then
            ttl = 1
        else
            ttl = ttl * 60
        end
        rendering.draw_text {
            text = message,
            target = entity,
            filled = true,
            surface = entity.surface,
            time_to_live = ttl,
            target_offset = {0, offset},
            alignment = "center",
            color = {r = 255, g = 255, b = 255, a = 255}
        }
    end
end
return Debug
