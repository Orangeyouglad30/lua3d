local lfs = require("lfs")
local Texture = require("engine/texture")

local Textures = {}
Textures.__index = Textures

function Textures.new(folder_path)
    local self = setmetatable({}, Textures)

    self.folder_path = folder_path
    self.items = {}

    for filename in lfs.dir(folder_path) do
        local lowercase_name = filename:lower()

        if lowercase_name:match("%.png$")
        or lowercase_name:match("%.jpg$")
        or lowercase_name:match("%.jpeg$") then

            local texture_name =
                filename:gsub("%.[^.]+$", "")

            local filepath =
                folder_path .. "/" .. filename

            self.items[texture_name] =
                Texture.new(filepath)
        end
    end

    return self
end

function Textures:get(texture_name)
    return self.items[texture_name]
end

return Textures