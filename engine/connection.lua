--Libraries

--Constants

--Dynamics

--Functions

--Constructors
local Connection = {}
Connection.__index = Connection
Connection.__type = "Connection"

function Connection.new(callback)
    local self = setmetatable({},Connection)

    self._callback = callback

    return self
end

--Methods
function Connection:Fire(...)
    self._callback(...)
end

function Connection:Disconnect()
    self = nil
end

--Return
return Connection