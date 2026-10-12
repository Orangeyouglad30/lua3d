local Shader = require("engine/shader")
local Frustum = require("engine/frustum")
local gl = require("moongl")
local ShadowMap = require("engine/shadowmap")
local CFrame = require("math/cframe")
local Camera = require("engine/camera")
local Vector3d = require("math/vector3d")
local Transform = require("engine/transform")

local Renderer = {}
Renderer.__index = Renderer

function Renderer.new()
    local self = setmetatable({},Renderer)

    self.shader = Shader.new(
        "shaders/basic.vert",
        "shaders/basic.frag"
    )
    self.current_material = nil

    self.shadow_shader = Shader.new(
        "shaders/shadow.vert",
        "shaders/shadow.frag"
    )

    self.shadow_cascades = {
        {near_distance = 0.1, far_distance = 3, resolution = 1024},
        {near_distance = 3, far_distance = 10.0, resolution = 1024},
        {near_distance = 10.0, far_distance = 30.0, resolution = 1024},
        {near_distance = 30.0, far_distance = 80.0, resolution = 1024},
    }

    self.shadow_maps = {}

    for _, cascade in ipairs(self.shadow_cascades) do
        self.shadow_maps[#self.shadow_maps + 1] = ShadowMap.new(cascade.resolution)
    end

    self.shadow_blur_radius = {
        1.0,
        2.0,
        4.0,
    }

    self.viewport_width = 1280
    self.viewport_height = 720

    return self
end

function Renderer:set_viewport(width,height)
    self.viewport_width = width
    self.viewport_height = height
end

function Renderer:destroy()
    if self.shader then
        self.shader:destroy()
    end
end

function Renderer:draw_scene(scene,mode,draw_shadows)
     if not self.shader then return end

    local projection = scene.camera:get_projection()
    local view = scene.camera:get_view()
    local view_projection = projection * view

    local light_space_matrices = {}

    if draw_shadows then
        for i = 1,#self.shadow_cascades do
            light_space_matrices[i] = self:get_cascade_light_space_matrix(scene,i)
        end

        self:draw_shadow_pass(scene)
    end

    self.shader:use()

    self.shader:set_matrix("projection",projection)
    self.shader:set_matrix("view",view)

    if draw_shadows then
        self.shader:set_int("drawShadows",1)

        self.shader:set_shadow_maps(
            light_space_matrices,
            self.shadow_cascades,
            self.shadow_maps,
            self.shadow_blur_radius
        )
    else
        self.shader:set_int("drawShadows",0)
    end

    self.shader:set_vector3(
        "viewPosition",
        scene.camera.CFrame.position
    )

    self.shader:set_lighting(
        scene.global_light,
        scene.lights
    )
    
    local frustum = Frustum.from_matrix(view_projection)

    local culled_objects = 0
    local total_objects = 1
    local total_meshes_drawn = 0

    --temporary
    self.current_material = nil

    for objectName, object in pairs(scene.objects) do
        local largest_scale = math.max(object.scale.x,object.scale.y,object.scale.z)
        local object_radius = 1--math.max(object.max_bounds.x-object.min_bounds.x,object.max_bounds.y-object.min_bounds.y,object.max_bounds.z-object.min_bounds.z)

        local radius = largest_scale * object_radius

        local distance = (scene.camera.CFrame.position - object.position):Magnitude()

        if distance < scene.camera.far_distance + radius and frustum:contains_sphere(object.position,radius) then
            local meshes_drawn, material_drawn = object:draw(self.shader,mode,self.current_material)
            total_meshes_drawn = total_meshes_drawn + meshes_drawn
            self.current_material = material_drawn
        else
            culled_objects = culled_objects + 1
        end
        total_objects = total_objects + 1
    end

    return total_objects,culled_objects,total_meshes_drawn
end

function Renderer:get_light_space_matrix(scene)
    local target = scene.camera.CFrame.position
    local light_direction = scene.global_light.direction:Unit()
    local light_position = target - light_direction * 10

    local light_camera = Camera.new(0,1,0.1,30)

    light_camera.CFrame = CFrame.lookAt(light_position,target)

    local light_view = light_camera:get_view()

    local light_projection = Transform.orthographic(-10,10,-10,10,0.1,30)

    return light_projection * light_view
end

function Renderer:get_cascade_light_space_matrix(scene,index)
    local cascade = self.shadow_cascades[index]
    local camera = scene.camera
    local _,_,camera_forward = camera:get_basis()

    local near_distance = cascade.near_distance
    local far_distance = cascade.far_distance

    local center_distance =
        (near_distance + far_distance) * 0.5

    local target =
        camera.CFrame.position +
        camera_forward * center_distance

    local half_height =
        math.tan(camera.field_of_view * 0.5) *
        far_distance

    local half_width =
        half_height *
        camera.aspect_ratio

    local extent =
        math.sqrt(
            half_width * half_width +
            half_height * half_height
        ) + 2.0

    local light_direction =
        scene.global_light.direction:Unit()

    local light_distance = 100
    local light_position =
        target - light_direction * light_distance

    local light_camera = Camera.new(
        0,
        1,
        0.1,
        light_distance + extent * 2
    )

    light_camera.CFrame =
        CFrame.lookAt(light_position,target)

    local light_view = light_camera:get_view()

    local light_projection =
        Transform.orthographic(
            -extent,
            extent,
            -extent,
            extent,
            0.1,
            light_distance + extent * 2
        )

    return light_projection * light_view
end

function Renderer:draw_shadow_pass(scene)
    local camera = scene.camera
    local camera_right,camera_up,camera_forward = camera:get_basis()

    for i,shadowmap in pairs(self.shadow_maps) do
        local shadowCascade = self.shadow_cascades[i]
        local lightSpaceMatrix = self:get_cascade_light_space_matrix(scene,i)

        self.shadow_shader:use()
        self.shadow_shader:set_matrix("lightSpaceMatrix", lightSpaceMatrix)

        gl.bind_framebuffer(
            "draw",
            shadowmap.framebuffer
        )

        gl.viewport(
            0,
            0,
            shadowmap.size,
            shadowmap.size
        )

        gl.clear("depth")

        local light_frustum = Frustum.from_matrix(lightSpaceMatrix)
        local max_shadow_distance = self.shadow_cascades[#self.shadow_cascades].far_distance

        for _,object in pairs(scene.objects) do
            local largest_scale = math.max(object.scale.x, object.scale.y, object.scale.z)

            local radius = largest_scale
            local distance = (scene.camera.CFrame.position - object.position):Magnitude()

            if distance < max_shadow_distance + radius and
            light_frustum:contains_sphere(object.position,radius) then
                object:draw_depth(self.shadow_shader)
            end
        end

        gl.unbind_framebuffer("draw")
    end

    gl.viewport(
        0,
        0,
        self.viewport_width,
        self.viewport_height
    )
end

return Renderer