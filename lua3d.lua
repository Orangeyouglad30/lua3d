package.path =
    "./vendor/lua/?.lua;" ..
    "./vendor/lua/?/init.lua;" ..
    package.path

package.cpath =
    "./vendor/bin/?.dll;" ..
    package.cpath

--Libraries
local gl = require("moongl")
local glfw = require("moonglfw")

local Lua3D = {
    ["graphics"] = {},
    ["math"] = {},
    ["system"] = {}
}
Lua3D.__index = Lua3D

local Renderer = require("engine/renderer")
local DebugRenderer = require("engine/debugrenderer")
local Shader = require("engine/shader")
local Camera = require("engine/camera")
local Textures = require("engine/textures")

--Constants

--Dynamics
Lua3D.window = nil
local w_width = 0
local w_height = 0
local initialized = false

--Functions
local function createWindow(window_width,window_height)
    if Lua3D.window then warn("Window already exists!") return end

    window_width = window_width or 1280
    window_height = window_height or 720
    
    w_width = window_width --bigger scope 
    w_height = window_height --bigger scope

    glfw.window_hint("context version major", 3)
    glfw.window_hint("context version minor", 3)
    glfw.window_hint("opengl profile", "core")
    glfw.window_hint("depth bits",24)

    Lua3D.window = glfw.create_window(window_width, window_height, "Lua Engine")

    assert(Lua3D.window, "Failed to create window")

    glfw.make_context_current(Lua3D.window)

    glfw.set_input_mode(
        Lua3D.window,
        "cursor",
        "normal"
    )

    glfw.swap_interval(0)

    gl.init()

    gl.enable("depth test")
    gl.enable("cull face")
    gl.cull_face("back")
    gl.clear_depth(1.0)

    gl.viewport(0, 0, window_width, window_height)
end

local function startRenderLoop(self)
    self.load()

    while not glfw.window_should_close(Lua3D.window) do
        glfw.poll_events()

        local dt = glfw.get_time() - self.elapsed_time
        self.elapsed_time = glfw.get_time()

        self.update(dt)

        gl.clear_color(0.1,0.1,0.15,1)
        gl.clear("color","depth")

        self.draw()

        glfw.swap_buffers(Lua3D.window)
    end

    glfw.destroy_window(Lua3D.window)
end

function Lua3D.system.get_window_width()
    return w_width
end

function Lua3D.system.get_window_height()
    return w_height
end

function Lua3D.system.get_window_dimensions()
    return w_width,w_height
end

--Constructors
function Lua3D.initialize(window_width,window_height)
    if initialized or Lua3D.window then warn("Lua3D already initialized!") return end
    initialized = true

    createWindow(window_width,window_height)

    Lua3D.graphics.scene = require("engine/scene")
    Lua3D.graphics.mesh = require("engine/mesh")
    Lua3D.graphics.transform = require("engine/transform")
    Lua3D.math.matrix = require("math/matrix")
    Lua3D.math.vector3d = require("math/vector3d")
    Lua3D.math.vector2d = require("math/vector2d")
    Lua3D.graphics.light = require("engine/light")
    Lua3D.graphics.object3d = require("engine/object3d")
    Lua3D.graphics.material = require("engine/material")
    Lua3D.graphics.materials = require("engine/materials")
    Lua3D.math.common = require("math/common")
    Lua3D.graphics.model = require("engine/model")
    Lua3D.math.cframe= require("math/cframe")
    Lua3D.system.signal = require("engine/signal")
    Lua3D.system.input = require("engine/input").new(Lua3D.window)

    Lua3D.graphics.materials.load()
    
    local self = setmetatable({},Lua3D)

    self._renderer = Renderer.new()
    self.elapsed_time = 0

    --signals
    self.system.on_window_resize = Lua3D.system.signal.new()

    glfw.set_window_size_callback(Lua3D.window, function(_, width, height)
        gl.viewport(0, 0, width, height)

        w_width,w_height = width,height

        if Lua3D.system.on_window_resize then
            Lua3D.system.on_window_resize:Fire(width,height)
        end
    end)

    --callbacks
    function self.load()
        print("There is no Lua3D.load() callback!")
    end

    function self.update(dt)
        print("There is no Lua3D.update() callback!")
    end

    function self.draw()
        print("There is no Lua3D.draw() callback!")
    end

    return self
end

--Methods
function Lua3D:start()
    startRenderLoop(self)
end

function Lua3D:render_scene(scene)
    self._renderer:draw_scene(scene,"triangles")
end

--Return
return Lua3D