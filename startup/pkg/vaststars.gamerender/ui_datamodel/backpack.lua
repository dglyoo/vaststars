local ecs, mailbox = ...
local world = ecs.world
local w = world.w

local ITEM_CATEGORY <const> = import_package "vaststars.prototype"("item_category")
local gameplay_core = require "gameplay.core"
local iprototype = require "gameplay.interface.prototype"
local iBackpack = import_package "vaststars.gameplay".interface "backpack"
local click_item_mb = mailbox:sub {"click_item"}
local close_mb = mailbox:sub {"close"}
local iui = ecs.require "engine.system.ui_system"
local iprototype_cache = ecs.require "prototype_cache"

local function get_backpack()
    local t = {}
    for _, slot in pairs(iBackpack.all(gameplay_core.get_world())) do
        local typeobject_item = assert(iprototype.queryById(slot.prototype))

        local v = {}
        v.id = typeobject_item.id
        v.name = typeobject_item.name
        v.icon = typeobject_item.item_icon
        v.count = slot.amount
        v.order = typeobject_item.item_order or 0

        local category = assert(typeobject_item.item_category, ("`%s` item_category is nil"):format(typeobject_item.name))
        t[category] = t[category] or {}
        t[category][#t[category]+1] = v
    end

    for _, items in pairs(t) do
        table.sort(items, function (a, b)
            return a.order < b.order
        end)
    end

    local backpack = {}
    for _, category in ipairs(ITEM_CATEGORY) do
        if t[category] then
            backpack[#backpack+1] = {category = category, items = t[category]}
        end
    end
    return backpack
end

local function set_item_value(datamodel, category_idx, item_idx, key, value)
    if category_idx == 0 and item_idx == 0 then
        return
    end
    assert(datamodel.backpack[category_idx])
    assert(datamodel.backpack[category_idx].items[item_idx])
    datamodel.backpack[category_idx].items[item_idx][key] = value
end

---------------
local M = {}

function M.create()
    return {
        category_idx = 0,
        item_idx = 0,
        item_name = "",
        item_desc = "",
        item_ingredients = {},
        item_assembling = {},
        backpack = get_backpack(),
    }
end

function M.update(datamodel)
    for _, _, _, category_idx, item_idx in click_item_mb:unpack() do
        if datamodel.category_idx == category_idx and datamodel.item_idx == item_idx then
            set_item_value(datamodel, category_idx, item_idx, "selected", false)
            datamodel.category_idx = 0
            datamodel.item_idx = 0 
            datamodel.item_name = ""
            datamodel.item_desc = ""
            datamodel.item_icon = ""
            datamodel.item_ingredients = {}
            datamodel.item_assembling = {}
        else
            set_item_value(datamodel, datamodel.category_idx, datamodel.item_idx, "selected", false)
            set_item_value(datamodel, category_idx, item_idx, "selected", true)
            datamodel.category_idx = category_idx
            datamodel.item_idx = item_idx

            local item_name = datamodel.backpack[category_idx].items[item_idx].name
            local typeobject = iprototype.queryByName(item_name)
            datamodel.item_name = iprototype.display_name(typeobject)
            datamodel.item_desc = typeobject.item_description or ""
            datamodel.item_icon = typeobject.item_icon

            datamodel.item_ingredients = {}
            for _, v in pairs(iprototype_cache.get("item_ingredients").item_ingredients[item_name] or {}) do
                local typeobject = assert(iprototype.queryById(v.id))
                local t = {
                    name = iprototype.display_name(typeobject),
                    icon = typeobject.item_icon,
                    count = v.count,
                }
                datamodel.item_ingredients[#datamodel.item_ingredients+1] = t
            end

            datamodel.item_assembling = {}
            for _, name in pairs(iprototype_cache.get("item_ingredients").item_assembling[item_name] or {}) do
                local typeobject = assert(iprototype.queryByName(name))
                local t = {
                    icon = typeobject.icon,
                    name = iprototype.display_name(typeobject),
                }
                datamodel.item_assembling[#datamodel.item_assembling+1] = t
            end
        end
    end

    for _ in close_mb:unpack() do
        iui.close("/pkg/vaststars.resources/ui/backpack.rml")
    end
end

function M.update_backpack(datamodel)
    datamodel.backpack = get_backpack()
end

return M