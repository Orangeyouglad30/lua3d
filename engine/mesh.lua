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

local function parse_face_token(face_token)
    local position_text, uv_text, normal_text =
        face_token:match("^([^/]*)/([^/]*)/([^/]*)$")

    return {
        position = tonumber(position_text),
        uv = uv_text ~= "" and tonumber(uv_text) or nil,
        normal = normal_text ~= "" and tonumber(normal_text) or nil
    }
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

local function normalize_vertices(vertices, target_size)
    target_size = target_size or 1.0

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

    local width = max_x - min_x
    local height = max_y - min_y
    local depth = max_z - min_z

    local largest_dimension =
        math.max(width, height, depth)

    assert(
        largest_dimension > 0,
        "Cannot normalize a model with no size"
    )

    local scale =
        target_size / largest_dimension

    for i = 1, #vertices, 11 do
        vertices[i] =
            (vertices[i] - center_x) * scale

        vertices[i + 1] =
            (vertices[i + 1] - center_y) * scale

        vertices[i + 2] =
            (vertices[i + 2] - center_z) * scale
    end
end

local function generate_uv(position)
    return Vector2d.new(
        position.x * 4.0,
        position.z * 4.0
    )
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
        local position =
            positions[corner.position]

        local normal =
            normals[corner.normal]

        local uv =
            corner.uv and uvs[corner.uv]
            or Vector2d.new(0, 0)

        add_vertex(
            vertices,
            position:flatten(),
            {1, 1, 1},
            normal:flatten(),
            uv:flatten()
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
    print("Parsing OBJ <"..file_path..">")

    local file = assert(
        io.open(file_path, "r"),
        "Could not open OBJ file: " .. file_path
    )

    local vertices, indices = {},{}

    local verticesReference = {}
    local normalsReference = {}
    local uvsReference = {}

    local lineI = 0

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
                local raw_face_token = tokens[i]

                face[#face + 1] = parse_face_token(raw_face_token)
            end

            for i = 2, #face - 1 do
                add_tri(
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

        lineI = lineI + 1
        --print(lineI)
    end

    file:close()

    print("Completed Parsing OBJ <"..file_path.."> | Results: "..#verticesReference.." vertices, "..#uvsReference.." UVs, "..#normalsReference.." normals")

    normalize_vertices(vertices)

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