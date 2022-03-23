-------------------------------------------------------------------------------
--  requires/includes
-------------------------------------------------------------------------------
-- tech unloack reload
local technology_unlocker = require("__Constructron-2__.script.reload_technology_unlock")

-- Constructron parent class
local Ctron = require("__Constructron-2__.script.objects.Ctron")
-- Classic Constructron
local Ctron_classic = require("__Constructron-2__.script.objects.Ctron-classic")
-- Steam Powered  Constructron with managed Gear
local Ctron_steam_powered = require("__Constructron-2__.script.objects.Ctron-steam-powered")
-- Solar Powered  Constructron with managed Gear
local Ctron_solar_powered = require("__Constructron-2__.script.objects.Ctron-solar-powered")
-- Nuclear Powered  Constructron with managed Gear
local Ctron_nuclear_powered = require("__Constructron-2__.script.objects.Ctron-nuclear-powered")
-- Constructron Service Station
local Station = require("__Constructron-2__.script.objects.Station")

local Surface_manager = require("__Constructron-2__.script.objects.Surface-manager")

-- Task Object
local Task = require("__Constructron-2__.script.objects.Task")

-- Pathfinder
local Spidertron_Pathfinder = require("__Constructron-2__.script.objects.Spidertron-pathfinder")

-- will be replaced later
local simple_movement_controller = require("__Constructron-2__.script.simple_movement_controller")

-------------------------------------------------------------------------------
--  variables & Class initializations
-------------------------------------------------------------------------------

Ctron.pathfinder = Spidertron_Pathfinder()

local ctrons = {}
local stations = {}
local surface_managers = {} -- luacheck: ignore

simple_movement_controller.ctrons = ctrons
-------------------------------------------------------------------------------
-- various scripting
-------------------------------------------------------------------------------
--- Sets up a Service-Station object for the given entity.
-- Some description, can be over several lines.
-- @param entity a factorio:LuaEntity object
local function init_service_station(entity)
    log("init_service_station")
    if not stations[entity.unit_number] then
        stations[entity.unit_number] = Station(entity)
    end
end

--- Sets up a Constructron object for the given entity.
-- Only if the entity matches given LuaEntity:type entries
-- @param entity a factorio:LuaEntity object
local function init_spidertron(entity)
    log("init_spidertron")
    if not ctrons[entity.unit_number] then
        if entity.name == "ctron-classic" then
            game.print("new classic ctron built")
            ctrons[entity.unit_number] = Ctron_classic(entity)
        elseif entity.name == "ctron-steam-powered" then
            game.print("new steam powered ctron built")
            ctrons[entity.unit_number] = Ctron_steam_powered(entity)
            ctrons[entity.unit_number]:set_request_items()
        elseif entity.name == "ctron-nuclear-powered" then
            game.print("new nuclear powered ctron built")
            ctrons[entity.unit_number] = Ctron_nuclear_powered(entity)
            ctrons[entity.unit_number]:set_request_items()
        elseif entity.name == "ctron-solar-powered" then
            game.print("new solar powered ctron built")
            ctrons[entity.unit_number] = Ctron_solar_powered(entity)
            ctrons[entity.unit_number]:set_request_items()
        end
    end
end

