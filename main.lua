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
local Scene = require("engine/scene")
local Model = require("engine/model")
local Renderer = require("engine/renderer")

--Constants
local move_speed = 3.0
local turn_speed = 1.0

local window_width = 1280
local window_height = 720

print("Creating scene...")

local scene = Scene.new()

--Dynamics
local window
local cam
local previous_time = 0

local mouse_locked = true
local simulation_paused = false
local first_mouse_event = true
local previous_mouse_x = 0
local previous_mouse_y = 0
local escape_was_down = false

local function createGLFWWindow()
    glfw.window_hint("context version major", 3)
    glfw.window_hint("context version minor", 3)
    glfw.window_hint("opengl profile", "core")
    glfw.window_hint("depth bits",24)

    print("Creating window...")

    window = glfw.create_window(window_width, window_height, "Lua Engine")

    assert(window, "Failed to create window")

    glfw.make_context_current(window)

    glfw.set_input_mode(
        window,
        "cursor",
        "disabled"
    )

    glfw.swap_interval(0)

    gl.init()

    gl.enable("depth test")
    gl.enable("cull face")
    gl.cull_face("back")
    gl.clear_depth(1.0)

    gl.viewport(0, 0, window_width, window_height)

    glfw.set_window_size_callback(window, function(_, width, height)
        gl.viewport(0, 0, width, height)
        scene.camera:set_aspect_ratio(width/height)
    end)

    glfw.set_cursor_pos_callback(
        window,
        function(_, mouse_x, mouse_y)
            if not mouse_locked then
                return
            end

            if first_mouse_event then
                previous_mouse_x = mouse_x
                previous_mouse_y = mouse_y
                first_mouse_event = false
                return
            end

            local delta_x =
                mouse_x - previous_mouse_x

            local delta_y =
                mouse_y - previous_mouse_y

            previous_mouse_x = mouse_x
            previous_mouse_y = mouse_y

            scene.camera:gimble(delta_x, delta_y)
        end
    )

    glfw.set_mouse_button_callback(
        window,
        function(_, button, action)
            if button == "left"
            and action == "press"
            and not mouse_locked then

                mouse_locked = true
                simulation_paused = false
                first_mouse_event = true

                glfw.set_input_mode(
                    window,
                    "cursor",
                    "disabled"
                )
            end
        end
    )
end

createGLFWWindow()

print("Creating materials...")

Materials.load()

print("Creating shader program...")

local renderer = Renderer.new()

print("Positioning camera...")

scene.camera:set_position(0,0,5)
scene.camera:set_aspect_ratio(window_width/window_height)

print("Creating objects, lights, and meshes...")

local newPointLight = Light.newPointLight()
newPointLight:set_color(Vector3d.new(1,0,0))
newPointLight:set_position(Vector3d.new(1,0,0))
newPointLight:set_intensity(24)
scene:add("pointLight1",newPointLight)

local newPointLight2 = Light.newPointLight()
newPointLight2:set_color(Vector3d.new(0,1,0))
newPointLight2:set_position(Vector3d.new(1,0,0))
newPointLight2:set_intensity(48)
scene:add("pointLight2",newPointLight2)

local sphereMesh = Mesh.fromOBJ("assets/models/sphere.obj")
--local ironManModel = Model.fromOBJ("assets/models/IronMan.obj")
local monkeyMesh = Mesh.fromOBJ("assets/models/blender_monkey.obj")
--local ironManMesh = Mesh.fromOBJ("assets/models/IronMan.obj")
--local cubeObjMesh = Mesh.fromOBJ("assets/models/cube.obj")
--local humanMesh = Mesh.fromOBJ("assets/models/FinalBaseMesh.obj")

local leftCube = Object3d.new(monkeyMesh,Materials.Ice)
leftCube:set_position(-3,0,0)
scene:add("left",leftCube)

