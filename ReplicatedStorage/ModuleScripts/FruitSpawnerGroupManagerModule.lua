local FruitSpawnerGroupManagerModule = {}

-- Debug Settings
local DEBUG_ENABLED = false

local function debugPrint(...)
	if DEBUG_ENABLED then
		print("[GroupManager]", ...)
	end
end

-- Services
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Module Dependencies
local Modules = ReplicatedStorage:WaitForChild("ModuleScripts")
local Constants = require(Modules:WaitForChild("ConstantsModule"))
local CustomEvents = require(Modules:WaitForChild("CustomEventsModule"))
local FruitManagerModule = require(Modules:WaitForChild("FruitManagerModule"))
local FruitSpawnerModule = require(Modules:WaitForChild("FruitSpawnerManagerModule"))

-- Private variables
local managedGroups = {}

local function GetGroupSpawners(group)
	if not group then return {} end

	local validSpawners = {}

	-- Only include direct children that are tagged spawners
	for _, spawner in ipairs(group:GetChildren()) do
		if CollectionService:HasTag(spawner, "FruitSpawner") and not spawner:IsA("Folder") then
			table.insert(validSpawners, spawner)
		end
	end

	return validSpawners
end

local function EnsureActiveSpawners(group)
	if not group or not group.Parent then return end

	local groupSettings = group:FindFirstChild(Constants.SpawnerSettings.GroupSpawnSettings_Name)
	if not groupSettings or not groupSettings:GetAttribute(Constants.SpawnerSettings.OverrideSpawners_Name) then 
		debugPrint("Group settings missing or override disabled for:", group:GetFullName())
		return 
	end

	local groupSpawners = GetGroupSpawners(group)
	debugPrint("Found", #groupSpawners, "total spawners in group")

	local targetActive = groupSettings:GetAttribute(Constants.SpawnerSettings.ActiveSpawners_Name) or 1
	local currentActive = 0

	-- Count current active spawners
	for _, spawner in ipairs(groupSpawners) do
		if spawner and FruitSpawnerModule.FruitExistsAtSpawner(spawner) then
			currentActive += 1
		end
	end

	debugPrint("Current active spawners:", currentActive, "Target:", targetActive)

	-- Spawn more if needed
	while currentActive < targetActive do
		local availableSpawners = {}
		for _, spawner in ipairs(groupSpawners) do
			if spawner and not FruitSpawnerModule.FruitExistsAtSpawner(spawner) then
				table.insert(availableSpawners, spawner)
			end
		end

		if #availableSpawners == 0 then 
			debugPrint("No available spawners left")
			break 
		end

		local randomSpawner = availableSpawners[math.random(1, #availableSpawners)]
		if not randomSpawner then continue end

		debugPrint("Selected spawner:", randomSpawner:GetFullName())

		local probabilities = FruitSpawnerModule.LoadProbabilities(randomSpawner)
		if probabilities then
			local ranges = FruitSpawnerModule.SetupRanges(probabilities)
			local fruitName = FruitSpawnerModule.PickFruit(ranges)
			if fruitName then
				local spawnAmount = FruitSpawnerModule.DetermineSpawnAmount(randomSpawner, fruitName)
				local fruit = FruitManagerModule.CreateFruit(fruitName, randomSpawner, spawnAmount)
				if fruit then
					debugPrint("Successfully spawned fruit")
					currentActive += 1
				else
					debugPrint("Failed to spawn fruit")
				end
			end
		end
	end
end

function FruitSpawnerGroupManagerModule.InitializeGroup(group)
	if not group or not group.Parent then return end

	debugPrint("Attempting to initialize group:", group:GetFullName())

	if managedGroups[group] then 
		debugPrint("Group already managed:", group:GetFullName())
		return 
	end

	local groupSettings = group:FindFirstChild(Constants.SpawnerSettings.GroupSpawnSettings_Name)
	if not groupSettings or not groupSettings:GetAttribute(Constants.SpawnerSettings.OverrideSpawners_Name) then 
		debugPrint("Group lacks proper settings:", group:GetFullName())
		return 
	end

	debugPrint("Initializing group:", group:GetFullName())

	-- Set up pickup event handling for this group
	local pickupConnection
	local OnFruitPickup = ReplicatedStorage:FindFirstChild("OnFruitPickup")
	if OnFruitPickup then
		pickupConnection = OnFruitPickup.Event:Connect(function(_, _, _, position)
			if group and group.Parent then
				task.wait(0.1)
				EnsureActiveSpawners(group)
			end
		end)
	end

	-- Store group and its cleanup function
	managedGroups[group] = {
		pickupConnection = pickupConnection,
		checkThread = task.defer(function()
			while true do
				if not group.Parent then
					FruitSpawnerGroupManagerModule.CleanupGroup(group)
					break
				end
				EnsureActiveSpawners(group)
				task.wait(1)
			end
		end)
	}
end

function FruitSpawnerGroupManagerModule.CleanupGroup(group)
	local groupData = managedGroups[group]
	if not groupData then return end

	if groupData.pickupConnection then
		groupData.pickupConnection:Disconnect()
	end

	if groupData.checkThread then
		task.cancel(groupData.checkThread)
	end

	managedGroups[group] = nil
end

function FruitSpawnerGroupManagerModule.IsGroupManaged(group)
	return managedGroups[group] ~= nil
end

local function Initialize()
	debugPrint("Starting group initialization...")
	for _, spawner in ipairs(CollectionService:GetTagged("FruitSpawner")) do
		local parent = spawner.Parent
		if parent then
			debugPrint("Checking spawner parent:", parent:GetFullName())
			local groupSettings = parent:FindFirstChild(Constants.SpawnerSettings.GroupSpawnSettings_Name)
			if groupSettings and groupSettings:GetAttribute(Constants.SpawnerSettings.OverrideSpawners_Name) then
				if not FruitSpawnerGroupManagerModule.IsGroupManaged(parent) then
					FruitSpawnerGroupManagerModule.InitializeGroup(parent)
				end
			end
		end
	end
	debugPrint("Group initialization complete")
end

Initialize()

return FruitSpawnerGroupManagerModule
