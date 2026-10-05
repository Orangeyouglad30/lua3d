local gl = require("moongl")
local Vector3d = require("math/vector3d")
local Vector2d = require("math/vector2d")
local Common = require("engine/common")

local Mesh = {}

function Mesh.new(vertices, indices)
    local self = {}

    self.vertex_count = #vertices / (3 + 3 + 3 + 2)

    local min_x,min_y,min_z,max_x,max_y,max_z = Common.get_vertices_bounds(vertices)

    self.min_bounds = Vector3d.new(min_x,min_y,min_z)
    self.max_bounds = Vector3d.new(max_x,max_y,max_z)

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

function Mesh.fromOBJ(file_path)
    if not file_path then return end

    print("Creating Mesh from OBJ <"..file_path..">")

    local start = os.clock()

    local file = assert(
        io.open(file_path, "r"),
        "Could not open OBJ file: " .. file_path
    )

    local vertices, indices = {},{}

    local verticesReference = {}
    local normalsReference = {}
    local uvsReference = {}
    
    local min_x,min_y,min_z,max_x,max_y,max_z = math.huge,math.huge,math.huge,-math.huge,-math.huge,-math.huge --bounds of the total model

    for line in file:lines() do
        local tokens = {}

        for token in line:gmatch("%S+") do
            tokens[#tokens + 1] = token
        end

        if tokens[1] == "v" then
            --grab the bounding box size of the model through the vertices
            min_x = math.min(min_x, tonumber(tokens[2]))
            min_y = math.min(min_y, tonumber(tokens[3]))
            min_z = math.min(min_z, tonumber(tokens[4]))

            max_x = math.max(max_x, tonumber(tokens[2]))
            max_y = math.max(max_y, tonumber(tokens[3]))
            max_z = math.max(max_z, tonumber(tokens[4]))

            verticesReference[#verticesReference+1] = Vector3d.new(tonumber(tokens[2]),tonumber(tokens[3]),tonumber(tokens[4]))
        elseif tokens[1] == "vt" then
            uvsReference[#uvsReference+1] = Vector2d.new(tonumber(tokens[2]),tonumber(tokens[3]))
        elseif tokens[1] == "vn" then
            normalsReference[#normalsReference+1] = Vector3d.new(tonumber(tokens[2]),tonumber(tokens[3]),tonumber(tokens[4]))
        elseif tokens[1] == "f" then
            local face = {}

            for i = 2, #tokens do
                local raw_face_token = tokens[i]

                face[#face + 1] = Common.parse_face_token(raw_face_token)
            end

            for i = 2, #face - 1 do
                Common.add_tri(
                    vertices,
                    indices,
                    verticesReference,
                    normalsReference,
                    uvsReference,
                    face[1],
                    face[i],
                    face[i + 1]
                )
            end
        end
    end

    file:close()

    print("Completed Parsing Mesh from OBJ <"..file_path.."> in "..os.clock()-start.." seconds | Results: "..#verticesReference.." vertices, "..#uvsReference.." UVs, "..#normalsReference.." normals")

    Common.squish_vertices(vertices,1.0,min_x,min_y,min_z,max_x,max_y,max_z)

    return Mesh.new(vertices,indices)
end

function Mesh:draw(shader,mode)
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