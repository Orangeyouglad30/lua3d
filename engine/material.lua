local Vector3d = require("math/vector3d")
local gl = require("moongl")

local Material = {}
Material.__index = Material

function Material.new(texture, shininess, specular_strength,diffuseColor,ambientColor,specularColor)
    local self = setmetatable({}, Material)

    self.texture = texture
    self.shininess = shininess or 16.0
    self.specular_strength = specular_strength or 1.0
    self.diffuseColor = diffuseColor or Vector3d.One()
    self.ambientColor = ambientColor or Vector3d.One()
    self.specularColor = specularColor or Vector3d.One()

    return self
end

function Material.fromMTL(info)
    local self = setmetatable({}, Material)

    self.texture = info.diffuseTexture or nil
    self.shininess = info.shininess or 1.0
    self.specular_strength = info.specularStrength or 1.0
    self.diffuseColor = info.diffuseColor or Vector3d.One()
    self.ambientColor = info.ambientColor or Vector3d.One()
    self.specularColor = info.specularColor or Vector3d.One()

    return self
end

function Material:apply(shader)
    if self.texture then
        self.texture:bind(0)
        shader:set_int("hasDiffuseTexture", 1)
    else
        gl.active_texture(0)
        gl.bind_texture("2d", 0)

        shader:set_int("hasDiffuseTexture", 0)
    end

    shader:set_int("diffuseTexture", 0)
    shader:set_float("shininess", self.shininess)
    shader:set_float("specularStrength", self.specular_strength)
    shader:set_vector3("diffuseColor", self.diffuseColor)
    shader:set_vector3("specularColor", self.specularColor)
    shader:set_vector3("ambientColor", self.ambientColor)
end

return Material