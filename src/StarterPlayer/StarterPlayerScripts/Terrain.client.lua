local ReplicatedStorage = game:GetService("ReplicatedStorage")

-------Events--------
local ChunkRequestEvent = ReplicatedStorage:WaitForChild("RequestChunkData")

local UpdateInterval = 1 -- Update interval in seconds

local function LoadChunks(chunksData)
	--Load chunks
	for _, chunkData in ipairs(chunksData) do -- Load instances for , instance in ipairs(chunkData.instances) do
		chunkData.instances.Parent = workspace

		--Load water
		workspace.Terrain:FillBlock(chunkData.waterCFrame, chunkData.waterSize, Enum.Material.Water)
	end
end

ChunkRequestEvent.OnClientEvent:Connect(LoadChunks)

----Call this function whenever you want to request chunks from the server
local function RequestChunks()
	ChunkRequestEvent:FireServer()
end

local function MainLoop()
	while true do
		RequestChunks()
		task.wait(UpdateInterval)
	end
end

MainLoop()