--- Processes the global chunk queue.
-- the chunk_processing_queue contains chunks that needs to be checked for constructabel objects
-- identified entities are registered with the entity_processing_queue
-- @see process_entity_queue
-- @see rescan_all_surfaces
local function process_chunk_queue()
    log("process_chunk_queue")
    local c = 0
    local index = next(global.chunk_processing_queue)
    while index and c < 5 do
        local chunk_data = global.chunk_processing_queue[index]
        local filters = {
            {type = "entity", filter = {type = "entity-ghost"}},
            {type = "entity", filter = {type = "tile-ghost"}},
            {type = "entity", filter = {to_be_deconstructed = true}},
            {type = "entity", filter = {to_be_upgraded = true}},
            {type = "tile", filter = {to_be_deconstructed = true}}
        }
        if not global.entity_processing_queue[game.tick] then
            global.entity_processing_queue[game.tick] = {}
        end

        if game.surfaces and game.surfaces[chunk_data.surface_key] and game.surfaces[chunk_data.surface_key].valid then
            local surface = game.surfaces[chunk_data.surface_key]
            for _, filter_def in pairs(filters) do
                filter_def.filter.area = {
                    chunk_data.left_top,
                    chunk_data.right_bottom
                }
                local objects
                if filter_def.type == "entity" then
                    objects = surface.find_entities_filtered(filter_def.filter)
                else
                    objects = surface.find_tiles_filtered(filter_def.filter)
                end
                for object in objects do
                    local max_index = #(global.entity_processing_queue[game.tick])
                    global.entity_processing_queue[game.tick][max_index + 1] = object
                end
            end
        end
        global.chunk_processing_queue[index] = nil
        index = next(global.chunk_processing_queue)
        c = c + 1
    end
    return (c > 0)
end

