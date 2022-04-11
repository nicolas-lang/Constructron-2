--===========================================================================--
--  requires/includes
--  libraries and static objects
--===========================================================================--
local technology_unlocker = require("__Constructron-2__.script.reload_technology_unlock")
local custom_lib = require("__Constructron-2__.data.lib.custom_lib")
--local control_lib = require("__Constructron-2__.script.lib.control_lib")

-------------------------------------------------------------------------------
-- Generic classes and parent classes
-------------------------------------------------------------------------------
---@type Ctron
local Ctron = require("__Constructron-2__.script.objects.Ctron")
---@type Surface_manager
local Surface_manager = require("__Constructron-2__.script.objects.Surface-manager")
---@type Task
local Task = require("__Constructron-2__.script.objects.Task")
---@type Job
local Job = require("__Constructron-2__.script.objects.Job")
---@type Spidertron_Pathfinder
local Spidertron_Pathfinder = require("__Constructron-2__.script.objects.Spidertron-pathfinder")
---@type Entity_queue
local Entity_processing_queue = require("__Constructron-2__.script.objects.Entity-processing-queue")

-------------------------------------------------------------------------------
-- Classes used as LuaEntity Wrappers
-------------------------------------------------------------------------------
local EntityClass = {
    ---@type Ctron
    ["ctron-classic"] = require("__Constructron-2__.script.objects.Ctron-classic"),
    ---@type Ctron
    ["ctron-steam-powered"] = require("__Constructron-2__.script.objects.Ctron-steam-powered"),
    ---@type Ctron
    ["ctron-solar-powered"] = require("__Constructron-2__.script.objects.Ctron-solar-powered"),
    ---@type Ctron
    ["ctron-nuclear-powered"] = require("__Constructron-2__.script.objects.Ctron-nuclear-powered"),
    ---@type Ctron
    ["ctron-rocket-powered"] = require("__Constructron-2__.script.objects.Ctron-rocket-powered"),
    ---@type Station
    ["service-station"] = require("__Constructron-2__.script.objects.Station")
}

--===========================================================================--
--  runtime variables & Class instanciation
--===========================================================================--
--- Create pathfinder instance for constructron base class
Ctron.pathfinder = Spidertron_Pathfinder()

--- object model supports multiple forces, but we dont care about setting it up for now
---@type table<uint,string>
local player_forces = {"player"}

---Surface managers are currently initialized as a local based on game.surfaces, TBD if that is desync safe
---@type table<uint,table<uint,Surface_manager>>
local surface_managers = {}

--- class instance Entity_processing_queue
---@type Entity_queue
local entity_processing_queue

--===========================================================================--
-- various scripting
--===========================================================================--

---Surface setup and reinitialization.
---Can be called multiple times to re-validate data structures
local function setup_surfaces()
    log("control:setup_surfaces")

    for key, sm in pairs(global.surface_managers) do
        if sm and not sm.surface.valid then
            global.surface_managers[key] = nil
        end
    end

    for _, force_name in pairs(player_forces) do
        local force = game.forces[force_name]
        if force and force.valid then
            surface_managers[force.index] = surface_managers[force.index] or {}
            for _, surface in pairs(game.surfaces) do
                if surface and surface.valid then
                    surface_managers[force.index][surface.index] = Surface_manager(surface, force)
                end
            end
        end
    end
end

-------------------------------------------------------------------------------
---Sets up a entity-wrapper-instance for the given entity.
---Also registers the entity-wrapper with the dedicated surface-manager
---@param entity LuaEntity
---@return boolean
local function init_entity_instance(entity)
    log("control:init_entity_instance")
    if EntityClass[entity.name] then
        local obj = EntityClass[entity.name](entity)
        if entity.name == "service-station" then
            surface_managers[entity.surface.index][entity.force.index]:add_station(obj)
            return true
        elseif EntityClass[entity.name] then
            obj:set_request_items()
            surface_managers[entity.surface.index][entity.force.index]:add_constructron(obj)
        end
    end
end

-------------------------------------------------------------------------------
---callback for the entity-queue to process the LuaEntity after validation/delay
---@param entity LuaEntity
---@param force LuaForce
local function assign_entity_to_surface(entity, force)
    log("control:assign_entity_to_surface")
    if not EntityClass[entity.name] then
        if surface_managers[entity.surface.index] and surface_managers[entity.surface.index][force.index] then
            surface_managers[entity.surface.index][force.index]:register_entity(entity)
        else
            log("WTF!?")
        end
    else
        init_entity_instance(entity)
    end
end

