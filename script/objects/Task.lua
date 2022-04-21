local custom_lib = require("__Constructron-2__.data.lib.custom_lib")
local control_lib = require("__Constructron-2__.script.lib.control_lib")
local Debug = require("__Constructron-2__.script.objects.Debug")

---@class Task : Debug
---@field positions table<uint,MapPosition>
---@field current_position uint
---@field entities table <uint,LuaEntity>
---@field items table<string,int>
---@field completed boolean
local Task = {
    class_name = "Task"
}
Task.__index = Task

setmetatable(
    Task,
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
function Task:new(obj)
    Debug.new(self)
    self:log()
    for k, v in pairs(obj or {}) do
        self[k] = v
    end
    global.tasks = global.tasks or {}
    self.id = self.id or #(global.tasks) + 1
    global.tasks[self.id] = self
    self.entities = {}
    self:log("id " .. self.id)
    self.current_position = 1
end

---Generic Type based initialization
function Task.init_globals()
    global.tasks = global.tasks or {}
end

-- Class Methods

--Destructor
function Task:destroy()
    self:log()
    global.tasks[self.id] = nil
end

---Add a new entity to the task'S construction targets
---@param entity LuaEntity
function Task:add_entity(entity)
    self:log()
    self.entities[control_lib.get_entity_key(entity)] = entity
end

---Get the next/current position where things are to be performed
---@return MapPosition
function Task:get_next_position()
    self:log()
    if self.current_position <= custom_lib.table_length(self.positions) then
        return self.positions[self.current_position]
    end
end

---Iterate to the next position
function Task:next_position()
    self.current_position = self.current_position + 1
end

---Get median position of the Task, will be within 32x32 of all entities as a Task represents at most a full chunk
function Task:get_position()
    self:get_median_position(self.entities)
end

---Get median position for the group of Entites
---@param entities table<uint,LuaEntity>
---@return MapPosition median_position
function Task:get_median_position(entities)
    self:log()
    local position = {x = 0, y = 0}
    if next(entities) then
        local c = 0
        for _, entity in pairs(entities) do
            if entity and entity.valid then
                position.x = position.x + entity.position.x
                position.y = position.y + entity.position.y
                self:log("entity " .. serpent.block(entity.position))
                c = c + 1
            end
        end
        if c > 0 then
            position.x = math.floor(position.x / c * 1000 + 0.5) / 1000
            position.y = math.floor(position.y / c * 1000 + 0.5) / 1000
            self:log(serpent.block(position))
            return position
        end
    end
end

---Create a Position mesh with a specific split for rows and cols
---@param split float
function Task:update_positions(split)
    self:log()
    local steps = math.ceil(32 / split)
    self:log(steps)
    local grid_positions = {}
    for x = 1, steps do
        for y = 1, steps do
            grid_positions[x] = {}
            grid_positions[x][y] = {}
        end
    end

    local chunk_base
    for _, e in pairs(self.entities) do
        if e.valid then
            chunk_base = chunk_base or {x = math.floor(e.position.x / 32) * 32, y = math.floor(e.position.y / 32) * 32}
            local index = {x = math.ceil(math.abs((e.position.x - chunk_base.x) / split)), y = math.ceil(math.abs((e.position.y - chunk_base.y) / split))}
            self:log("entity-index" .. serpent.block(index))
            grid_positions[index.x] = grid_positions[index.x] or {}
            grid_positions[index.x][index.y] = grid_positions[index.x][index.y] or {}
            local t = grid_positions[index.x][index.y]
            self:log("entity-position" .. serpent.block(e.position))
            t[#t + 1] = e
            self:log("grid_positions[x][y]" .. serpent.block(grid_positions[index.x][index.y]))
        end
    end
    self:log("entity-positions" .. serpent.block(grid_positions))
    local positions = {}
    for x = 1, steps do
        for y = 1, steps do
            if grid_positions[x] and grid_positions[x][y] and custom_lib.table_length(grid_positions[x][y]) > 0 then
                local median_position = self:get_median_position(grid_positions[x][y])
                self:log("grid_positions[x][y]" .. serpent.block(grid_positions[x][y]))
                self:log("median_position" .. serpent.block(median_position))
                positions[#positions + 1] = median_position
            end
        end
    end
    self:log("task-positions" .. serpent.block(positions))
    self:log(serpent.block(positions))
    self.positions = positions
    self.current_position = 1
end

---Required number of required items for the task
---@return table<string, int>
function Task:get_items()
    self:log()
    if next(self.items) then
        return self.items
    end
end

---Required number of required item-stacks/inventory-slots for the task (rounded up)
function Task:get_item_stacks()
    self:log()
    if next(self.items) then
        local stacks = {}
        for name, count in pairs(self.items) do
            stacks[name] = math.ceil(count / custom_lib.get_stack_size(name))
        end
        return stacks
    end
end

---Get total number of required item-stacks/inventory-slots for the task
---@return number
function Task:get_stack_count()
    self:log()
    if next(self.items) then
        local count = 0
        for _, stacks in pairs(self:get_item_stacks()) do
            count = count + stacks
        end
        return count
    end
end

---Mark the Task completed
function Task:mark_completed()
    self:log()
    self.completed = true
end

---Check if the Task is completed
function Task:get_completed()
    self:log()
    return self.completed
end

---Update the Task: required items, complete-state
function Task:update()
    self:log()
    local items = {}
    for key, entity in pairs(self.entities) do
        local req_items = self:get_required_items(entity)
        if req_items then
            for k, v in pairs(req_items) do
                self:log(k .. " " .. v)
                items[k] = (items[k] or 0) + v
            end
        else
            self.entities[key] = nil
        end
    end
    local item_count = custom_lib.table_length(items)
    if item_count == 0 then
        self:log("completed!")
        self:mark_completed()
    end
    self.items = items
end

---Check which items are required to perform construction on the Tasks Entities
---TODO: port creative-mod fix from continued: if a item is hidden, check if a non hidden, enabled recipe is present to create it.
---TODO: Implement Requester Chest
---@param entity LuaEntity
---@return table
function Task:get_required_items(entity)
    self:log()
    local function item_to_place_this(items_to_place_this)
        self:log()
        if not items_to_place_this then
            return
        end
        for _, item in ipairs(items_to_place_this) do
            if not game.item_prototypes[item.name].has_flag("hidden") then
                return item.name
            end
        end
    end

    if entity and entity.valid then
        local items = {}
        if (entity.type == "tile-ghost" or entity.type == "entity-ghost") and entity.is_registered_for_construction() == false then
            local item_name = item_to_place_this(entity.ghost_prototype.items_to_place_this)
            if item_name then
                items[item_name] = (items[item_name] or 0) + 1
            end
        elseif entity.to_be_deconstructed() then
            local item_name = item_to_place_this(entity.prototype.items_to_place_this)
            if item_name then
                items[item_name] = (items[item_name] or 0) - 1
            elseif entity.prototype.mineable_properties and entity.prototype.mineable_properties.minable then
                for _, product in ipairs(entity.prototype.mineable_properties.products) do
                    if product.type == "item" then
                        item_name = product.name
                        items[item_name] = (items[item_name] or 0) - (product.amount or product.amount_max)
                    end
                end
            end
        elseif entity.to_be_upgraded() and entity.is_registered_for_upgrade() then
            local item_name = item_to_place_this(entity.get_upgrade_target().items_to_place_this)
            if item_name then
                items[item_name] = (items[item_name] or 0) + 1
            end
            item_name = item_to_place_this(entity.prototype.items_to_place_this)
            if item_name then
                items[item_name] = (items[item_name] or 0) - 1
            end
        elseif entity.type == "cliff" then
            items["cliff-explosives"] = (items["cliff-explosives"] or 0) + 1
        elseif entity.type == "item-request-proxy" and entity.is_registered_for_construction() then
            for name, count in pairs(entity.item_requests) do
                if not game.item_prototypes[name].has_flag("hidden") then
                    items[name] = (items[name] or 0) + count
                end
            end
        elseif entity.get_health_ratio() < 0.95 and entity.is_registered_for_repair() then
            local missing = (entity.health / entity.get_health_ratio()) * (1 - entity.get_health_ratio())
            items["repair-pack"] = (items["repair-pack"] or 0) + (missing / 300) * 1.3 -- bring 30% extra tools
        elseif entity.name == "ctron-buffer-chest" then
            self:log("ctron-buffer-chest not yet implemented")
        -- items = chest_requested - chest_inventory - network_inventory(which is not in buffer chests)
        end
        if next(items) then
            return items
        end
    end
end

return Task
