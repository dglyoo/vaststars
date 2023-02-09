local type = require "register.type"
local iendpoint = require "interface.endpoint"

local c1 = type "solar_panel"
function c1:ctor(init, pt)
    return {
        solar_panel = true
    }
end

local c2 = type "base"

function c2:ctor(init, pt)
    return {
        base = true,
        manual = {
            recipe = 0,
            speed = 100,
            status = 0,
            progress = 0,
        },
    }
end