--===========================================================================--
-- event callback
--===========================================================================--
--- Initializes required globals
--- @see https://lua-api.factorio.com/latest/Data-Lifecycle.html
local function on_init()
    log("control:on_init")
    global.pause_processing = false
    Surface_manager.init_globals()
    Ctron.init_globals()
    Task.init_globals()
    Job.init_globals()
    EntityClass["service-station"].init_globals()
    Spidertron_Pathfinder.init_globals()
    Surface_manager.init_globals()
    Entity_processing_queue.init_globals()
end

--- Updates Mod Setting related stuff
--- @see https://lua-api.factorio.com/latest/Data-Lifecycle.html
local function on_configuration_changed()
    log("control:on_configuration_changed")
    technology_unlocker.reload_tech("spidertron")
    Ctron.update_tech_unlocks()
end

-------------------------------------------------------------------------------
---main worker for unit updates
---delegated to the LuaEntity wrappers by the related surface-managers
---@param _ EventData
local function on_nth_tick_300(_)
    log("control:on_nth_tick_300")
    for force_index, _ in pairs(surface_managers) do
        for _, surface_manager in pairs(surface_managers[force_index]) do
            surface_manager:tick_update()
        end
    end
end

-------------------------------------------------------------------------------
--- main worker for unit/job processing
---@param _ EventData
local function on_nth_tick_60(_)
    log("control:on_nth_tick_60")
    if global.pause_processing then
        log("paused")
        return
    end

    -- todo decide on meaningfull processing limits for each process step
    -- todo weave processing limit through all calls

    -- work-work
    entity_processing_queue:process_chunk_queue()
    entity_processing_queue:process_entity_queue()

    for force_index, _ in pairs(surface_managers) do
        for _, surface_manager in pairs(surface_managers[force_index]) do
            surface_manager:assign_tasks()
        end
        for _, surface_manager in pairs(surface_managers[force_index]) do
            surface_manager:assign_jobs()
        end
        for _, surface_manager in pairs(surface_managers[force_index]) do
            surface_manager:run_jobs()
        end
    end
end

-------------------------------------------------------------------------------
--- !!!! NEEDS to be migrated to on_load() for desync safety,
--- this requires changing the obj:new() to not create additional globals,
--- but rather depend on on_init !!!!
--- main object initialization is expected to be scheduled to run on_tick
--- on_tick will be unscheduled
--- schedules on_nth_tick_120
---@param _ EventData
local function on_tick_once(_)
    log("control:on_tick_once")
    Ctron.init_managed_gear()
    entity_processing_queue = Entity_processing_queue(assign_entity_to_surface)
    Spidertron_Pathfinder.check_pathfinder_requests_timeout()

    --create surface-manager objects
    setup_surfaces()
    --create constructron objects
    for unit_number, entity in pairs(global.constructrons.units) do
        if entity and entity.valid then
            local obj = EntityClass[entity.name](entity)
            surface_managers[entity.surface.index][entity.force.index]:add_constructron(obj)
        else
            global.constructrons.units[unit_number] = nil
        end
    end
    --create station objects
    for unit_number, entity in pairs(global.service_stations.entities) do
        if entity and entity.valid then
            local obj = EntityClass[entity.name](entity)
            surface_managers[entity.surface.index][entity.force.index]:add_station(obj)
        else
            global.service_stations.entities[unit_number] = nil
        end
    end
    -- unschdule self and schedule main worker
    script.on_event(defines.events.on_tick, nil)
    script.on_nth_tick(120, on_nth_tick_60)
    script.on_nth_tick(300, on_nth_tick_300)
end

-------------------------------------------------------------------------------
--- Event handler on_player_removed_equipment
--- assumption: our managed gear if only exists in spidertrons, whenever a known gear is removed we treat the unit as a spidertron
--- every prototype has a fixed location where if will be placed which is csv encoded in the equipments order field
---@param event on_player_removed_equipment
local function on_player_removed_equipment(event)
    log("control:on_player_removed_equipment")

    if Ctron.managed_equipment[event.equipment] then
        game.players[event.player_index].remove_item {
            name = event.equipment,
            count = 100
        }
        Ctron.restore_gear(event.grid, event.equipment)
    end
end

-------------------------------------------------------------------------------
---whenever a research is completed or reverted we just re-evaluate and update the custom gear
---@param _ on_research_reversed|on_research_finished
local function on_research(_)
    log("control:on_research")
    Ctron.update_tech_unlocks()
end

