local Transform = require("engine/transform")
local Vector3d = require("math/vector3d")

local Camera = {}
Camera.__index = Camera

function Camera.new(field_of_view,aspect_ratio,near_distance,far_distance)
    local self = setmetatable({},Camera)

    self.field_of_view = field_of_view
    self.aspect_ratio = aspect_ratio
    self.near_distance = near_distance
    self.far_distance = far_distance
    self.position = Vector3d.Zero()
    self.rotation = Vector3d.Zero()

    return self
end

function Camera:get_basis()
    local yaw,pitch = self.rotation.y,self.rotation.x

    local forward = Vector3d.new(
        -math.sin(yaw) * math.cos(pitch),
        math.sin(pitch),
        -math.cos(yaw) * math.cos(pitch)
    ):Unit()

    local world_up = Vector3d.new(0,1,0)
    local right = forward:Cross(world_up):Unit()
    local up = right:Cross(forward):Unit()

    return right,up,forward
end

function Camera:get_view()
    return Transform.rotation_z(-self.rotation.z)*Transform.rotation_x(-self.rotation.x)*Transform.rotation_y(-self.rotation.y)*Transform.translation(-self.position.x,-self.position.y,-self.position.z)
end

function Camera:get_projection()
    return Transform.perspective(self.field_of_view,self.aspect_ratio,self.near_distance,self.far_distance)
end

function Camera:set_aspect_ratio(new_aspect_ratio)
    self.aspect_ratio = new_aspect_ratio
end

function Camera:set_position(x,y,z)
    if type(x) == "table" and x.__type and x.__type == "Vector3d" then self.position = x return end

    self.position.x = x
    self.position.y = y
    self.position.z = z
end

function Camera:set_rotation(x,y,z)
    if type(x) == "table" and x.__type and x.__type == "Vector3d" then self.rotation = x return end

    self.rotation.x = x
    self.rotation.y = y
    self.rotation.z = z
end

function Camera:set_direction(x,y,z)
    if type(x) == "table" and x.__type and x.__type == "Vector3d" then self.rotation = x:getRotation() return end

    self.rotation = Vector3d.new(x,y,z):getRotation()
end

function Camera:move(x,y,z)
    if type(x) == "table" and x.__type and x.__type == "Vector3d" then self.position = self.position + x return end

    self.position.x = self.position.x + x
    self.position.y = self.position.y + y
    self.position.z = self.position.z + z
end

function Camera:rotate(x, y, z)
    if type(x) == "table" and x.__type and x.__type == "Vector3d" then self.rotation = self.rotation + x return end

    self.rotation.x = self.rotation.x + x
    self.rotation.y = self.rotation.y + y
    self.rotation.z = self.rotation.z + z
end

function Camera:gimble(mouse_delta_x, mouse_delta_y, sensitivity)
    sensitivity = sensitivity or 0.002

    self.rotation.y =
        self.rotation.y - mouse_delta_x * sensitivity

    self.rotation.x =
        self.rotation.x - mouse_delta_y * sensitivity

    local pitch_limit = math.pi / 2 - 0.01

    self.rotation.x =
        math.max(
            -pitch_limit,
            math.min(pitch_limit, self.rotation.x)
        )
end

return Camera