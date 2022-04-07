local M = {}

function M.packcoord(x, y)
    return x | (y<<8)
end

function M.unpackcoord(coord)
    return coord & 0xFF, coord >> 8
end

function M.unpackarea(area)
    return area >> 8, area & 0xFF
end

local DIRECTION <const> = {
    N = 0,
    E = 1,
    S = 2,
    W = 3,
}

local DIRECTION_REV = {}
for dir, v in pairs(DIRECTION) do
    DIRECTION_REV[v] = dir
end

function M.rotate_dir(dir, rotate_dir)
    return DIRECTION_REV[(DIRECTION[dir] + DIRECTION[rotate_dir]) % 4]
end

function M.rotate_dir_times(dir, times)
    return DIRECTION_REV[(DIRECTION[dir] + times) % 4]
end

local OPPOSITE <const> = {
    N = 'S',
    E = 'W',
    S = 'N',
    W = 'E',
}
function M.opposite_dir(dir)
    return OPPOSITE[dir]
end

function M.dir_tonumber(dir)
    return DIRECTION[dir]
end

function M.rotate_area(area, dir)
    local w, h = M.unpackarea(area)
    if dir == 'N' or dir == 'S' then
        return w, h
    elseif dir == 'E' or dir == 'W' then
        return h, w
    end
end

function M.rotate_fluidbox(position, direction, area)
    local w, h = M.unpackarea(area)
    local x, y = position[1], position[2]
    local dir = M.rotate_dir(position[3], direction)
    w = w - 1
    h = h - 1
    if direction == 'N' then
        return x, y, dir
    elseif direction == 'E' then
        return h - y, x, dir
    elseif direction == 'S' then
        return w - x, h - y, dir
    elseif direction == 'W' then
        return y, w - x, dir
    end
end

return M
