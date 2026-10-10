--Libraries
local glfw = require("moonglfw")
local Vector2d = require("math/vector2d")
local Signal = require("engine/signal")
local Action = require("engine/action")

--Constants

--Dynamics
local initialized = false

--Functions

--Constructors
local Input = {}
Input.__index = Input

function Input.new(window)
    if initialized then warn("Input is already initialized!") return end
    initialized = true

    local self = setmetatable({},Input)

    self._window = window
    self._pressed_keys = {}
    self._pressed_mouse_buttons = {}
    self._mouse_position = Vector2d.Zero()
    self._mouse_position_delta = Vector2d.Zero()
    self._mouse_scroll_delta = Vector2d.Zero()
    self._mouse_locked = false

    self.key_pressed = Signal.new()
    self.key_released = Signal.new()

    self.current_context = "any"

    self._actions = {}
    self._actions_in_context = {}

    self._dirty_actions_in_context = false

    glfw.set_key_callback(window, function(win, key, scancode, action, shift, control, alt, super)
        if action == "press" then
            self._pressed_keys[key] = true
            self.key_pressed:Fire(key)
        elseif action == "release" then
            self._pressed_keys[key] = false
            self.key_released:Fire(key)
        end

        if self._dirty_actions_in_context then
            self:_update_actions_in_context()
        end
        self._dirty_actions_in_context = false

        for actionName, actionObject in pairs(self._actions_in_context) do
            if actionObject._type == "normal" then
                for _,actionKey in pairs(actionObject.keys) do
                    if actionKey == key then
                        if action == "press" then
                            actionObject.Activated:Fire()
                        elseif action == "release" then
                            actionObject.Deactivated:Fire()
                        end
                        break
                    end 
                end
            elseif actionObject._type == "axis" then
                --TODO: FIX THIS
                for _,actionKey in pairs(actionObject.plus_keys) do
                    if actionKey == key then
                        if action == "press" then
                            actionObject.value = actionObject.value + 1
                        elseif action == "release" then
                            actionObject.value = actionObject.value - 1
                        end
                    end 
                end

                for _,actionKey in pairs(actionObject.minus_keys) do
                    if actionKey == key then
                        if action == "press" then
                            actionObject.value = actionObject.value - 1
                            break
                        elseif action == "release" then
                            actionObject.value = actionObject.value + 1
                        end
                    end 
                end

                if actionObject.value ~= 0 then
                    actionObject.Activated:Fire(actionObject.value)
                else
                    actionObject.Deactivated:Fire()
                end
            end
        end
    end)

    glfw.set_mouse_button_callback(window, function(win, button, action, shift, control, alt, super)
        if action == "press" then
            self._pressed_mouse_buttons[button] = true
        elseif action == "release" then
            self._pressed_mouse_buttons[button] = false
        end
    end)

    glfw.set_cursor_pos_callback(window, function(win, x, y)
        --self._mouse_position_delta = Vector2d.new(x,y) - self._mouse_position
        self._mouse_position = Vector2d.new(x,y)
    end)

    glfw.set_scroll_callback(window, function(window, xoffset, yoffset)
        self._mouse_scroll_delta = Vector2d.new(xoffset,yoffset)
    end)

    Action._set_input_instance(self)

    return self
end

--Methods
function Input:is_key_down(key)
    return self._pressed_keys[key]
end

function Input:is_mouse_button_down(button)
    return self._pressed_mouse_buttons[button] 
end

function Input:get_mouse_position()
    return self._mouse_position
end

function Input:get_mouse_position_delta()
    return self._mouse_position_delta
end

function Input:get_scroll_wheel_delta()
    return self._mouse_scroll_delta
end

function Input:is_mouse_locked()
    return self._mouse_locked
end

function Input:lock_mouse()
    if self._mouse_locked then return end

    glfw.set_input_mode(
        self._window,
        "cursor",
        "disabled"
    )

    self._mouse_locked = true
end

function Input:unlock_mouse()
    if not self._mouse_locked then return end

    glfw.set_input_mode(
        self._window,
        "cursor",
        "normal"
    )

    self._mouse_locked = false
end

function Input:_update_actions_in_context()
    self._actions_in_context = {}

    print("Updating actions in context!")

    for actionName,action in pairs(self._actions) do
        if action.contexts == "any" then
            self._actions_in_context[actionName] = action
        elseif type(action.contexts) == "string" and action.contexts == self.current_context then
            self._actions_in_context[actionName] = action
        elseif type(action.contexts) == "table" then
            for _,context in pairs(action.contexts) do
                if context == self.current_context then
                    self._actions_in_context[actionName] = action
                    break
                end
            end
        end
    end
end

function Input:set_context(newContext)
    if not self._dirty_actions_in_context then
        if not newContext then return end
        if newContext == self.current_context then return end
    end

    self.current_context = newContext

    self:_update_actions_in_context()
end

function Input:create_action(action_name,contexts)
    if not action_name then return end
    contexts = contexts or "any"

    local newAction = Action.new(action_name,contexts)

    self._actions[action_name] = newAction

    self._dirty_actions_in_context = true

    return newAction
end

function Input:create_axis_action(action_name,contexts)
    if not action_name then return end
    contexts = contexts or "any"

    local newAction = Action.newAxisAction(action_name,contexts)

    self._actions[action_name] = newAction

    self._dirty_actions_in_context = true

    return newAction
end 

function Input:get_action(action_name)
    return self._actions[action_name]
end

--Return
return Input