--- Processes the global entity queue.
-- the entity_processing_queue contains entities that needs to be checked for construction tasks
-- @see process_chunk_queue
-- @see on_built_entity
-- @see on_entity_marked
local function process_entity_queue()
    log("process_entity_queue")
    local max_entities_per_call = 5000
    local processing_delay = 60 * 5
    local c = 0
    local tick_index = next(global.entity_processing_queue)
    if tick_index and tick_index + processing_delay < game.tick then
        log("entity processing for tick " .. tick_index .. " was " .. (game.tick - tick_index - processing_delay) .. " ticks late")
        while tick_index and c < max_entities_per_call do
            log("processing tick " .. tick_index)
            local entities = global.entity_processing_queue[tick_index]
            local entity_index = next(entities)
            while entity_index and c < max_entities_per_call do
                local entity = entities[entity_index]
                if entity and entity.valid then
                    if entity.type == "spider-vehicle" then
                        init_spidertron(entity)
                    elseif entity.name == "service-station" then
                        init_service_station(entity)
                    else
                        -- process it
                        log("processing entity:")
                        log("entity.type " .. (entity.type or "nil"))
                        log("entity.name " .. (entity.name or "nil"))
                        if entity.surface then
                            log("entity.surface.index " .. (entity.surface.index or "nil"))
                        end
                        log("entity.unit_number " .. (entity.unit_number or "nil"))
                        local surface_index = entity.surface.index
                        local surface_manager = surface_managers[surface_index]
                        log(serpent.block(surface_manager))
                        surface_manager:process_entity(entity)
                    end
                    c = c + 1
                end
                entities[entity_index] = nil
                entity_index = next(entities)
            end
            if (#entities or 0) == 0 then
                global.entity_processing_queue[tick_index] = nil
            end

            tick_index = next(global.entity_processing_queue)
        end
    end
    return (c > 0)
end

--refacor: rename
local function set_tech_unlock(tech_name)
    for n in (tech_name):gmatch("ctron%-exoskeleton%-equipment%-(%d+)") do
        game.print("unlocked spider movement_research " .. n)
        Ctron.movement_research = tonumber(n)
        for _, unit in pairs(ctrons) do
            unit:setup_gear()
        end
    end
end

--refacor: rename
local function process_tech_unlock()
    -- ToDo Multiple forces
    for _, force in pairs(game.forces) do
        for _, tech in pairs(force.technologies) do
            if tech.researched and string.find(tech.name, "ctron%-exoskeleton%-equipment%-") then
                set_tech_unlock(tech.name)
            end
        end
    end
end

--- Creates a Status Report on *things*.
-- @returns report table object
-- @see interface:get_status_report
local function update_status_report()
    local report = {
        global_stats = {
            report_version = 1,
            info = "work in progress; report contains only static values; object model might change; make sure to validate report_version(int)",
            queue = {
                chunk = 0,
                entity = 0,
                task = 0
            },
            active_jobs = 0,
            paused = global.pause_processing,
            constructrons = {
                classic = {
                    idle = 0
                },
                solar_powered = {
                    idle = 0
                },
                steam_powered = {
                    idle = 0
                },
                nuclear_powered = {
                    idle = 0
                }
            },
            missing_items = {
                name = -23
            }
        },
        surfaces = {
            nauvis = {
                constructrons = {},
                stations = {},
                queue = {
                    chunk = 0,
                    entity = 0,
                    task = 0
                },
                missing_items = {
                    name = -23
                }
            }
        }
    }
    global.status_report = report
end

-------------------------------------------------------------------------------
-- event callback
-------------------------------------------------------------------------------
--- Initializes required globals
-- @see https://lua-api.factorio.com/latest/Data-Lifecycle.html
local on_init = function()
    log("on_init")
    technology_unlocker.reload_tech("spidertron")
    Ctron.init_globals()
    Station.init_globals()
    Spidertron_Pathfinder.init_globals()
    Surface_manager.init_globals()
    Task.init_globals()
    global.entity_processing_queue = global.entity_processing_queue or {}
    global.chunk_processing_queue = global.chunk_processing_queue or {}
    global.status_report = global.status_report or {}
    global.pause_processing = global.pause_processing or false
end

local function on_force_created()
    technology_unlocker.reload_tech("spidertron")
end

--- main worker for entity pre-processing
-- is expected to be scheduled to run every 20 ticks
-- @param event from factorio framework
local on_nth_tick_20 = function(_)
    log("on_nth_tick_20")
    if global.pause_processing then
        log("paused")
        return
    end
    local has_worked
    has_worked = process_chunk_queue()
    if not has_worked then
        has_worked = process_entity_queue()
    end
    if not has_worked then
        limit = 10
        for _, manager in pairs(surface_managers) do
            if limit > 0 then
                limit = limit - manager:assign_tasks(limit)
            end
        end
    end
end

--- main worker for unit/job processing
-- is expected to be scheduled to run every 120 ticks
-- @param event from factorio framework
local on_nth_tick_120 = function(event)
    log("on_nth_tick_120")
    if global.pause_processing then
        log("paused")
        return
    end
    log("entity_processing_queue next " .. (next(global.entity_processing_queue) or 0))
    log(serpent.block(global.entity_processing_queue))
    simple_movement_controller.main(event)
end

--- main object initialization
-- is expected to be scheduled to run on_tick
-- on_tick will be unscheduled
-- schedules on_nth_tick_120
-- @param event from factorio framework
local on_tick_once = function(_)
    log("on_tick_once")
    --initialize logfile
    game.write_file("constructron.log","Constructron Logfile", false)
    Ctron.init_managed_gear()
    Spidertron_Pathfinder.check_pathfinder_requests_timeout()
    process_tech_unlock()

    for _, g_surface in pairs(global.surface_managers or {}) do
        local surface = game.surfaces[g_surface.surface_id]
        if surface and surface.valid then
            surface_managers[surface.index] = Surface_manager(surface)
        else
            surface_managers[g_surface.id] = nil
        end
    end

    for _, surface in pairs(game.surfaces) do
        if surface and surface.valid and not surface_managers[surface.index] then
            surface_managers[surface.index] = Surface_manager(surface)
        end
    end

    for unit_number, entity in pairs(global.constructrons.units) do
        if entity and entity.valid then
            if not ctrons[unit_number] then
                init_spidertron(entity)
            end
        else
            global.constructrons.units[unit_number] = nil
        end
    end

    for unit_number, entity in pairs(global.service_stations.entities) do
        if entity and entity.valid then
            if not stations[unit_number] then
                init_service_station(entity)
            end
        else
            global.service_stations.entities[unit_number] = nil
        end
    end

    -- replace with main worker
    script.on_event(defines.events.on_tick, nil)
    script.on_nth_tick(120, on_nth_tick_120)
    -- log(serpent.block(on_nth_tick_120))
    log("on_tick_once:done")
end

--- Event handler on_built_entity
-- @param event from factorio framework
local function on_built_entity(event)
    game.print("on_built_entity")
    local entity = event.created_entity
    if entity and entity.valid then
        if entity.type == "tile-ghost" or entity.type == "entity-ghost" or entity.type == "item-request-proxy" then
            -- register entity for processing, conditions are ordered by maximum expected number of build prototypes per tick to allow quick "short-circuiting"
            if not global.entity_processing_queue[event.tick] then
                global.entity_processing_queue[event.tick] = {}
            end
            local max_index = #(global.entity_processing_queue[event.tick])
            global.entity_processing_queue[event.tick][max_index + 1] = entity
            log("registered entity for processing #" .. max_index + 1)
        elseif entity.type == "spider-vehicle" then
            init_spidertron(entity)
        elseif entity.name == "service-station" then
            init_service_station(entity)
        end
    end
end

--- Event handler on_entity_marked_for_upgrade and on_entity_marked_for_deconstruction
-- @param event from factorio framework
local function on_entity_marked(event)
    log("on_entity_marked_for_*")
    local entity = event.entity
    if entity and entity.valid then
        if not global.entity_processing_queue[event.tick] then
            global.entity_processing_queue[event.tick] = {}
        end
        local max_index = #(global.entity_processing_queue[event.tick])
        global.entity_processing_queue[event.tick][max_index + 1] = entity
        log("registered entity for processing #" .. max_index + 1)
    end
end

--- Event handler on_entity_damaged
-- @param event from factorio framework
local function on_entity_damaged(event)
    log("on_entity_damaged ")
    local entity = event.entity
    if entity and entity.valid then
        if event.force == "player" and (event.final_health / (event.final_damage_amount + event.final_health)) < 0.95 then
            if not global.entity_processing_queue[event.tick] then
                global.entity_processing_queue[event.tick] = {}
            end
            local max_index = #(global.entity_processing_queue[event.tick])
            global.entity_processing_queue[event.tick][max_index + 1] = entity
            log("registered entity for processing #" .. max_index + 1)
        end
    end
end

--- Event handler on_entity_destroyed
-- @param event from factorio framework
local on_entity_destroyed = function(event)
    log("on_entity_destroyed")
    if Ctron.get_registered_unit(event.registration_number) then
        local unit_number = Ctron.get_registered_unit(event.registration_number)
        if ctrons[unit_number] then
            ctrons[unit_number]:destroy()
            ctrons[unit_number] = nil
        end
    elseif Station.get_registered_entity(event.registration_number) then
        local unit_number = Station.get_registered_entity(event.registration_number)
        if stations[unit_number] then
            stations[unit_number]:destroy()
            stations[unit_number] = nil
        end
    end
end

--- Event handler on_player_removed_equipment
-- @param event from factorio framework
local on_player_removed_equipment = function(event)
    log("on_player_removed_equipment")
    -- assumption: our managed gear if only exists in spidertrons
    -- whenever a known gear is removed we treat the unit as a spidertron
    -- every prototype has a fixed location where if will be placed which is csv encoded in the order field
    if Ctron.managed_equipment[event.equipment] then
        game.players[event.player_index].remove_item {
            name = event.equipment,
            count = 100
        }
        Ctron.restore_gear(event.grid, event.equipment)
    end
end

local on_research_finished = function(event)
    if event and event.research then
        set_tech_unlock(event.research.name)
    end
end

local function on_surface_created(event)
    local surface = event.surface
    if surface and surface.valid then
        surface_managers[surface.index] = Surface_manager(surface)
    end
end
local function on_surface_deleted(event)
    local surface = event.surface
    surface_managers[surface.index] = nil
end
-------------------------------------------------------------------------------
-- event registration
-------------------------------------------------------------------------------
local ev = defines.events

script.on_init(on_init)
script.on_configuration_changed(on_init)

script.on_event(ev.on_force_created, on_force_created)

script.on_nth_tick(20, on_nth_tick_20)

script.on_event(ev.on_tick, on_tick_once) -- replaced by on_nth_tick --> simple_movement_controller.main after 1st tick

script.on_event(
    {
        ev.on_built_entity,
        ev.script_raised_built,
        ev.on_robot_built_entity
    },
    on_built_entity
)
script.on_event(
    ev.on_script_path_request_finished,
    (function(event)
        Spidertron_Pathfinder:on_script_path_request_finished(event)
    end)
)

script.on_event(
    {
        ev.on_entity_destroyed,
        ev.script_raised_destroy
    },
    on_entity_destroyed
)

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

script.on_event(ev.on_player_removed_equipment, on_player_removed_equipment)

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
        {filter = "name", name = "item-on-ground", invert = true, mode = "and"},
        {filter = "type", type = "fish", invert = true, mode = "and"}
    }
)

