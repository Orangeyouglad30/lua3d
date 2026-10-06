local Vector3d = require("math/vector3d")
local Line = require("engine/line")
local Billboard = require("engine/billboard")
local Texture = require("engine/texture")

local bulbTexture = Texture.new("assets/textures/lightbulb.png")

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

    self.billboard = Billboard.new(bulbTexture,self.position,1,false)

    return self
end

function Light.newSpotLight()
    local self = setmetatable({}, Light)

    self._type = "spot"
    self.position = Vector3d.Zero()
    self.direction = Vector3d.new(1,0,0)
    self.intensity = 1
    self.color = Vector3d.new(1, 1, 1)
    self.maxAngle = math.rad(30)

    self.constant_attenuation = 1
    self.linear_attenuation = 1
    self.quadratic_attenuation = 1

    self.line = Line.new(self.position,self.position+self.direction,Vector3d.Zero(),self.color)
    self.billboard = Billboard.new(bulbTexture,self.position,1,false)

    return self
end

function Light:update_line_and_billboard()
    if self.line then
        self.line:update(self.position,self.position+self.direction,Vector3d.Zero(),self.color)
    end

    if self.billboard then
        self.billboard:update(self.position)
    end
end

function Light:set_direction(newDirection)
    if not self.direction then return end

    self.direction = newDirection:Unit()

    self:update_line_and_billboard()
end

function Light:set_intensity(newIntensity)
    self.intensity = newIntensity
end

function Light:set_color(newColor)
    self.color = newColor

    self:update_line_and_billboard()
end

function Light:set_ambient_color(newColor)
    if not self.set_ambient_color then return end

    self.ambient_color = newColor
end

function Light:set_position(newPosition)
    if not self.position then return end

    self.position = newPosition

    self:update_line_and_billboard()
end

function Light:set_max_angle(newAngle)
    if not self.maxAngle then return end

    self.maxAngle = newAngle
end

return Light