local Vector2d = {}
Vector2d.__index = Vector2d
Vector2d.__type = "Vector2d"

local function isVector(vec)
    if type(vec)~="table" then return end
    if not vec.__type then return end
    if vec.__type ~= "Vector2d" then return end
    return true
end

--Constructors

function Vector2d.new(x,y)
    local self = setmetatable({},Vector2d)

    self.x = x
    self.y = y

    return self
end

--Methods

function Vector2d:Magnitude()
    return math.sqrt(self.x*self.x + self.y*self.y)
end

function Vector2d:Mag()
    return self:Magnitude()
end

function Vector2d:Unit()
    local mag = self:Mag()

    return Vector2d.new(self.x/mag,self.y/mag)
end

function Vector2d:Dot(other)
    if not isVector(other) then return end

    return self.x*other.x + self.y*other.y
end

function Vector2d:flatten()
    return {self.x,self.y}
end

function Vector2d.__tostring(self)
    return "<"..self.x..", "..self.y..">"
end

return Vector2d