local mi = require("moonimage")
local gl = require("moongl")

local Texture = {}
Texture.__index = Texture

function Texture.new(filepath)
    local self = setmetatable({}, Texture)

    local image, width, height = mi.load(filepath, "rgba")

    assert(image, "Failed to load texture: " .. filepath)

    self.handle = gl.new_texture("2d")

    gl.bind_texture("2d", self.handle)

    gl.texture_parameter("2d", "wrap s", "repeat")
    gl.texture_parameter("2d", "wrap t", "repeat")
    gl.texture_parameter("2d", "min filter", "linear")
    gl.texture_parameter("2d", "mag filter", "linear")

    gl.texture_image(
        "2d",
        0,
        "rgba",
        "rgba",
        "ubyte",
        image,
        width,
        height
    )

    gl.generate_mipmap("2d")
    gl.unbind_texture("2d")

    self.filepath = filepath
    self.width = width
    self.height = height

    return self
end

function Texture:destroy()
    if self.destroyed then return end

    gl.delete_textures(self.handle)

    self.destroyed = true
end

function Texture:bind(texture_unit)
    gl.active_texture(texture_unit)
    gl.bind_texture("2d", self.handle)
end

function Texture.__tostring(self)
    return "Texture <"..self.filepath..">"
end

return Texture