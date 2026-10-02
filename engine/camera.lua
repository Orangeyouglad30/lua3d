local Transform = require("engine/transform")

local Camera = {}
Camera.__index = Camera

function Camera.new(field_of_view,aspect_ratio,near_distance,far_distance)
    local self = setmetatable({},Camera)

    self.field_of_view = field_of_view
    self.aspect_ratio = aspect_ratio
    self.near_distance = near_distance
    self.far_distance = far_distance
    self.position = {
        x = 0,
        y = 0,
        z = 0,
    }
    self.rotation = {
        x = 0,
        y = 0,
        z = 0,
    }

    return self
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
    self.position.x = x
    self.position.y = y
    self.position.z = z
end

function Camera:move(x,y,z)
    self.position.x = self.position.x + x
    self.position.y = self.position.y + y
    self.position.z = self.position.z + z
end

function Camera:rotate(x, y, z)
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