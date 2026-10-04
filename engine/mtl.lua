local Material = require("engine/material")

local MTL = {}
MTL.__index = MTL

function MTL.new(ambient,diffuse,specular)

end

function MTL.fromFile(file_path)
    local file = assert(
        io.open(file_path, "r"),
        "Could not open OBJ file: " .. file_path
    )

    local materials = {}

    for line in file:lines() do
        local tokens = {}

        for token in line:gmatch("%S+") do
            tokens[#tokens + 1] = token
        end

        if tokens[1] == "newmtl" then 
            materials[tokens[2]] = {}
        elseif tokens[1] == "Ka" then   
            
        elseif tokens[1] == "Kd" then
            
        elseif tokens[1] == "Ks"then
            
        elseif tokens[1] == "d"then
            
        elseif tokens[1] == "Ns"then
            
        elseif tokens[1] == "illum" then
            
        end

    end
end

return MTL