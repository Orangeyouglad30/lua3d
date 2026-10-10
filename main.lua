local Lua3D = require("lua3d")
local Engine = Lua3D.initialize(1280,720)

local CFrame = Lua3D.math.cframe
local Vector3d = Lua3D.math.vector3d
local Input = Lua3D.system.input

local newScene

function Engine.load()
    newScene = Lua3D.graphics.scene.new()
    newScene.camera.CFrame = CFrame.lookAt(Vector3d.new(0,0,5),Vector3d.new(0,0,0))

    local testMaterial = Lua3D.graphics.material.new(
        nil,
        16,
        0.0,
        Vector3d.One(),
        Vector3d.One(),
        Vector3d.One()
    )

    local monkeyMesh = Lua3D.graphics.mesh.fromOBJ("assets/models/blender_monkey.obj")--,Lua3D.graphics.materials.Ice)
    local monkeyObject = Lua3D.graphics.object3d.new(monkeyMesh)--testMaterial)
    monkeyObject.position = (Vector3d.new(2,0,0))

    local ironManModel = Lua3D.graphics.model.fromOBJ("assets/models/IronMan.obj")
    local ironManObject = Lua3D.graphics.object3d.new(ironManModel)--,testMaterial)
    ironManObject:set_position(Vector3d.new(0,0,0))

    local pointLight1 = Lua3D.graphics.light.newPointLight()
    pointLight1:set_position(Vector3d.new(1,0,0))
    pointLight1:set_intensity(24)
    pointLight1:set_color(Vector3d.new(0,1,0))

    newScene:add("pointLight1",pointLight1)
    newScene:add("Monkey",monkeyObject)
    newScene:add("Iron Man",ironManObject)

    for i=0,9 do
        for j=1,10 do
            local newModel = Lua3D.graphics.object3d.new(monkeyMesh)
            newModel:set_position(Vector3d.new(i*2,0,j*2)+Vector3d.new(-10,0,-25))
            newScene:add("IronMan"..i*10+j,newModel)
        end
    end
end

local fpsUpdateEvery = 0.5
local lastUpdate = fpsUpdateEvery
local frames = 0
local fpsSmoothing = 1
local FPS = 0

local CAMERA_SPEED = 3
local SENSITIVITY = 20

local DO_BENCHMARK = false
local BENCHMARK_UNTIL = 5

local strafe_movement = 0
local forward_movement = 0
local vertical_movement = 0

local FORWARD_ACTION = Input:create_axis_action("forward"):bind_keys("w","s").Activated:Connect(function(value) forward_movement = value end)
local STRAFE_ACTION = Input:create_axis_action("strafe"):bind_keys("d","a").Activated:Connect(function(value) strafe_movement = value end)
local VERTICAL_ACTION = Input:create_axis_action("vertical"):bind_keys("space","left shift").Activated:Connect(function(value) vertical_movement = value end)

local QUIT_ACTION = Input:create_action("quit"):bind_keys("q").Activated:Connect(function() Engine:stop() end)

function Engine.update(dt)
    frames = frames + 1

    FPS = Lua3D.math.common.lerp(FPS,1/dt,fpsSmoothing * dt)

    if Engine.elapsed_time > lastUpdate then
        lastUpdate = lastUpdate + fpsUpdateEvery
        print("FPS: "..math.floor(FPS))
    end

    for _,object in pairs(newScene.objects) do
        object:set_rotation(Vector3d.new(math.sin(Engine.elapsed_time),math.cos(Engine.elapsed_time),2*math.sin(Engine.elapsed_time)))
    end
    --newScene.objects["Iron Man"]:set_rotation(Lua3D.math.vector3d.new(math.sin(Engine.elapsed_time),math.cos(Engine.elapsed_time),2*math.sin(Engine.elapsed_time)))
    
    if forward_movement~=0 or strafe_movement~=0 or vertical_movement~=0 then
        local camera = newScene.camera
        local right, up, forward = camera.CFrame:get_basis()

        local movement =
            forward * (forward_movement * dt * CAMERA_SPEED) +
            right * (strafe_movement * dt * CAMERA_SPEED) +
            up * (vertical_movement * dt * CAMERA_SPEED)

        camera:move(movement)

        --newScene.camera.CFrame = newScene.camera.CFrame * CFrame.new(strafe_movement*dt*CAMERA_SPEED,vertical_movement*dt*CAMERA_SPEED,-forward_movement*dt*CAMERA_SPEED)
        --newScene.camera.CFrame = newScene.camera.CFrame * CFrame.new(0,0,-forward_movement*dt*CAMERA_SPEED) * CFrame.new(strafe_movement*dt*CAMERA_SPEED,0,0) * CFrame.new(0,vertical_movement*dt*CAMERA_SPEED,0)
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