-------------------------------------------------------------------------------
--- Event handler on_built_entity
--- perforemance optimized; everything is queued in entity_processing_queue and then deep-processed in smaller batches
---@param event on_built_entity
local function on_built_entity(event)
    log("control:on_built_entity")
    local entity = event.created_entity
    if entity and entity.valid then
        if not entity_processing_queue:queue_entity(entity, entity.force, event.tick, "construction") then
            init_entity_instance(entity)
        end
    end
end

-------------------------------------------------------------------------------
--- Event handler on_post_entity_died
--- perforemance optimized; everything is queued in entity_processing_queue and then deep-processed in smaller batches
---@param event on_post_entity_died
local function on_post_entity_died(event)
    log("control:on_post_entity_died")
    entity_processing_queue:queue_entity(event.ghost, event.ghost.force, event.tick, "construction")
end

-------------------------------------------------------------------------------
--- Event handler on_entity_marked_for_upgrade and on_entity_marked_for_deconstruction
--- perforemance optimized; everything is queued in entity_processing_queue and then deep-processed in smaller batches
---@param event on_marked_for_deconstruction|on_marked_for_upgrade
local function on_entity_marked(event)
    log("control:on_entity_marked_for_*")
    if event.entity and event.entity.valid then
        local force = event.entity.force
        local player = game.players[event.player_index]
        if player then
            force = player.force
        end
        entity_processing_queue:queue_entity(event.entity, force, event.tick, "upgrade/deconstruction")
    end
end

-------------------------------------------------------------------------------
--- Event handler on_entity_damaged
--- perforemance optimized; everything is queued in entity_processing_queue and then deep-processed in smaller batches
---@param event on_entity_damaged
local function on_entity_damaged(event)
    log("control:on_entity_damaged ")
    if event.entity.valid then
        local force = event.entity.force
        if force and custom_lib.table_has_value(player_forces, force.name) and (event.final_health / (event.final_damage_amount + event.final_health)) < 0.90 then
            entity_processing_queue:queue_entity(event.entity, force, event.tick, "repair")
        end
    end
end

-------------------------------------------------------------------------------
--- Event handler on_entity_destroyed
--- perforemance optimized; everything is queued in entity_processing_queue and then deep-processed in smaller batches
---@param event on_entity_destroyed
---@return any
local function on_entity_destroyed(event)
    log("control:on_entity_destroyed")
    log(serpent.block(event))
    local data = Ctron.get_registered_unit(event.registration_number)
    if data then
        return surface_managers[data.surface_index][data.force_index]:constructron_destroyed(data)
    end

    data = EntityClass["service-station"].get_registered_entity(event.registration_number)
    if data then
        return surface_managers[data.surface_index][data.force_index]:station_destroyed(data)
    end
end

-------------------------------------------------------------------------------
--- Event handler on_entity_cloned
--- Spidertrons are cloned in a special way, as they are a composite entity - we have to ignore the legs
---@param event on_entity_cloned
local function on_entity_cloned(event)
    log("control:on_entity_cloned")
    local entity = event.destination
    if entity and EntityClass[entity.name] then
        --register at new surface
        local obj = EntityClass[entity.name](entity)
        if entity.name == "service-station" then
            surface_managers[entity.surface.index][entity.force.index]:add_station(obj)
        else
            obj:set_request_items()
            surface_managers[entity.surface.index][entity.force.index]:add_constructron(obj)
        end
    end
end

--===========================================================================--
-- event registration
--===========================================================================--
local ev = defines.events
-------------------------------------------------------------------------------
-- generic events
-------------------------------------------------------------------------------
script.on_init(on_init)
script.on_configuration_changed(on_configuration_changed)

script.on_event({ev.on_surface_created, ev.on_surface_deleted, ev.on_force_created, ev.on_forces_merged}, setup_surfaces)

script.on_event(ev.on_tick, on_tick_once) -- replaced by on_nth_tick --> fix this, we will desync

script.on_event(ev.on_player_removed_equipment, on_player_removed_equipment)

script.on_event({ev.on_research_finished, ev.on_research_reversed}, on_research)

script.on_event(
    ev.on_entity_cloned,
    on_entity_cloned,
    {
        {filter = "name", name = "service-station", mode = "or"},
        {filter = "name", name = "ctron-classic", mode = "or"},
        {filter = "name", name = "ctron-steam-powered", mode = "or"},
        {filter = "name", name = "ctron-solar-powered", mode = "or"},
        {filter = "name", name = "ctron-nuclear-powered", mode = "or"},
        {filter = "name", name = "ctron-rocket-powered", mode = "or"}
    }
)

