package.path =
    "./vendor/lua/?.lua;" ..
    "./vendor/lua/?/init.lua;" ..
    package.path

package.cpath =
    "./vendor/bin/?.dll;" ..
    package.cpath

print("Running project...")

--Libraries
local gl = require("moongl")
local glfw = require("moonglfw")
local Mesh = require("engine/mesh")
local Shader = require("engine/shader")
local Transform = require("engine/transform")
local Matrix = require("math/matrix")
local Camera = require("engine/camera")
local Vector3d = require("math/vector3d")
local Vector2d = require("math/vector2d")
local Light = require("engine/light")
local Object3d = require("engine/object3d")
local Material = require("engine/material")
local Textures = require("engine/textures")
local Materials = require("engine/materials")
local Common = require("math/common")

--Constants
local field_of_view = math.rad(70)
local aspect_ratio = 1
local near_distance = 0.1
local far_distance = 300
local camera_distance = 5

local move_speed = 3.0
local turn_speed = 1.0

local lighting = Light.new()

lighting:set_direction(Vector3d.new(0,-1,-1):Unit())
lighting:set_color(Vector3d.new(1,1,1))
lighting:set_intensity(1)

--Dynamics
local window
local cam
local previous_time = 0

local function createGLFWWindow()
    glfw.window_hint("context version major", 3)
    glfw.window_hint("context version minor", 3)
    glfw.window_hint("opengl profile", "core")
    glfw.window_hint("depth bits",24)

    print("Creating window...")

    window = glfw.create_window(800, 800, "Lua Engine")

    assert(window, "Failed to create window")

    glfw.make_context_current(window)

    glfw.make_context_current(window)

    glfw.swap_interval(0)

    gl.init()

    gl.enable("depth test")
    gl.clear_depth(1.0)

    gl.viewport(0, 0, 800, 800)

    glfw.set_window_size_callback(window, function(_, width, height)
        gl.viewport(0, 0, width, height)
        cam:set_aspect_ratio(width/height)
    end)
end

createGLFWWindow()

print("Creating materials...")

Materials.load()

print("Creating shader program...")

local shader = Shader.new(
    "shaders/basic.vert",
    "shaders/basic.frag"
)

print("Creating camera...")

cam = Camera.new(field_of_view,aspect_ratio,near_distance,far_distance)
cam:set_position(0,0,camera_distance)

print("Creating objects and meshes...")

local function add_vertex(vertices, position, color, normal,uv)
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

