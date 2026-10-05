local gl = require("moongl")
local Vector3d = require("math/vector3d")
local Vector2d = require("math/vector2d")
local Mesh = require("engine/mesh")
local Common = require("engine/common")
local MTL = require("engine/mtl")

local Model = {}
Model.__index = Model

function Model.new(parts,min_bounds,max_bounds)
    local self = setmetatable({},Model)

    self.parts = parts or {}
    self.min_bounds = min_bounds or Vector3d.Zero()
    self.max_bounds = max_bounds or Vector3d.Zero()

    return self
end

function Model.fromOBJ(file_path)
    if not file_path then return end

    print("Creating Model from OBJ <"..file_path..">")

    local start = os.clock()

    local file = assert(
        io.open(file_path, "r"),
        "Could not open OBJ file: " .. file_path
    )

    local parts = {} --pairs of a material and the mesh with that material
    local groups = {} --has a dictionary where the key is the material and the value is a vertices table and an indices table

    local verticesReference = {} --all of the vertices of the obj in order
    local normalsReference = {} --all of the normals of the obj in order
    local uvsReference = {} --all of the uvs of the obj in order

    local mtllibPath --the path to the mtl file
    local min_x,min_y,min_z,max_x,max_y,max_z = math.huge,math.huge,math.huge,-math.huge,-math.huge,-math.huge --bounds of the total model

    --first pass to grab every vertex, normal and uv
    for line in file:lines() do
        local tokens = {}

        for token in line:gmatch("%S+") do
            tokens[#tokens + 1] = token
        end

        if tokens[1] == "mtllib" then
            --grab the mttlib path
            mtllibPath = tokens[2]
        elseif tokens[1] == "v" then
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
        end
    end

    file:close() --close file after first loop

    --retrieve all of the materials and compile them from the specified .mtl file
    local modelMaterials = {} 
    if mtllibPath then
        --convert the mttlib path into a path that lua can use before trying to retrieve the library from the .mtl file
        modelMaterials = MTL.fromFile(Common.resolve_relative_path(file_path,mtllibPath))
    end

    --create groups for each material
    for materialName,materialInfo in pairs(modelMaterials) do
        groups[materialName] = {
            ["vertices"] = {},
            ["indices"] = {},
        }
    end

    --reopen file for second loop
    file = assert(
        io.open(file_path, "r"),
        "Could not open OBJ file: " .. file_path
    )

    --declare the current material for use in second loop
    local currentMaterial = nil
    local faces = 0

    --second pass to normalize vertices on faces as well as separate each part of the mesh
    for line in file:lines() do
        local tokens = {}

        --turn the line into tokens
        for token in line:gmatch("%S+") do
            tokens[#tokens + 1] = token
        end

        --if first line is usemtl then switch the current material over
        if tokens[1] == "usemtl" then
            currentMaterial = tokens[2]

            --if the material that the line specifies isn't actually found then try to shorten it down after the colon
            if not modelMaterials[currentMaterial] then
                local shortened_name = currentMaterial:match(":(.+)$")

                if shortened_name then
                    currentMaterial = shortened_name
                end
            end
        elseif tokens[1] == "f" then --if the token indicates that the line is a face
            local face = {}

            --parses through all of the tokens, could be more than 4 tokens depending on vertices of face (i.e. quads vs triangles)
            for i = 2, #tokens do
                --grabs the raw face token i.e 4/5/2
                local raw_face_token = tokens[i]

                --adds the parsed data into the face table in the form of {position = positionIndex, uv = uvIndex, normal = normalIndex}
                face[#face + 1] = Common.parse_face_token(raw_face_token)
            end

            --in case there are more than one triangle i.e. #face = 4 cause 4 vertices then it will add two tris instead of one
            for i = 2, #face - 1 do
                --print(currentMaterial)
                faces = faces + 1

                Common.add_tri(
                    groups[currentMaterial].vertices,
                    groups[currentMaterial].indices,
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

    --loops through the groups and finishes up the vertices and indices into one mesh and material pair
    for materialName,groupInfo in pairs(groups) do
        local vertices = groupInfo.vertices
        local indices = groupInfo.indices

        --in case a group is empty just give up lowk
        if #indices == 0 then
            return
        end

        --squish the vertices to fit inside of the bounding box so that the model is normalized to the target size (in this case 1.0)
        Common.squish_vertices(
            vertices,
            1.0,
            min_x, min_y, min_z,
            max_x, max_y, max_z
        )

        --finally add the mesh material pair into the parts table
        table.insert(parts, {
            mesh = Mesh.new(vertices, indices),
            material = modelMaterials[materialName]
        })
    end

    print("Completed Parsing Model from OBJ <"..file_path.."> in "..os.clock()-start.." seconds | Results: "..#verticesReference.." vertices, "..#uvsReference.." UVs, "..#normalsReference.." normals, "..faces.." faces, "..#parts.." meshes")

    return Model.new(parts,Vector3d.new(min_x,min_y,min_z),Vector3d.new(max_x,max_y,max_z))
end

function Model:destroy()
    if self.destroyed then return end

    for _,part in pairs(self.parts) do
        part.mesh:destroy()
    end

    self.destroyed = true
end

function Model:draw(shader,mode)
    local meshesDrawn = 0

    for _,partInfo in pairs(self.parts) do
        --print("Drawing mesh with material: "..partInfo.material)
        if partInfo.material then
            partInfo.material:apply(shader)
        end
        partInfo.mesh:draw(shader,mode)

        meshesDrawn = meshesDrawn + 1
    end

    return meshesDrawn
end

return Model