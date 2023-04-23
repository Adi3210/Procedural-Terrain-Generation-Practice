---------Services--------
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

---------Modules---------
local ChunkModule = require(ReplicatedStorage.Chunk)

---------Object Variables--------
local RenderDistance = 12
local ChunksLoadedPerTick = 4
local Camera = workspace.CurrentCamera

--------Math Variables--------
local CenterPosX
local CenterPosZ
local Chunks = {}
local ChunkCount = 0
local FastLoad = true
local CachedTriangles = {} -- Cache triangles

-------Functions--------
local function ChunkWait() -- Wait for the chunk to be created
	ChunkCount = (ChunkCount + 1) % ChunksLoadedPerTick

	if ChunkCount == 0 and not FastLoad then
		task.wait()
	end
end

local function UpdateCenterPosFromCamera()
	local CamPosition = Camera.CFrame.Position -- Get the camera's position

	CenterPosX = math.floor(CamPosition.X / ChunkModule.WidthSizeX)
	CenterPosZ = math.floor(CamPosition.Z / ChunkModule.WidthSizeZ)
end

local function DoesChunkExist(x, z)
	for i, Chunk in pairs(Chunks) do
		if Chunk.x == x and Chunk.z == z then
			return true -- If the chunk exists, return true
		end
	end

	return false -- If the chunk doesn't exist, return false
end

local function IsChunkOutOfRange(Chunk)
	if Chunk == nil then
		return
	end

	if math.abs(Chunk.x - CenterPosX) > RenderDistance or math.abs(Chunk.z - CenterPosZ) > RenderDistance then
		return true -- If the chunk is out of range, return true
	end

	return false -- If the chunk is in range, return false
end

local function MakeChunks()
	for x = CenterPosX - RenderDistance, CenterPosX + RenderDistance do
		for z = CenterPosZ - RenderDistance, CenterPosZ + RenderDistance do
			if not DoesChunkExist(x, z) then
				local NewChunk = ChunkModule.new(x, z, CachedTriangles)
				table.insert(Chunks, NewChunk)
				ChunkWait()
			end
		end
	end
end

local function DestroyChunks()
	local NumOfChunks = #Chunks

	-----Destroy chunks that are out of range-----
	for i = NumOfChunks, 1, -1 do
		local Chunk = Chunks[i]

		if IsChunkOutOfRange(Chunk) then
			Chunk:Destroy(CachedTriangles) ---This now adds the triangles to the CachedTriangles table
			ChunkWait() -- Wait for the chunk to be destroyed

			Chunks[i] = nil
		end
	end

	-----Remove nil values from table-----
	local j = 0

	for i = 1, NumOfChunks do
		if Chunks[i] ~= nil then
			j += 1
			Chunks[j] = Chunks[i]
		end
	end

	-----Remove extra values from table-----
	for i = j + 1, NumOfChunks do
		Chunks[i] = nil
	end
end

--------**Loop To Create Chunks**--------
local updateInterval = 0.5
local timeSinceLastUpdate = 0

local function MainLoop(deltaTime)
	timeSinceLastUpdate = timeSinceLastUpdate + deltaTime

	if timeSinceLastUpdate >= updateInterval then
		UpdateCenterPosFromCamera()

		DestroyChunks()

		MakeChunks()

		timeSinceLastUpdate = 0

		FastLoad = false
	end
end

RunService.Heartbeat:Connect(MainLoop)
