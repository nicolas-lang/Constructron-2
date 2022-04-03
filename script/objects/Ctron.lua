local Debug = require("__Constructron-2__.script.objects.Debug")
--local util = require("__core__.lualib.util")
local custom_lib = require("__Constructron-2__.data.lib.custom_lib")

-- class Type Ctron, nil members exist just to describe fields
local Ctron = {
    class_name = "Ctron",
    -- <base game spidertron entity unit_number used as PK for everything>
    unit_number = nil,
    -- <base game spidertron entity>
    entity = nil,
    name = nil,
    force = nil,
    registration_id = nil,
    pathfinder = nil,
    gear = {},
    managed_equipment = {},
    managed_equipment_cols = 0,
    last_status_update_tick = 0,
    movement_research = 1
}
Ctron.__index = Ctron

setmetatable(
    Ctron,
    {
        __index = Debug, -- this is what makes the inheritance work
        __call = function(cls, ...)
            local self = setmetatable({}, cls)
            self:new(...)
            return self
        end
    }
)

-- Ctron Constructor
function Ctron:new(entity)
    self:log()
    Debug.new(self, nil)
    if entity and entity.valid then
        self.type = "Ctron"
        self.entity = entity
        self.unit_number = entity.unit_number
        self.name = entity.name
        self.force = entity.force
        self.last_status_update_tick = game.tick
        self.registration_id = script.register_on_entity_destroyed(entity)
        global.constructrons.unit_registration[self.registration_id] = {
            unit_number = entity.unit_number,
            surface_index = entity.surface.index,
            force_index = entity.force.index
        }
        global.constructrons.units[entity.unit_number] = entity
        self.status = Ctron.status.free
    else
        log("Ctron:entity invalid")
    end
end

-- Static members
Ctron.status = {
    requesting = 4,
    robots_active = 3,
    idle = 1,
    traveling = 2,
    error = 6,
    pathfinding_failed = 9,
    no_power = 7,
    no_fuel = 8
}
-- Generic Type based initialization
function Ctron.init_globals()
    global.constructrons = global.constructrons or {}
    global.constructrons.units = global.constructrons.units or {}
    global.constructrons.unit_registration = global.constructrons.unit_registration or {}
    global.constructrons.unit_status = global.constructrons.unit_status or {}
end

function Ctron.init_managed_gear()
    -- Use "order" field to store predefined grid location as csv
    for _, prototype in pairs(game.equipment_prototypes) do
        if prototype.equipment_categories and custom_lib.table_has_value(prototype.equipment_categories, "constructron-managed") then
            for x, y in (prototype.order):gmatch "constructron=(%d+);(%d+)" do --"constructron=3;1"
                Ctron.managed_equipment[prototype.name] = {x = tonumber(x), y = tonumber(y)}
            end
        end
    end
    log("managed_equipment" .. serpent.block(Ctron.managed_equipment))
end

function Ctron.update_tech_unlocks()
    --just update tech unlocks for all forces
end

-- Equippment Grid Fixer
--[[Rseding91: "The equipment grid has no idea what entity currently owns it - and may not even be owned by an entity."
    --> on_player_removed_equipment event needs to operate on the grid and it is near impossible to get a related entity
    --> we just care about the equipment_name and assume the layout was validated in Ctron:setup_gear()
]]
function Ctron.restore_gear(equipment_grid, equipment_name)
    log("restore_gear")
    if equipment_grid then
        local grid_contents = equipment_grid.get_contents()
        if grid_contents and not grid_contents[equipment_name] and Ctron.managed_equipment[equipment_name] then
            equipment_grid.put {
                name = equipment_name,
                position = Ctron.managed_equipment[equipment_name]
            }
        end
    end
end

function Ctron.get_registered_unit(unit_registration_number)
    return global.constructrons.unit_registration[unit_registration_number]
end
-- Class Methods

function Ctron:destroy()
    self:log()
    global.constructrons.unit_registration[self.registration_id] = nil
    global.constructrons.units[self.unit_number] = nil
    global.constructrons.unit_status[self.unit_number] = nil
end

function Ctron:is_valid()
    --self:log()
    return (self.entity and self.entity.valid)
end

