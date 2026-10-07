local Vector3d = require("math/vector3d")
local Matrix = require("math/matrix")
local Transform = require("engine/transform")
local Materials = require("engine/materials")
local gl = require("moongl")

local Object3d = {}
Object3d.__index = Object3d

--Constructors
function Object3d.new(mesh,material)
    material = material or Materials.Ice

    local self = setmetatable({},Object3d)

    self.position = Vector3d.Zero()
    self.rotation = Vector3d.Zero()
    self.scale = Vector3d.One()
    self.mesh = mesh
    self.material = material
    self.min_bounds = mesh.min_bounds
    self.max_bounds = mesh.max_bounds
    self._transform_dirty = true
    self._model_matrix = nil
    self._normal_matrix = nil

    return self
end

--Methods

function Object3d:destroy()
    if self.destroyed then return end

    self.mesh:destroy()

    self.destroyed = true
end

function Object3d:set_rotation(x,y,z)
    self._transform_dirty = true

    if type(x)=="table" then self.rotation = x return end --if just a vector3d is passed through then set that vector equal to position

    self.rotation = Vector3d.new(x,y,z)
end

function Object3d:set_position(x,y,z)
    self._transform_dirty = true

    if type(x)=="table" then self.position = x return end --if just a vector3d is passed through then set that vector equal to position

    self.position = Vector3d.new(x,y,z)
end

function Object3d:set_scale(x,y,z)
    self._transform_dirty = true

    if type(x)=="table" then self.scale = x return end --if just a vector3d is passed through then set that vector equal to position

    self.scale = Vector3d.new(x,y,z)
end

function Object3d:set_material(material)
    self.material = material
end

function Object3d:get_model()
    if self._transform_dirty then
        local newModel = Transform.translation(self.position.x,self.position.y,self.position.z) * Transform.rotation_y(self.rotation.y) * Transform.rotation_x(self.rotation.x) * Transform.rotation_z(self.rotation.z) * Transform.scale(self.scale.x,self.scale.y,self.scale.z)
        self._model_matrix = newModel

        local newNormalMatrix = newModel:normal_matrix()
        self._normal_matrix = newNormalMatrix
        self._transform_dirty = false
        return newModel, newNormalMatrix
    else
        return self._model_matrix, self._normal_matrix
    end
    
end

function Object3d:draw(shader, mode, current_material)
    local modelMatrix,normalMatrix = self:get_model()
    local lastMaterial = current_material

    shader:set_matrix(
        "model",
        modelMatrix
    )

    shader:set_matrix3(
        "normalMatrix",
        normalMatrix
    )

    local meshes = 1

    if self.mesh.parts then
        meshes, lastMaterial = self.mesh:draw(shader, mode)
    else
        if self.material ~= lastMaterial then
            self.material:apply(shader)
            lastMaterial = self.material
        end
        self.mesh:draw(shader, mode)
    end

    return meshes, lastMaterial
end

return Object3d