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

    local ironManModel = Lua3D.graphics.model.fromOBJ("assets/models/IronMan.obj")
    local ironManObject = Lua3D.graphics.object3d.new(ironManModel)
    ironManObject:set_position(Vector3d.new(2,0,0))

    local pointLight1 = Lua3D.graphics.light.newPointLight()
    pointLight1:set_position(Vector3d.new(1,0,0))
    pointLight1:set_intensity(10)
    pointLight1:set_color(Vector3d.new(0,1,0))

    newScene:add("pointLight1",pointLight1)
    newScene:add("Monkey",monkeyObject)
    newScene:add("Iron Man",ironManObject)
end

local fpsUpdateEvery = 10
local lastUpdate = fpsUpdateEvery
local frames = 0
local fpsSmoothing = 1
local FPS = 0

local CAMERA_SPEED = 3
local SENSITIVITY = 20

local DO_BENCHMARK = true
local BENCHMARK_UNTIL = 5

local strafe_movement = 0
local forward_movement = 0
local vertical_movement = 0

Input.key_pressed:Connect(function(key)
    if key=="w" then forward_movement = forward_movement + 1 end
    if key=="s" then forward_movement = forward_movement - 1 end
    if key=="a" then strafe_movement = strafe_movement - 1 end
    if key=="d" then strafe_movement = strafe_movement + 1 end
    if key=="space" then vertical_movement = vertical_movement + 1 end
    if key=="left shift" then vertical_movement = vertical_movement - 1 end
end)

Input.key_released:Connect(function(key)
    if key=="w" then forward_movement = forward_movement - 1 end
    if key=="s" then forward_movement = forward_movement + 1 end
    if key=="a" then strafe_movement = strafe_movement + 1 end
    if key=="d" then strafe_movement = strafe_movement - 1 end
    if key=="space" then vertical_movement = vertical_movement - 1 end
    if key=="left shift" then vertical_movement = vertical_movement + 1 end
end)

function Engine.update(dt)
    frames = frames + 1

    FPS = Lua3D.math.common.lerp(FPS,1/dt,fpsSmoothing * dt)

    if Engine.elapsed_time > lastUpdate then
        lastUpdate = lastUpdate + fpsUpdateEvery
        print("FPS: "..math.floor(FPS))
    end

    newScene.objects["Iron Man"]:set_rotation(Lua3D.math.vector3d.new(math.sin(Engine.elapsed_time),math.cos(Engine.elapsed_time),2*math.sin(Engine.elapsed_time)))

    if forward_movement~=0 or strafe_movement~=0 or vertical_movement~=0 then
        newScene.camera.CFrame = newScene.camera.CFrame * CFrame.new(0,0,-forward_movement*dt*CAMERA_SPEED) * CFrame.new(strafe_movement*dt*CAMERA_SPEED,0,0) * CFrame.new(0,vertical_movement*dt*CAMERA_SPEED,0)
    end
    
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
    Engine:render_scene(newScene,true)

    if Engine.elapsed_time > BENCHMARK_UNTIL and DO_BENCHMARK then
        print("Total frames: "..frames)
        Engine:stop()
    end
end

Engine:start()