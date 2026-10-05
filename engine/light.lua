local Vector3d = require("math/vector3d")

local Light = {}
Light.__index = Light
Light.__type = "Light"

function Light.newGlobalLight()
    local self = setmetatable({},Light)

    self._type = "global"
    self.direction = Vector3d.new(0,-1,0):Unit()
    self.intensity = 1
    self.color = Vector3d.new(1,1,1)
    self.ambient_color = Vector3d.new(0.15,0.15,0.15)
    self.constant_attenuation = 1
    self.linear_attenuation = 1
    self.quadratic_attenuation = 1

    return self
end

function Light.newPointLight()
    local self = setmetatable({}, Light)

    self._type = "point"
    self.position = Vector3d.Zero()
    self.intensity = 1
    self.color = Vector3d.new(1, 1, 1)

    self.constant_attenuation = 1
    self.linear_attenuation = 1
    self.quadratic_attenuation = 1

    return self
end

function Light:set_direction(newDirection)
    if not self.direction then return end

    self.direction = newDirection
end

function Light:set_intensity(newIntensity)
    self.intensity = newIntensity
end

function Light:set_color(newColor)
    self.color = newColor
end

function Light:set_ambient_color(newColor)
    if not self.set_ambient_color then return end

    self.ambient_color = newColor
end

function Light:set_position(newPosition)
    if not self.position then return end

    self.position = newPosition
end

return Light