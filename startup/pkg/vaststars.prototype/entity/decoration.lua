local gameplay = import_package "vaststars.gameplay"
local prototype = gameplay.register.prototype

prototype "组装机残骸" {
    model = "prefabs/broken-assembling-3X3.prefab",
    icon = "textures/building_pic/small_pic_assemble.texture",
    background = "textures/build_background/pic_mars_assembling_machine.texture",
    construct_detector = {"exclusive"},
    type = {"entity", "chest"},
    chest_type = "red",
    crossing = {
        connections = {
            {type="chest", position={4,2,"E"}, roadside = true},
        },
    },
    group = {"物流" , "默认"},
    area = "5x5",
    slots = 8,
}

prototype "排水口残骸" {
    model = "prefabs/broken-outfall-2X2.prefab",
    icon = "textures/building_pic/small_pic_outfall.texture",
    background = "textures/build_background/pic_mars_outfall.texture",
    construct_detector = {"exclusive"},
    type = {"entity", "chest"},
    chest_type = "red",
    crossing = {
        connections = {
            {type="chest", position={1,0,"N"}, roadside = true},
        },
    },
    group = {"物流" , "默认"},
    area = "3x3",
    slots = 5,
}

prototype "抽水泵残骸" {
    model = "prefabs/broken-pump-2X2.prefab",
    icon = "textures/building_pic/small_pic_offshore.texture",
    background = "textures/building_pic/pic_pumpjack.texture",
    construct_detector = {"exclusive"},
    type = {"entity", "chest"},
    chest_type = "red",
    crossing = {
        connections = {
            {type="chest", position={1,2,"S"}, roadside = true},
        },
    },
    group = {"物流" , "默认"},
    area = "3x3",
    slots = 11,
}

prototype "铁矿" {
    model = "prefabs/terrain/mine_iron.prefab",
    icon = "textures/construct/broken-pump.texture",
    background = "textures/build_background/pic_pumpjack.texture",
    construct_detector = {"exclusive"},
    type = {"entity"},
    area = "4x4",
}

prototype "石矿" {
    model = "prefabs/terrain/mine_Stone.prefab",
    icon = "textures/construct/broken-pump.texture",
    background = "textures/build_background/pic_pumpjack.texture",
    construct_detector = {"exclusive"},
    type = {"entity"},
    area = "4x4",
}