local rightCube = Object3d.new(sphereMesh,Materials.Crate)
rightCube:set_position(3,0,0)
rightCube:set_scale(1,1,1)
scene:add("right",rightCube)

local middleCube = Object3d.new(monkeyMesh,Materials.Crate)
middleCube:set_position(0,0,-3)
middleCube:set_scale(1,1,1)
scene:add("middle",middleCube)

for i=1,5 do
    for j=1,5 do
        for k=1,5 do
            local newModel = Object3d.new(sphereMesh)
            newModel:set_position((i)-3,(j)-3,(k)-3)
            scene:add("Sphere"..i*25+j*5+k,newModel)
        end
        
    end
end

print("Entering render loop...")

local fpsUpdateEvery = 0.5
local lastUpdate = 0
local frames = 0
local fpsSmoothing = 1
local FPS = 0

while not glfw.window_should_close(window) do
    glfw.poll_events()

    local escape_down =
        glfw.get_key(window, "escape") == "press"

    if escape_down and not escape_was_down then
        simulation_paused = not simulation_paused
        mouse_locked = not simulation_paused
        first_mouse_event = true

        if mouse_locked then
            glfw.set_input_mode(
                window,
                "cursor",
                "disabled"
            )
        else
            glfw.set_input_mode(
                window,
                "cursor",
                "normal"
            )
        end
    end

    escape_was_down = escape_down

    local current_time = glfw.get_time()
    local dt = current_time - previous_time
    previous_time = current_time

    frames = frames + 1

    FPS = Common.lerp(FPS,1/dt,fpsSmoothing * dt)

    scene:update(dt)

    local distance = move_speed * dt

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
        scene.camera:rotate(0, turn_speed * dt, 0)
    end

    if glfw.get_key(window, "right") == "press" then
        scene.camera:rotate(0, -turn_speed * dt, 0)
    end

    local vertical_input = 0

    if glfw.get_key(window, "space") == "press" then
        vertical_input = vertical_input + 1
    end

    if glfw.get_key(window, "left shift") == "press" then
        vertical_input = vertical_input - 1
    end

    local yaw = scene.camera.rotation.y

    local forward_x = -math.sin(yaw)
    local forward_z = -math.cos(yaw)

    local right_x = math.cos(yaw)
    local right_z = -math.sin(yaw)

    local movement_x = (forward_x * forward_input + right_x * strafe_input) * dt * move_speed
    local movement_z = (forward_z * forward_input + right_z * strafe_input) * dt * move_speed
    local movement_y = vertical_input * dt * move_speed

    scene.camera:move(movement_x, movement_y, movement_z)

    gl.clear_color(0.1, 0.1, 0.15, 1.0)
    gl.clear("color","depth")

    for _,object in pairs(scene.objects) do
        object:set_rotation(math.sin(current_time), math.cos(current_time) * 2, 0)
    end

    local lightPos = Vector3d.new(1*math.sin(current_time),1*math.cos(current_time),1*math.cos(current_time))
    --print(lightPos)
    scene.lights["pointLight1"]:set_position(lightPos)
    scene.objects["middle"]:set_position(lightPos)
    --scene.lights["pointLight2"]:set_position(Vector3d.new(1*math.sin(current_time/3),1*math.cos(current_time),1*math.cos(current_time/2)))

    local total_objects,culled_objects,total_meshes_drawn = renderer:draw_scene(scene,"triangles")

    if current_time > lastUpdate then
        lastUpdate = lastUpdate + fpsUpdateEvery
        print("FPS: "..math.floor(FPS))
        print("Objects: "..total_objects-culled_objects.." + "..culled_objects.." / "..total_objects)
        print("Total Meshes Drawn: "..total_meshes_drawn)
        print("Camera Position: "..scene.camera.position.x..", "..scene.camera.position.y..", "..scene.camera.position.z)
    end

    glfw.swap_buffers(window)
end

scene:destroy()
renderer:destroy()
glfw.destroy_window(window)

print("Program ended.")