local gl = require("moongl")

local ShadowMap = {}
ShadowMap.__index = ShadowMap

function ShadowMap.new(size)
    local self = setmetatable({},ShadowMap)

    self.size = size
    self.texture = gl.new_texture("2d")

    gl.bind_texture("2d",self.texture)
    gl.texture_image(
        "2d",
        0,
        "depth component24",
        "depth component",
        "float",
        nil,
        size,
        size
    )

    gl.texture_parameter("2d","min filter","nearest")
    gl.texture_parameter("2d","mag filter","nearest")
    gl.texture_parameter("2d","wrap s","clamp to edge")
    gl.texture_parameter("2d","wrap t","clamp to edge")

    self.framebuffer = gl.new_framebuffer("draw")
    gl.bind_framebuffer("draw",self.framebuffer)

    gl.framebuffer_texture_2d(
        "draw",
        "depth attachment",
        "2d",
        self.texture,
        0
    )

    gl.draw_buffer("none")
    gl.read_buffer("none")

    assert(
        gl.check_framebuffer_status("draw") == "complete",
        "Shadow framebuffer is incomplete"
    )

    gl.unbind_framebuffer("draw")
    gl.unbind_texture("2d")

    return self
end

function ShadowMap:destroy()
    if self._destroyed then return end

    gl.delete_framebuffers(self.framebuffer)
    gl.delete_textures(self.texture)

    self._destroyed = true
end

return ShadowMap