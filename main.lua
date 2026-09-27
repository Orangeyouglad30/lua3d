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

--Constants
local field_of_view = math.rad(70)
local aspect_ratio = 1
local near_distance = 0.1
local far_distance = 10
local camera_distance = 5

local move_speed = 3.0
local turn_speed = 1.0

local lighting = Light.new()

lighting:set_direction(Vector3d.new(0,0,-1):Unit())
lighting:set_color(Vector3d.new(1,1,1))
lighting:set_intensity(1)

--Dynamics
local window
local cam
local previous_time = 0
local texture

local function createGLFWWindow()
    glfw.window_hint("context version major", 3)
    glfw.window_hint("context version minor", 3)
    glfw.window_hint("opengl profile", "core")
    glfw.window_hint("depth bits",24)

    print("Creating window...")

    window = glfw.create_window(800, 800, "Lua Engine")

    assert(window, "Failed to create window")

    glfw.make_context_current(window)

    gl.init()

    local mi = require("moonimage")

    local image, width, height = mi.load(
        "assets/textures/crate1_diffuse.png",
        "rgb"
    )

    assert(image, "Failed to load texture")

    texture = gl.new_texture("2d")

    gl.bind_texture("2d", texture)

    gl.texture_parameter("2d", "wrap s", "repeat")
    gl.texture_parameter("2d", "wrap t", "repeat")
    gl.texture_parameter("2d", "min filter", "linear")
    gl.texture_parameter("2d", "mag filter", "linear")

    gl.texture_image(
        "2d",
        0,
        "rgb",
        "rgb",
        "ubyte",
        image,
        width,
        height
    )

    gl.generate_mipmap("2d")
    gl.unbind_texture("2d")

    gl.enable("depth test")
    gl.clear_depth(1.0)

    gl.viewport(0, 0, 800, 800)

    glfw.set_window_size_callback(window, function(_, width, height)
        gl.viewport(0, 0, width, height)
        cam:set_aspect_ratio(width/height)
    end)
end

createGLFWWindow()

print("Creating shader program...")

local shader = Shader.new(
    "shaders/basic.vert",
    "shaders/basic.frag"
)

print("Creating camera...")

cam = Camera.new(field_of_view,aspect_ratio,near_distance,far_distance)
cam:set_position(0,0,camera_distance)

print("Creating object...")

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
    local normal = vec1:Cross(vec2):Unit():flatten()

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

local newCube = Mesh.new(vertices, indices)

print("Entering render loop...")

while not glfw.window_should_close(window) do
    glfw.poll_events()

    local current_time = glfw.get_time()
    local delta_time = current_time - previous_time
    previous_time = current_time

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

    gl.active_texture(0)
    gl.bind_texture("2d", texture)

    shader:set_int("diffuseTexture", 0)

    shader:set_lighting(lighting)

    shader:set_matrix("projection", cam:get_projection())
    
    shader:set_matrix("view", cam:get_view())
    
    local model = Transform.translation(0,0,0) * Transform.rotation_y(current_time) * Transform.rotation_x(current_time*0.5)
    shader:set_matrix("model", model)
    
    newCube:draw("triangles")

    glfw.swap_buffers(window)
end

print("Program ended.")