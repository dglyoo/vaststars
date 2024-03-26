local ecs, mailbox = ...
local world = ecs.world

local CONSTRUCT_LIST <const> = ecs.require "vaststars.prototype|construct_list"
local BUTTONS <const> = {
    { command = "rotate",           icon = "/pkg/vaststars.resources/ui/textures/build/rotate.texture", },
    { command = "continuous_build", icon = "/pkg/vaststars.resources/ui/textures/build/continuous_build.texture", },
    { command = "single_build",     icon = "/pkg/vaststars.resources/ui/textures/build/single_build.texture", },
}
local DESC <const> = ecs.require "vaststars.prototype|menu.desc"

local iui = ecs.require "engine.system.ui_system"
local click_main_button_mb = mailbox:sub {"click_main_button"}
local lock_axis_mb = mailbox:sub {"lock_axis"}
local rotate_mb = mailbox:sub {"rotate"}
local single_build_mb = mailbox:sub {"single_build"}
local continuous_build_mb = mailbox:sub {"continuous_build"}
local gameplay_core = require "gameplay.core"
local iinventory = require "gameplay.interface.inventory"
local iprototype = require "gameplay.interface.prototype"
local click_item_mb = mailbox:sub {"click_item"}
local item_unlocked = ecs.require "ui_datamodel.common.item_unlocked".is_unlocked
local set_button_offset = ecs.require "ui_datamodel.common.sector_menu".set_button_offset

local M = {}

local function get_list()
    local gameplay_world = gameplay_core.get_world()

    local res = {}
    for category_idx, menu in ipairs(CONSTRUCT_LIST) do
        local r = {}
        r.category = menu.category
        r.items = {}

        for item_idx, prototype_name in ipairs(menu.items) do
            local typeobject = assert(iprototype.queryByName(prototype_name))
            local count = iinventory.query(gameplay_world, typeobject.id)
            if not (item_unlocked(typeobject.name) or count > 0) then
                goto continue
            end

            r.items[#r.items + 1] = {
                id = ("%s:%s"):format(category_idx, item_idx),
                prototype = typeobject.id,
                name = iprototype.display_name(typeobject),
                icon = typeobject.item_icon,
                count = count,
                selected = false,
            }
            ::continue::
        end

        if #r.items > 0 then
            res[#res+1] = r
        end
    end
    return res
end

local function update_list_item(construct_list, category_idx, item_idx, key, value)
    if category_idx == 0 and item_idx == 0 then
        return
    end
    assert(construct_list[category_idx])
    assert(construct_list[category_idx].items[item_idx])
    construct_list[category_idx].items[item_idx][key] = value
end

local function get_index(list, prototype)
    for category_idx, v in pairs(list) do
        for item_idx, item in pairs(v.items) do
            if item.prototype == prototype then
                return category_idx, item_idx
            end
        end
    end
    error(("%s not found in construct_list"):format(iprototype.queryById(prototype).name))
end

local function _handler(datamodel)
    local t = {}
    for _, v in ipairs(BUTTONS) do
        if datamodel[v.command] then
            t[#t+1] = {
                command = v.command,
                background_image = v.icon,
                desc = DESC["bulk_opt." .. v.command] or "",
            }
        end
    end
    set_button_offset(t)
    return t
end

function M.create(prototype)
    local main_button_icon = ""
    if prototype then
        local typeobject = assert(iprototype.queryById(prototype))
        main_button_icon = typeobject.item_icon
    end

    local category_idx, item_idx = 0, 0
    local construct_list = get_list()
    if prototype then
        category_idx, item_idx = get_index(construct_list, prototype)
        update_list_item(construct_list, category_idx, item_idx, "selected", true)
    end

    local t = {
        rotate = false,
        build = false,
        continuous_build = false,
        desc = "",
        lock_axis = false,
        main_button_icon = main_button_icon,
        category_idx = category_idx,
        item_idx = item_idx,
        construct_list = construct_list,
        show_list = true,
    }

    t.buttons = _handler(t)
    return t
end

function M.update(datamodel)
    for _ in click_main_button_mb:unpack() do
        iui.redirect("/pkg/vaststars.resources/ui/construct.html", "build")
    end

    for _ in lock_axis_mb:unpack() do
        datamodel.lock_axis = not datamodel.lock_axis
        if datamodel.lock_axis then
            iui.redirect("/pkg/vaststars.resources/ui/construct.html", "lock_axis")
        else
            iui.redirect("/pkg/vaststars.resources/ui/construct.html", "unlock_axis")
        end
    end

    for _ in rotate_mb:unpack() do
        iui.redirect("/pkg/vaststars.resources/ui/construct.html", "rotate")
    end

    for _ in single_build_mb:unpack() do
        iui.redirect("/pkg/vaststars.resources/ui/construct.html", "set_continuity", false)
        datamodel.single_build = false
        datamodel.continuous_build = true
        datamodel.buttons = _handler(datamodel)
    end

    for _ in continuous_build_mb:unpack() do
        iui.redirect("/pkg/vaststars.resources/ui/construct.html", "set_continuity", true)
        datamodel.single_build = true
        datamodel.continuous_build = false
        datamodel.buttons = _handler(datamodel)
    end

    for _, _, _, category_idx, item_idx in click_item_mb:unpack() do
        update_list_item(datamodel.construct_list, datamodel.category_idx, datamodel.item_idx, "selected", false)
        update_list_item(datamodel.construct_list, category_idx, item_idx, "selected", true)
        datamodel.category_idx = category_idx
        datamodel.item_idx = item_idx

        datamodel.show_list = false

        local prototype = datamodel.construct_list[category_idx].items[item_idx].prototype
        local typeobject = assert(iprototype.queryById(prototype))
        datamodel.main_button_icon = typeobject.item_icon

        datamodel.rotate = true
        local continuity = typeobject.continuity == nil and true or typeobject.continuity
        datamodel.single_build = continuity
        datamodel.continuous_build = not continuity
        datamodel.buttons = _handler(datamodel)

        iui.redirect("/pkg/vaststars.resources/ui/construct.html", "construct_entity", typeobject.name, continuity)
    end
end

return M