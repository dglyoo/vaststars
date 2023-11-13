local guide = require "guide"
local mountain = require "mountain"

local entities = { {
  amount = 20,
  dir = "N",
  prototype_name = "指挥中心",
  x = 156,
  y = 76
}, {
  dir = "N",
  prototype_name = "风力发电机I",
  x = 182,
  y = 11
}, {
  dir = "N",
  prototype_name = "风力发电机I",
  x = 185,
  y = 11
}, {
  dir = "N",
  prototype_name = "风力发电机I",
  x = 182,
  y = 14
}, {
  dir = "N",
  prototype_name = "风力发电机I",
  x = 185,
  y = 14
}, {
  dir = "N",
  prototype_name = "组装机I",
  recipe = "地质科技包1",
  x = 123,
  y = 83
}, {
  dir = "N",
  prototype_name = "组装机I",
  recipe = "机械科技包1",
  x = 123,
  y = 86
}, {
  dir = "N",
  fluid_name = {
    input = { "润滑油" },
    output = {}
  },
  prototype_name = "组装机I",
  recipe = "电子科技包1",
  x = 123,
  y = 90
}, {
  dir = "N",
  prototype_name = "组装机I",
  recipe = "物理科技包1",
  x = 123,
  y = 93
}, {
  dir = "N",
  items = { { "机械科技包", 26 }, { "化学科技包", 26 }, { "物理科技包", 26 }, { "地质科技包", 26 } },
  prototype_name = "仓库I",
  x = 127,
  y = 89
}, {
  dir = "N",
  prototype_name = "无人机平台I",
  x = 127,
  y = 91
}, {
  dir = "N",
  prototype_name = "无人机平台I",
  x = 127,
  y = 87
}, {
  dir = "N",
  prototype_name = "科研中心I",
  x = 129,
  y = 88
}, {
  dir = "N",
  items = {},
  prototype_name = "仓库I",
  x = 142,
  y = 60
}, {
  dir = "N",
  prototype_name = "采矿机I",
  recipe = "碎石挖掘",
  x = 115,
  y = 129
}, {
  dir = "N",
  items = { { "碎石", 60 }, { "碎石", 60 } },
  prototype_name = "仓库I",
  x = 117,
  y = 132
}, {
  dir = "N",
  prototype_name = "无人机平台I",
  x = 116,
  y = 132
}, {
  dir = "N",
  prototype_name = "采矿机I",
  recipe = "铝矿挖掘",
  x = 130,
  y = 129
}, {
  dir = "N",
  items = { { "铝矿石", 60 } },
  prototype_name = "仓库I",
  x = 132,
  y = 132
}, {
  dir = "N",
  prototype_name = "无人机平台I",
  x = 131,
  y = 132
}, {
  dir = "N",
  prototype_name = "采矿机I",
  recipe = "铁矿石挖掘",
  x = 120,
  y = 129
}, {
  dir = "N",
  items = { { "铁矿石", 60 } },
  prototype_name = "仓库I",
  x = 122,
  y = 132
}, {
  dir = "N",
  prototype_name = "无人机平台I",
  x = 121,
  y = 132
} }
local backpack = {}
local road = { {
  dir = "E",
  prototype_name = "砖石公路-U型",
  x = 154,
  y = 82
}, {
  dir = "E",
  prototype_name = "砖石公路-I型",
  x = 156,
  y = 82
}, {
  dir = "E",
  prototype_name = "砖石公路-I型",
  x = 158,
  y = 82
}, {
  dir = "E",
  prototype_name = "砖石公路-I型",
  x = 160,
  y = 82
}, {
  dir = "E",
  prototype_name = "砖石公路-I型",
  x = 162,
  y = 82
}, {
  dir = "E",
  prototype_name = "砖石公路-I型",
  x = 164,
  y = 82
}, {
  dir = "E",
  prototype_name = "砖石公路-I型",
  x = 166,
  y = 82
}, {
  dir = "E",
  prototype_name = "砖石公路-I型",
  x = 168,
  y = 82
}, {
  dir = "E",
  prototype_name = "砖石公路-I型",
  x = 170,
  y = 82
}, {
  dir = "E",
  prototype_name = "砖石公路-I型",
  x = 172,
  y = 82
}, {
  dir = "N",
  prototype_name = "砖石公路-T型",
  x = 174,
  y = 82
}, {
  dir = "N",
  prototype_name = "砖石公路-I型",
  x = 174,
  y = 84
}, {
  dir = "N",
  prototype_name = "砖石公路-I型",
  x = 174,
  y = 86
}, {
  dir = "N",
  prototype_name = "砖石公路-I型",
  x = 174,
  y = 88
}, {
  dir = "N",
  prototype_name = "砖石公路-I型",
  x = 174,
  y = 90
}, {
  dir = "N",
  prototype_name = "砖石公路-I型",
  x = 174,
  y = 92
}, {
  dir = "N",
  prototype_name = "砖石公路-I型",
  x = 174,
  y = 94
}, {
  dir = "N",
  prototype_name = "砖石公路-I型",
  x = 174,
  y = 96
}, {
  dir = "N",
  prototype_name = "砖石公路-I型",
  x = 174,
  y = 98
}, {
  dir = "N",
  prototype_name = "砖石公路-I型",
  x = 174,
  y = 100
}, {
  dir = "N",
  prototype_name = "砖石公路-U型",
  x = 174,
  y = 102
}, {
  dir = "E",
  prototype_name = "砖石公路-I型",
  x = 176,
  y = 82
}, {
  dir = "E",
  prototype_name = "砖石公路-I型",
  x = 178,
  y = 82
}, {
  dir = "E",
  prototype_name = "砖石公路-I型",
  x = 180,
  y = 82
}, {
  dir = "W",
  prototype_name = "砖石公路-U型",
  x = 182,
  y = 82
} }
local mineral = {
["115,129"] = "碎石",
["120,129"] = "铁矿石",
["125,129"] = "地热气",
["130,129"] = "铝矿石",
["135,129"] = "砂岩"
}
return {
  name = "游戏教程",
  entities = entities,
  road = road,
  mineral = mineral,
  mountain = mountain,
  order = 2,
  guide = guide,
  start_tech = "润滑",
  init_ui = {
    "/pkg/vaststars.resources/ui/construct.rml",
    "/pkg/vaststars.resources/ui/message_pop.rml"
  },
  init_instances = {
  },
  debugger = {
    skip_guide = true,
    recipe_unlocked = true,
    item_unlocked = true,
    infinite_item = true,
  },
  camera = "/pkg/vaststars.resources/camera_default.prefab",
}