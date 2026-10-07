local Matrix = {}
Matrix.__index = Matrix
Matrix.__type = "Matrix"

local function isMatrix(matrix)
    if type(matrix) ~= "table" then return end
    if not matrix.__type then return end
    if matrix.__type ~= "Matrix" then return end
    return true
end

local function sameSize(matrix1,matrix2)
    return matrix1.columns==matrix2.columns and matrix1.rows==matrix2.rows
end

local function shallowCopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in pairs(orig) do
            copy[orig_key] = orig_value
        end
    else
        copy = orig
    end
    return copy
end

--Constructors

function Matrix.new(matrix)
    local self = setmetatable({},Matrix)

    self._matrix = matrix

    self.rows = #matrix
    self.columns = #matrix[1]

    return self
end

function Matrix.identity(size)
    local newMatrix = {}

    for ri=1,size do
        newMatrix[ri] = {}
        for ci=1,size do
            if ci==ri then
                newMatrix[ri][ci] = 1
            else
                newMatrix[ri][ci] = 0
            end
        end
    end

    return Matrix.new(newMatrix)
end

--Metamethods

function Matrix.__mul(self,otherMatrix)
    if isMatrix(otherMatrix) then
        if self.columns ~= otherMatrix.rows then return end

        local newMatrix = {} --new matrix's _matrix

        for ri,row in pairs(self._matrix) do 
            newMatrix[ri] = {} --add a new row. when multiplying two matrices resulting matrix is self.rows x otherMatrix.columns

            for ori,orow in pairs(otherMatrix._matrix) do 
                for oci,ovalue in pairs(orow) do 
                    if not newMatrix[ri][oci] then newMatrix[ri][oci] = 0 end

                    --print("["..ri.."]["..oci.."] : "..newMatrix[ri][oci].." --> "..newMatrix[ri][oci] + row[ori] * ovalue)
                    newMatrix[ri][oci] = newMatrix[ri][oci] + row[ori] * ovalue
                end
            end
        end

        return Matrix.new(newMatrix)
    elseif type(otherMatrix) == "number" then
        local newMatrix = shallowCopy(self._matrix)

        for ri,row in pairs(newMatrix) do
            for ci,value in pairs(row) do
                newMatrix[ri][ci] = value * otherMatrix
            end
        end

        return Matrix.new(newMatrix)
    end
end

function Matrix.__add(self,otherMatrix)
    if not isMatrix(otherMatrix) then return end
    if not sameSize(self,otherMatrix) then return end

    local newMatrix = shallowCopy(self._matrix)

    for ri,row in pairs(newMatrix) do
        for ci,value in pairs(row) do
            newMatrix[ri][ci] = value + otherMatrix._matrix[ri][ci]
        end
    end

    return Matrix.new(newMatrix)
end

function Matrix.__tostring(self)
    local newString = ""

    for ri,row in pairs(self._matrix) do
        local line = "| "

        for ci,value in pairs(row) do
            line = line..value.." "
        end

        line = line.."|\n"
        newString = newString..line
    end

    return newString
end

--Methods

function Matrix:flatten()
    local flattenedMatrix = {}

    for ri,row in pairs(self._matrix) do
        for ci,value in pairs(row) do
            flattenedMatrix[(ri-1)*self.columns+ci] = value
        end
    end

    return flattenedMatrix
end

function Matrix:normal_matrix()
    if self.columns ~= 4 or self.rows ~= 4 then return end

    local m = self._matrix

    local a,b,c = m[1][1],m[1][2],m[1][3]
    local d,e,f = m[2][1],m[2][2],m[2][3]
    local g,h,i = m[3][1],m[3][2],m[3][3]

    local determinant =
        a * (e * i - f * h) -
        b * (d * i - f * g) +
        c * (d * h - e * g)

    assert(math.abs(determinant) > 1e-8,"Model matrix cannot be inverted")

    return Matrix.new({
        {(e*i-f*h)/determinant,(f*g-d*i)/determinant,(d*h-e*g)/determinant},
        {(c*h-b*i)/determinant,(a*i-c*g)/determinant,(b*g-a*h)/determinant},
        {(b*f-c*e)/determinant,(c*d-a*f)/determinant,(a*e-b*d)/determinant}
    })
end

return Matrix