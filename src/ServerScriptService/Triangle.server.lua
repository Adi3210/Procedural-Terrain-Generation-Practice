local RunService = game:GetService("RunService")

----Create Wedge Part----
local wedge = Instance.new("WedgePart")
wedge.Anchored = true
wedge.TopSurface = Enum.SurfaceType.Smooth
wedge.BottomSurface = Enum.SurfaceType.Smooth

----Grid Variables----
local X = 15
local Z = 15

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

RunService.Heartbeat:Connect(function() --- This is just for testing the part with triangles
	local APart = workspace.A.Position
	local BPart = workspace.B.Position
	local CPart = workspace.C.Position

	local WedgeA, WedgeB = Draw3dTriangle(APart, BPart, CPart)

	task.wait() -- wait for the next frame

	WedgeA:Destroy()
	WedgeB:Destroy()
end)

-----**Create position Grid With Perlin Noise**-----
local PositionGrid = {}

for x = 0, X do
	PositionGrid[x] = {}

	for z = 0, Z do
		PositionGrid[x][z] = Vector3.new(x * 5, math.noise(x / 10, z / 10) * 25, z * 5)
	end
end

for x = 0, X - 1 do
	for z = 0, Z - 1 do
		local a = PositionGrid[x][z]
		local b = PositionGrid[x + 1][z]
		local c = PositionGrid[x][z + 1]
		local d = PositionGrid[x + 1][z + 1]

		Draw3dTriangle(a, b, c) -- Draw one triangle
		Draw3dTriangle(b, c, d) -- Draw the other triangle
	end
end
