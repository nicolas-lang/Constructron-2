-- local debug_lib = require("__Constructron-2__.script.lib.debug_lib")
-- local color_lib = require("__Constructron-2__.script.lib.color_lib")
local control_lib = require("__Constructron-2__.script.lib.control_lib")
local cust_lib = require("__Constructron-2__.data.lib.custom_lib")
local collision_mask_util_extended = require("__Constructron-2__.script.lib.collision-mask-util-control")

---@class Spidertron_Pathfinder
local Spidertron_Pathfinder = {
    class_name = "Spidertron_Pathfinder",
    clean_linear_path_enabled = false,
    clean_path_steps_enabled = true,
    clean_path_steps_distance = 5,
    -- how close do we need to get to the target
    non_colliding_position_accuracy = 0.5,
    radius = 1,
    path_resolution_modifier = -2,
    initial_bounding_box = {{-5, -5}, {5, 5}}
}

Spidertron_Pathfinder.__index = Spidertron_Pathfinder

setmetatable(
    Spidertron_Pathfinder,
    {
        __call = function(cls, ...)
            local self = setmetatable({}, cls)
            self:new(...)
            return self
        end
    }
)

-- Spidertron_Pathfinder Constructor
function Spidertron_Pathfinder:new(params)
    for key, value in pairs(params or {}) do
        self[key] = value
    end
    self.path_resolution_modifier = math.min(math.max(self.path_resolution_modifier, -8), 8)
end

Spidertron_Pathfinder.init_globals = function()
    global.pathfinder_requests = global.pathfinder_requests or {}
end

Spidertron_Pathfinder.check_pathfinder_requests_timeout = function()
    for key, request in pairs(global.pathfinder_requests) do
        if ((game.tick - request.request_tick) > 60 * 60) then -- one minute
            global.pathfinder_requests[key] = nil
        end
    end
end

function Spidertron_Pathfinder.clean_linear_path(path)
    -- removes points on the same line except the start and the end.
    local new_path = {}
    for i, waypoint in ipairs(path) do
        if i >= 2 and i < #path then
            local prev_angle = math.atan2(waypoint.position.y - path[i - 1].position.y, waypoint.position.x - path[i - 1].position.x)
            local next_angle = math.atan2(path[i + 1].position.y - waypoint.position.y, path[i + 1].position.x - waypoint.position.x)
            if math.abs(prev_angle - next_angle) > 0.005 then
                table.insert(new_path, waypoint)
            end
        else
            table.insert(new_path, waypoint)
        end
    end
    return new_path
end

