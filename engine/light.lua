local Vector3d = require("math/vector3d")

local Light = {}
Light.__index = Light

function Light.new()
    local self = setmetatable({},Light)

    self.direction = Vector3d.new(0,-1,0):Unit()
    self.intensity = 1
    self.color = Vector3d.new(1,1,1)
    self.ambient_color = Vector3d.new(0.15,0.15,0.15)

    return self
end

function Light.newPointLight()
    local self = setmetatable({},Light)

    self.position = Vector3d.Zero()
    self.intensity = 1
    self.color = Vector3d.new(1,1,1)
    self.ambient_color = Vector3d.new(0.15,0.15,0.15)

    return self
end

function Light:set_direction(newDirection)
    self.direction = newDirection
end

function Light:set_intensity(newIntensity)
    self.intensity = newIntensity
end

function Light:set_color(newColor)
    self.color = newColor
end

function Light:set_ambient_color(newColor)
    self.ambient_color = newColor
end

return Light