function Ctron:tick_update()
    self:log()
    log("Ctron:tick_update")
    if self:is_valid() then
        local distance = {
            nearby = 10,
            at_target = 3
        }

        -- do we have a target?
        if self.target then
            -- are we at target?
            if self:is_moving() == false then
                log("is_moving-false")
                local distance_from_target = self:distance_to(self.target)
                log("distance_from_target" .. distance_from_target)
                if distance_from_target then
                    if distance_from_target < distance.at_target then
                        -- todo implement movement error counter (reset)
                        log("arrived")
                        self.target = nil
                    elseif distance_from_target < distance.nearby then
                        log("move-it")
                        self:go_to(self.target)
                    -- todo implement movement error counter (increment)
                    end
                end
            else
                log("is moving")
            end

            --are we in risk of cycloning/overshooting ?
            local next_waypoint = self.entity.autopilot_destination
            if next_waypoint then
                local distance_from_next_waypoint = self:distance_to(next_waypoint)
                if distance_from_next_waypoint < distance.nearby then
                    --ToDo: create slow sticker prototype in data stage
                    --ToDo: attach 75% slow sticker (1.5s)
                    -- see Companion drones for example code
                    log("sticker")
                end
            else
                log("no next waypoint")
            end
        else
            log("no target")
        end
    end
end

function Ctron:status_update()
    self:log()
    if self:is_valid() then
        if self.entity.burner and self.fuel then
            local fuel_items = self:get_inventory("fuel")
            if not self.entity.burner.currently_burning and fuel_items[self.fuel] == 0 then
                return self:set_status(Ctron.status.no_fuel)
            end
        end

        if self.target then
            return self:set_status(Ctron.status.traveling)
        end

        if self:is_moving() == false and self.construction_enabled and self:robots_inactive() == false then
            return self:set_status(Ctron.status.constructing)
        end

        if self:in_logistic_network() then
            local active_logistic_requests = self:get_logistic_status() or {}
            if custom_lib.table_length(active_logistic_requests) > 0 then
                --todo check if items are avaliable at all in network
                return self:set_status(Ctron.status.requesting)
            end
        end
        --[[
        if in_some_network and item_inventory<item_requests and item_requests avaliable in network_inventory then
            return self:set_status(Ctron.status.requesting)
        end

        if () then
            return self:set_status(Ctron.status.time_out)
        end
        ]]
        return self:set_status(Ctron.status.idle)
    end
end

function Ctron:parse_gear_name(name)
    name = string.gsub(name, "{movement_research}", tostring(self.movement_research))
    return name
end

function Ctron:setup_gear()
    self:log()
    self:attach_text(self.entity, "update_gear", self.debug.def.dynamic, 2)
    if self:is_valid() and #(self.gear) > 0 then
        -- remove incorrect gear
        local equipment_grid = self.entity.grid
        for _, equipment in pairs(equipment_grid.equipment) do
            local remove = false
            -- remove every unmanaged equippment from first n rows
            if not Ctron.managed_equipment[equipment.name] and equipment.position.x <= self.managed_equipment_cols then
                remove = true
            end
            -- remove incorrectly placed managed gear
            if
                Ctron.managed_equipment[equipment.name] and
                    ((equipment.position.x ~= Ctron.managed_equipment[equipment.name].x) or (equipment.position.x ~= Ctron.managed_equipment[equipment.name].x))
             then
                remove = true
            end
            --remove gear with  incorrect tier
            local found = false
            for _, expected_equipment in pairs(self.gear) do
                if self:parse_gear_name(expected_equipment) == equipment.name then
                    found = true
                end
            end
            if found == false then
                remove = true
            end
            if remove then
                equipment_grid.take(
                    {
                        position = {
                            x = equipment.position.x,
                            y = equipment.position.y
                        }
                    }
                )
            end
        end
        -- insert  missing gear
        local equipment_count = equipment_grid.get_contents()
        for _, equipment in pairs(self.gear) do
            equipment = self:parse_gear_name(equipment)
            if not equipment_count[equipment] then
                equipment_grid.put {
                    name = equipment,
                    position = Ctron.managed_equipment[equipment]
                }
            end
        end
    end
end

function Ctron:get_health_ratio()
    self:log()
    if self:is_valid() then
        return self.entity.get_health_ratio()
    end
    return 0
