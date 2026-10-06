local gl = require("moongl")
local Vector3d = require("math/vector3d")

local Line = {}
Line.__index = Line

function Line.new(from,to,from_color,to_color)
    local self = setmetatable({},Line)

    self.from_color = from_color or Vector3d.Zero()
    self.to_color = to_color or self.from_color
    self.from,self.to = from,to

    --make a table of the 2 vertices or 6 values
    local vertices = from
    for _,coord in pairs(to:flatten()) do
        vertices[#vertices+1] = coord
    end

    --make a new vertex array and bind
    self.vao = gl.new_vertex_array()
    gl.bind_vertex_array(self.vao)

    --make a new vbo and bind
    self.vbo = gl.new_buffer("array")

    gl.buffer_data(
        "array",
        gl.pack("float",vertices),
        "static draw"
    )

    local float_size = gl.sizeof("float")

    gl.vertex_attrib_pointer(
        0,
        3,
        "float",
        false,
        (3 + 3) * float_size,
        0
    )

    gl.enable_vertex_attrib_array(0)

    gl.vertex_attrib_pointer(
        1,
        3,
        "float",
        false,
        (3 + 3) * float_size,
        3 * float_size
    )

    gl.enable_vertex_attrib_array(1)

    gl.unbind_vertex_array()

    return self
end

function Line:destroy()
    if self.destroyed then return end

    gl.delete_vertex_arrays(self.vao)
    gl.delete_buffers(self.vbo)

    self.destroyed = true
end

function Line:update(from,to,from_color,to_color)
    self.from,self.to = from,to
    self.from_color,self.to_color = from_color or self.from_color,to_color or self.to_color
    local vertices = {
        from.x,from.y,from.z,self.from_color.x,self.from_color.y,self.from_color.z,
        to.x,to.y,to.z,self.to_color.x,self.to_color.y,self.to_color.z
    }

    gl.bind_vertex_array(self.vao)
    gl.bind_buffer("array",self.vbo)
    gl.buffer_data("array",gl.pack("float",vertices),"dynamic draw")
    gl.unbind_vertex_array()
end

function Line:draw(shader)
    gl.bind_vertex_array(self.vao)

    gl.line_width(4.0)

    gl.draw_arrays(
        "lines",
        0,
        2
    )

    gl.line_width(1.0)

    gl.unbind_vertex_array()
end

return Line