local mi = require("moonimage")
local Texture = require("engine/texture")
local Material = require("engine/material")

local Materials = {}

Materials._materials = {
    ["Brick"] = {
        ["shininess"] = 16,
        ["specularStrength"] = 0.2,
        ["img_path"] = "assets/textures/brick1.png"
    },
    ["Crate"] = {
        ["shininess"] = 16,
        ["specularStrength"] = 0.2,
        ["img_path"] = "assets/textures/crate1.png"
    },
    ["Ice"] = {
        ["shininess"] = 128,
        ["specularStrength"] = 0.4,
        ["img_path"] = "assets/textures/ice1.png"
    }
}

function Materials.load()
    for material_name,material_properties in pairs(Materials._materials) do
        local texture = Texture.new(material_properties.img_path)
        
        local newMaterial = Material.new(texture,material_properties.shininess,material_properties.specularStrength)

        Materials[material_name] = newMaterial
    end
end

return Materials