function Spidertron_Pathfinder.clean_path_steps(path, min_distance)
    if #path == 1 then
        return path
    end
    --log("path" .. serpent.block(path))
    local new_path = {}
    local prev = path[1]
    table.insert(new_path, prev)
    for i, p in pairs(path) do
        local d = control_lib.distance_between(prev.position, p.position)
        if (d > min_distance) then
            prev = p
            table.insert(new_path, p)
        end
    end
    --fix last point
    local d = control_lib.distance_between(prev.position, path[#path].position)
    if (d > min_distance) or (#new_path == 1) then
        table.insert(new_path, path[#path])
    else
        new_path[#new_path] = path[#path]
    end
    --log("new_path" .. serpent.block(new_path))
    return new_path
end
function Spidertron_Pathfinder:find_non_colliding_position(surface, position)
    for _, param in pairs(
        {
            {size = 12, radius = 8},
            {size = 8, radius = 8},
            {size = 6, radius = 8},
            {size = 4, radius = 8},
            {size = 2, radius = 8},
            {size = 1, radius = 32}
        }
    ) do
        local new_position = surface.find_non_colliding_position("constructron_pathing_proxy_" .. param.size, position, param.radius, self.non_colliding_position_accuracy, false)
        if new_position then
            return new_position
        end
    end
end

function Spidertron_Pathfinder:request_path(unit, goal)
    local request_params = {unit = unit, goal = goal}
    self:request_path2(request_params)
end

function Spidertron_Pathfinder:request_path2(request_params)
    log("request_path2")
    local pathing_collision_mask = {"water-tile", "consider-tile-transitions", "colliding-with-tiles-only", "not-colliding-with-itself"}
    if game.active_mods["space-exploration"] then
        local spaceship_collision_layer = collision_mask_util_extended.get_named_collision_mask("moving-tile")
        local empty_space_collision_layer = collision_mask_util_extended.get_named_collision_mask("empty-space-tile")
        table.insert(pathing_collision_mask, spaceship_collision_layer)
        table.insert(pathing_collision_mask, empty_space_collision_layer)
    end
    request_params = request_params or {}
    local unit = request_params.unit -- object-type: CTron
    if unit then
        unit:set_autopilot({})
        local position = unit:get_position()
        local request = {
            unit = nil, -- not used by the factorio-pathfinder
            surface = position.surface, -- not used by the factorio-pathfinder
            -- 1st Request: use huge bounding box to avoid pathing near sketchy areas
            bounding_box = self.initial_bounding_box,
            collision_mask = pathing_collision_mask,
            start = position.position,
            goal = nil,
            force = unit.force,
            radius = self.radius,
            path_resolution_modifier = self.path_resolution_modifier,
            pathfinding_flags = {
                cache = true,
                low_priority = true
            },
            retry = 0, -- not used by the factorio-pathfinder
            try_again_later = 0 -- not used by the factorio-pathfinder
        }
        cust_lib.merge(request, request_params)
        request.initial_target = request.initial_target or request.goal -- not used by the factorio-pathfinder
        request.request_tick = game.tick -- not used by the factorio-pathfinder

        --log("new pathign request" .. serpent.block(request))
        local request_id = position.surface.request_path(request)
        global.pathfinder_requests[request_id] = request
    end
end

function Spidertron_Pathfinder:on_script_path_request_finished(event)
    local request = global.pathfinder_requests[event.id]
    if request and request.unit then
        local path = event.path
        if event.try_again_later then
            if request.try_again_later < 5 then
                log("try_again_later")
                request.request_tick = game.tick
                request.try_again_later = request.try_again_later + 1
                self:request_path2(request)
            else
                log("try_again_later: ABORTED, to many retrys")
            end
        elseif not path then
            if request.retry < 6 then
                if request.retry == 1 then
                    -- 2. Re-Request with normal  bounding box
                    request.bounding_box = {{-1, -1}, {1, 1}}
                elseif request.retry == 2 then
                    -- 4. Re-Request with increased radius (just for this try)
                    request.radius = 5
                elseif request.retry == 3 then
                    -- 3. Re-Request with tiny bounding box
                    request.bounding_box = {{-0.015, -0.015}, {0.015, 0.015}} -- leg collision_box = {{-0.01, -0.01}, {0.01, 0.01}},
                elseif request.retry == 4 then
                    request.radius = self.radius
                    -- 5. find_non_colliding_positions and Re-Request
                    local position = request.unit:get_position()
                    request.start = self:find_non_colliding_position(position.surface, request.start) or request.start
                    request.goal = self:find_non_colliding_position(position.surface, request.goal) or request.goal
                elseif request.retry == 5 then
                    -- 6. Re-Request with even more increased radius again
                    request.radius = 10
                end
                request.retry = request.retry + 1
                request.request_tick = game.tick
                self:request_path2(request)
            else
                request.unit:set_status("pathfinding_failed")
            end
        else
            if self.clean_linear_path_enabled then
                path = Spidertron_Pathfinder.clean_linear_path(path)
            end
            if self.clean_path_steps_enabled then
                path = Spidertron_Pathfinder.clean_path_steps(path, self.clean_path_steps_distance)
            end
            table.insert(path, {position = {x = request.initial_target.x, y = request.initial_target.y}})
            if self.clean_path_steps_enabled then
                path = Spidertron_Pathfinder.clean_path_steps(path, 2.5)
            end
            --log(serpent.block(request.request))
            request.unit:set_autopilot(path)
        end
    end
    global.pathfinder_requests[event.id] = nil
end

return Spidertron_Pathfinder
