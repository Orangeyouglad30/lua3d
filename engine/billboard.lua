local gl = require("moongl")
local Vector3d = require("math/vector3d")

local Billboard = {}
Billboard.__index = Billboard

function Billboard.new(texture,position,size,relative_size)
    local self = setmetatable({},Billboard)

    self.texture = texture or nil
    self.size = size / math.max(texture.width/100,texture.height/100) or 1.0
    self.relative_size = relative_size or false
    self.position = position or Vector3d.Zero()

    self.vao = gl.new_vertex_array()
    gl.bind_vertex_array(self.vao)

    self.vbo = gl.new_buffer("array")
    local vertices = {
        -1,-1,0,0,
        1,-1,1,0,
        -1,1,0,1,
        1,1,1,1
    }

    gl.buffer_data(
        "array",
        gl.pack("float",vertices),
        "static draw"
    )

    local float_size = gl.sizeof("float")
    gl.vertex_attrib_pointer(0,2,"float",false,4*float_size,0)
    gl.enable_vertex_attrib_array(0)
    gl.vertex_attrib_pointer(1,2,"float",false,4*float_size,2*float_size)
    gl.enable_vertex_attrib_array(1)

    gl.unbind_vertex_array()

    return self
end

function Billboard:destroy()
    if self.destroyed then return end

    gl.delete_vertex_arrays(self.vao)
    gl.delete_buffers(self.vbo)

    self.destroyed = true
end

function Billboard:update(position)
    self.position = position
end

function Billboard:draw(shader,camera_right,camera_up)
    shader:set_vector3("billboardPosition",self.position)
    shader:set_vector3("cameraRight",camera_right)
    shader:set_vector3("cameraUp",camera_up)
    shader:set_float("billboardSize",self.size)

    self.texture:bind(0)
    shader:set_int("Texture",0)

    gl.bind_vertex_array(self.vao)
    gl.draw_arrays("triangle strip",0,4)
    gl.unbind_vertex_array()
end

return Billboard