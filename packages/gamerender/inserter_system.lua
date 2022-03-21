local ecs = ...
local world = ecs.world
local w = world.w

local inserter_sys = ecs.system "inserter_system"
local gameplay = ecs.require "gameplay"
local prototype = ecs.require "prototype"
local igame_object = ecs.import.interface "vaststars.gamerender|igame_object"

-- define packages\gameplay\type\assembling.lua
local STATUS_IDLE <const> = 0
local STATUS_DONE <const> = 1

local function get_percent(process, total)
    assert(process <= total)
    if process < 0 then
        process = 0
    end
    return (total - process) / total -- 爪子进度是递减
end

function inserter_sys.update_world()
    for e in gameplay.select "inserter:in entity:in" do
        local inserter = e.inserter
        local game_object = assert(igame_object.get_game_object(e.entity.x, e.entity.y))
        local animation_name
        if inserter.status == STATUS_DONE then
            animation_name = "DownToUp"
        else
            animation_name = "UpToDown"
        end

        local pt = assert(prototype.query(e.entity.prototype))
        igame_object.animation_update(game_object, animation_name, get_percent(inserter.process, assert(pt.speed)))
    end
end
