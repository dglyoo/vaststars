local ecs, mailbox = ...
local world = ecs.world
local w = world.w
local bgfx          = require "bgfx"
local math3d        = require "math3d"
local iUiRt         = ecs.import.interface "ant.rmlui|iuirt"
local ientity       = ecs.import.interface "ant.render|ientity"
local imaterial     = ecs.import.interface "ant.asset|imaterial"
local ivs		    = ecs.import.interface "ant.scene|ivisible_state"
local global = require "global"
local statistics_mb = mailbox:sub {"statistics"}

local M = {}

local queuename = "statistic_chart_queue"
local canvas_size_w = 0
local canvas_size_h = 0
local chart_type = 0
local chart_eid = {}
local chart_data = {}
local filter_type = "5s"
local chart_color_table = {}
local function hide_chart()
    for _, eid in ipairs(chart_eid) do
        local e <close> = w:entity(eid)
        ivs.set_state(e, queuename, false)
    end
end
local grid = {}
local function create_grid(row, col)
    local lines = {}
    local rowstep = canvas_size_h / row
    for index = 1, row - 1 do
        lines[#lines + 1] = {0, index * rowstep, 0, 0.5}
        lines[#lines + 1] = {canvas_size_w, index * rowstep, 0, 0.5}
    end
    local colstep = canvas_size_w / col
    for index = 1, col - 1 do
        lines[#lines + 1] = {index * colstep, 0, 0, 0.5}
        lines[#lines + 1] = {index * colstep, canvas_size_h, 0, 0.5}
    end
    grid[#grid + 1] = ientity.create_screen_line_list(lines, nil, {u_color = {0.05, 0.05, 0.05, 1.0}, u_canvas_size = {canvas_size_w, canvas_size_h, 0, 0} }, true, "translucent", queuename)
end
function M:create(object_id)
    if #chart_color_table < 1 then
        chart_color_table[#chart_color_table + 1] = {0, 110, 255, 255}
        chart_color_table[#chart_color_table + 1] = {0, 255, 221, 255}
        chart_color_table[#chart_color_table + 1] = {166, 255, 0, 255}
        chart_color_table[#chart_color_table + 1] = {250, 233, 0, 255}
        chart_color_table[#chart_color_table + 1] = {255, 136, 0, 255}
        chart_color_table[#chart_color_table + 1] = {255, 72, 0, 255}
        chart_color_table[#chart_color_table + 1] = {4, 0, 255, 255}
        chart_color_table[#chart_color_table + 1] = {111, 0, 255, 255}
        chart_color_table[#chart_color_table + 1] = {255, 0, 255, 255}
        chart_color_table[#chart_color_table + 1] = {255, 0, 64, 255}
        chart_color_table[#chart_color_table + 1] = {102, 255, 0, 255}
        chart_color_table[#chart_color_table + 1] = {0, 255, 221, 255}
        chart_color_table[#chart_color_table + 1] = {255, 255, 255, 255}
        chart_color_table[#chart_color_table + 1] = {65, 60, 60, 255}
        chart_color_table[#chart_color_table + 1] = {82, 31, 31, 255}
        chart_color_table[#chart_color_table + 1] = {82, 110, 16, 255}
        chart_color_table[#chart_color_table + 1] = {114, 6, 69, 255}
        --
        for _, color in ipairs(chart_color_table) do
            color[1] = color[1] / 255
            color[2] = color[2] / 255
            color[3] = color[3] / 255
            color[4] = color[4] / 255
        end
    end
    chart_data = {}
    filter_type = "5s"
    chart_type = 0
    hide_chart()
    return {
        items = {},
        total = 0,
        label_x = {"5s","4.5s","4.0s","3.5s","3.0s","2.5s","2.0s","1.5s","1.0s","0.5s"},
        label_y = {"8w ","7w ","6w ","5w ","4w ","3w ","2w ","1w "}
    }
end
local interval = 1

local function update_vb(eid, points)
    local vb = {}
    for _, pt in ipairs(points) do
        vb[#vb + 1] = pt[1]
        vb[#vb + 1] = pt[2]
        vb[#vb + 1] = pt[3]
    end
    local e <close> = w:entity(eid, "simplemesh:in")
    local mesh = e.simplemesh
    bgfx.update(mesh.vb.handle, 0, bgfx.memory_buffer("fff", vb));
end

local tick_count = 0
local step = 0
local line_count = 50
local start_x = 0
local curve_state = {}

local function update_chart(group, total)
    local line_list = chart_data[group.cfg.name]
    if not chart_data[group.cfg.name] then
        local lines = {{start_x, 0, 0.5}, {start_x + step, 0, 0.5}}
        for i = 2, line_count do
            local tail = lines[#lines]
            lines[#lines + 1] = {tail[1], tail[2], tail[3]}
            lines[#lines + 1] = {start_x + i * step, 0, 0.5}
        end
        chart_data[group.cfg.name] = lines
        line_list = lines
    end
    local line_idx = 1
    local framecount = #group.frames
    local index = group.tail
    
    local totalframe = total.frames
    -- 7/8 canvas_size_h
    local topheight = canvas_size_h * 0.875
    for count = 1, framecount do
        local frame = group.frames[index]
        line_list[line_idx][2] = (frame.power / totalframe[index].power) * topheight
        if count > 1 and count < framecount then
            line_list[line_idx + 1][2] = line_list[line_idx][2]
            line_idx = line_idx + 1
        end
        line_idx = line_idx + 1
        index = index + 1
        if index > framecount then
            index = 1
        end
    end
    local colorcount = #chart_color_table
    local colorindex = math.floor((group.power / total.power) * colorcount)
    if colorindex < 1 then
        colorindex = 1
    elseif colorindex > colorcount then
        colorindex = colorcount
    end
    local color = chart_color_table[colorindex]
    if group.eid then
        local e <close> = w:entity(group.eid)
        ivs.set_state(e, queuename, curve_state[group.cfg.name])
        imaterial.set_property(e, "u_color", math3d.vector(color))
        update_vb(group.eid, line_list)
    else
        group.eid = ientity.create_screen_line_list(line_list, nil, {u_color = color, u_canvas_size = {canvas_size_w, canvas_size_h, 0, 0} }, true, "translucent", queuename)
        chart_eid[#chart_eid + 1] = group.eid
    end
    return color
end

local function gen_label_y(power)
    -- power is sum of 50 ticks
    -- frame ratio 30
    local persec = 30 / 50
    local total = power * persec
    local unit = "k"
    local divisor = 1000
    if total >= 1000000000 then
        divisor = 1000000000
        unit = "G"
    elseif total >= 1000000 then
        divisor = 1000000
        unit = "M"
    end
    total = total / divisor
    local step = total / 7
    local label = {}
    label[#label + 1] = ""--placehold
    for i = 1, 7 do
        label[#label + 1] = ("%.1f%s"):format(total-step*(i-1), unit)
    end
    return label
end

local item_bc = {
    {250,205,9},
    {128,128,128}
}
local items = {}
local items_ref = {}
local show_count = 0
function M:stage_ui_update(datamodel)
    local gid = iUiRt.get_group_id("statistic_chart")
    if gid and canvas_size_w == 0 then
        local g = ecs.group(gid)
        g:enable "view_visible"
        g:enable "scene_update"
        local qe = w:first(queuename .." render_target:in")
        local rt = qe.render_target
        local vr = rt.view_rect
        canvas_size_w, canvas_size_h = vr.w, vr.h
        step = canvas_size_w / line_count
        create_grid(8, 10)
    end

    for _, _, _, type, value in statistics_mb:unpack() do
        if type == "filter_type" and filter_type ~= value then
            filter_type = value
            local label = {}
            local total_str, postfix = string.match(value,"(%d+)(%a)")
            local total = tonumber(total_str)
            local step = total / 10
            for i = 1, 10 do
                label[#label + 1] = (total-step*(i-1))..postfix
            end
            datamodel.label_x = label
            hide_chart()
        elseif type == "chart_type" then
            local nv = math.floor(value)
            if chart_type ~= nv then
                chart_type = nv
                hide_chart()
            end
        elseif type == "item_click" then
            if not curve_state[value] then
                curve_state[value] = true
                items_ref[value].show = true
                show_count = show_count + 1
            else
                if show_count > 1 then
                    if show_count == #items then
                        -- hide others
                        for name, it in pairs(items_ref) do
                            if name ~= value then
                                curve_state[name] = false
                                it.show = false
                            end
                        end
                        show_count = 1
                    else
                        curve_state[value] = false
                        items_ref[value].show = false
                        show_count = show_count - 1
                    end
                else
                    --click last visible item, show all
                    for name, it in pairs(items_ref) do
                        curve_state[name] = true
                        it.show = true
                    end
                    show_count = #items
                end
            end
            datamodel.items = items
        end
    end

    local function create_items(total)
        local power_group = global.statistic.power_group
        items = {}
        items_ref = {}
        show_count = 0
        for _, group in pairs(power_group) do
            local node = group[filter_type]
            local match = false
            if chart_type == 0 and node.consumer then
                match = true
            elseif chart_type == 1 and not node.consumer then
                match = true
            end
            if match then
                local fc = update_chart(node, total)
                local ic = {math.floor(fc[1] * 255), math.floor(fc[2] * 255), math.floor(fc[3] * 255)}
                local name = node.cfg.name
                if curve_state[name] == nil then
                    curve_state[name] = true
                end
                local show = curve_state[name]
                if show then
                    show_count = show_count + 1
                end
                local item = {name = name, show = show, icon = node.cfg.icon, count = group.count, power = node.power, color = ic, bc = show and item_bc[1] or item_bc[2]}
                items[#items + 1] = item
                items_ref[name] = item
            end
        end
        return items
    end

    interval = interval + 1
    if interval > 5 then
        interval = 1
        if chart_type == 0 or chart_type == 1 then
            local total = (chart_type == 0) and global.statistic.power_consumed[filter_type] or global.statistic.power_generated[filter_type]
            datamodel.total = total.power
            datamodel.label_y = gen_label_y(total.power)
            local newitems = create_items(total)
            table.sort(newitems, function (a, b) return a.power > b.power end)
            datamodel.items = newitems
        end
    end
end
return M