script.on_event(ev.on_research_finished, on_research_finished)

script.on_event(ev.on_surface_created, on_surface_created)
script.on_event(ev.on_surface_deleted, on_surface_deleted)
--[[script.on_event(ev.on_entity_cloned, ctron.on_entity_cloned)
on_runtime_mod_setting_changed

script.on_event(ev.on_post_entity_died, ctron.on_post_entity_died)
--]]
-------------------------------------------------------------------------------
-- command & interfaces function
-------------------------------------------------------------------------------
--- Resets the queues, And requeues all chunks on all surfaces to be scanned
-- @see process_entity_queue
-- @see process_chunk_queue
local function rescan_all_surfaces()
    log("rescan_all_surfaces")
    global.chunk_processing_queue = {}
    global.entity_processing_queue = {}
    local i = 1
    for surface_key, surface in pairs(game.surfaces) do
        if surface.valid then
            for chunk in surface.get_chunks() do
                if chunk.valid then
                    local index = #global.chunk_processing_queue
                    global.chunk_processing_queue[index + 1] = {
                        surface = surface_key,
                        left_top = chunk.area.left_top,
                        right_bottom = chunk.area.right_bottom
                    }
                    i = i + 1
                end
            end
        end
    end
    log("registered " .. i .. " chunks for rescan")
