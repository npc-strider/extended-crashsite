--[[ Copyright (c) 2020 npc_strider
 * For direct use of code or graphics, credit is appreciated. See LICENSE.txt for more information.
 * This mod may contain modified code sourced from base/core Factorio
 *
 * data.lua
 * Recipes!!
--]]

require("util")

local function make_wreck_item(name,order)
    return {
        type = "item",
        name = name.."-player",
        icon = "__base__/graphics/icons/"..name..".png",
        icon_size = 64, icon_mipmaps = 4,
        subgroup = "crash-site",
        order = "z[crash-site-spaceship]-"..order,
        place_result = name.."-player",
        stack_size = 1,
        flags = {"hidden"}
    }
end

local entity = {
    {"crash-site-generator","electric-energy-interface"},
    {"crash-site-lab-repaired","lab"}
}

for i=1,2 do
    entity[#entity+1] = {"crash-site-assembling-machine-"..i.."-repaired","assembling-machine"}
    entity[#entity+1] = {"crash-site-chest-"..i,"container"}
end

for i=1, #entity do
    local e = entity[i]
    local newname = e[1].."-player"

    local entity_player = util.table.deepcopy(data.raw[e[2]][e[1]])
    entity_player.name = newname

    if e[1] == "crash-site-generator" then
        entity_player.energy_source = {
            type = "electric",
            buffer_capacity = "2.5MJ",
            usage_priority = "tertiary",
            input_flow_limit = "0kW",
            output_flow_limit = "200kW"
        }
        entity_player.energy_production = "200kW"
        entity_player.energy_usage = "0kW"
    end
    
    entity_player.flags = {"placeable-neutral", "placeable-player", "player-creation", "not-rotatable"} -- I think all of them aren't rotatable - need to check some time
    entity_player.localised_name = {"entity-name."..e[1]}
    if entity_player.minable and not entity_player.minable.result then
        entity_player.minable.result = newname
    else
        entity_player.minable = {mining_time = 0.2, result = newname}
    end

    
    local split = {}
    for match in (newname.."-"):gmatch("(.-)-") do
        split[#split+1] = match
    end

    local item_player

    item_player = util.table.deepcopy(data.raw["item"][e[1]])
    item_player.name = newname
    item_player.place_result = newname

    data:extend({entity_player,item_player})
end