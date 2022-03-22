local ecs = ...
local world = ecs.world
local w = world.w

local igame_object = ecs.import.interface "vaststars.gamerender|igame_object"
local iconstruct_button = ecs.import.interface "vaststars.gamerender|iconstruct_button"
local construct_sys = ecs.system "construct_system"
local prototype = ecs.require "prototype"
local gameplay = ecs.require "gameplay"
local engine = ecs.require "engine"
local pipe = ecs.require "pipe"
local dir = require "dir"
local dir_rotate = dir.rotate

local ui_construct_begin_mb = world:sub {"ui", "construct", "construct_begin"}       -- 建造模式
local ui_construct_entity_mb = world:sub {"ui", "construct", "construct_entity"}
local ui_construct_complete_mb = world:sub {"ui", "construct", "construct_complete"} -- 开始施工
local ui_fluidbox_update_mb = world:sub {"ui", "construct", "fluidbox_update"}
local drapdrop_entity_mb = world:sub {"drapdrop_entity"}
local construct_button_mb = world:sub {"construct_button"}
local pickup_mapping_mb = world:sub {"pickup_mapping"}

local CONSTRUCT_RED_BASIC_COLOR <const> = {50.0, 0.0, 0.0, 0.8}
local CONSTRUCT_GREEN_BASIC_COLOR <const> = {0.0, 50.0, 0.0, 0.8}
local CONSTRUCT_WHITE_BASIC_COLOR <const> = {50.0, 50.0, 50.0, 0.8}
local DISMANTLE_YELLOW_BASIC_COLOR <const> = {50.0, 50.0, 0.0, 0.8}

local cur_mode = ""
local construct_queue = {}

local function check_construct_detector(prototype_name, x, y, dir)
    local construct_detector = prototype.get_construct_detector(prototype_name)
    if not construct_detector then
        return true
    end

    local area = prototype.get_area(prototype_name)
    if not area then
        return false
    end

    return true
end

local function deepcopy(t)
    local r = {}
    for k, v in pairs(t) do
        if type(v) == "table" then
            r[k] = deepcopy(v)
        else
            r[k] = v
        end
    end
    return r
end

