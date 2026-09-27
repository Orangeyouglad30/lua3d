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

--Methods

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

return Vector3d