local Transform = require("engine/transform")
local Vector3d = require("math/vector3d")
local CFrame = require("math/cframe")

local Camera = {}
Camera.__index = Camera

function Camera.new(field_of_view,aspect_ratio,near_distance,far_distance)
    local self = setmetatable({},Camera)

    self.field_of_view = field_of_view
    self.aspect_ratio = aspect_ratio
    self.near_distance = near_distance
    self.far_distance = far_distance
    self.CFrame = CFrame.new()
    --self.position = Vector3d.Zero()
    --self.rotation = Vector3d.Zero()

    return self
end

function Camera:get_basis()
    return self.CFrame:get_basis()
end

function Camera:get_view()
    local rotation = self.CFrame.rotation
    local position = self.CFrame.position

    return Transform.rotation_z(-rotation.z)*Transform.rotation_x(-rotation.x)*Transform.rotation_y(-rotation.y)*Transform.translation(-position.x,-position.y,-position.z)
end

function Camera:get_projection()
    return Transform.perspective(self.field_of_view,self.aspect_ratio,self.near_distance,self.far_distance)
end

function Camera:set_aspect_ratio(new_aspect_ratio)
    self.aspect_ratio = new_aspect_ratio
end

function Camera:set_position(x,y,z)
    if type(x) == "table" and x.__type and x.__type == "Vector3d" then self.CFrame.position = x return end

    local newPosition = Vector3d.new(x,y,z)

    self.CFrame.position = newPosition
end

function Camera:set_rotation(x,y,z)
    if type(x) == "table" and x.__type and x.__type == "Vector3d" then self.CFrame.rotation = x return end

    local newRotation = Vector3d.new(x,y,z)

    self.CFrame.rotation = newRotation
end

function Camera:set_direction(x,y,z)
    if type(x) == "table" and x.__type and x.__type == "Vector3d" then self.CFrame.rotation = x:getRotation() return end

    self.CFrame.rotation = Vector3d.new(x,y,z):getRotation()
end

function Camera:move(x,y,z)
    if type(x) == "table" and x.__type and x.__type == "Vector3d" then self.CFrame.position = self.CFrame.position + x return end

    local newPosition = Vector3d.new(x,y,z)
    self.CFrame.position = self.CFrame.position + newPosition
end

function Camera:rotate(x, y, z)
    if type(x) == "table" and x.__type and x.__type == "Vector3d" then self.CFrame.rotation = self.CFrame.rotation + x return end

    local newRotation = Vector3d.new(x,y,z)
    self.CFrame.rotation = self.CFrame.rotation + newRotation
end

function Camera:gimble(mouse_delta_x, mouse_delta_y, sensitivity)
    sensitivity = sensitivity or 0.002

    self.CFrame.rotation.y =
        self.CFrame.rotation.y - mouse_delta_x * sensitivity

    self.CFrame.rotation.x =
        self.CFrame.rotation.x - mouse_delta_y * sensitivity

    local pitch_limit = math.pi / 2 - 0.01

    self.CFrame.rotation.x =
        math.max(
            -pitch_limit,
            math.min(pitch_limit, self.CFrame.rotation.x)
        )
end

return Camera