local function add_face(vertices, indices, a, b, c, d, color)
    -- The first vertex index for this face.
    -- Indices are zero-based because OpenGL uses zero-based indices.
    local base_index = #vertices / 11

    local vec1 = Vector3d.new(b[1]-a[1],b[2]-a[2],b[3]-a[3])
    local vec2 = Vector3d.new(c[1]-a[1],c[2]-a[2],c[3]-a[3])
    local normal = vec2:Cross(vec1):Unit():flatten()

    -- Add each face corner once.
    add_vertex(vertices, a, color, normal, Vector2d.new(0,1):flatten())
    add_vertex(vertices, b, color, normal, Vector2d.new(1,1):flatten())
    add_vertex(vertices, c, color, normal, Vector2d.new(1,0):flatten())
    add_vertex(vertices, d, color, normal, Vector2d.new(0,0):flatten())

    -- Two triangles:
    -- a, b, c
    -- a, c, d
    indices[#indices + 1] = base_index
    indices[#indices + 1] = base_index + 1
    indices[#indices + 1] = base_index + 2

    indices[#indices + 1] = base_index
    indices[#indices + 1] = base_index + 2
    indices[#indices + 1] = base_index + 3
end

local red    = {1.0, 0.0, 0.0}
local green  = {0.0, 1.0, 0.0}
local blue   = {0.0, 0.0, 1.0}
local yellow = {1.0, 1.0, 0.0}
local cyan   = {0.0, 1.0, 1.0}
local purple = {1.0, 0.0, 1.0}
local gray   = {0.5, 0.5, 0.5}

local vertices = {}
local indices = {}

add_face(
    vertices,
    indices,
    {-0.5,  0.5,  0.5},
    { 0.5,  0.5,  0.5},
    { 0.5, -0.5,  0.5},
    {-0.5, -0.5,  0.5},
    red
)

add_face(
    vertices,
    indices,
    { 0.5,  0.5, -0.5},
    {-0.5,  0.5, -0.5},
    {-0.5, -0.5, -0.5},
    { 0.5, -0.5, -0.5},
    green
)

add_face(
    vertices,
    indices,
    {-0.5,  0.5, -0.5},
    {-0.5,  0.5,  0.5},
    {-0.5, -0.5,  0.5},
    {-0.5, -0.5, -0.5},
    blue
)

add_face(
    vertices,
    indices,
    { 0.5,  0.5,  0.5},
    { 0.5,  0.5, -0.5},
    { 0.5, -0.5, -0.5},
    { 0.5, -0.5,  0.5},
    yellow
)

add_face(
    vertices,
    indices,
    {-0.5,  0.5, -0.5},
    { 0.5,  0.5, -0.5},
    { 0.5,  0.5,  0.5},
    {-0.5,  0.5,  0.5},
    purple
)

add_face(
    vertices,
    indices,
    {-0.5, -0.5,  0.5},
    { 0.5, -0.5,  0.5},
    { 0.5, -0.5, -0.5},
    {-0.5, -0.5, -0.5},
    cyan
)

local cubeMesh = Mesh.new(vertices, indices)
local monkeyMesh = Mesh.createFromObj("assets/models/blender_monkey.obj")
local cubeObjMesh = Mesh.createFromObj("assets/models/cube.obj")

local leftCube = Object3d.new(monkeyMesh,Materials.Ice)
leftCube:set_position(-3,0,0)

local rightCube = Object3d.new(monkeyMesh,Materials.Brick)
rightCube:set_position(3,0,0)
rightCube:set_scale(2,1,4)

local middleCube = Object3d.new(monkeyMesh,Materials.Crate)
middleCube:set_position(0,0,-3)
middleCube:set_scale(1,1,1)

local objects = {rightCube,leftCube,middleCube}

print("Entering render loop...")

local fpsUpdatePeriodic = 300
local frames = 0
local fpsSmoothing = 0.001
local FPS = 0

while not glfw.window_should_close(window) do
    glfw.poll_events()

    local current_time = glfw.get_time()
    local delta_time = current_time - previous_time
    previous_time = current_time

    frames = frames + 1

    FPS = Common.lerp(FPS,1/delta_time,fpsSmoothing)

    if frames%fpsUpdatePeriodic == 0 then
        print("FPS: "..math.floor(FPS))
    end

    local distance = move_speed * delta_time

    local forward_input = 0
    local strafe_input = 0

    if glfw.get_key(window, "w") == "press" then
        forward_input = forward_input + 1
    end

    if glfw.get_key(window, "s") == "press" then
        forward_input = forward_input - 1
    end

    if glfw.get_key(window, "a") == "press" then
        strafe_input = strafe_input - 1
    end

    if glfw.get_key(window, "d") == "press" then
        strafe_input = strafe_input + 1
    end

    if glfw.get_key(window, "left") == "press" then
        cam:rotate(0, turn_speed * delta_time, 0)
    end

    if glfw.get_key(window, "right") == "press" then
        cam:rotate(0, -turn_speed * delta_time, 0)
    end

    local yaw = cam.rotation.y

    local forward_x = -math.sin(yaw)
    local forward_z = -math.cos(yaw)

    local right_x = math.cos(yaw)
    local right_z = -math.sin(yaw)

    local movement_x =
        (forward_x * forward_input + right_x * strafe_input)
        * delta_time
        * move_speed

    local movement_z =
        (forward_z * forward_input + right_z * strafe_input)
        * delta_time
        * move_speed

    cam:move(movement_x, 0, movement_z)

    gl.clear_color(0.1, 0.1, 0.15, 1.0)
    gl.clear("color","depth")

    shader:use()

    shader:set_lighting(lighting)

    shader:set_matrix("projection", cam:get_projection())
    
    shader:set_matrix("view", cam:get_view())

    shader:set_vector3(
        "viewPosition",
        cam.position
    )

    for _, object in pairs(objects) do
        object:set_rotation(math.sin(current_time), math.cos(current_time) * 2, 0)

        object:draw(shader,"triangles")
    end

    glfw.swap_buffers(window)
end

glfw.destroy_window(window)

print("Program ended.")