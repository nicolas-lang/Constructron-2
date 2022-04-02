local custom_lib = require("__Constructron-2__.data.lib.custom_lib")
local control_lib = require("__Constructron-2__.script.lib.control_lib")
local Debug = require("__Constructron-2__.script.objects.Debug")

-- class Type Task, nil members exist just to describe fields
local Task = {
    class_name = "Task",
    area = nil,
    position = nil
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
-- Task Constructor
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

-- Generic Type based initialization
function Task.init_globals()
    global.tasks = global.tasks or {}
end

-- Class Methods
function Task:destroy()
    self:log()
    global.tasks[self.id] = nil
end

function Task:add_entity(entity)
    self:log()
    self.entities[control_lib.get_entity_key(entity)] = entity
end

function Task:get_next_position()
    if self.current_position == 1 then
        self.current_position = self.current_position + 1
        return self:get_position()
    end
end

function Task:get_position()
    self:log()
    local position = {x = 0, y = 0}
    if next(self.entities) then
        local c = 0
        for _, entity in pairs(self.entities) do
            position.x = entity.position.x
            position.y = entity.position.y
            c = c + 1
        end
        position.x = math.floor(position.x / c * 1000 + 0.5) / 1000
        position.y = math.floor(position.y / c * 1000 + 0.5) / 1000
        return position
    end
end

function Task:get_items()
    self:log()
    if next(self.items) then
        return self.items
    end
end

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

function Task:mark_completed()
    self:log()
    self.completed = true
end

function Task:get_completed()
    self:log()
    return self.completed
end

function Task:update()
    self:log()
    local items = {}
    for _, entity in pairs(self.entities) do
        local req_items = self:get_required_items(entity) or {}
        for k, v in pairs(req_items) do
            self:log(k .. " " .. v)
            items[k] = (items[k] or 0) + v
        end
    end
    local item_count = custom_lib.table_length(items)
    if item_count == 0 then
        self:mark_completed()
    end
    self.items = items
end

function Task:get_required_items(entity)
    self:log()
    local function item_to_place_this(items_to_place_this)
        self:log()
        for _, item in ipairs(items_to_place_this) do
            if not game.item_prototypes[item.name].has_flag("hidden") then
                return item.name
            end
        end
    end

    if entity and entity.valid then
        local items = {}
        if entity.type == "tile-ghost" or entity.type == "entity-ghost" then
            local item_name = item_to_place_this(entity.ghost_prototype.items_to_place_this)
            if item_name then
                items[item_name] = (items[item_name] or 0) + 1
            end
        elseif entity.to_be_deconstructed() then
            local item_name = item_to_place_this(entity.prototype.items_to_place_this)
            if not item_name and entity.prototype.minable then
                item_name = entity.prototype.minable.result
            end
            if item_name then
                items[item_name] = (items[item_name] or 0) - 1
            end
        elseif entity.to_be_upgraded() then
            local item_name = item_to_place_this(entity.get_upgrade_target().items_to_place_this)
            if item_name then
                items[item_name] = (items[item_name] or 0) + 1
            end
        elseif entity.type == "cliff" then
            items["cliff-explosives"] = (items["cliff-explosives"] or 0) + 1
        elseif entity.type == "item-request-proxy" then
            for name, count in pairs(entity.item_requests) do
                if not game.item_prototypes[name].has_flag("hidden") then
                    items[name] = (items[name] or 0) + count
                end
            end
        elseif entity.get_health_ratio() < 0.95 then
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
