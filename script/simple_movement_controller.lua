local me = {}

local function log(_)
end

local function table_length(tbl)
    local len = 0
    for _, _ in pairs(tbl) do
        len = len + 1
    end
    return len
end

me.main = function(event)
    local request
    if event.tick % 120 == 0 then
        log("tick")
        local p1 = {
            x = -22,
            y = 15
        }
        local p2 = {
            x = 22,
            y = 15
        }
        local p3 = {
            x = 0,
            y = 25
        }
        local target
        local target_distance = 2.5
        for unit_number, unit in pairs(me.ctrons) do
            log("unit_number" .. unit_number)
            if unit:is_valid() then
                log("status:" .. (unit:get_status_name()))
                if unit:get_status_name() == "moving" then
                    log("Ctron.status.moving")
                    if unit:distance_to(p1) < 3 then
                        log("at p1 " .. unit_number)
                        request = {}
                        request["copper-plate"] = 10
                        unit:set_request_items(request)
                        unit:set_status("requesting")
                    elseif unit:distance_to(p2) < 3 then
                        log("at p2 " .. unit_number)
                        request = {}
                        request["iron-plate"] = 10
                        unit:set_request_items(request)
                        unit:set_status("requesting")
                    elseif not unit:is_moving() then
                        unit:set_status("idle")
                    end
                end

                if unit:get_status_name() == "requesting" then
                    log("Ctron.status.requesting")
                    local logistic_status = unit:get_logistic_status()
                    log("logistic_status: " .. serpent.block(logistic_status))
                    log("logistic_status: #" .. table_length(logistic_status))
                    if table_length(logistic_status) > 0 then
                        log("waiting for request " .. unit_number)
                    else
                        unit:set_status("idle")
                    end
                end

                if unit:get_status_name() == "idle" then
                    log("Ctron.status.idle")
                    if unit:distance_to(p1) < target_distance then
                        target = p2
                    elseif unit:distance_to(p2) < target_distance then
                        target = p3
                    elseif unit:distance_to(p3) < target_distance then
                        target = p1
                    else
                        target = p1
                        game.print("reset " .. unit_number)
                    end

                    if not unit:is_moving() then
                        log("move " .. unit_number)
                        unit:go_to(target)
                    end
                end
            else
                unit:destroy()
            end
        end
    end
    if event.tick % 480 == 0 then
        for _, unit in pairs(me.ctrons) do
            if unit:is_valid() then
                unit:tick_update()
            else
                unit:destroy()
            end
        end
    end
end

return me
