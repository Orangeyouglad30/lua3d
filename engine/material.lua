local Material = {}
Material.__index = Material

function Material.new(texture, shininess, specular_strength)
    local self = setmetatable({}, Material)

    self.texture = texture
    self.shininess = shininess or 16.0
    self.specular_strength = specular_strength or 1.0

    return self
end

function Material:apply(shader)
    self.texture:bind(0)

    shader:set_int("diffuseTexture", 0)
    shader:set_float("shininess", self.shininess)
    shader:set_float(
        "specularStrength",
        self.specular_strength
    )
end

return Material