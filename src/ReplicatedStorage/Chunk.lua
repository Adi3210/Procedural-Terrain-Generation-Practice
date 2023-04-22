----Create Wedge Part----
local wedge = Instance.new("WedgePart")
wedge.Anchored = true
wedge.TopSurface = Enum.SurfaceType.Smooth
wedge.BottomSurface = Enum.SurfaceType.Smooth

----Grid Variables----
local X = 4
local Z = 4
local WidthScale = 15
local HeightScale = 100
local TerrainSmoothness = 20

-----Functions-----
-----**Function to draw a triangle**-----
local function Draw3dTriangle(a, b, c)
	local ab, ac, bc = b - a, c - a, c - b
	local abd, acd, bcd = ab:Dot(ab), ac:Dot(ac), bc:Dot(bc)

	if abd > acd and abd > bcd then
		c, a = a, c
	elseif acd > bcd and acd > abd then
		a, b = b, a
	end

	ab, ac, bc = b - a, c - a, c - b

	local right = ac:Cross(ab).unit
	local up = bc:Cross(right).unit
	local back = bc.unit

	local height = math.abs(ab:Dot(up))

	local w1 = wedge:Clone()
	w1.Size = Vector3.new(0, height, math.abs(ab:Dot(back)))
	w1.CFrame = CFrame.fromMatrix((a + b) / 2, right, up, back)
	w1.Parent = workspace

	local w2 = wedge:Clone()
	w2.Size = Vector3.new(0, height, math.abs(ac:Dot(back)))
	w2.CFrame = CFrame.fromMatrix((a + c) / 2, -right, up, -back)
	w2.Parent = workspace

	return w1, w2
end

local function GetHeight(ChunkPosX, ChunkPosZ, x, z)
	return math.noise(
		(X / TerrainSmoothness * ChunkPosX) + x / TerrainSmoothness,
		(Z / TerrainSmoothness * ChunkPosZ) + z / TerrainSmoothness
	) * HeightScale
end

local function GetPosition(ChunkPosX, ChunkPosZ, x, z)
	return Vector3.new(
		ChunkPosX * X * WidthScale + x * WidthScale,
		GetHeight(ChunkPosX, ChunkPosZ, x, z),
		ChunkPosZ * Z * WidthScale + z * WidthScale
	)
end

------Modules-----
local Chunk = {}
Chunk.__index = Chunk

Chunk.WidthSizeX = X * WidthScale
Chunk.WidthSizeZ = Z * WidthScale

function Chunk.new(ChunkPosX, ChunkPosZ)
	local self = setmetatable({}, Chunk)

	self.instances = {}
	self.x = ChunkPosX
	self.z = ChunkPosZ

	-----**Create position Grid With Perlin Noise**-----
	local PositionGrid = {}

	for x = 0, X do
		PositionGrid[x] = {}

		for z = 0, Z do
			PositionGrid[x][z] = GetPosition(ChunkPosX, ChunkPosZ, x, z) -- Get the position of the vertex
		end
	end

	for x = 0, X - 1 do
		for z = 0, Z - 1 do
			local a = PositionGrid[x][z]
			local b = PositionGrid[x + 1][z]
			local c = PositionGrid[x][z + 1]
			local d = PositionGrid[x + 1][z + 1]

			local WedgeA, WedgeB = Draw3dTriangle(a, b, c) -- Draw one triangle
			local WedgeC, WedgeD = Draw3dTriangle(b, c, d) -- Draw the other triangle

			local WedgesTable = { WedgeA, WedgeB, WedgeC, WedgeD } -- Put the wedges in a table
			for _, WedgeChild in ipairs(WedgesTable) do -- Loop through the table
				table.insert(self.instances, WedgeChild) -- Insert the wedges into the instances table
			end
		end
	end

	return self
end

function Chunk:Destroy()
	for _, instance in ipairs(self.instances) do
		instance:Destroy()
	end

	self.instances = {}
end

return Chunk
