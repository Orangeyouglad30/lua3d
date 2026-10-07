--Libraries
local Vector3d = require("math/vector3d")
local Transform = require("engine/transform")

--Constants

--Dynamics

--Functions
local function isCFrame(cframe)
    if type(cframe) ~= "table" then return end
    if not cframe.__type then return end
    if cframe.__type ~= "CFrame" then return end
    return true
end

local function isVector3d(vec)
    if type(vec)~="table" then return end
    if not vec.__type then return end
    if vec.__type ~= "Vector3d" then return end
    return true
end

--Constructors
local CFrame = {}
CFrame.__index = CFrame
CFrame.__type = "CFrame"

function CFrame.new(arg1,arg2,arg3,arg4,arg5,arg6)
    local self = setmetatable({},CFrame)

    local arg1 = arg1 or 0
    local arg2 = arg2 or 0
    local arg3 = arg3 or 0
    local arg4 = arg4 or 0
    local arg5 = arg5 or 0
    local arg6 = arg6 or 0

    if type(arg1) == "number" and type(arg2) == "number" and type(arg3) == "number" then --if arg1,arg2, and arg3 are x, y, and z respectively
        self.position = Vector3d.new(arg1,arg2,arg3)
        self.rotation = Vector3d.new(arg4,arg5,arg6)
    elseif type(arg1) == "table" and arg1.__type and arg1.__type == "Vector3d" then --arg1 is a vector3d
        if type(arg2) == "table" and arg2.__type and arg2.__type == "Vector3d" then --if arg1 and arg2 are both vector3d
            self.position = arg1
            self.rotation = arg2
        else --if just arg1 is a vector3d
            self.position = arg1
            self.rotation = Vector3d.new(0,0,0)
        end
    end

    return self
end

function CFrame.lookAt(position,looking_at)
    local self = setmetatable({},CFrame)

    self.position = position
    self.rotation = Vector3d.fromDirection(looking_at - position)

    return self
end

function CFrame.lookInDirection(position,direction)
    local self = setmetatable({},CFrame)

    self.position = position
    self.rotation = Vector3d.fromDirection(direction)
    
    return self
end

function CFrame.Angles(x,y,z)
    return CFrame.new(Vector3d.Zero(),Vector3d(x,y,z))
end

function CFrame.from_matrix(matrix)
    local m = matrix._matrix
    local position = Vector3d.new(m[1][4],m[2][4],m[3][4])
    local pitch = math.asin(math.max(-1,math.min(1,-m[2][3])))
    local yaw = math.atan(m[1][3],m[3][3])
    local roll = math.atan(m[2][1],m[2][2])

    return CFrame.new(position,Vector3d.new(pitch,yaw,roll))
end

--Methods
function CFrame:get_position()
    return self.position
end

function CFrame:get_rotation()
    return self.rotation
end

function CFrame:get_direction()
    return Vector3d.fromRotation(self.rotation)
end

function CFrame:to_matrix()
    return Transform.translation(self.position.x,self.position.y,self.position.z) * Transform.rotation_y(self.rotation.y) * Transform.rotation_x(self.rotation.x) * Transform.rotation_z(self.rotation.z)
end

function CFrame:get_forward()
    local yaw,pitch = self.rotation.y,self.rotation.x

    local forward = Vector3d.new(
        -math.sin(yaw) * math.cos(pitch),
        math.sin(pitch),
        -math.cos(yaw) * math.cos(pitch)
    ):Unit()

    return forward
end

function CFrame:get_right()
    local yaw,pitch = self.rotation.y,self.rotation.x

    local forward = Vector3d.new(
        -math.sin(yaw) * math.cos(pitch),
        math.sin(pitch),
        -math.cos(yaw) * math.cos(pitch)
    ):Unit()

    local world_up = Vector3d.new(0,1,0)
    local right = forward:Cross(world_up):Unit()

    return right
end

function CFrame:get_up()
    local yaw,pitch = self.rotation.y,self.rotation.x

    local forward = Vector3d.new(
        -math.sin(yaw) * math.cos(pitch),
        math.sin(pitch),
        -math.cos(yaw) * math.cos(pitch)
    ):Unit()

    local world_up = Vector3d.new(0,1,0)
    local right = forward:Cross(world_up):Unit()
    local up = right:Cross(forward):Unit()

    return up
end

function CFrame:get_basis()
    local yaw,pitch = self.rotation.y,self.rotation.x

    local forward = Vector3d.new(
        -math.sin(yaw) * math.cos(pitch),
        math.sin(pitch),
        -math.cos(yaw) * math.cos(pitch)
    ):Unit()

    local world_up = Vector3d.new(0,1,0)
    local right = forward:Cross(world_up):Unit()
    local up = right:Cross(forward):Unit()

    return right,up,forward
end

function CFrame:PointToWorldSpace(point)
    local m = self:to_matrix()._matrix

    return Vector3d.new(
        m[1][1] * point.x + m[1][2] * point.y + m[1][3] * point.z + m[1][4],
        m[2][1] * point.x + m[2][2] * point.y + m[2][3] * point.z + m[2][4],
        m[3][1] * point.x + m[3][2] * point.y + m[3][3] * point.z + m[3][4]
    )
end

function CFrame.__mul(self,other)
    if isCFrame(other) then
        return CFrame.from_matrix(self:to_matrix() * other:to_matrix())
    elseif isVector3d(other) then
        return self:PointToWorldSpace(other)
    end

    error("CFrame can only multiply by another CFrame or Vector3d")
end

--Return
return CFrame