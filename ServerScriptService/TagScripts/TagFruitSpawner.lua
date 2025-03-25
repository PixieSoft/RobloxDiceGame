--[[
    TagFruitSpawner
    Handles the spawning and management of collectible fruits in the game world.
    
    Features:
    - Automatic fruit spawning at tagged locations
    - Individual and group-based spawning systems
    - Probability-based fruit selection
    - Configurable spawn amounts
    - Automatic cleanup and respawning
]]

-- Services
local CollectionService = game:GetService("CollectionService")

-- Module Dependencies
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Modules = ReplicatedStorage:WaitForChild("ModuleScripts")
local Constants = require(Modules:WaitForChild("ConstantsModule"))
local FruitManagerModule = require(Modules:WaitForChild("FruitManagerModule"))
local FruitSpawnerModule = require(Modules:WaitForChild("FruitSpawnerManagerModule"))
local FruitSpawnerGroupManagerModule = require(Modules:WaitForChild("FruitSpawnerGroupManagerModule"))

-- Define functions first
local function StartIndividualSpawner(spawner)
	if not spawner or not spawner.Parent then return end

	task.defer(function()
		while true do
			if spawner.Parent and not FruitSpawnerGroupManagerModule.IsGroupManaged(spawner.Parent) then
				-- Get timer values, falling back to defaults if not set
				local minTime = spawner:GetAttribute(Constants.SpawnerSettings.SpawnTimerMin_Name) or Constants.SpawnerSettings.SpawnTimerMin_Default
				local maxTime = spawner:GetAttribute(Constants.SpawnerSettings.SpawnTimerMax_Name) or Constants.SpawnerSettings.SpawnTimerMax_Default

				-- Ensure min is not greater than max
				if minTime > maxTime then
					local temp = minTime
					minTime = maxTime
					maxTime = temp
				end

				-- Ensure both values are positive
				minTime = math.max(1, minTime)
				maxTime = math.max(minTime, maxTime)

				local waitTime = math.random(minTime, maxTime)

				if not FruitSpawnerModule.FruitExistsAtSpawner(spawner) then
					local probabilities = FruitSpawnerModule.LoadProbabilities(spawner)
					if probabilities then
						local ranges = FruitSpawnerModule.SetupRanges(probabilities)
						local fruitName = FruitSpawnerModule.PickFruit(ranges)
						if fruitName then
							local spawnAmount = FruitSpawnerModule.DetermineSpawnAmount(spawner, fruitName)
							FruitManagerModule.CreateFruit(fruitName, spawner, spawnAmount)
						end
					end
				end

				task.wait(waitTime)
			else
				task.wait(1)
			end
		end
	end)
end

-- Then initialize spawners
for _, spawner in ipairs(CollectionService:GetTagged("FruitSpawner")) do
	StartIndividualSpawner(spawner)

	-- Check if spawner is in a group that should be managed
	local parent = spawner.Parent
	if parent then
		local groupSettings = parent:FindFirstChild(Constants.SpawnerSettings.GroupSpawnSettings_Name)
		if groupSettings and groupSettings:GetAttribute(Constants.SpawnerSettings.OverrideSpawners_Name) then
			if not FruitSpawnerGroupManagerModule.IsGroupManaged(parent) then
				FruitSpawnerGroupManagerModule.InitializeGroup(parent)
			end
		end
	end
end

-- Set up event handling
CollectionService:GetInstanceAddedSignal("FruitSpawner"):Connect(function(spawner)
	StartIndividualSpawner(spawner)

	-- Check if the new spawner should be part of a managed group
	local parent = spawner.Parent
	if parent then
		local groupSettings = parent:FindFirstChild(Constants.SpawnerSettings.GroupSpawnSettings_Name)
		if groupSettings and groupSettings:GetAttribute(Constants.SpawnerSettings.OverrideSpawners_Name) then
			if not FruitSpawnerGroupManagerModule.IsGroupManaged(parent) then
				FruitSpawnerGroupManagerModule.InitializeGroup(parent)
			end
		end
	end
end)

-- Finally hide the spawners
task.wait(0.1)
FruitSpawnerModule.HideSpawners()
