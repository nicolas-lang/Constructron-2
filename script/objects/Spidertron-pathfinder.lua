-- local debug_lib = require("__Constructron-2__.script.lib.debug_lib")
-- local color_lib = require("__Constructron-2__.script.lib.color_lib")
local control_lib = require("__Constructron-2__.script.lib.control_lib")
local cust_lib = require("__Constructron-2__.data.lib.custom_lib")
local collision_mask_util_extended = require("__Constructron-2__.script.lib.collision-mask-util-control")

local Spidertron_Pathfinder = {
    clean_linear_path = false,
    clean_path_steps = true,
    clean_path_steps_distance = 5,
    -- how close do we need to get to the target
    radius = 1,
    path_resolution_modifier = -2
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
            if math.abs(prev_angle - next_angle) > 0.01 then
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

function Spidertron_Pathfinder:request_path(unit, goal)
    local request_params = {goal = goal}
    self:request_path2(unit, request_params)
end

function Spidertron_Pathfinder:request_path2(unit, request_params, request_obj)
    -- 1. Request with huge bounding box to avoid pathing near sketchy areas
    -- 2. Re-Request with normal  bounding box
    -- 3. Re-Request with tiny bounding box
    -- 4. Re-Request with increased radius (just for this try)
    -- 5. find_non_colliding_positions and Re-Request
    -- 6. Re-Request with even more increased radius again
    -- 7. f*ck it... just try to walk there in a straight line

    -- new_start = surface.find_non_colliding_position(pathfinding_proxy_entity_name, spidertron.position, 32, 0.1, false)
    -- new_goal = surface.find_non_colliding_position(pathfinding_proxy_entity_name, goal, 32, 0.1, false)
    local pathing_collision_mask = {"water-tile", "consider-tile-transitions", "colliding-with-tiles-only"}
    if game.active_mods["space-exploration"] then
        local spaceship_collision_layer = collision_mask_util_extended.get_named_collision_mask("moving-tile")
        local empty_space_collision_layer = collision_mask_util_extended.get_named_collision_mask("empty-space-tile")
        table.insert(pathing_collision_mask, spaceship_collision_layer)
        table.insert(pathing_collision_mask, empty_space_collision_layer)
    end

    unit:set_autopilot({})
    local position = unit:get_position()
    request_params = request_params or {}
    local request = {
        bounding_box = {{-0.25, -0.25}, {0.25, 0.25}},
        collision_mask = pathing_collision_mask,
        start = position.position,
        goal = nil,
        force = unit.force,
        radius = self.radius,
        path_resolution_modifier = self.path_resolution_modifier,
        pathfinding_flags = {
            cache = true,
            low_priority = true
        }
    }
    cust_lib.merge(request, request_params)
    local request_id = position.surface.request_path(request)

    request_obj =
        request_obj or
        {
            unit = unit,
            target = request_params.goal,
            retry = 0
        }
    request_obj.request_tick = game.tick
    request_obj.request = request

    global.pathfinder_requests[request_id] = request_obj
end

function Spidertron_Pathfinder:on_script_path_request_finished(event)
    local request_obj = global.pathfinder_requests[event.id]
    if request_obj and request_obj.unit then
        local path = event.path
        if event.try_again_later then
            log("try_again_later")
        elseif not path then
            -- ToDo re-Request path
            log("pathfinder callback: path nil")
        else
            if self.clean_linear_path then
                path = Spidertron_Pathfinder.clean_linear_path(path)
            end
            if self.clean_path_steps then
                path = Spidertron_Pathfinder.clean_path_steps(path, self.clean_path_steps_distance)
            end
            table.insert(path, {position = {x = request_obj.target.x, y = request_obj.target.y}})
            if self.clean_path_steps then
                path = Spidertron_Pathfinder.clean_path_steps(path, 2.5)
            end
            request_obj.unit:set_autopilot(path)
        end
    end
    global.pathfinder_requests[event.id] = nil
end

return Spidertron_Pathfinder
