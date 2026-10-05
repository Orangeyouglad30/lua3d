local Vector3d = require("math/vector3d")
local Matrix = require("math/matrix")
local Transform = require("engine/transform")
local Materials = require("engine/materials")
local gl = require("moongl")

local Object3d = {}
Object3d.__index = Object3d

--Constructors

function Object3d.new(mesh,material)
    material = material or Materials.Crate

    local self = setmetatable({},Object3d)

    self.position = Vector3d.Zero()
    self.rotation = Vector3d.Zero()
    self.scale = Vector3d.new(1,1,1)
    self.mesh = mesh
    self.material = material
    self.min_bounds = mesh.min_bounds
    self.max_bounds = mesh.max_bounds

    return self
end

--Methods

function Object3d:destroy()
    if self.destroyed then return end

    self.mesh:destroy()

    self.destroyed = true
end

function Object3d:set_rotation(x,y,z)
    self.rotation = Vector3d.new(x,y,z)
end

function Object3d:set_position(x,y,z)
    if type(x)=="table" then self.position = x return end --if just a vector3d is passed through then set that vector equal to position

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

function Object3d:draw(shader, mode)
    shader:set_matrix(
        "model",
        self:get_model()
    )

    local meshes = 1

    if self.mesh.parts then
        meshes = self.mesh:draw(shader, mode)
    else
        self.material:apply(shader)
        self.mesh:draw(shader, mode)
    end

    return meshes
end

return Object3d