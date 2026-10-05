local Material = require("engine/material")
local Vector3d = require("math/vector3d")
local Common = require("engine/common")

local MTL = {}
MTL.__index = MTL

function MTL.new(ambient,diffuse,specular)

end

function MTL.fromFile(file_path)
    --print("RECEIVED FILE PATH: <"..file_path..">")

    local file = assert(
        io.open(file_path, "r"),
        "Could not open MTL file: " .. file_path
    )

    local materials = {}
    local currentMaterialInfo = {
        ["ambientColor"] = Vector3d.One(),
        ["specularColor"] = Vector3d.One(),
        ["diffuseColor"] = Vector3d.One(),
        ["shininess"] = 0,
        ["specularStrength"] = 0,
        ["diffuseTexture"] = nil,
    }
    local currentMaterialName = ""

    for line in file:lines() do
        local tokens = {}

        for token in line:gmatch("%S+") do
            tokens[#tokens + 1] = token
        end

        if tokens[1] == "newmtl" then 
            if currentMaterialName ~= "" then
                --print("Finished up material "..currentMaterialName..". Adding to material library...")
                materials[currentMaterialName] = Material.fromMTL(currentMaterialInfo)
            end

            --materials[tokens[2]] = {}
            currentMaterialName = tokens[2]
            currentMaterialInfo = {
                ["ambientColor"] = Vector3d.One(),
                ["specularColor"] = Vector3d.One(),
                ["diffuseColor"] = Vector3d.One(),
                ["shininess"] = 0,
                ["specularStrength"] = 0,
                ["diffuseTexture"] = nil,
            }
        elseif tokens[1] == "Ka" then   
            currentMaterialInfo.ambientColor = Vector3d.new(tokens[2],tokens[3],tokens[4])
        elseif tokens[1] == "Kd" then
            currentMaterialInfo.diffuseColor = Vector3d.new(tokens[2],tokens[3],tokens[4])
        elseif tokens[1] == "Ks"then
            currentMaterialInfo.specularColor = Vector3d.new(tokens[2],tokens[3],tokens[4])
        elseif tokens[1] == "d"then
            
        elseif tokens[1] == "Ns"then
            currentMaterialInfo.shininess = tokens[2]
        elseif tokens[1] == "illum" then
            
        end

    end

    --print("Finished up material "..currentMaterialName..". Adding to material library...")
    materials[currentMaterialName] = Material.fromMTL(currentMaterialInfo)

    --print(Common.dumpDepth(materials))

    return materials
end

return MTL