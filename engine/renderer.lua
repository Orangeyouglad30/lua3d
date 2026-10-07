local Shader = require("engine/shader")
local Frustum = require("engine/frustum")

local Renderer = {}
Renderer.__index = Renderer

function Renderer.new()
    local self = setmetatable({},Renderer)

    self.shader = Shader.new(
        "shaders/basic.vert",
        "shaders/basic.frag"
    )

    return self
end

function Renderer:destroy()
    if self.shader then
        self.shader:destroy()
    end
end

function Renderer:draw_scene(scene,mode)
    if not self.shader then return end

    self.shader:use()
    
    self.shader:set_lighting(scene.global_light,scene.lights)

    local projection = scene.camera:get_projection()
    local view = scene.camera:get_view()
    local view_projection = projection * view

    local frustum = Frustum.from_matrix(view_projection)

    self.shader:set_matrix("projection", projection)
    
    self.shader:set_matrix("view", view)

    self.shader:set_vector3(
        "viewPosition",
        scene.camera.CFrame.position
    )

    local culled_objects = 0
    local total_objects = 1
    local total_meshes_drawn = 0

    for _, object in pairs(scene.objects) do
        local largest_scale = math.max(object.scale.x,object.scale.y,object.scale.z)
        local object_radius = 1--math.max(object.max_bounds.x-object.min_bounds.x,object.max_bounds.y-object.min_bounds.y,object.max_bounds.z-object.min_bounds.z)

        local radius = largest_scale * object_radius

        local distance = (scene.camera.CFrame.position - object.position):Magnitude()

        if distance < scene.camera.far_distance + radius and frustum:contains_sphere(object.position,radius) then
            local meshes_drawn = object:draw(self.shader,mode)
            total_meshes_drawn = total_meshes_drawn + meshes_drawn
        else
            culled_objects = culled_objects + 1
        end
        total_objects = total_objects + 1
    end

    return total_objects,culled_objects,total_meshes_drawn
end

return Renderer