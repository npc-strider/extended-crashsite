
local util = require("util")
local crash_site = require("crash-site")

local ship_parts =
{
    {
      name = "crash-site-assembling-machine",
      variations = 2,
      angle_deviation = 0.07,
      max_distance = 40,
      min_separation = 16,
      fire_count = 1
    },
    {
      name = "crash-site-lab-repaired",
      angle_deviation = 0.07,
      max_distance = 15,
      fire_count = 0
    },
    {
      name = "crash-site-generator",
      angle_deviation = 0.06,
      max_distance = 15,
      fire_count = 0
    },
    {
      name = "crash-site-chest",
      variations = 2,
      angle_deviation = 0.075,
      max_distance = 40,
      min_separation = 16,
      fire_count = 0
    }
}

local random = math.random

local rotate = function(offset, angle)
    local x = offset[1]
    local y = offset[2]
    local rotated_x = x * math.cos(angle) - y * math.sin(angle)
    local rotated_y = x * math.sin(angle) + y * math.cos(angle)
    return {rotated_x, rotated_y}
end

local get_name = function(part, k)
    if not part.variations then return part.name end
    local variant = k or random(part.variations)
    return part.name.."-"..variant
end
  
local get_lifetime = function(offset)
    --Generally, close to the ship, last longer.
    local distance = ((offset[1] * offset[1]) + (offset[2] * offset[2])) ^ 0.5
    local time = random(60 * 20, 60 * 30) - math.min(distance * 100, 15 * 60)
    return time
end
  
local get_random_position = function(box, x_scale, y_scale)
    local x_scale = x_scale or 1
    local y_scale = y_scale or 1
    local x1 = box.left_top.x
    local y1 = box.left_top.y
    local x2 = box.right_bottom.x
    local y2 = box.right_bottom.y
    local x = ((x2 - x1) * x_scale * (random() - 0.5)) + ((x1 + x2) / 2)
    local y = ((y2 - y1) * y_scale * (random() - 0.5)) + ((y1 + y2) / 2)
    return {x, y}
end
  
local entry_angle = 0.70
local random = math.random
local get_offset = function(part)
    local angle = entry_angle + ((random() - 0.5) * part.angle_deviation)
    angle = angle - 0.25
    angle = angle * math.pi * 2
    local distance = 8 + (random() * (part.max_distance or 40))
    local offset = rotate({distance, 0}, angle)
    return offset
end

script.on_init(function()
    if remote.interfaces.freeplay then
        remote.call("freeplay", "set_disable_crashsite", false)     -- That's the point of this mod... to have a crashsite, so we're force enabling it
    end
end)


script.on_event(defines.events.on_player_created, function(event)
    if not global.init_ran then
        global.init_ran = true

        if remote.interfaces.freeplay then
            -- game.print("FREEPLAY")
            local player = game.players[event.player_index]
            local surface = player.surface
            local sps = surface.find_entities_filtered{position = player.force.get_spawn_position(surface), radius = 250, name = "crash-site-spaceship"}    -- Just to confirm the spaceship loc
            local position = sps[1].position
            
            local wreck_parts = {}

            for k, part in pairs (ship_parts) do
                for k = 1, (part.variations or 1) do
                    local name = get_name(part, k)
                    if game.entity_prototypes[name.."-repaired-player"] then 
                        name=name.."-repaired-player"
                    else
                        name=name.."-player"
                    end
                    -- local name_ = get_name(part, k, "-repaired")
                    for i = 1, part.repeat_count or 1 do
              
                        local part_position
                        local count = 0
                        local offset
                        while true do
                            offset = get_offset(part)
                            local x = (position[1] or position.x) + offset[1]
                            local y = (position[2] or position.y) + offset[2]
                            part_position = {x, y}
                            if surface.can_place_entity
                            {
                                name = name,
                                position = part_position,
                                force = "player",
                                build_check_type = defines.build_check_type.ghost_place,
                                forced = true
                            } then
                                -- game.print(count.. " " .. k .. " " .. surface.count_entities_filtered{position = part_position, radius = part.min_separation, limit = 1, type = game.entity_prototypes[name_].type})

                                if not part.min_separation then
                                    break
                                elseif surface.count_entities_filtered{position = part_position, radius = part.min_separation, limit = 1, type = game.entity_prototypes[name].type} == 0 then
                                    break
                                else
                                end
                            end
                            count = count + 1
                            if count > 40 then
                                part_position = surface.find_non_colliding_position(name, part_position, 50, 4)
                                break
                            end
                          end
              
                        if part_position then
                            local entity = surface.create_entity({
                                name = name,
                                position = part_position,
                                force = "player"
                            })
                            -- Something dumb happening with simple-entity and a position that is not constant. Have to use repaired variant of entity!

                            local type = game.entity_prototypes[name].type
                            if type == "assembling-machine" then
                                entity.health = entity.health/6
                            elseif type == "lab" then
                                entity.health = entity.health/1.5
                            elseif type == "container" then
                                local count = random(0,2)
                                if count > 0 then
                                    entity.insert({name="repair-pack",count=count})
                                end
                            end

                            if entity.get_output_inventory() and #entity.get_output_inventory() > 0 then
                                wreck_parts[entity.unit_number] = entity
                            end
                
                            for k, entity in pairs (surface.find_entities_filtered{type = {"tree", "simple-entity"}, position = part_position, radius = 1 + entity.get_radius()}) do
                                if entity.type == "tree" then
                                    entity.die()
                                else
                                    entity.destroy()
                                end
                            end

                            if part.fire_count then
                                for k = 1, part.fire_count do
                                    surface.create_entity
                                    {
                                        name = "crash-site-fire-flame",
                                        position = get_random_position(entity.bounding_box)
                                    }
                                    local explosions = surface.create_entity
                                    {
                                        name = "crash-site-fire-smoke",
                                        position = get_random_position(entity.bounding_box)
                                    }
                                    explosions.time_to_live = get_lifetime(offset)
                                    explosions.time_to_next_effect = random(30)
                                end
                              end
                    
                        end
                    end
                end
            end
            
        else
            -- game.print("NOT FREEPLAY")
        end
    end
end)
