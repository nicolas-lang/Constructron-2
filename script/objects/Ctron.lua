--local Class = require("__Constructron-2__.script.objects.Class")
local Debug = require("__Constructron-2__.script.objects.Debug")
--local util = require("__core__.lualib.util")
local custom_lib = require("__Constructron-2__.data.lib.custom_lib")

---@class Ctron : Debug
---@field entity LuaEntity
---@field status table<string, number>
---@field pathfinder Spidertron_Pathfinder
---@field speed_sticker LuaEntity
---@field fuel string
---@field construction_enabled boolean
---@field construction_robots table <string,any>
---@field target MapPosition
---@field job_id uint
---@field managed_equipment table <string,table>
---@field gear table <uint,string>
---@field managed_equipment_cols uint
---@field movement_research uint
---@field inventory_filters table <string,uint>
local Ctron = {
    class_name = "Ctron",
    gear = {},
    managed_equipment = {},
    managed_equipment_cols = 0,
    last_status_update_tick = 0,
    movement_research = 1,
    inventory_filters = {},
    status = {
        requesting = 4,
        robots_active = 3,
        robots_charging = 10,
        idle = 1,
        traveling = 2,
        error = 6,
        pathfinding_failed = 9,
        no_power = 7,
        no_fuel = 8
    }
}

--Class Initialization
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

---Constructor
---@param entity LuaEntity
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
    else
        log("Ctron:entity invalid")
    end
end

---Generic Type based initialization
---TODO: move init to on_load
function Ctron.init_globals()
    global.constructrons = global.constructrons or {}
    global.constructrons.units = global.constructrons.units or {}
    global.constructrons.unit_registration = global.constructrons.unit_registration or {}
    global.constructrons.unit_status = global.constructrons.unit_status or {}
end

---Initializes managed gear prototypes and stores default location
---Uses gear's "order" field to store compute predefined location from csv-string
function Ctron.init_managed_gear()
    for _, prototype in pairs(game.equipment_prototypes) do
        if prototype.equipment_categories and custom_lib.table_has_value(prototype.equipment_categories, "constructron-managed") then
            for x, y in (prototype.order):gmatch "constructron=(%d+);(%d+)" do --"constructron=3;1"
                Ctron.managed_equipment[prototype.name] = {x = tonumber(x), y = tonumber(y)}
            end
        end
    end
    log("managed_equipment" .. serpent.block(Ctron.managed_equipment))
end

---Update of managed gear based on the force's unlocked techs
---TODO: change to be entity based instead of prototype based
function Ctron.update_tech_unlocks()
    log("Ctron.update_tech_unlocks")
    local tech_name = "ctron%-exoskeleton%-equipment%-(%d+)"
    local max_tier = 1
    --if self:is_valid() then
    --local force = self.entity.force
    local force = game.forces["player"]
    for _, tech in pairs(force.technologies) do
        if tech.researched then
            for tier in (tech.name):gmatch(tech_name) do
                max_tier = math.max(max_tier, tonumber(tier))
            end
        end
    end
    log("max_tier: " .. max_tier)
    Ctron.movement_research = max_tier
    --end
end

---Equippment Grid Fixer
---Quote Rseding91: "The equipment grid has no idea what entity currently owns it - and may not even be owned by an entity."
-----> on_player_removed_equipment event needs to operate on the grid and it is near impossible to get a related entity
-----> we just care about the equipment_name and assume the layout was validated in Ctron:setup_gear()
---@param equipment_grid LuaEquipmentGrid
---@param equipment_name string
function Ctron.restore_gear(equipment_grid, equipment_name)
    log("restore_gear")
    if equipment_grid then
        local grid_contents = equipment_grid.get_contents()
        if grid_contents and not grid_contents[equipment_name] and Ctron.managed_equipment[equipment_name] then
            equipment_grid.put(
                {
                    name = equipment_name,
                    position = Ctron.managed_equipment[equipment_name]
                }
            )
        end
    end
end

---Get registered force,surface and id based on constructron's unit_registration_number
---@param unit_registration_number int
---@return table
function Ctron.get_registered_unit(unit_registration_number)
    return global.constructrons.unit_registration[unit_registration_number]
end

---Cleanup of globals
function Ctron:destroy()
    self:log()
    global.constructrons.unit_registration[self.registration_id] = nil
    global.constructrons.units[self.unit_number] = nil
    global.constructrons.unit_status[self.unit_number] = nil
