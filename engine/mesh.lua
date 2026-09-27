local gl = require("moongl")

local Mesh = {}

function Mesh.new(vertices, indices)
    local self = {}

    self.vertex_count = #vertices / (3 + 3 + 3)

    self.vao = gl.new_vertex_array()
    gl.bind_vertex_array(self.vao)

    self.ebo = gl.new_buffer("element array")

    gl.buffer_data(
        "element array",
        gl.pack("uint", indices),
        "static draw"
    )

    self.index_count = #indices

    self.vbo = gl.new_buffer("array")

    gl.buffer_data(
        "array",
        gl.pack("float", vertices),
        "static draw"
    )

    local float_size = gl.sizeof("float")

    gl.vertex_attrib_pointer(
        0,
        3,
        "float",
        false,
        (3 + 3 + 3 + 2) * float_size,
        0
    )

    gl.enable_vertex_attrib_array(0)

    gl.vertex_attrib_pointer(
        1,
        3,
        "float",
        false,
        (3 + 3 + 3 + 2) * float_size,
        3 * float_size
    )

    gl.enable_vertex_attrib_array(1)

    gl.vertex_attrib_pointer(
        2,
        3,
        "float",
        false,
        (3 + 3 + 3 + 2) * float_size,
        6 * float_size
    )

    gl.enable_vertex_attrib_array(2)

    gl.vertex_attrib_pointer(
        3,
        2,
        "float",
        false,
        (3 + 3 + 3 + 2) * float_size,
        9 * float_size
    )
    
    gl.enable_vertex_attrib_array(3)

    gl.unbind_vertex_array()

    setmetatable(self, { __index = Mesh })

    return self
end

function Mesh:draw(mode)
    gl.bind_vertex_array(self.vao)

    gl.draw_elements(
        mode,
        self.index_count,
        "uint",
        0
    )

    gl.unbind_vertex_array()
end

return Mesh