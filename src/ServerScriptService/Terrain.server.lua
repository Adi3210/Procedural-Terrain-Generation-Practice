---------Services--------
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

---------Modules---------
local ChunkModule = require(ReplicatedStorage.Chunk)

---------Object Variables--------
local RenderDistance = 12
local ChunksLoadedPerTick = 4
local ChunkRequestEvent = ReplicatedStorage:WaitForChild("RequestChunkData")
-- local Camera = workspace.CurrentCamera

--------Math Variables--------
local CenterPosX
local CenterPosZ
local Chunks = {}
local ChunkCount = 0
local CachedTriangles = {} -- Cache triangles

-------Loading Variables--------
local FastLoad = true
local TerrainIntialized = false
local UpdateInterval = 0.5
local TimeSinceLastUpdate = 0

-------Functions--------

local function ChunkWait() -- Wait for the chunk to be created
	ChunkCount = (ChunkCount + 1) % ChunksLoadedPerTick

	if ChunkCount == 0 and not FastLoad then
		task.wait()
	end
end

local function UpdateCenterPosFromPlayerHead(player)
	local Character = player.Character
	if not Character then
		return
	end

	local Head = Character:FindFirstChild("Head")
	if not Head then
		return
	end

	local HeadPosition = Head.Position

	CenterPosX = math.floor(HeadPosition.X / ChunkModule.WidthSizeX)
	CenterPosZ = math.floor(HeadPosition.Z / ChunkModule.WidthSizeZ)
end

local function DoesChunkExist(x, z)
	for _, Chunk in pairs(Chunks) do
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
	if not CenterPosX or not CenterPosZ then
		return
	end

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

-----**Initialize Terrain**-----
local function InitializeTerrain()
	MakeChunks()

	TerrainIntialized = true
end

local function MainLoop(deltaTime)
	if not TerrainIntialized then
		return
	end

	TimeSinceLastUpdate = TimeSinceLastUpdate + deltaTime

	if TimeSinceLastUpdate >= UpdateInterval then
		for _, player in pairs(Players:GetPlayers()) do
			UpdateCenterPosFromPlayerHead(player)
		end

		DestroyChunks()

		MakeChunks()

		FastLoad = false

		TimeSinceLastUpdate = 0
	end
end

-------**Events**-------
Players.PlayerAdded:Connect(InitializeTerrain)
RunService.Heartbeat:Connect(MainLoop)

ChunkRequestEvent.OnServerEvent:Connect(function(player)
	local playerCharacter = player.Character
	if not playerCharacter then
		return
	end

	local playerHead = playerCharacter:FindFirstChild("Head")
	if not playerHead then
		return
	end

	UpdateCenterPosFromPlayerHead(player)
	DestroyChunks()
	MakeChunks()

	local chunksData = {}
	for _, chunk in ipairs(Chunks) do
		table.insert(chunksData, {
			x = chunk.x,
			z = chunk.z,
			instances = chunk.instances,
			waterCFrame = chunk.WaterCFrame,
			waterSize = chunk.WaterSize,
		})
	end

	ChunkRequestEvent:FireClient(player, chunksData)
end)
