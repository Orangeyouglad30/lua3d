local gl = require("moongl")
local Vector3d = require("math/vector3d")
local Vector2d = require("math/vector2d")
local Mesh = require("engine/mesh")
local Common = require("engine/common")

local Model = {}
Model.__index = Model

function Model.new(parts)
    local self = setmetatable({},Model)

    self.parts = parts or {}

    return self
end

function Model.fromOBJ(file_path)
    if not file_path then return end

    local meshes = {}
    local mtls = {}
    local parts = {}

    print("Parsing OBJ <"..file_path..">")

    local file = assert(
        io.open(file_path, "r"),
        "Could not open OBJ file: " .. file_path
    )

    local vertices, indices = {},{}

    local verticesReference = {}
    local normalsReference = {}
    local uvsReference = {}

    local currentPart = {
        ["mesh"] = {},
        ["material"] = {}
    }
    local mttlib
    local min_x,min_y,min_z,max_x,max_y,max_z = math.huge,math.huge,math.huge,-math.huge,-math.huge,-math.huge

    local lineI = 0

    --first pass to grab every vertex, normal and uv
    for line in file:lines() do
        local tokens = {}

        for token in line:gmatch("%S+") do
            tokens[#tokens + 1] = token
        end

        if tokens[1] == "mttlib" then
            mttlib = tokens[2]
        elseif tokens[1] == "v" then
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
        end

        lineI = lineI + 1
        --print(lineI)
    end

    file:close()

    file = assert(
        io.open(file_path, "r"),
        "Could not open OBJ file: " .. file_path
    )

    print("Doing second pass.")

    --second pass to normalize vertices on faces as well as separate each part of the mesh
    for line in file:lines() do
        local tokens = {}

        for token in line:gmatch("%S+") do
            tokens[#tokens + 1] = token
        end

        if tokens[1] == "usemtl" then
            --print("Switching material to "..tokens[2])

            if #indices > 0 and #vertices > 0 then
                Common.squish_vertices(vertices,1.0,min_x,min_y,min_z,max_x,max_y,max_z)

                table.insert(parts,{
                    ["mesh"] = Mesh.new(vertices,indices),
                    ["material"] = tokens[2]
                })
            end

            vertices = {}
            indices = {}
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

        lineI = lineI + 1
        --print(lineI)
    end

    file:close()

    print("Completed Parsing OBJ <"..file_path.."> | Results: "..#verticesReference.." vertices, "..#uvsReference.." UVs, "..#normalsReference.." normals")

    return Model.new(parts)
end

function Model:draw(mode)
    for _,partInfo in pairs(self.parts) do
        --print("Drawing mesh with material: "..partInfo.material)
        partInfo.mesh:draw(mode)
    end
end

return Model