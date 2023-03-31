local entities = {
    {
        prototype_name = "指挥中心",
        dir = "N",
        x = 126,
        y = 120,
    },
    {
        prototype_name = "组装机残骸",
        dir = "N",
        items = {
            {"采矿机设计图",2},
            {"电线杆设计图",4},
            {"熔炼炉设计图",2},
            {"组装机设计图",2},
            {"空气过滤器设计图",4},
            {"水电站设计图",2},
            {"无人机仓库设计图",5},
        },
        x = 107,
        y = 134,
    },
    {
        prototype_name = "抽水泵残骸",
        dir = "S",
        items = {
            {"采矿机设计图",2},
            {"电线杆设计图",4},
            {"无人机仓库设计图",4},
            {"科研中心设计图",1},
            {"组装机设计图",2},
            {"修路站设计图",2},
            {"修管站设计图",2},
            {"送货车站设计图",2},
            {"收货车站设计图",2},
        },
        x = 113,
        y = 120,
    },
    {
        prototype_name = "无人机仓库",
        dir = "N",
        x = 116,
        y = 121,
    },
    {
        prototype_name = "建造中心",
        dir = "N",
        x = 119,
        y = 120,
    },
    {
        prototype_name = "风力发电机I",
        dir = "N",
        x = 122,
        y = 114,
    },
    {
        prototype_name = "排水口残骸",
        dir = "S",
        items = {
            {"运输车框架",4},
            {"太阳能板设计图",6},
            {"蓄电池设计图",15},
	        {"地下水挖掘机设计图",4},
	        {"电解厂设计图",1},
	        {"化工厂设计图",3},
            {"组装机设计图",2},
            {"无人机仓库设计图",4},
        },
        x = 133,
        y = 122,
    },
    {
        prototype_name = "组装机I",
        dir = "N",
        x = 133,
        y = 117,
    },
    {
        prototype_name = "熔炼炉I",
        dir = "N",
        x = 140,
        y = 126,
    },
}

local road = {
}

return {
    entities = entities,
    road = road,
}