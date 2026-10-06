local Vector3d = {}
Vector3d.__index = Vector3d
Vector3d.__type = "Vector3d"

local function isVector(vec)
    if type(vec)~="table" then return end
    if not vec.__type then return end
    if vec.__type ~= "Vector3d" then return end
    return true
end

--Constructors

function Vector3d.new(x,y,z)
    local self = setmetatable({},Vector3d)

    self.x = x
    self.y = y
    self.z = z

    return self
end

function Vector3d.Zero()
    return Vector3d.new(0,0,0)
end

function Vector3d.One()
    return Vector3d.new(1,1,1)
end

function Vector3d.fromRotation(rotation) --takes in rotation outputs direction
    local yaw,pitch = rotation.y,rotation.x
    return Vector3d.new(-math.sin(yaw) * math.cos(pitch),math.sin(pitch),-math.cos(yaw) * math.cos(pitch)):Unit()
end

function Vector3d.fromDirection(direction) --takes in direction outputs rotation
    if direction:Magnitude() == 0 then return Vector3d.Zero() end

    local direction = direction:Unit()
    local pitch = math.asin(math.max(-1,math.min(1,direction.y)))
    local yaw = math.atan(-direction.x,-direction.z)

    return Vector3d.new(pitch,yaw,0)
end

--Methods

function Vector3d:getDirection() 
    return Vector3d.fromEulerAngles(self)
end

function Vector3d:getRotation()
    print("before vec3 toeulerangles method")
    local rotation = Vector3d.fromDirection(Vector3d.new(self.x,self.y,self.z))
    print("after")

    return rotation
end

function Vector3d:Magnitude()
    return math.sqrt(self.x*self.x + self.y*self.y + self.z*self.z)
end

function Vector3d:Mag()
    return self:Magnitude()
end

function Vector3d:Unit()
    local mag = self:Mag()

    return Vector3d.new(self.x/mag,self.y/mag,self.z/mag)
end

function Vector3d:Cross(other)
    if not isVector(other) then return end

    return Vector3d.new(self.y*other.z-self.z*other.y,-(self.x*other.z-self.z*other.x),self.x*other.y-self.y*other.x)
end

function Vector3d:Dot(other)
    if not isVector(other) then return end

    return self.x*other.x + self.y*other.y + self.z*other.z
end

function Vector3d:flatten()
    return {self.x,self.y,self.z}
end

function Vector3d.__tostring(self)
    return "<"..self.x..", "..self.y..", "..self.z..">"
end

function Vector3d.__add(self,other)
    if not isVector(other) then return end

    return Vector3d.new(self.x+other.x,self.y+other.y,self.z+other.z)
end

function Vector3d.__sub(self,other)
    if not isVector(other) then return end

    return Vector3d.new(self.x-other.x,self.y-other.y,self.z-other.z)
end

function Vector3d.__mul(self,other)
    if type(other) ~= "number" then return end

    return Vector3d.new(self.x*other,self.y*other,self.z*other)
end

return Vector3d