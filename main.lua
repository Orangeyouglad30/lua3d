local Lua3D = require("lua3d")
local Engine = Lua3D.initialize(1280,720)

local CFrame = Lua3D.math.cframe
local Vector3d = Lua3D.math.vector3d
local Input = Lua3D.system.input

local newScene

function Engine.load()
    newScene = Lua3D.graphics.scene.new()
    newScene.camera.CFrame = CFrame.lookAt(Vector3d.new(0,0,5),Vector3d.new(0,0,0))

    local monkeyMesh = Lua3D.graphics.mesh.fromOBJ("assets/models/blender_monkey.obj")
    local monkeyObject = Lua3D.graphics.object3d.new(monkeyMesh)
    monkeyMesh.position = (Vector3d.new(0,0,0))

    newScene:add("Monkey",monkeyObject)
end

local fpsUpdateEvery = 0.25
local lastUpdate = 0
local frames = 0
local fpsSmoothing = 1
local FPS = 0

local CAMERA_SPEED = 3
local SENSITIVITY = 20

function Engine.update(dt)
    FPS = Lua3D.math.common.lerp(FPS,1/dt,fpsSmoothing * dt)

    if Engine.elapsed_time > lastUpdate then
        lastUpdate = lastUpdate + fpsUpdateEvery
        print("FPS: "..math.floor(FPS))
    end

    --newScene.objects["Monkey"].rotation = Lua3D.math.vector3d.new(math.sin(Engine.elapsed_time),math.cos(Engine.elapsed_time),2*math.sin(Engine.elapsed_time))

    local strafe_movement = 0
    local forward_movement = 0
    local vertical_movement = 0

    if Input:is_key_down("w") then forward_movement = forward_movement + 1 end
    if Input:is_key_down("s") then forward_movement = forward_movement - 1 end

    if Input:is_key_down("a") then strafe_movement = strafe_movement - 1 end
    if Input:is_key_down("d") then strafe_movement = strafe_movement + 1 end

    if Input:is_key_down("space") then vertical_movement = vertical_movement + 1 end
    if Input:is_key_down("left shift") then vertical_movement = vertical_movement - 1 end

    newScene.camera.CFrame = newScene.camera.CFrame * CFrame.new(0,0,-forward_movement*dt*CAMERA_SPEED) * CFrame.new(strafe_movement*dt*CAMERA_SPEED,0,0) * CFrame.new(0,vertical_movement*dt*CAMERA_SPEED,0)

    if Input:is_mouse_button_down("left") then
        Input:lock_mouse()
    end

    if Input:is_key_down("escape") then
        Input:unlock_mouse()
    end

    if Input:is_mouse_locked() then
        newScene.camera:gimble(SENSITIVITY*math.rad(-Input._mouse_position_delta.x),SENSITIVITY*math.rad(-Input._mouse_position_delta.y))
    end
end

function Engine.draw()
    Engine:render_scene(newScene)
end

Engine:start()