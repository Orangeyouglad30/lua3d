local Vector3d = require("math/vector3d")
local Matrix = require("math/matrix")
local Transform = require("engine/transform")
local gl = require("moongl")

local Object3d = {}
Object3d.__index = Object3d

--Constructors

function Object3d.new(mesh,material)
    local self = setmetatable({},Object3d)

    self.position = Vector3d.Zero()
    self.rotation = Vector3d.Zero()
    self.scale = Vector3d.new(1,1,1)
    self.mesh = mesh
    self.material = material

    return self
end

--Methods

function Object3d:set_rotation(x,y,z)
    self.rotation = Vector3d.new(x,y,z)
end

function Object3d:set_position(x,y,z)
    self.position = Vector3d.new(x,y,z)
end

function Object3d:set_scale(x,y,z)
    self.scale = Vector3d.new(x,y,z)
end

function Object3d:set_material(material)
    self.material = material
end

function Object3d:get_model()
    return  Transform.translation(self.position.x,self.position.y,self.position.z) * Transform.rotation_y(self.rotation.y) * Transform.rotation_x(self.rotation.x) * Transform.rotation_z(self.rotation.z) * Transform.scale(self.scale.x,self.scale.y,self.scale.z)
end

function Object3d:draw(mode)
    gl.bind_vertex_array(self.mesh.vao)

    gl.draw_elements(
        mode,
        self.mesh.index_count,
        "uint",
        0
    )

    gl.unbind_vertex_array()
end

return Object3d