local Shader = require("engine/shader")
local Frustum = require("engine/frustum")
local Texture = require("engine/texture")

local DebugRenderer = {}
DebugRenderer.__index = DebugRenderer

function DebugRenderer.new()
    local self = setmetatable({},DebugRenderer)

    self.line_shader = Shader.new(
        "shaders/line.vert",
        "shaders/line.frag",
        "debug"
    )

    self.billboard_shader = Shader.new(
        "shaders/billboard.vert",
        "shaders/billboard.frag",
        "debug"
    )

    return self
end

function DebugRenderer:destroy()
    if self.shader then
        self.shader:destroy()
    end
end

function DebugRenderer:draw_lights(scene)
    if not self.line_shader then return end
    if not self.billboard_shader then return end

    self.line_shader:use()

    local projection = scene.camera:get_projection()
    local view = scene.camera:get_view()
    local view_projection = projection * view

    local frustum = Frustum.from_matrix(view_projection)

    self.line_shader:set_matrix("projection", projection)
    self.line_shader:set_matrix("view", view)

    for lightName,light in pairs(scene.lights) do
        if light.line then
            light.line:draw()
        end
    end

    self.billboard_shader:use()

    self.billboard_shader:set_matrix("projection",projection)
    self.billboard_shader:set_matrix("view",view)

    local camera_right,camera_up,camera_forward = scene.camera:get_basis()

    for lightName,light in pairs(scene.lights) do
        if light.billboard then
            light.billboard:draw(self.billboard_shader,camera_right,camera_up)
        end
    end
end

return DebugRenderer