end

function Ctron:get_job_id()
    self:log()
    return self.job_id
end

function Ctron:assign_job(job_id)
    self:log()
    self:attach_text(self.entity, "set_job", self.debug.def.dynamic, 2)
    self.job_id = job_id
end

function Ctron:set_status(status)
    self:log()
    if self:is_valid() then
        --log("set_status:set status to " .. status)
        local parsed_status
        if type(status) == "number" then
            for key, value in pairs(Ctron.status) do
                if value == status then
                    parsed_status = status
                    self:log(key)
                    self:attach_text(self.entity, key, self.debug.def.line_2, 2)
                end
            end
        else
            self:log(status)
            self:attach_text(self.entity, status, self.debug.def.line_2, 2)
            parsed_status = Ctron.status[status]
        end
        if not parsed_status then
            log("set_status:unknown status: " .. (status or "nil"))
        end
        global.constructrons.unit_status[self.unit_number] = parsed_status
        self.last_status_update_tick = game.tick
        return parsed_status
    end
end
function Ctron:get_last_status_update_tick()
    self:log()
    return self.last_status_update_tick
end
function Ctron:get_status_id()
    self:log()
    local status
    if self:is_valid() then
        status = global.constructrons.unit_status[self.unit_number]
        for _, value in pairs(Ctron.status) do
            if value == status then
                return value
            end
        end
    end
    log("get_status_id:invalid status: " .. (status or "nil"))
    return Ctron.status.idle
end

function Ctron:get_status_name()
    self:log()
    local status_id = self:get_status_id()
    for name, value in pairs(Ctron.status) do
        if value == status_id then
            return name
        end
    end
    log("get_status_name:invalid status_id: " .. (status_id or "nil"))
    return "idle" --return Ctron.status.idle
end

function Ctron:get_inventory(inventory_type)
    self:log()
    -- todo: cache if on the same tick
    local items = {}
    if self:is_valid() then
        local inventory
        if inventory_type == "fuel" and self.entity.burner then
            inventory = self.entity.burner.inventory
        elseif inventory_type == "burnt_result" and self.entity.burner then
            inventory = self.entity.burner.burnt_result_inventory
        elseif inventory_type == "spider_trash" then
            inventory = self.entity.get_inventory(defines.inventory.spider_trash)
        elseif inventory_type == "spider_trunk" then
            inventory = self.entity.get_inventory(defines.inventory.spider_trunk)
        end
        inventory = inventory or {}
        for i = 1, #inventory do
            local item = inventory[i]
            if item.valid_for_read then
                items[item.name] = (items[item.name] or 0) + item.count
            end
        end
    end
    return items
end

function Ctron:get_main_inventory_stats()
    self:log()
    if self:is_valid() then
        local inventory = self.entity.get_inventory(defines.inventory["spider_trunk"])
        local item_count = 0
        for i = 1, #inventory do
            if inventory[i] and (inventory[i]).valid_for_read and (inventory[i]).count > 0 then
                item_count = item_count + 1
            end
        end
        return {
            total = #(inventory),
            used = item_count,
            free = inventory.count_empty_stacks()
        }
    end
end

function Ctron:in_logistic_network()
    if self:is_valid() then
        local network = self.entity.logistic_network
        if network then
            return #(network.logistic_members) > 0
        end
        return false
    end
end

function Ctron:get_logistic_status()
    self:log()
    local request = {}
    if self:is_valid() then
        for i = 1, (self.entity.request_slot_count) do
            local item = self.entity.get_vehicle_logistic_slot(i)
            if item and item.name then
                request[item.name] = (request[item.name] or 0) - item.min
            end
        end
        for _, inv in pairs({"fuel", "burnt_result", "spider_trash", "spider_trunk"}) do
            local items = self:get_inventory(inv)
            for name, count in pairs(items) do
                -- only care about items that are being handled by logistic requests
                if request[name] then
                    request[name] = (request[name] or 0) + count
                end
            end
        end
    end
    for name, count in pairs(request) do
        if count == 0 then
            request[name] = nil
        end
    end
    return request
end

