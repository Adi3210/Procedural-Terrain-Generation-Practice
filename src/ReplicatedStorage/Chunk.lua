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

	local W1CFrame = CFrame.fromMatrix((a + b) / 2, right, up, back)
	local W2CFrame = CFrame.fromMatrix((a + c) / 2, -right, up, -back)

	local W1Size = Vector3.new(0, height, math.abs(ab:Dot(back)))
	local W2Size = Vector3.new(0, height, math.abs(ac:Dot(back)))

	return W1CFrame, W2CFrame, W1Size, W2Size
end

local function CreateWedge(cframe, size)
	local wedge = wedge:Clone()
	wedge.CFrame = cframe
	wedge.Size = size
	wedge.Parent = workspace
	return wedge
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

------**Modules**-----
local Chunk = {}
Chunk.__index = Chunk

Chunk.WidthSizeX = X * WidthScale
Chunk.WidthSizeZ = Z * WidthScale

function Chunk.new(ChunkPosX, ChunkPosZ, CachedTriangles)
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

			local WedgeA, WedgeB, WedgeC, WedgeD

			if #CachedTriangles > 0 then -- If there are cached triangles
				----Reuse Cached Triangles----
				WedgeA, WedgeB = table.remove(CachedTriangles, 1), table.remove(CachedTriangles, 1)
				WedgeC, WedgeD = table.remove(CachedTriangles, 1), table.remove(CachedTriangles, 1)

				--------Update the Triangle Positions and Sizes--------
				local W1CFrame, W2CFrame, W1Size, W2Size = Draw3dTriangle(a, b, c)
				local W3CFrame, W4CFrame, W3Size, W4Size = Draw3dTriangle(b, c, d)

				WedgeA.CFrame, WedgeB.CFrame = W1CFrame, W2CFrame
				WedgeC.CFrame, WedgeD.CFrame = W3CFrame, W4CFrame

				WedgeA.Size, WedgeB.Size = W1Size, W2Size
				WedgeC.Size, WedgeD.Size = W3Size, W4Size
			else
				--------Create New Triangles--------
				local w1CFrame, w2CFrame, w1Size, w2Size = Draw3dTriangle(a, b, c) -- Get the CFrame and Size of the triangle
				local w3CFrame, w4CFrame, w3Size, w4Size = Draw3dTriangle(b, c, d) -- Get the CFrame and Size of the triangle

				WedgeA, WedgeB = CreateWedge(w1CFrame, w1Size), CreateWedge(w2CFrame, w2Size) -- Create the triangle
				WedgeC, WedgeD = CreateWedge(w3CFrame, w3Size), CreateWedge(w4CFrame, w4Size) -- Create the triangle
			end

			local WedgesTable = { WedgeA, WedgeB, WedgeC, WedgeD } -- Put the wedges in a table
			for _, WedgeChild in ipairs(WedgesTable) do -- Loop through the table
				table.insert(self.instances, WedgeChild) -- Insert the wedges into the instances table
			end
		end
	end

	return self
end

function Chunk:Destroy(CachedTriangles)
	for _, instance in ipairs(self.instances) do
		table.insert(CachedTriangles, instance) -- Insert the wedges into the cached triangles table instead of destroying them
	end

	self.instances = {}
end

return Chunk
