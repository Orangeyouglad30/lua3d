local gl = require("moongl")
local Vector3d = require("math/vector3d")
local Vector2d = require("math/vector2d")

local Mesh = {}

local function dump(o)
   if type(o) == 'table' then
      local s = '{ '
      for k,v in pairs(o) do
         if type(k) ~= 'number' then k = '"'..k..'"' end
         s = s .. '['..k..'] = ' .. dump(v) .. ','
      end
      return s .. '} '
   else
      return tostring(o)
   end
end

local function split(inputstr, sep)
    if sep == nil then
        sep = "%s" -- Defaults to whitespace
    end
    local t = {}
    for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do
        table.insert(t, str)
    end
    return t
end

local function add_vertex(vertices, position, color, normal, uv)
    vertices[#vertices + 1] = position[1]
    vertices[#vertices + 1] = position[2]
    vertices[#vertices + 1] = position[3]

    vertices[#vertices + 1] = color[1]
    vertices[#vertices + 1] = color[2]
    vertices[#vertices + 1] = color[3]

    vertices[#vertices + 1] = normal[1]
    vertices[#vertices + 1] = normal[2]
    vertices[#vertices + 1] = normal[3]

    vertices[#vertices + 1] = uv[1]
    vertices[#vertices + 1] = uv[2]
end

local function add_face(vertices, indices, a, b, c, d, color)
    -- The first vertex index for this face.
    -- Indices are zero-based because OpenGL uses zero-based indices.
    local base_index = #vertices / 11

    local vec1 = Vector3d.new(b[1]-a[1],b[2]-a[2],b[3]-a[3])
    local vec2 = Vector3d.new(c[1]-a[1],c[2]-a[2],c[3]-a[3])
    local normal = vec2:Cross(vec1):Unit():flatten()

    -- Add each face corner once.
    add_vertex(vertices, a, color, normal, Vector2d.new(0,1):flatten())
    add_vertex(vertices, b, color, normal, Vector2d.new(1,1):flatten())
    add_vertex(vertices, c, color, normal, Vector2d.new(1,0):flatten())
    add_vertex(vertices, d, color, normal, Vector2d.new(0,0):flatten())

    -- Two triangles:
    -- a, b, c
    -- a, c, d
    indices[#indices + 1] = base_index
    indices[#indices + 1] = base_index + 1
    indices[#indices + 1] = base_index + 2

    indices[#indices + 1] = base_index
    indices[#indices + 1] = base_index + 2
    indices[#indices + 1] = base_index + 3
end

--[[
local function add_tri(vertices,indices,vi,vni,uvi,v1i,v2i,v3i,vn1i,vn2i,vn3i,uv1i,uv2i,uv3i)
    local base_index = #vertices / 11

    add_vertex(vertices, vi[tonumber(v1i)]:flatten(), Vector3d.Zero():flatten(), vni[tonumber(vn1i)]:flatten(), uvi[tonumber(uv1i)]:flatten())
    add_vertex(vertices, vi[tonumber(v2i)]:flatten(), Vector3d.Zero():flatten(), vni[tonumber(vn2i)]:flatten(), uvi[tonumber(uv2i)]:flatten())
    add_vertex(vertices, vi[tonumber(v3i)]:flatten(), Vector3d.Zero():flatten(), vni[tonumber(vn3i)]:flatten(), uvi[tonumber(uv3i)]:flatten())

    indices[#indices + 1] = base_index
    indices[#indices + 1] = base_index + 1
    indices[#indices + 1] = base_index + 2
end
]]

local function center_vertices(vertices)
    local min_x = math.huge
    local min_y = math.huge
    local min_z = math.huge

    local max_x = -math.huge
    local max_y = -math.huge
    local max_z = -math.huge

    for i = 1, #vertices, 11 do
        min_x = math.min(min_x, vertices[i])
        min_y = math.min(min_y, vertices[i + 1])
        min_z = math.min(min_z, vertices[i + 2])

        max_x = math.max(max_x, vertices[i])
        max_y = math.max(max_y, vertices[i + 1])
        max_z = math.max(max_z, vertices[i + 2])
    end

    local center_x = (min_x + max_x) / 2
    local center_y = (min_y + max_y) / 2
    local center_z = (min_z + max_z) / 2

    for i = 1, #vertices, 11 do
        vertices[i] = vertices[i] - center_x
        vertices[i + 1] = vertices[i + 1] - center_y
        vertices[i + 2] = vertices[i + 2] - center_z
    end
end

local function add_tri(
    vertices,
    indices,
    positions,
    normals,
    uvs,
    corner_a,
    corner_b,
    corner_c
)
    local base_index = #vertices / 11

    local corners = {
        corner_a,
        corner_b,
        corner_c
    }

    for _, corner in ipairs(corners) do
        local position_index = tonumber(corner[1])
        local uv_index = tonumber(corner[2])
        local normal_index = tonumber(corner[3])

        add_vertex(
            vertices,
            positions[position_index]:flatten(),
            {1, 1, 1},
            normals[normal_index]:flatten(),
            uvs[uv_index]:flatten()
        )
    end

    indices[#indices + 1] = base_index
    indices[#indices + 1] = base_index + 1
    indices[#indices + 1] = base_index + 2
end

function Mesh.new(vertices, indices)
    local self = {}

    self.vertex_count = #vertices / (3 + 3 + 3 + 2)

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

function Mesh.createFromObj(file_path)
    local file = assert(
        io.open(file_path, "r"),
        "Could not open OBJ file: " .. file_path
    )

    local vertices, indices = {},{}

    local verticesReference = {}
    local normalsReference = {}
    local uvsReference = {}

    for line in file:lines() do
        local tokens = {}

        for token in line:gmatch("%S+") do
            tokens[#tokens + 1] = token
        end

        if tokens[1] == "v" then
            verticesReference[#verticesReference+1] = Vector3d.new(tonumber(tokens[2]),tonumber(tokens[3]),tonumber(tokens[4]))
        elseif tokens[1] == "vt" then
            uvsReference[#uvsReference+1] = Vector2d.new(tonumber(tokens[2]),tonumber(tokens[3]))
        elseif tokens[1] == "vn" then
            normalsReference[#normalsReference+1] = Vector3d.new(tonumber(tokens[2]),tonumber(tokens[3]),tonumber(tokens[4]))
        elseif tokens[1] == "f" then
            local face = {}

            for i = 2, #tokens do
                local face_token = tokens[i]
                local references = {}

                for value in face_token:gmatch("[^/]+") do
                    references[#references + 1] = value
                end

                face[#face + 1] = references
            end

            for i = 2, #face - 1 do
                add_tri(vertices, indices, verticesReference, normalsReference, uvsReference, face[1], face[i], face[i + 1])
            end
        end
    end

    file:close()

    center_vertices(vertices)

    return Mesh.new(vertices,indices)
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