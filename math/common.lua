local Common = {}

function Common.lerp(a,b,t)
    return a + (b - a) * t
end

function Common.atan2(y,x)
    if math.atan2 then
        return math.atan2(y,x)
    end

    return math.atan(y,x)
end

return Common