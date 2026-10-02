local Camera = require("engine/camera")
local Object3d = require("engine/object3d")
local Light = require("engine/light")
local Vector3d = require("math/vector3d")
local Vector2d = require("math/vector2d")

local Scene = {}
Scene.__index = Scene

function Scene.new()
    local self = setmetatable({},Scene)

    local field_of_view = math.rad(70)
    local aspect_ratio = 1
    local near_distance = 0.1
    local far_distance = 300
    local camera_distance = 5

    --objects
    self.objects = {}

    --camera
    self.camera = Camera.new(field_of_view,aspect_ratio,near_distance,far_distance)

    --lighting
    self.light = Light.new()

    self.light:set_direction(Vector3d.new(0,-1,-1):Unit())
    self.light:set_color(Vector3d.new(1,1,1))
    self.light:set_intensity(1)

    return self
end

function Scene:add(name,object)
    if not name then return end
    if not object then return end

    self.objects[name] = object
end

function Scene:remove(name)
    if not name then return end

    self.objects[name] = nil
end

function Scene:clear()
    self.objects = {}
end

function Scene:update(dt)
    if not dt then return end
end

function Scene:draw(shader)
    if not shader then return end

    shader:use()

    shader:set_lighting(self.light)

    shader:set_matrix("projection", self.camera:get_projection())
    
    shader:set_matrix("view", self.camera:get_view())

    shader:set_vector3(
        "viewPosition",
        self.camera.position
    )

    for _, object in pairs(self.objects) do
        object:draw(shader,"triangles")
    end
end

return Scene