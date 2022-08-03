local iprototype = require "gameplay.interface.prototype"
local gameplay_core = require "gameplay.core"
local math3d = require "math3d"
local DEFAULT_COLOR <const> = math3d.constant("v4", {2.5, 0.0, 0.0, 0.55})

local function _round(max_tick)
    local v <const> = 100 / max_tick / 100
    return function(progress) -- progress: 0.0 ~ 1.0
        return math.ceil(progress / v) * v
    end
end
local _get_progress = _round(10)

local color_cache = {}
local function _get_fluid_color(fluid)
    if color_cache[fluid] then
        return color_cache[fluid]
    end

    local typeobject = iprototype.queryById(fluid)
    if typeobject.color then
        color_cache[fluid] = math3d.constant("v4", typeobject.color)
        return color_cache[fluid]
    end
end

local function update_world(world, get_object_func)
    local t = {}
    for e in world.ecs:select "fluidbox:in entity:in" do
        local typeobject = assert(iprototype.queryById(e.entity.prototype))
        if not typeobject.storage_tank then
            goto continue
        end

        local volume = 0
        local capacity = 0
        local color
        if e.fluidbox.fluid ~= 0 then
            color = _get_fluid_color(e.fluidbox.fluid)
            local r = gameplay_core.fluidflow_query(e.fluidbox.fluid, e.fluidbox.id)
            if r then
                volume = r.volume / r.multiple
                capacity = r.capacity / r.multiple
            end
        end

        local vsobject = get_object_func(e.entity.x, e.entity.y)

        if volume > 0 then
            vsobject:attach("water_slot", "prefabs/storage-tank-water.prefab", "opacity", color or DEFAULT_COLOR)
        else
            vsobject:detach()
        end

        if volume > 0 then
            local animation_name = "ArmatureAction"
            vsobject:animation_update(animation_name, _get_progress(volume / capacity))
        end
        ::continue::
    end
    return t
end
return update_world