local fs = require "bee.filesystem"
local serialize = import_package "ant.serialize"

local function parseArguments(allargs)
    local args = allargs[1]
    local result = {}
    for _, arg in ipairs(args) do
        local key, value = arg:match("--([%w_]+)=(.*)")
        if key and value then
            result[key] = value
        end
    end
    return result
end

local params = parseArguments({...})
assert(params.atlas_dir, "need atlas_dir")
assert(params.parent_dir, "need parent_dir")
assert(params.setting_path, "need setting_path")

local function findAllFilesRecursively(directory, extension, files)
    for p in fs.pairs(directory) do
        if fs.is_directory(p) then
            findAllFilesRecursively(p, extension, files)
        else
            if p:extension() == extension then
                files[#files + 1] = p
            end
        end
    end
end

local function InjectAtlas(atlas, parentDir, settingPath)
    local tt = {}
    for _, at in ipairs(atlas) do
        local atlasRelativePath = "/" .. fs.relative(fs.path(at), parentDir):string()
        local textureRelativePath = fs.path(atlasRelativePath):replace_extension "texture":string()
        tt[textureRelativePath] = atlasRelativePath
    end
    local file <close> = assert(io.open(settingPath, 'wb'))
    file:write(serialize.stringify(tt))
end

local atlas = {}

findAllFilesRecursively(params.atlas_dir, ".atlas", atlas)

InjectAtlas(atlas, params.parent_dir, params.setting_path)

print("Done")