end

---entity validation
function Ctron:is_valid()
    --self:log()
    return (self.entity and self.entity.valid)
end

---regular unit maintenance tasks
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
                    --attach slow sticker
                    if self:is_moving() then
                        self:set_speed_sticker()
                    else
                        self:set_speed_sticker(true)
                    end
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

---unit's status update
---@return nil
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
            -- if travel times out alert the player
            return self:set_status(Ctron.status.traveling)
        end

        if self:is_moving() == false and self.construction_enabled then
            if self:robots_inactive() == false then
                --todo add timeout
                --also: if robots time-out we need to collect them --> drop items on the floor mark them for decon and destroy the robots
                return self:set_status(Ctron.status.robots_active)
            end

            for i, equipment in pairs(self.entity.grid.equipment) do -- does not account for only 1 item in grid
                if equipment.type == "roboport-equipment" then
                    if (equipment.energy / equipment.max_energy) < 0.99 then
                        return self:set_status(Ctron.status.robots_charging)
                    end
                end
            end
        end
        if self:in_logistic_network() then
            local active_logistic_requests = self:get_logistic_status() or {}
            if custom_lib.table_length(active_logistic_requests) > 0 then
                --todo check if items are avaliable at all in network
                --todo add timeout
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

---helper to get the correct gear name based on tech level
---TODO: Change to be instance not prototype based
---@param name string
---@return string
function Ctron:parse_gear_name(name)
    self:log()
    name = string.gsub(name, "{movement_research}", tostring(Ctron.movement_research))
    return name
end

---remove unmanaged equippment from first n rows
---setup mananaged gear in first n rows
function Ctron:setup_gear()
    self:log()
    self:attach_text(self.entity, "update_gear", self.debug_definition.lines.dynamic, 2)
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

---get health ratio 0(dead) --> 1(healthy)
---@return float
function Ctron:get_health_ratio()
    self:log()
    if self:is_valid() then
        return self.entity.get_health_ratio()
    end
    return 0
end

---if the constructron is assigned to a job get the job-id
function Ctron:get_job_id()
    self:log()
    return self.job_id
end

---assignes the constructron to a job
---@param job_id string|number
function Ctron:assign_job(job_id)
    self:log()
    self:attach_text(self.entity, "set_job", self.debug_definition.lines.dynamic, 2)
    self.job_id = job_id
end

---update constructrons unit-status-field
---@param status string|int
---@return string
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
                    self:attach_text(self.entity, key, self.debug_definition.lines.line_2, 2)
                end
            end
        else
            self:log(status)
            self:attach_text(self.entity, status, self.debug_definition.lines.line_2, 2)
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

---check when the last lastus update happened
---@return number|uint
function Ctron:get_last_status_update_tick()
    self:log()
    return self.last_status_update_tick
end

---get status id
---@return number
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

---get status name
---@return string
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

---get simplified inventory contents
---@param inventory_type string
---@return table
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

---get simplified inventory information
---@return table
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

---check if the unit is currently within an external logistic network
---@return boolean
function Ctron:in_logistic_network()
    if self:is_valid() then
        local network = self.entity.logistic_network
        if network then
            return #(network.logistic_members) > 0
        end
        return false
    end
end

---check if the unit's logistic requests are satisfied
---@return table
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

---gets the construction radius for the units own logistic cell
---@return float
function Ctron:get_construction_radius()
    self:log()
    if self:is_valid() then
        return self.entity.logistic_cell.construction_radius * 0.8
    end
end

---sets logistic requests, existing unrequested items will be trashed if not whitelisted
---@param request_items table items to request
---@param item_whitelist table items to keep
---@return boolean
function Ctron:set_request_items(request_items, item_whitelist)
    self:log()
    self:attach_text(self.entity, "set_request_items", self.debug_definition.lines.dynamic, 2)
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

---clears all items from inventory
function Ctron:clear_items()
    self:log()
    self:set_request_items({})
end

---removes all requests for new items, but keeps the requests for items currently in the inventory
function Ctron:clear_requests()
    self:log()
    local inventory = Ctron:get_inventory("spider_trunk")
    self:set_request_items({}, inventory)
end

---current unit position including surface and speed
---@return table
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

