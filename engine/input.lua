--Libraries
local glfw = require("moonglfw")
local Vector2d = require("math/vector2d")
local Signal = require("engine/signal")

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

    glfw.set_key_callback(window, function(win, key, scancode, action, shift, control, alt, super)
        if action == "press" then
            self._pressed_keys[key] = true
            self.key_pressed:Fire(key)
        elseif action == "release" then
            self._pressed_keys[key] = false
            self.key_released:Fire(key)
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

--Return
return Input