local function confirm_construct(game_object)
    local gameplay_entity = game_object.gameplay_entity
    local construct_detector = prototype.get_construct_detector(gameplay_entity.prototype_name)
    if construct_detector then
        if not check_construct_detector(gameplay_entity.prototype_name, gameplay_entity.x, gameplay_entity.y, gameplay_entity.dir) then
            print("can not construct") -- todo error tips
            return
        end
    end

    igame_object.set_state(game_object, gameplay_entity.prototype_name, "translucent", CONSTRUCT_WHITE_BASIC_COLOR)
    game_object.drapdrop = false
    game_object.construct_pickup = false
    iconstruct_button.hide()

    construct_queue[#construct_queue + 1] = {eid = game_object.id, entity = deepcopy(game_object.gameplay_entity)}
end

-- 通过 game_object 获取信息, 只读
local function get_object(game_object)
    local obj = {}
    for k, v in pairs(game_object.gameplay_entity) do
        obj[k] = v
    end

    if game_object.gameplay_id ~= -1 then
        local e = gameplay.entity(game_object.gameplay_id)
        for k, v in pairs(e) do
            obj[k] = obj[k] or v
        end
    end
    return obj
end

-- 获取指定位置的 game_object 信息, 只读
local function get_entity(x, y)
    for _, game_object in engine.world_select "gameplay_id" do
        -- entity 是否已经删除?
        if not igame_object.get_prefab_object(game_object.id) then
            goto continue
        end

        local obj = get_object(game_object)
        if obj.x == x and obj.y == y then
            return obj
        end
        ::continue::
    end
end

-- 获取指定位置的 game_object, 并可以对其进行操作
local function get_game_object(x, y)
    for _, game_object in engine.world_select "gameplay_id" do
        if not igame_object.get_prefab_object(game_object.id) then
            goto continue
        end

        local obj = get_object(game_object)
        if obj.x == x and obj.y == y then
            return game_object
        end
        ::continue::
    end
end

local adjust_neighbor_pipe ; do
    local vector2 = ecs.require "vector2"
    local neighbor <const> = {
        vector2.DOWN,
        vector2.UP,
        vector2.LEFT,
        vector2.RIGHT,
    }

    local function packCoord(x, y)
        assert(x & 0xFF == x)
        assert(y & 0xFF == y)
        return x | (y << 8)
    end

    local function unpackCoord(v)
        return v & 0xFF, v >> 8
    end

    function adjust_neighbor_pipe(...)
        local t = {}
        local a = {...}
        local x, y

        for _, n in ipairs(neighbor) do
            for _, v in ipairs(a) do
                x = v[1] + n[1]
                y = v[2] + n[2]
                t[packCoord(x, y)] = true
            end
        end

        for c in pairs(t) do
            x, y = unpackCoord(c)
            local game_object = get_game_object(x, y)
            if not game_object then
                goto continue
            end

            local object = get_object(game_object)
            if not prototype.is_pipe(object.prototype_name) then
                goto continue
            end

            local prototype_name, dir = pipe.adjust(x, y, get_entity)
            if prototype_name then
                game_object.gameplay_entity.prototype_name = prototype_name
                game_object.gameplay_entity.dir = dir

                igame_object.set_prototype_name(game_object, prototype_name)
                igame_object.set_dir(game_object, dir)

                construct_queue[#construct_queue + 1] = {eid = game_object.id, entity = deepcopy(game_object.gameplay_entity)}
            end
            ::continue::
        end
    end
end

local function drapdrop_entity(game_object_eid, mouse_x, mouse_y)
    local game_object = world:entity(game_object_eid)
    if not game_object then
        log.error(("can not found game_object `%s`"):format(game_object_eid))
        return
    end
    assert(game_object.construct_pickup == true)

    local gameplay_entity = game_object.gameplay_entity
    local x, y, position = prototype.get_coord(gameplay_entity.prototype_name, mouse_x, mouse_y)
    if x and y and gameplay_entity.x == x and gameplay_entity.y == y then
        return
    end

    igame_object.set_position(game_object.id, position)

    local sx, sy = gameplay_entity.x, gameplay_entity.y
    gameplay_entity.x, gameplay_entity.y = x, y

    -- 针对水管的特殊处理
    if prototype.is_pipe(gameplay_entity.prototype_name) then
        adjust_neighbor_pipe({sx, sy}, {x, y})

        local prototype_name, dir = pipe.adjust(gameplay_entity.x, gameplay_entity.y, get_entity)
        if prototype_name and (prototype_name ~= gameplay_entity.prototype_name or dir ~= gameplay_entity.dir )then
            gameplay_entity.prototype_name = prototype_name
            igame_object.set_prototype_name(game_object, prototype_name)

            gameplay_entity.dir = dir
            igame_object.set_dir(game_object, dir)
        end
    end

    local basecolor_factor
    if not check_construct_detector(gameplay_entity.prototype_name, gameplay_entity.x, gameplay_entity.y, gameplay_entity.dir) then
        basecolor_factor = CONSTRUCT_RED_BASIC_COLOR
    else
        basecolor_factor = CONSTRUCT_GREEN_BASIC_COLOR
    end
    igame_object.set_state(game_object, gameplay_entity.prototype_name, "translucent", basecolor_factor)

    iconstruct_button.show(gameplay_entity.prototype_name, gameplay_entity.x, gameplay_entity.y)
end

local construct_button_events = {}
construct_button_events.confirm = function()
    local game_object = engine.world_singleton("construct_pickup", "construct_pickup")
    if not game_object then
        log.error("can not found game_object")
        return
    end
    if prototype.is_fluidbox(game_object.gameplay_entity.prototype_name) then
        if not game_object.gameplay_entity.fluid[1] then
            world:pub {"ui_message", "show_set_fluidbox", true}
        else
            confirm_construct(game_object)
        end
    else
        confirm_construct(game_object)
    end
end

construct_button_events.cancel = function()
    local game_object = engine.world_singleton("construct_pickup", "construct_pickup")
    if not game_object then
        return
    end

    local adjust = {}
    local game_object = engine.world_singleton("construct_pickup", "construct_pickup")
    if game_object then
        local obj = get_object(game_object)
        adjust[#adjust+1] = {obj.x, obj.y}

        igame_object.remove(game_object.id)
    end
    iconstruct_button.hide()

    -- 还原未施工的水管形状
    for _, v in ipairs(adjust) do
        adjust_neighbor_pipe(v)
    end
end

construct_button_events.rotate = function()
    local game_object = engine.world_singleton("construct_pickup", "construct_pickup")
    if not game_object then
        log.error("can not found game_object")
        return
    end
    local dir = dir_rotate(game_object.gameplay_entity.dir, -1) -- 逆时针方向旋转一次
    game_object.gameplay_entity.dir = dir
    igame_object.set_dir(game_object, dir)
end

function construct_sys:camera_usage()
    for _, _, _, prototype_name in ui_construct_entity_mb:unpack() do
        construct_button_events.cancel()
        igame_object.create(prototype_name, {
            on_ready = function(game_object)
                local gameplay_entity = game_object.gameplay_entity
                iconstruct_button.show(gameplay_entity.prototype_name, gameplay_entity.x, gameplay_entity.y)
            end
        })
        if prototype.is_fluidbox(prototype_name) then
            world:pub {"ui_message", "show_set_fluidbox", true}
        end
    end

    for _, game_object_eid, mouse_x, mouse_y in drapdrop_entity_mb:unpack() do
        drapdrop_entity(game_object_eid, mouse_x, mouse_y)
    end
end

function construct_sys:data_changed()
    for _ in ui_construct_begin_mb:unpack() do
        cur_mode = "construct"
        engine.set_camera("camera_construct.prefab")
    end

    for _, button in construct_button_mb:unpack() do
        local func = construct_button_events[button]
        if func then
            func()
        end
    end

    for _ in ui_construct_complete_mb:unpack() do
        cur_mode = ""
        engine.set_camera("camera_default.prefab")
        construct_button_events.cancel()

        if #construct_queue > 0 then
            for _, v in ipairs(construct_queue) do
                local eid = v.eid
                local game_object = world:entity(eid)
                if not game_object then
                    goto continue
                end

                local entity = v.entity
                if game_object.gameplay_id == -1 then
                    gameplay.create_entity(entity)
                    game_object.gameplay_id = entity.x | (entity.y << 8)
                end
                local gameplay_entity = gameplay.entity(entity.x | (entity.y << 8))

                igame_object.set_state(game_object, entity.prototype_name, "opaque") --RETODO prototype_name nil
                game_object.gameplay_entity = {}

                ::continue::
            end
            construct_queue = {}
            gameplay.build()
        end
    end

    for _, _, _, fluidname in ui_fluidbox_update_mb:unpack() do
        local game_object = engine.world_singleton("construct_pickup", "construct_pickup")
        if game_object then
            game_object.gameplay_entity.fluid = {fluidname, 0}
        end
    end

    for _, _, eid in pickup_mapping_mb:unpack() do
        if cur_mode ~= "construct" then
            goto continue
        end

        local game_object = engine.world_singleton("construct_pickup", "construct_pickup")
        if game_object then
            goto continue
        end

        game_object = world:entity(eid)
        if game_object and game_object.game_object_state then
            game_object.drapdrop = true
            game_object.construct_pickup = true
            igame_object.set_state(game_object, "translucent", CONSTRUCT_GREEN_BASIC_COLOR)

            local gameplay_entity = game_object.gameplay_entity
            iconstruct_button.show(gameplay_entity.prototype_name, gameplay_entity.x, gameplay_entity.y) --RETODO prototype_name nil
        end
        ::continue::
    end
end