---are we moving?
---@return boolean
function Ctron:is_moving()
    self:log()
    if self:is_valid() then
        return self.entity.speed > 0.05
    end
end

---distance to target position
---@param position MapPosition
---@return number
function Ctron:distance_to(position)
    self:log(serpent.block(position))
    if self:is_valid() and position then
        return math.sqrt((self.entity.position.x - position.x) ^ 2 + (self.entity.position.y - position.y) ^ 2)
    end
end

---move to the target using the factorio pathfinder
---(unless we are nearby in which case a direct move will be executed)
---@param target MapPosition
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

---teleport to the target
---@param target MapPosition
function Ctron:teleport_to(target)
    self:log()
    if self:is_valid() then
        -- todo create smoke/vortex at source and target
        self.entity.teleport(target, self.entity.surface)
    end
end

---check if the unit is set up for construction
---@return boolean
function Ctron:get_construction_enabled()
    self:log()
    return self.construction_enabled == true
end

---set up unit for construction
function Ctron:enable_construction()
    self:log()
    self:attach_text(self.entity, "enable_construction", self.debug_definition.lines.dynamic, 2)
    self.construction_enabled = true
    self.entity.enable_logistics_while_moving = true
end

---disable construction
function Ctron:disable_construction()
    self:log()
    self:attach_text(self.entity, "disable_construction", self.debug_definition.lines.dynamic, 2)
    self.construction_enabled = false
    self.entity.enable_logistics_while_moving = false
end

---removes all requests without touching inventory
function Ctron:cancel_requests()
    self:log()
    self:attach_text(self.entity, "cancel_requests", self.debug_definition.lines.dynamic, 2)
    for i = 1, self.entity.request_slot_count do
        self.entity.clear_vehicle_logistic_slot(i)
    end
end

---checks if the unit's construction robots are deplyed
---@return boolean
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

---checks if the unit's construction robots are stashed
---@return any
function Ctron:robots_inactive()
    self:log()
    return (self:robots_active() ~= true)
end

---start moving on a path using the unit's autopilot system
---@param path any
function Ctron:set_autopilot(path)
    self:log()
    self:attach_text(self.entity, "set_autopilot", self.debug_definition.lines.dynamic, 2)
    if self:is_valid() then
        --log("set_autopilot")
        self.entity.autopilot_destination = nil
        self:disable_construction()
        self:cancel_requests()
        for i, waypoint in ipairs(path) do
            self.entity.add_autopilot_destination(waypoint.position)
            self.target = waypoint.position
        end
        if self.target then
            --self:clear_passengers()
            self:attach_text(self.entity, "target: " .. math.floor(self.target.x * 10) / 10 .. " / " .. math.floor(self.target.y * 10) / 10, self.debug_definition.lines.dynamic, 2)
            self:set_status(self.status.traveling)
        else
            self:set_status(self.status.idle)
        end
    end
end

---set inventory slot filters
function Ctron:update_slot_filters()
    self:log()
    local offset = 0
    local inventory = self.entity.get_inventory(defines.inventory.spider_trunk)
    log(serpent.block(self.inventory_filters))
    for item, slot_count in pairs(self.inventory_filters) do
        self:log(item .. ": " .. slot_count)
        for i = 1, slot_count do
            local slot = (#inventory) - offset
            self:log(item .. ": " .. slot)
            if not inventory.set_filter(slot, item) then
                inventory[slot].clear()
                inventory.set_filter(slot, item)
            end
            offset = offset + 1
        end
    end
end

---slow down unit using a speed sticker
---@param extended boolean apply a extended duration sticker
function Ctron:set_speed_sticker(extended)
    if self.speed_sticker and self.speed_sticker.valid then
        return
    end
    self.speed_sticker =
        self.entity.surface.create_entity(
        {
            name = "ctron-speed-sticker",
            target = self.entity,
            force = self.entity.force,
            position = self.entity.position
        }
    )
    if extended then
        self.speed_sticker.time_to_live = 120
    end
    self.speed_sticker.active = true
end

---remove all passengers from the unit
function Ctron:clear_passengers()
    if self.entity.driver and self.entity.driver.valid then
        self.entity.driver.destroy()
        self.entity.driver = nil
    end

    if self.entity.passenger and self.entity.passenger.valid then
        self.entity.passenger.destroy()
        self.entity.passenger = nil
    end
end

return Ctron
