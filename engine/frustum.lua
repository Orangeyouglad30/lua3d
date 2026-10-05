local Frustum = {}
Frustum.__index = Frustum

local function make_plane(a, b, c, d)
    local magnitude =
        math.sqrt(a * a + b * b + c * c)

    return {
        a = a / magnitude,
        b = b / magnitude,
        c = c / magnitude,
        d = d / magnitude
    }
end

function Frustum.from_matrix(matrix)
    local m = matrix._matrix

    return setmetatable({
        left = make_plane(
            m[4][1] + m[1][1],
            m[4][2] + m[1][2],
            m[4][3] + m[1][3],
            m[4][4] + m[1][4]
        ),

        right = make_plane(
            m[4][1] - m[1][1],
            m[4][2] - m[1][2],
            m[4][3] - m[1][3],
            m[4][4] - m[1][4]
        ),

        bottom = make_plane(
            m[4][1] + m[2][1],
            m[4][2] + m[2][2],
            m[4][3] + m[2][3],
            m[4][4] + m[2][4]
        ),

        top = make_plane(
            m[4][1] - m[2][1],
            m[4][2] - m[2][2],
            m[4][3] - m[2][3],
            m[4][4] - m[2][4]
        ),

        near = make_plane(
            m[4][1] + m[3][1],
            m[4][2] + m[3][2],
            m[4][3] + m[3][3],
            m[4][4] + m[3][4]
        ),

        far = make_plane(
            m[4][1] - m[3][1],
            m[4][2] - m[3][2],
            m[4][3] - m[3][3],
            m[4][4] - m[3][4]
        )
    }, Frustum)
end

function Frustum:contains_sphere(center, radius)
    for _, plane in pairs(self) do
        if type(plane) == "table" and plane.a then
            local distance =
                plane.a * center.x +
                plane.b * center.y +
                plane.c * center.z +
                plane.d

            if distance < -radius then
                return false
            end
        end
    end

    return true
end

return Frustum