--Libraries
local Connection = require("engine/connection")

--Constants

--Dynamics

--Functions
local function isConnection(object)
    if type(object) ~= "table" then return end
    if not object.__type then return end
    if object.__type ~= "Connection" then return end
    return true
end

--Constructors
local Signal = {}
Signal.__index = Signal

function Signal.new()
    local self = setmetatable({},Signal)

    self._connections = {}

    return self
end

--Methods
function Signal:Connect(callback)
    local newConnection = Connection.new(callback)

    table.insert(self._connections,newConnection)

    return newConnection
end

function Signal:Fire(...)
    for _,connection in pairs(self._connections) do
        connection:Fire(...)
    end
end

function Signal:DisconnectAll()
    for _,connection in pairs(self._connections) do
        connection:Disconnect()
    end
end

--Return
return Signal