local Camera = require("engine/camera")
local Object3d = require("engine/object3d")
local Light = require("engine/light")
local Vector3d = require("math/vector3d")
local Vector2d = require("math/vector2d")
local Frustum = require("engine/frustum")
local Line = require("engine/line")

local Scene = {}
Scene.__index = Scene

function Scene.new()
    local self = setmetatable({},Scene)

    local field_of_view = math.rad(70)
    local aspect_ratio = 1
    local near_distance = 0.1
    local far_distance = 30
    local camera_distance = 5

    --objects
    self.objects = {}

    --camera
    self.camera = Camera.new(field_of_view,aspect_ratio,near_distance,far_distance)

    --lighting
    self.lights = {}

    self.global_light = Light.newGlobalLight()
    self.global_light:set_direction(Vector3d.new(-1, -1, -1):Unit())
    self.global_light:set_color(Vector3d.new(1, 1, 1))
    self.global_light:set_intensity(1)

    self.lights = {}
    self.lines = {}
    self.billboards = {}

    return self
end

function Scene:add(name,object)
    if not name then return end
    if not object then return end

    if type(object) == "table" and object.__type and object.__type == "Light" then
        self.lights[name] = object
    else
        self.objects[name] = object
    end
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

function Scene:destroy()
    print("Destroying scene...")

    for objectName,object in pairs(self.objects) do
        object:destroy()
    end

    print("Scene destroyed.")
end

return Scene