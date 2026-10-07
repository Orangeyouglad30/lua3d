local gl = require("moongl")

local Shader = {}
Shader.__index = Shader

function Shader.new(vertex_path, fragment_path,shader_mode)
    local self = setmetatable({},Shader)

    self.program,self.vertex_shader,self.fragment_shader = gl.make_program(
        "vertex", vertex_path,
        "fragment", fragment_path
    )

    self.uniforms = {}
    self.shader_mode = shader_mode or "default"

    return self
end

function Shader:destroy()
    if self.destroyed then return end

    gl.clean_program(self.program,self.vertex_shader,self.fragment_shader)

    self.destroyed = true
end

function Shader:use()
    gl.use_program(self.program)
end

function Shader:uniform_location(name)
    if self.uniforms[name] == nil then
        self.uniforms[name] =
            gl.get_uniform_location(self.program, name)
    end

    return self.uniforms[name]
end

function Shader:set_float(name, value)
    local location = self:uniform_location(name)
    gl.uniform(location, "float", value)
end

function Shader:set_matrix(name, matrix)
    local location = self:uniform_location(name)

    gl.uniform_matrix(
        location,
        "float",
        "4x4",
        true,
        gl.flatten(matrix:flatten())
    )
end

function Shader:set_matrix3(name,matrix)
    local location = self:uniform_location(name)

    gl.uniform_matrix(
        location,
        "float",
        "3x3",
        true,
        gl.flatten(matrix:flatten())
    )
end

function Shader:set_vector3(name, vector)
    local location = self:uniform_location(name)

    gl.uniform(
        location,
        "float",
        vector.x,
        vector.y,
        vector.z
    )
end

function Shader:set_int(name, value)
    local location = self:uniform_location(name)
    gl.uniform(location, "int", value)
end

function Shader:set_bool(name,value)
    local location = self:uniform_location(name)
    gl.uniform(location, "bool",value)
end

function Shader:set_point_lights(lights)
    local i = 1
    for lightName, light in pairs(lights) do
        local shaderI = i-1
        local prefix = "pointLights["..shaderI.."]."
        i=i+1

        self:set_vector3(
            prefix.."position",
            light.position
        )

        if self.shader_mode == "debug" then goto continue end

        self:set_vector3(
            prefix.."color",
            light.color
        )

        self:set_float(
            prefix.."intensity",
            light.intensity
        )

        self:set_float(
            prefix.."constantAttenuation",
            light.constant_attenuation
        )

        self:set_float(
            prefix.."linearAttenuation",
            light.linear_attenuation
        )

        self:set_float(
            prefix.."quadraticAttenuation",
            light.quadratic_attenuation
        )

        ::continue::
    end

    self:set_int("pointLightCount",i-1)
end

function Shader:set_spot_lights(lights)
    local i = 1
    for lightName, light in pairs(lights) do
        local shaderI = i-1
        local prefix = "spotLights["..shaderI.."]."
        i=i+1

        self:set_vector3(
            prefix.."direction",
            light.direction
        )

        self:set_vector3(
            prefix.."position",
            light.position
        )

        if self.shader_mode == "debug" then goto continue end

        self:set_float(
            prefix.."maxAngle",
            light.maxAngle
        )

        self:set_vector3(
            prefix.."color",
            light.color
        )

        self:set_float(
            prefix.."intensity",
            light.intensity
        )

        self:set_float(
            prefix.."constantAttenuation",
            light.constant_attenuation
        )

        self:set_float(
            prefix.."linearAttenuation",
            light.linear_attenuation
        )

        self:set_float(
            prefix.."quadraticAttenuation",
            light.quadratic_attenuation
        )

        ::continue::
    end

    self:set_int("spotLightCount",i-1)
end

function Shader:set_lighting(global_lighting,lights)
    if self.shader_mode == "debug" then goto skip_non_debug end

    gl.uniform(
        self:uniform_location("lightDirection"),
        "float",
        global_lighting.direction.x,
        global_lighting.direction.y,
        global_lighting.direction.z
    )

    gl.uniform(
        self:uniform_location("lightColor"),
        "float",
        global_lighting.color.x,
        global_lighting.color.y,
        global_lighting.color.z
    )

    gl.uniform(
        self:uniform_location("ambientLightColor"),
        "float",
        global_lighting.ambient_color.x,
        global_lighting.ambient_color.y,
        global_lighting.ambient_color.z
    )

    gl.uniform(
        self:uniform_location("lightIntensity"),
        "float",
        global_lighting.intensity
    )

    ::skip_non_debug::

    local pointLights, spotLights = {},{}

    for lightName,light in pairs(lights) do
        if light._type == "point" then
            pointLights[lightName] = light
        elseif light._type == "spot" then
            spotLights[lightName] = light
        end
    end

    if pointLights then
        self:set_point_lights(pointLights)
    end

    if spotLights then
        self:set_spot_lights(spotLights)
    end
end

return Shader