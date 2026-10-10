--Libraries
local Signal = require("engine/signal")

--Constants
local Input

--Dynamics

--Functions

--Constructors
local Action = {}
Action.__index = Action

function Action._set_input_instance(input_instance)
    Input = input_instance
end

function Action.new(action_name,contexts)
    if not action_name then return end

    local self = setmetatable({},Action)

    self.keys = nil
    self.plus_keys = nil
    self.minus_keys = nil
    self.action = action_name
    self.contexts = contexts or "any"
    self.Activated = Signal.new()
    self.Deactivated = Signal.new()
    self._type = "normal"

    return self
end

function Action.newAxisAction(action_name,contexts)
    if not action_name then return end

    local self = setmetatable({},Action)

    self.keys = nil
    self.plus_keys = nil
    self.minus_keys = nil
    self.action = action_name
    self.contexts = contexts or "any"
    self.Activated = Signal.new()
    self.Deactivated = Signal.new()
    self._type = "axis"
    self.value = 0

    return self
end

--Methods
function Action:bind_keys(plus_keys,minus_keys)
    if not plus_keys then return end
    
    if type(plus_keys) ~= "table" then plus_keys = {plus_keys} end

    if self._type == "normal" then
        self.keys = plus_keys
    elseif self._type == "axis" then
        if not minus_keys then return end

        if type(minus_keys) ~= "table" then minus_keys = {minus_keys} end

        self.plus_keys = plus_keys
        self.minus_keys = minus_keys
    end
end

function Action:set_contexts(contexts)
    contexts = contexts or "any"

    self.contexts = contexts

    Input._dirty_actions_in_context = true
end

function Action:get_type()
    return self._type
end

--Return
return Action