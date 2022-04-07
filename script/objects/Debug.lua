local util = require("util")
local custom_lib = require("__Constructron-2__.data.lib.custom_lib")
---@class Debug
local Debug = {
    class_name = "Debug",
    debug = true,
    logfileName = "constructron.log",
    debug_definition = {
        lines = {
            line_1 = -2,
            line_2 = -1,
            --line_3 = 0,
            dynamic = 0
        }
    }
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
    self.debug_messages = {}
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

function Debug:attach_text(entity, message, line, ttl)
    if self and self.debug then
        for k, msg in ipairs(self.debug_messages) do
            if msg.tick + msg.ttl < game.tick then
                self.debug_messages[k] = nil
            end
        end
        if entity and entity.valid then
            line = line or 0
            ttl = (ttl or 1) * 60
            local color = {r = 255, g = 255, b = 255, a = 255}
            if line == self.debug_definition.lines.dynamic then
                local index = custom_lib.table_length(self.debug_messages) + 1
                self.debug_messages[index] = {tick = game.tick, ttl = ttl}
                line = line + index - 1
                color = {r = 150, g = 150, b = 150, a = 255}
            end

            rendering.draw_text {
                text = message,
                target = entity,
                filled = true,
                surface = entity.surface,
                time_to_live = ttl,
                target_offset = util.by_pixel(0, line * 16),
                alignment = "center",
                color = color
            }
        end
    end
end
return Debug
