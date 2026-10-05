local gl = require("moongl")

local Shader = {}
Shader.__index = Shader

function Shader.new(vertex_path, fragment_path)
    local self = setmetatable({},Shader)

    self.program,self.vertex_shader,self.fragment_shader = gl.make_program(
        "vertex", vertex_path,
        "fragment", fragment_path
    )

    self.uniforms = {}

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

function Shader:set_lighting(lighting)
    gl.uniform(
        self:uniform_location("lightDirection"),
        "float",
        lighting.direction.x,
        lighting.direction.y,
        lighting.direction.z
    )

    gl.uniform(
        self:uniform_location("lightColor"),
        "float",
        lighting.color.x,
        lighting.color.y,
        lighting.color.z
    )

    gl.uniform(
        self:uniform_location("ambientLightColor"),
        "float",
        lighting.ambient_color.x,
        lighting.ambient_color.y,
        lighting.ambient_color.z
    )

    gl.uniform(
        self:uniform_location("lightIntensity"),
        "float",
        lighting.intensity
    )
end

return Shader