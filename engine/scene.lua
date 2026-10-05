local Camera = require("engine/camera")
local Object3d = require("engine/object3d")
local Light = require("engine/light")
local Vector3d = require("math/vector3d")
local Vector2d = require("math/vector2d")
local Frustum = require("engine/frustum")

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

function Scene:draw(shader,mode)
    if not shader then return end

    shader:use()

    shader:set_lighting(self.light)

    local projection = self.camera:get_projection()
    local view = self.camera:get_view()
    local view_projection = projection * view

    local frustum = Frustum.from_matrix(view_projection)

    shader:set_matrix("projection", projection)
    
    shader:set_matrix("view", view)

    shader:set_vector3(
        "viewPosition",
        self.camera.position
    )

    local culled_objects = 0
    local total_objects = 1
    local total_meshes_drawn = 0

    for _, object in pairs(self.objects) do
        local largest_scale = math.max(object.scale.x,object.scale.y,object.scale.z)
        local object_radius = 1--math.max(object.max_bounds.x-object.min_bounds.x,object.max_bounds.y-object.min_bounds.y,object.max_bounds.z-object.min_bounds.z)

        local radius = largest_scale * object_radius

        local distance = (self.camera.position - object.position):Magnitude()

        if distance < self.camera.far_distance + radius and frustum:contains_sphere(object.position,radius) then
            local meshes_drawn = object:draw(shader,mode)
            total_meshes_drawn = total_meshes_drawn + meshes_drawn
        else
            culled_objects = culled_objects + 1
        end
        total_objects = total_objects + 1
    end

    return total_objects,culled_objects,total_meshes_drawn
end

return Scene