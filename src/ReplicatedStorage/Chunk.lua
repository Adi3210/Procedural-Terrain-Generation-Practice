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

------Tables------
local TerrainHeightColors = {
	[-50] = Color3.fromRGB(216, 204, 157), -- sand yellow
	[-10] = Color3.fromRGB(72, 113, 58), -- grassy green
	[0] = Color3.fromRGB(72, 113, 58), -- grassy green
	[75] = Color3.fromRGB(76, 80, 86), -- stone grey mountain
}

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

-----**Function to create a wedge**-----
local function CreateWedge(cframe, size)
	local wedgeInstance = wedge:Clone()
	wedgeInstance.CFrame = cframe
	wedgeInstance.Size = size
	wedgeInstance.Parent = workspace
	return wedgeInstance
end

-----**Function to get the height of a point**-----
local function GetHeight(ChunkPosX, ChunkPosZ, x, z)
	-----Get the height of the terrain using Perlin Noise-----
	local TerrainHeight = math.noise(
		(X / TerrainSmoothness * ChunkPosX) + x / TerrainSmoothness,
		(Z / TerrainSmoothness * ChunkPosZ) + z / TerrainSmoothness
	) * HeightScale

	-------Detect if the terrain is too high or too low and smooth it out-------
	if TerrainHeight > 20 then
		local Difference = TerrainHeight - 20
		TerrainHeight += (Difference * 0.5)
	end

	if TerrainHeight < -20 then
		local Difference = TerrainHeight + 20
		TerrainHeight += (Difference * 0.5)
	end

	return TerrainHeight
end

-----**Function to get the position of a point**-----
local function GetPosition(ChunkPosX, ChunkPosZ, x, z)
	return Vector3.new(
		ChunkPosX * X * WidthScale + x * WidthScale,
		GetHeight(ChunkPosX, ChunkPosZ, x, z),
		ChunkPosZ * Z * WidthScale + z * WidthScale
	)
end

-----**Function to paint the wedge**-----
local function PaintWedge(WedgePaint)
	local WedgeHeight = WedgePaint.Position.Y

	local Color
	local LowerColorHeight
	local HigherColorHeight

	for HeightNum, HeightColor in pairs(TerrainHeightColors) do
		if WedgeHeight == HeightNum then
			Color = HeightColor
			break
		end

		if (WedgeHeight < HeightNum) and (not HigherColorHeight or HeightNum < HigherColorHeight) then -- If the height is less than the current height and less than the higher color height
			HigherColorHeight = HeightNum
		end

		if (WedgeHeight > HeightNum) and (not LowerColorHeight or HeightNum > LowerColorHeight) then -- If the height is greater than the current height and greater than the lower color height
			LowerColorHeight = HeightNum
		end
	end

	if not Color then
		if HigherColorHeight == nil then
			Color = TerrainHeightColors[LowerColorHeight]
		elseif LowerColorHeight == nil then
			Color = TerrainHeightColors[HigherColorHeight]
		else
			local Alpha = (WedgeHeight - LowerColorHeight) / (HigherColorHeight - LowerColorHeight)
			local LowerColor = TerrainHeightColors[LowerColorHeight]
			local HigherColor = TerrainHeightColors[HigherColorHeight]

			Color = LowerColor:Lerp(HigherColor, Alpha)
		end
	end

	WedgePaint.Material = Enum.Material.Grass
	WedgePaint.Color = Color
end

local function AddWater(Chunk)
	local ChunkCFrame = CFrame.new((Chunk.x + 0.5) * Chunk.WidthSizeX, -70, (Chunk.z + 0.5) * Chunk.WidthSizeZ)

	local Size = Vector3.new(Chunk.WidthSizeX, 90, Chunk.WidthSizeZ)

	workspace.Terrain:FillBlock(ChunkCFrame, Size, Enum.Material.Water)

	Chunk.WaterCFrame = ChunkCFrame
	Chunk.WaterSize = Size
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

			for _, Wedges in ipairs(WedgesTable) do -- Loop through the table
				PaintWedge(Wedges) -- Paint the wedges
			end

			for _, WedgeChild in ipairs(WedgesTable) do -- Loop through the table
				table.insert(self.instances, WedgeChild) -- Insert the wedges into the instances table
			end
		end
	end

	AddWater(self)

	return self
end

function Chunk:Destroy(CachedTriangles)
	for _, instance in ipairs(self.instances) do
		table.insert(CachedTriangles, instance) -- Insert the wedges into the cached triangles table instead of destroying them
	end

	self.instances = {}

	workspace.Terrain:FillBlock(self.WaterCFrame, self.WaterSize, Enum.Material.Air)
end

return Chunk
