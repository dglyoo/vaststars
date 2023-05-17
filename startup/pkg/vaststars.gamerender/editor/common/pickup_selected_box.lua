local ecs = ...
local world = ecs.world
local w = world.w

local iprototype = require "gameplay.interface.prototype"
local create_selected_boxes = ecs.require "selected_boxes"
local SPRITE_COLOR = import_package "vaststars.prototype".load("sprite_color")

local mt = {}
mt.__index = mt

function mt:on_status_change(valid)
    local color
    if valid then
        color = SPRITE_COLOR.CONSTRUCT_OUTLINE_SELF_VALID
    else
        color = SPRITE_COLOR.CONSTRUCT_OUTLINE_SELF_INVALID
    end
    self.selected_boxes:set_color_transition(color, 400)
end

function mt:on_position_change(building_srt)
    self.selected_boxes:set_position(building_srt.t)
end

function mt:remove()
    self.selected_boxes:remove()
end

return function (position, typeobject, dir, valid)
    local self = setmetatable({}, mt)

    local color
    if valid then
        color = SPRITE_COLOR.CONSTRUCT_OUTLINE_SELF_VALID
    else
        color = SPRITE_COLOR.CONSTRUCT_OUTLINE_SELF_INVALID
    end
    local selected_boxes = create_selected_boxes(
        {
            "/pkg/vaststars.resources/prefabs/selected-box-no-animation.prefab",
            "/pkg/vaststars.resources/prefabs/selected-box-no-animation-line.prefab",
        },
        position, color, iprototype.rotate_area(typeobject.area, dir)
    )

    self.selected_boxes = selected_boxes
    return self
end