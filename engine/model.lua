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

    --print("Creating Model from OBJ <"..file_path..">")

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

    --save positions of the last index in each reference table
    local vcursor = 1
    local ncursor = 1
    local uvcursor = 1

    local mtllibPath --the path to the mtl file
    local min_x,min_y,min_z,max_x,max_y,max_z = math.huge,math.huge,math.huge,-math.huge,-math.huge,-math.huge --bounds of the total model

    local modelMaterials = {} 
    local currentMaterial = "none"
    local faces = 0

    --first pass to grab every vertex, normal and uv
    for line in file:lines() do
        local prefix = line:sub(1,2)

        if prefix == "mt" then
            local tokens = {}

            for token in line:gmatch("%S+") do
                tokens[#tokens + 1] = token
            end

            --grab the mttlib path
            mtllibPath = tokens[2]

            if mtllibPath then
                --convert the mttlib path into a path that lua can use before trying to retrieve the library from the .mtl file
                modelMaterials = MTL.fromFile(Common.resolve_relative_path(file_path,mtllibPath))

                --create groups for each material
                for materialName,materialInfo in pairs(modelMaterials) do
                    groups[materialName] = {
                        ["vertices"] = {},
                        ["indices"] = {},
                    }
                end
            end
        elseif prefix == "v " then
            local x,y,z = line:match("^v%s+([^%s]+)%s+([^%s]+)%s+([^%s]+)")
            x,y,z = tonumber(x),tonumber(y),tonumber(z)

            --grab the bounding box size of the model through the vertices
            min_x = math.min(min_x, x)
            min_y = math.min(min_y, y)
            min_z = math.min(min_z, z)

            max_x = math.max(max_x, x)
            max_y = math.max(max_y, y)
            max_z = math.max(max_z, z)

            verticesReference[vcursor] = x
            verticesReference[vcursor+1] = y
            verticesReference[vcursor+2] = z

            vcursor = vcursor + 3
        elseif prefix == "vt" then
            local u,v = line:match("^vt%s+([^%s]+)%s+([^%s]+)")
            u,v = tonumber(u),tonumber(v)

            uvsReference[uvcursor] = u
            uvsReference[uvcursor+1] = v

            uvcursor = uvcursor + 2
        elseif prefix == "vn" then
            local x,y,z = line:match("^vn%s+([^%s]+)%s+([^%s]+)%s+([^%s]+)")
            x,y,z = tonumber(x),tonumber(y),tonumber(z)

            normalsReference[ncursor] = x
            normalsReference[ncursor+1] = y
            normalsReference[ncursor+2] = z

            ncursor = ncursor + 3
        elseif prefix == "us" then
            local tokens = {}

            for token in line:gmatch("%S+") do
                tokens[#tokens + 1] = token
            end

            currentMaterial = tokens[2]

            --if the material that the line specifies isn't actually found then try to shorten it down after the colon
            if not modelMaterials[currentMaterial] then
                local shortened_name = currentMaterial:match(":(.+)$")

                if shortened_name then
                    currentMaterial = shortened_name
                end
            end
        elseif prefix == "f " then --if the token indicates that the line is a face
            local tokens = {}

            for token in line:gmatch("%S+") do
                tokens[#tokens + 1] = token
            end

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

    file:close() --close file after first loop

    --print("Finished first pass in "..os.clock()-start.." seconds.")

    local min_bounds = Vector3d.new(min_x,min_y,min_z)
    local max_bounds = Vector3d.new(max_x,max_y,max_z)

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
            mesh = Mesh.new(vertices, indices,min_bounds,max_bounds),
            material = modelMaterials[materialName]
        })
    end

    print("Completed Parsing Model from OBJ <"..file_path.."> in "..os.clock()-start.." seconds | Results: "..#verticesReference.." vertices, "..#uvsReference.." UVs, "..#normalsReference.." normals, "..faces.." faces, "..#parts.." meshes")

    return Model.new(parts,min_bounds,max_bounds)
end

function Model:destroy()
    if self.destroyed then return end

    for _,part in pairs(self.parts) do
        part.mesh:destroy()
    end

    self.destroyed = true
end

function Model:draw(shader,mode,current_material)
    local meshesDrawn = 0

    local lastMaterial = current_material

    for _,partInfo in pairs(self.parts) do
        --print("Drawing mesh with material: "..partInfo.material)
        if partInfo.material and partInfo.material ~= lastMaterial and partInfo.material ~= "none" then
            partInfo.material:apply(shader)
            lastMaterial = partInfo.material
        elseif partInfo.material == "none" then
            print("no material found so applyign tho")
            require("Lua3D").graphics.material.Ice:apply(shader)
        end
        partInfo.mesh:draw(shader,mode)

        meshesDrawn = meshesDrawn + 1
    end

    return meshesDrawn, lastMaterial
end

return Model