function Ctron:set_request_items(request_items, item_whitelist)
    self:log()
    self:attach_text(self.entity, "set_request_items", self.debug.def.dynamic, 2)
    if self:is_valid() then
        local updated = false
        request_items = request_items or {}
        -- set limits to remove unwanted items from inventory
        item_whitelist = item_whitelist or {}
        for _, inv in pairs({"fuel", "burnt_result", "spider_trash", "spider_trunk"}) do
            local items = self:get_inventory(inv)
            for item_name, _ in pairs(items) do
                if not request_items[item_name] and not item_whitelist[item_name] then
                    request_items[item_name] = 0
                end
            end
        end
        -- set requests
        --log(serpent.block(request_items))
        local slot = 1

        --trash everything + request everything new + fuel + robots
        local max_request_slot_count = self.entity.prototype.get_inventory_size(defines.inventory.spider_trunk) * 2 + 2
        for name, count in pairs(request_items) do
            if slot <= max_request_slot_count then
                count = math.max(count, 0)
                local current = self.entity.get_vehicle_logistic_slot(slot)
                if not current or (current.name or "-") ~= name or current.min ~= count or current.max ~= count then
                    updated = true
                    self.entity.set_vehicle_logistic_slot(
                        slot,
                        {
                            name = name,
                            min = count,
                            max = count
                        }
                    )
                end
            end
            slot = slot + 1
        end
        -- clear remaining slots
        for i = slot, self.entity.request_slot_count do
            self.entity.clear_vehicle_logistic_slot(i)
        end
        return updated
    end
end

function Ctron:clear_items()
    self:log()
    self:set_request_items({})
end

function Ctron:clear_requests()
    self:log()
    local inventory = Ctron:get_inventory("spider_trunk")
    self:set_request_items({}, inventory)
end

function Ctron:get_position()
    self:log()
    if self:is_valid() then
        return {
            position = self.entity.position,
            surface = self.entity.surface,
            speed = self.entity.speed
        }
    end
end

function Ctron:is_moving()
    self:log()
    if self:is_valid() then
        return self.entity.speed > 0.05
    end
end

function Ctron:distance_to(position)
    self:log(serpent.block(position))
    if self:is_valid() and position then
        return math.sqrt((self.entity.position.x - position.x) ^ 2 + (self.entity.position.y - position.y) ^ 2)
    end
end

function Ctron:go_to(target)
    self:log(serpent.block(target))
    if self:is_valid() and target then
        if (self:distance_to(target) < 12) then
            self:set_autopilot(
                {
                    {
                        position = target
                    }
                }
            )
        else
            self.pathfinder:request_path(self, target)
        end
    end
end

function Ctron:teleport_to(target)
    self:log()
    if self:is_valid() then
        -- todo create smoke/vortex at source and target
        self.entity.teleport(target, self.entity.surface)
    end
end

function Ctron:get_construction_enabled()
    self:log()
    return self.construction_enabled == true
end

function Ctron:enable_construction()
    self:log()
    self:attach_text(self.entity, "enable_construction", self.debug.def.dynamic, 2)
    self.construction_enabled = true
    self.entity.enable_logistics_while_moving = true
end

function Ctron:disable_construction()
    self:log()
    self:attach_text(self.entity, "disable_construction", self.debug.def.dynamic, 2)
    self.construction_enabled = false
    self.entity.enable_logistics_while_moving = false
end

function Ctron:robots_active()
    self:log()
    if self:is_valid() then
        local network = self.entity.logistic_network
        if network then
            local cell = network.cells[1]
            local all_construction_robots = network.all_construction_robots
            local stationed_bots = cell.stationed_construction_robot_count
            local active_bots = (all_construction_robots) - (stationed_bots)
            if (network and (active_bots > 0)) then
                return true
            end
            return false
        end
    end
end
function Ctron:robots_inactive()
    self:log()
    return (self:robots_active() ~= true)
end

function Ctron:set_autopilot(path)
    self:log()
    self:attach_text(self.entity, "set_autopilot", self.debug.def.dynamic, 2)
    if self:is_valid() then
        --log("set_autopilot")
        self.entity.autopilot_destination = nil
        self:disable_construction()
        for i, waypoint in ipairs(path) do
            self.entity.add_autopilot_destination(waypoint.position)
            self.target = waypoint.position
        end
        self:set_status(self.status.traveling)
    end
end

return Ctron
