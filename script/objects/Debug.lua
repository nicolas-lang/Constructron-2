local util = require("util")
local custom_lib = require("__Constructron-2__.data.lib.custom_lib")
---@class Debug
---@field class_name string
---@field debug boolean
---@field debug_definition table<string,table<string,int>>
---@field debug_messages table
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

---Constructor
function Debug:new() -- luacheck: ignore
    --todo: globalize to make it MP safe
    self.debug_messages = {}
end

---Log to factorio_current.log
---@see https://wiki.factorio.com/Log_file
---@param o any msg/object
function Debug:log(o)
    if self and self.debug then
        local msg = ""
        if type(o) == "string" then
            msg = " " .. o
        elseif type(o) == "number" then
            msg = " " .. tostring(o)
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

---Attach a floating text to the entity for a duration
---@param entity LuaEntity
---@param message string
---@param line uint line definition
---@param ttl uint seconds to display
function Debug:attach_text(entity, message, line, ttl)
    if self and self.debug then
        if entity and entity.valid then
            for k, msg in pairs(self.debug_messages) do
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
end

---Draw a circle for a short duration at a specific location
---@param position MapPosition
---@param surface LuaSurface
---@param color Color
---@param text string
function Debug:draw_circle(surface, position, color, text, ttl)
    if self and self.debug then
        if position then
            ttl = (ttl or 15) * 60
            local message = "Circle"
            rendering.draw_circle {
                target = position,
                radius = 0.5,
                filled = true,
                surface = surface,
                time_to_live = ttl,
                color = color
            }
            if text then
                message = message .. "(" .. text .. ")"
                rendering.draw_text {
                    text = text,
                    target = {position.x, position.y - 0.25},
                    filled = true,
                    surface = surface,
                    time_to_live = ttl,
                    alignment = "center",
                    color = {
                        r = 255,
                        g = 255,
                        b = 255,
                        a = 255
                    }
                }
            end
            log("surface " .. (surface.name or surface.index) .. " (x:" .. (position.x) .. ",y:" .. (position.y) .. "):" .. message)
        end
    end
end

---Highlight an Area
---@param minimum MapPosition
---@param maximum MapPosition
---@param surface LuaSurface
---@param color Color
function Debug:draw_rectangle (surface, minimum, maximum, color, ttl)
    if self and self.debug then
        ttl = (ttl or 10) * 60
        local message = "rectangle"
        local inner_color = {
            r = color.r,
            g = color.g,
            b = color.b,
            a = 0.075
        }

        rendering.draw_rectangle {
            left_top = minimum,
            right_bottom = maximum,
            filled = true,
            surface = surface,
            time_to_live = ttl,
            color = inner_color
        }

        rendering.draw_rectangle {
            left_top = minimum,
            right_bottom = maximum,
            width = 3,
            filled = false,
            surface = surface,
            time_to_live = ttl,
            color = color
        }

        log("surface " .. (surface.name or surface.index) .. message)
        log("minimum:" .. serpent.block(minimum) .. ", maximum:" .. serpent.block(maximum))
    end
end

return Debug