script.on_event({ev.on_entity_destroyed, ev.script_raised_destroy}, on_entity_destroyed)

script.on_event(
    ev.on_script_path_request_finished,
    (function(event)
        Ctron.pathfinder:on_script_path_request_finished(event)
    end)
)

-------------------------------------------------------------------------------
-- entity queue events
-------------------------------------------------------------------------------
script.on_event(
    {
        ev.on_built_entity,
        ev.script_raised_built,
        ev.on_robot_built_entity
    },
    on_built_entity
)

script.on_event(ev.on_post_entity_died, on_post_entity_died)

script.on_event(
    ev.on_entity_damaged,
    on_entity_damaged,
    {
        {filter = "final-damage-amount", comparison = ">", value = 20, mode = "and"},
        {filter = "final-health", comparison = ">", value = 0, mode = "and"},
        {filter = "robot-with-logistics-interface", invert = true, mode = "and"},
        {filter = "vehicle", invert = true, mode = "and"},
        {filter = "rolling-stock", invert = true, mode = "and"},
        {filter = "type", type = "character", invert = true, mode = "and"},
        {filter = "type", type = "fish", invert = true, mode = "and"}
    }
)

script.on_event(
    ev.on_marked_for_upgrade,
    on_entity_marked,
    {
        {filter = "vehicle", invert = true, mode = "and"},
        {filter = "rolling-stock", invert = true, mode = "and"}
    }
)

script.on_event(
    ev.on_marked_for_deconstruction,
    on_entity_marked,
    {
        --{filter = "name", name = "item-on-ground", invert = true, mode = "and"},
        {filter = "type", type = "fish", invert = true, mode = "and"}
    }
)

--===========================================================================--
-- command & interface functions
--===========================================================================--

-------------------------------------------------------------------------------
---pauses statemachine and queue processing
---only pauses statemachine and queue processing, the initial event capture is not paused
---on unpause every ctron might have it's current task run into timeout
---@return boolean
local function toggle_pause()
    log("control:toggle_pause")
    global.pause_processing = not global.pause_processing
    game.print("paused: " .. tostring(global.pause_processing))
    return global.pause_processing
end

-------------------------------------------------------------------------------
--- Resets the queues, And requeues all chunks on all surfaces to be scanned
--- neutral deconstructions for nond efault force  might have issues being requeued
local function rescan_all_surfaces()
    log("control:rescan_all_surfaces")
    global.chunk_processing_queue = {}
    global.entity_processing_queue = {}
    for _, surface in pairs(game.surfaces) do
        if surface.valid then
            for chunk in surface.get_chunks() do
                entity_processing_queue:queue_chunk(chunk)
            end
        end
    end
end

-------------------------------------------------------------------------------
--- full hardreset of everything
--- probably not desync safe.
local function reset()
    log("control:reset")
    game.print("Constructron: !!! hard reset !!!", {r = 1, g = 0.2, b = 0.2})
    for k, _ in pairs(global) do
        global[k] = nil
    end
    for force_index, _ in pairs(surface_managers) do
        for key, surface_manager in pairs(surface_managers[force_index]) do
            surface_manager:destroy()
            surface_managers[force_index][key] = nil
        end
    end
    surface_managers = {}
    on_init()
    setup_surfaces()
    rescan_all_surfaces()
    game.print("Constructron: All surfaces queued for rescan")
    game.print("Constructron: please be patient...")
    global.pause_processing = false
end

-------------------------------------------------------------------------------
---get stats from all surface managers and group them
---@return table
local function get_stats()
    log("control:get_stats")
    local stats = {}
    for force_index, _ in pairs(surface_managers) do
        for _, surface_manager in pairs(surface_managers[force_index]) do
            local surface_stats = surface_manager:get_stats()
            custom_lib.merge(stats, surface_stats)
        end
    end
    return stats
end

--===========================================================================--
-- commands & interfaces
--===========================================================================--

local ctron_commands = {
    rescan = rescan_all_surfaces,
    reset = reset,
    pause = toggle_pause,
    stats = get_stats
}

-------------------------------------------------------------------------------
-- commands
-------------------------------------------------------------------------------
commands.add_command(
    "ctron",
    "/ctron rescan|reset|pause",
    function(param)
        log("/ctron " .. (param.parameter or ""))
        --local player = game.players[param.player_index]
        if param.parameter and ctron_commands[param.parameter] then
            ctron_commands[param.parameter]()
        end
    end
)

-------------------------------------------------------------------------------
--- game interfaces
-------------------------------------------------------------------------------
remote.add_interface("ctron_interface", ctron_commands)
