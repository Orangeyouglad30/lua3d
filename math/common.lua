local Common = {}

function Common.lerp(a,b,t)
    return a + (b - a) * t
end

return Common