end

--- full hardreset of everything
-- not implemented
local function reset()
    game.print("hard reset not yet implemented")
    --      global = {}
    -- kill all objects
    --      ctrons = {}
    --      stations = {}
    --      surfacesmanagers = {}
    -- rescan all surfaces for stations and constructrons
    --      ...
    -- re-queue all ghosts
    --      rescan_all_surfaces()
end
--- pauses statemachine and queue processing
-- only pauses statemachine and queue processing, not initial event capture
-- on unpause every ctron might have it's current task run into timeout
local function pause()
    global.pause_processing = not global.pause_processing
    return global.pause_processing
end

--- teleports all ctrons to the next service station
-- not implemented
local function unstuck_all()
    game.print("/ctron unstuck not yet implemented")
end
-------------------------------------------------------------------------------
-- commands & interfaces
-------------------------------------------------------------------------------
--- Game Commands
-- /ctron rescan
-- /ctron reset
-- /ctron pause
-- /ctron unstuck
commands.add_command(
    "ctron",
    "type /ctron rescan to queue all surfaces for a ghost rescan",
    function(param)
        log("/ctron")
        --local player = game.players[param.player_index]
        if param.parameter then
            local command = param.parameter
            if command == "rescan" then
                log("command_rescan")
                rescan_all_surfaces()
            elseif command == "reset" then
                log("command_reset")
                reset()
            elseif command == "pause" then
                log("command_pause")
                pause()
            elseif command == "unstuck" then
                log("command_unstuck")
                unstuck_all()
            end
        end
    end
)

--- Game interfaces
-- rescan
-- reset
-- toggle_pause
-- unstuck
-- get_status_report
remote.add_interface(
    "ctron_interface",
    {
        rescan = function()
            log("interface_rescan")
            rescan_all_surfaces()
        end,
        reset = function()
            log("interface_reset")
            reset()
        end,
        toggle_pause = function()
            log("interface_toggle_pause")
            return pause()
        end,
        unstuck = function()
            log("interface_unstuck")
            unstuck_all()
        end,
        get_status_report = function(update)
            log("get_status_report")
            if update then
                update_status_report()
            end
            return global.status_report
        end
    }
)
