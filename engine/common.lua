local gl = require("moongl")
local Vector3d = require("math/vector3d")
local Vector2d = require("math/vector2d")

local Common = {}

function Common.dump(o)
   if type(o) == 'table' then
      local s = '{ '
      for k,v in pairs(o) do
         if type(k) ~= 'number' then k = '"'..k..'"' end
         s = s .. '['..k..'] = ' .. Common.dump(v) .. ','
      end
      return s .. '} '
   else
      return tostring(o)
   end
end

function Common.dumpDepth(o,depth)
    depth = depth or ""

    if type(o) == 'table' then
      local s = '{ \n'
      for k,v in pairs(o) do
         if type(k) ~= 'number' then k = '"'..k..'"' end
         s = s .. depth..'['..k..'] = ' .. Common.dumpDepth(v,depth.."  ") .. ',\n'
      end
      return s .. depth..'} '
   else
      return tostring(o)
   end
end

function Common.split(inputstr, sep)
    if sep == nil then
        sep = "%s" -- Defaults to whitespace
    end
    local t = {}
    for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do
        table.insert(t, str)
    end
    return t
end

function Common.parse_face_token(face_token)
    local position_text, uv_text, normal_text =
        face_token:match("^([^/]*)/([^/]*)/([^/]*)$")

    return {
        position = tonumber(position_text),
        uv = uv_text ~= "" and tonumber(uv_text) or nil,
        normal = normal_text ~= "" and tonumber(normal_text) or nil
    }
end

function Common.get_directory(filepath)
    -- Convert Windows separators to Lua-friendly separators
    filepath = filepath:gsub("\\", "/")

    -- Everything before the final slash
    return filepath:match("^(.*)/") or "."
end

function Common.resolve_relative_path(base_file, relative_path)
    relative_path = relative_path:gsub("\\", "/")

    -- Already absolute: examples include C:/... or /...
    if relative_path:match("^%a:/") or relative_path:sub(1, 1) == "/" then
        return relative_path
    end

    local base_directory = Common.get_directory(base_file)

    if base_directory == "." then
        return relative_path
    end

    return base_directory .. "/" .. relative_path
end

function Common.add_vertex(vertices, position, color, normal, uv)
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

function Common.center_vertices(vertices)
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

function Common.squish_vertices(vertices,target_size,min_x,min_y,min_z,max_x,max_y,max_z)
    target_size = target_size or 1.0

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

function Common.get_vertices_bounds(vertices)
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

    return min_x,min_y,min_z,max_x,max_y,max_z
end

function Common.normalize_vertices(vertices, target_size)
    target_size = target_size or 1.0

    local min_x,min_y,min_z,max_x,max_y,max_z = Common.get_vertices_bounds(vertices)

    Common.squish_vertices(vertices,target_size,min_x,min_y,min_z,max_x,max_y,max_z)
end

function Common.generate_uv(position)
    return Vector2d.new(
        position.x * 4.0,
        position.z * 4.0
    )
end

function Common.add_tri(
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
            {positions[corner.position*3-2],positions[corner.position*3-1],positions[corner.position*3]}

        local normal =
            {normals[corner.normal*3-2],normals[corner.normal*3-1],normals[corner.normal*3]}

        local uv =
            corner.uv and {uvs[corner.uv*2-1],uvs[corner.uv*2]}
            or {0,0}--Vector2d.new(0, 0)

        Common.add_vertex(
            vertices,
            position,--position:flatten(),
            {1, 1, 1},
            normal,--normal:flatten(),
            uv--uv:flatten()
        )
    end

    indices[#indices + 1] = base_index
    indices[#indices + 1] = base_index + 1
    indices[#indices + 1] = base_index + 2
end

return Common