local x = 50
local z = 50

local grid = {}

for i = 1, x do
	grid[i] = {}
	for j = 1, z do
		grid[i][j] = math.noise(i / 10, j / 10) * 15
	end
end

for i = 1, x do
	for j = 1, z do
		local YPosition = grid[i][j]

		local Part = Instance.new("Part")
		Part.Anchored = true

		if YPosition < -3 then
			Part.Material = Enum.Material.Sand
			Part.BrickColor = BrickColor.new("Cool yellow")
		else
			Part.Material = Enum.Material.Grass
			Part.BrickColor = BrickColor.new("Lime green")
		end

		Part.Size = Vector3.new(5, 30, 5)
		Part.Position = Vector3.new(i * 5, YPosition, j * 5)
		Part.Parent = workspace
	end
end

-----Add Waterfall-----
local Waterfall = Instance.new("Part")
Waterfall.Anchored = true
Waterfall.Transparency = 0.5
Waterfall.CanCollide = false
Waterfall.BrickColor = BrickColor.new("Cyan")
Waterfall.Size = Vector3.new(x * 5, 30, z * 5)
Waterfall.Position = Vector3.new(((x + 1) * 5) / 2, -5, ((z + 1) * 5) / 2)
Waterfall.Parent = workspace
