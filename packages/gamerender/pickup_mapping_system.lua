local ecs = ...
local world = ecs.world
local w = world.w

local pickup_mb = world:sub {"pickup"}

local pickup_mapping_sys = ecs.system "pickup_mapping_system"
local ipickup_mapping = ecs.interface "ipickup_mapping"

local id_mapping = {}
local id_entity = {}

function pickup_mapping_sys.after_pickup()
    local mapping_eid
    local params
    for _, eid in pickup_mb:unpack() do
        if id_mapping[eid] then
            mapping_eid = id_mapping[eid].eid
            params = id_mapping[eid].params
            if #params == 0 then
                world:pub {"pickup_mapping", mapping_eid}
            else
                for _, v in ipairs(params) do
                    world:pub {"pickup_mapping", v, mapping_eid}
                end
            end
        end
    end
end

function ipickup_mapping.mapping(eid, mapping_eid, params)
    id_mapping[eid] = {eid = mapping_eid, params = params or {}}
    id_entity[mapping_eid] = id_entity[mapping_eid] or {}
    table.insert(id_entity[mapping_eid], eid)
    print(("ipickup_mapping.mapping %s -> %s"):format(eid, mapping_eid))
end
