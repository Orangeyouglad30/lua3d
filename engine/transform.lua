local Matrix = require("math/matrix")

local Transform = {}

function Transform.identity()
    return Matrix.identity(4)
end

function Transform.rotation_x(angle)
    local cosine = math.cos(angle)
    local sine = math.sin(angle)

    return Matrix.new({
         {1,      0,      0, 0},
         {0, cosine,  -sine, 0},
         {0,   sine, cosine, 0},
         {0,      0,      0, 1}
    })
end

function Transform.rotation_y(angle)
    local cosine = math.cos(angle)
    local sine = math.sin(angle)

    return Matrix.new({
         {cosine, 0,   sine, 0},
         {     0, 1,      0, 0},
         { -sine, 0, cosine, 0},
         {     0, 0,      0, 1}
    })
end

function Transform.rotation_z(angle)
    local cosine = math.cos(angle)
    local sine = math.sin(angle)

    return Matrix.new({
         {cosine, -sine, 0, 0},
         {sine,   cosine, 0, 0},
         {0,      0,      1, 0},
         {0,      0,      0, 1}
    })
end

function Transform.scale(x,y,z,s)
    x,y,z,s = x or 1,y or 1,z or 1,s or 1

    return Matrix.new({
        {x, 0, 0, 0},
        {0, y, 0, 0},
        {0, 0, z, 0},
        {0, 0, 0, s},
    })
end

function Transform.translation(x,y,z)
    x,y,z = x or 0,y or 0,z or 0

    return Matrix.new({
        {1, 0, 0, x},
        {0, 1, 0, y},
        {0, 0, 1, z},
        {0, 0, 0, 1},
    })
end

function Transform.perspective(field_of_view,aspect,near,far)
    local f = 1 / math.tan(field_of_view/2)

    return Matrix.new({
        {f / aspect, 0,                           0,                               0},
        {         0, f,                           0,                               0},
        {         0, 0, (far + near) / (near - far), (2 * far * near) / (near - far)},
        {         0, 0,                          -1,                               0}
    })
end

return Transform