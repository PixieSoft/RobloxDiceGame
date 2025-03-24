-- /ServerScriptService/Modules/Dice/DiceSpawnerManager

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- Require the necessary modules
local DiceGenerator = require(ServerScriptService.Modules.Dice.DiceGenerator)
local DiceSpawnerConfig = require(ServerScriptService.Modules.Dice.DiceSpawnerConfig)

local DiceSpawnerManager = {}

-- Get the template die from ReplicatedStorage
local DiceTemplate = ReplicatedStorage.Assets.Dice.Dice

-- Store spawner tasks so we can clean them up if needed
local SpawnerTasks = {}

-- Helper function to calculate die size based on spawner dimensions
local function CalculateDieSize(spawnerSize)
	-- Find the smallest dimension of the spawner (width, height, or depth)
	local minDimension = math.min(spawnerSize.X, spawnerSize.Y, spawnerSize.Z)

	-- Set die size to match the smallest dimension
	return Vector3.new(minDimension, minDimension, minDimension)
end

-- Helper function to center a position within a CFrame
local function CenterInCFrame(cframe, size)
	local position = cframe.Position
	return CFrame.new(position)
end

-- Check if a spawner should be active (creating dice)
local function IsSpawnerEnabled(spawner)
	-- First, check if we have a direct SpawnerEnabled attribute on the spawner
	local enabledAttribute = spawner:GetAttribute("SpawnerEnabled")
	if enabledAttribute ~= nil then
		return enabledAttribute
	end

	-- Next, check if we have a spawner config
	local configScript = spawner:FindFirstChild("SpawnerConfig")
	if configScript and configScript:IsA("ModuleScript") then
		local success, config = pcall(function()
			return require(configScript)
		end)

		if success and config then
			-- Check if the config has a spawnerEnabled property
			if config.spawnerEnabled ~= nil then
				return config.spawnerEnabled
			end
		end
	end

	-- Finally, check parent for a config (for group inheritance)
	if spawner.Parent then
		local parentConfigScript = spawner.Parent:FindFirstChild("SpawnerConfig")
		if parentConfigScript and parentConfigScript:IsA("ModuleScript") then
			local success, parentConfig = pcall(function()
				return require(parentConfigScript)
			end)

			if success and parentConfig and parentConfig.spawnerEnabled ~= nil then
				return parentConfig.spawnerEnabled
			end
		end
	end

	-- Default to enabled if no configuration is found
	return true
end

-- Check if a spawner's configuration should be applied
local function ShouldApplyConfig(spawner)
	-- First, check if we have a direct ConfigEnabled attribute on the spawner
	local configEnabledAttribute = spawner:GetAttribute("ConfigEnabled")
	if configEnabledAttribute ~= nil then
		return configEnabledAttribute
	end

	-- Next, check if we have a spawner config
	local configScript = spawner:FindFirstChild("SpawnerConfig")
	if configScript and configScript:IsA("ModuleScript") then
		local success, config = pcall(function()
			return require(configScript)
		end)

		if success and config then
			-- Check if the config has a configEnabled property
			if config.configEnabled ~= nil then
				return config.configEnabled
			end
		end
	end

	-- Finally, check parent for a config (for group inheritance)
	if spawner.Parent then
		local parentConfigScript = spawner.Parent:FindFirstChild("SpawnerConfig")
		if parentConfigScript and parentConfigScript:IsA("ModuleScript") then
			local success, parentConfig = pcall(function()
				return require(parentConfigScript)
			end)

			if success and parentConfig and parentConfig.configEnabled ~= nil then
				return parentConfig.configEnabled
			end
		end
	end

	-- Default to enabled if no configuration is found
	return true
end

-- Get the configuration for a spawner
local function GetSpawnerConfiguration(spawner)
	-- Try to get parent configuration first
	local parentConfig
	if spawner.Parent then
		local parentConfigScript = spawner.Parent:FindFirstChild("SpawnerConfig")
		if parentConfigScript and parentConfigScript:IsA("ModuleScript") then
			local success, result = pcall(function()
				return require(parentConfigScript)
			end)

			if success then
				parentConfig = result
				print("Successfully loaded parent SpawnerConfig")

				-- If parent config exists and has configEnabled = true, use it regardless
				-- of the spawner's own configEnabled setting
				if parentConfig.configEnabled == true then
					print("Using parent config for " .. spawner:GetFullName() .. " (parent configEnabled = true)")
					return parentConfig
				end
			end
		end
	end

	-- If we get here, either there's no parent config or the parent's configEnabled is not true
	-- Now check if this specific spawner's configuration should be applied
	local configEnabled = ShouldApplyConfig(spawner)
	if not configEnabled then
		print("Configuration disabled for " .. spawner:GetFullName() .. ". Using default config.")
		-- Return default configuration
		return DiceSpawnerConfig.New({
			tier = 2,
			category = "Rainbow",
			special = "Fireball",
			attackElement = "Fire",
			resistElement = "Water",
			statPriority = {"Attack", "Elemental"}
		})
	end

	-- Try to get spawner's own configuration
	local configScript = spawner:FindFirstChild("SpawnerConfig")
	if configScript and configScript:IsA("ModuleScript") then
		local success, result = pcall(function()
			return require(configScript)
		end)

		if success then
			print("Successfully loaded SpawnerConfig for: " .. spawner:GetFullName())
			return result
		else
			warn("Failed to load SpawnerConfig: " .. tostring(result))
		end
	end

	-- If parent config exists, use it as fallback
	if parentConfig then
		print("Using parent SpawnerConfig as fallback for: " .. spawner:GetFullName())
		return parentConfig
	end

	-- If no configuration was found, return default
	print("No configuration found for " .. spawner:GetFullName() .. ". Using default config.")
	return DiceSpawnerConfig.New({
		tier = 2,
		category = "Rainbow",
		special = "Fireball",
		attackElement = "Fire",
		resistElement = "Water",
		statPriority = {"Attack", "Elemental"}
	})
end

-- Main function to create a die at a spawner
function DiceSpawnerManager.CreateDie(spawner)
	-- Validate inputs
	if not spawner or not spawner:IsA("BasePart") then
		warn("Invalid spawner provided to CreateDie")
		return nil
	end

	-- Check if the spawner is enabled
	if not IsSpawnerEnabled(spawner) then
		print("Spawner " .. spawner:GetFullName() .. " is disabled. Skipping die creation.")
		return nil
	end

	-- Get spawner configuration
	local config = GetSpawnerConfiguration(spawner)

	-- Double-check spawnerEnabled in the config (in case it was loaded after the initial check)
	if config.spawnerEnabled == false then
		print("Spawner " .. spawner:GetFullName() .. " is disabled via loaded config. Skipping die creation.")
		return nil
	end

	-- Get the spawn position and rotation from the spawner's CFrame
	local spawnCFrame = spawner.CFrame

	-- Use DiceGenerator to create the die with proper stats
	local newDie = DiceGenerator.CreateDieInWorld(config, spawnCFrame.Position)
	if not newDie then
		warn("Failed to create die at spawner: " .. spawner:GetFullName())
		return nil
	end

	-- Apply the spawner's orientation to the die
	newDie.CFrame = CFrame.new(newDie.Position) * spawnCFrame.Rotation

	-- Mark this as a die for future detection
	newDie:SetAttribute("IsDie", true)

	-- Calculate appropriate size for the die based on spawner
	local dieSize = CalculateDieSize(spawner.Size)
	newDie.Size = dieSize

	-- Set the spawner as the parent to maintain the hierarchy
	newDie.Parent = spawner

	-- Ensure the die's name matches its Name attribute
	newDie.Name = newDie:GetAttribute("Name")

	-- Double-check the MaxHP value to ensure it's set correctly
	local tier = newDie:GetAttribute("Tier")
	if tier then
		local constants = require(ServerScriptService.Modules.Dice.DiceConstants)
		local tierData = constants.Tier[tier]
		if tierData and tierData.MaxHP then
			-- Verify the MaxHP is correct
			if newDie:GetAttribute("MaxHP") ~= tierData.MaxHP then
				print("Correcting MaxHP for " .. newDie:GetAttribute("Name") .. " from " .. 
					newDie:GetAttribute("MaxHP") .. " to " .. tierData.MaxHP)
				newDie:SetAttribute("MaxHP", tierData.MaxHP)
				newDie:SetAttribute("HP", tierData.MaxHP) -- Also update HP if needed
			end
		end
	end

	return newDie
end

-- Function to get all dice spawners
function DiceSpawnerManager.GetAllSpawners()
	return CollectionService:GetTagged("DiceSpawner")
end

-- Function to start spawning loop for a spawner
local function StartSpawning(spawner)
	-- Check if the spawner is enabled
	if not IsSpawnerEnabled(spawner) then
		print("Spawner " .. spawner:GetFullName() .. " is disabled. Not starting spawn loop.")
		return
	end

	-- Create a unique key for this spawner
	local spawnerKey = spawner:GetFullName()

	-- Clean up existing task if it exists
	if SpawnerTasks[spawnerKey] then
		task.cancel(SpawnerTasks[spawnerKey])
		SpawnerTasks[spawnerKey] = nil
	end

	-- Maximum number of iterations to prevent infinite loops
	local MAX_ITERATIONS = 1000
	local iterations = 0

	-- Create new spawn loop
	SpawnerTasks[spawnerKey] = task.spawn(function()
		while spawner and spawner.Parent do
			-- Check if the spawner is still enabled (could change during execution)
			if not IsSpawnerEnabled(spawner) then
				print("Spawner " .. spawner:GetFullName() .. " is now disabled. Stopping spawn loop.")
				break
			end

			-- Safety check to prevent infinite loops
			iterations = iterations + 1
			if iterations >= MAX_ITERATIONS then
				warn("Spawner loop for " .. spawner:GetFullName() .. " reached maximum iterations. Terminating loop.")
				break
			end

			-- Check if the spawner already has a die (only direct children)
			local existingDie = false
			for _, child in ipairs(spawner:GetChildren()) do
				-- Only check the direct child itself, not its descendants
				if child:GetAttribute("IsDie") then
					existingDie = true
					break
				end
			end

			-- Only create a new die if no die was found
			if not existingDie then
				DiceSpawnerManager.CreateDie(spawner)
			else
				-- If we already have a die, we don't need to keep checking frequently
				-- Exit the loop since we found a die - we'll rely on die removal events to restart spawning
				break
			end

			-- Wait for random time before checking again
			task.wait(1 + math.random() * 3)
		end

		-- Remove from the tasks table when done
		SpawnerTasks[spawnerKey] = nil
	end)
end

-- Function to stop spawning loop for a spawner
local function StopSpawning(spawner)
	local spawnerKey = spawner:GetFullName()
	if SpawnerTasks[spawnerKey] then
		task.cancel(SpawnerTasks[spawnerKey])
		SpawnerTasks[spawnerKey] = nil
	end
end

-- Set up attribute change handler for flag properties
local function SetupFlagChangeHandlers(spawner)
	-- Handle SpawnerEnabled changes
	spawner:GetAttributeChangedSignal("SpawnerEnabled"):Connect(function()
		local isEnabled = spawner:GetAttribute("SpawnerEnabled")
		if isEnabled then
			print("Spawner " .. spawner:GetFullName() .. " enabled. Starting spawn loop.")
			StartSpawning(spawner)
		else
			print("Spawner " .. spawner:GetFullName() .. " disabled. Stopping spawn loop.")
			StopSpawning(spawner)
		end
	end)

	-- Handle ConfigEnabled changes
	spawner:GetAttributeChangedSignal("ConfigEnabled"):Connect(function()
		local configEnabled = spawner:GetAttribute("ConfigEnabled")
		print("ConfigEnabled changed to " .. tostring(configEnabled) .. " for " .. spawner:GetFullName())

		-- If a die exists and we're enabled, recreate it with the new configuration
		if IsSpawnerEnabled(spawner) then
			for _, child in ipairs(spawner:GetChildren()) do
				if child:GetAttribute("IsDie") then
					print("Recreating die with " .. (configEnabled and "custom" or "default") .. " configuration")
					child:Destroy()
					StartSpawning(spawner)
					break
				end
			end
		end
	end)
end

-- Set up tag handling
CollectionService:GetInstanceAddedSignal("DiceSpawner"):Connect(function(spawner)
	-- Set up flag change handlers
	SetupFlagChangeHandlers(spawner)

	-- Start spawning if enabled
	StartSpawning(spawner)

	-- Connect to ChildRemoved event to detect when dice are removed
	spawner.ChildRemoved:Connect(function(child)
		if child:GetAttribute("IsDie") then
			-- A die was removed, restart the spawning process if enabled
			if IsSpawnerEnabled(spawner) then
				StartSpawning(spawner)
			end
		end
	end)
end)

CollectionService:GetInstanceRemovedSignal("DiceSpawner"):Connect(function(spawner)
	StopSpawning(spawner)
end)

-- Initialize spawning for any existing spawners
for _, spawner in ipairs(CollectionService:GetTagged("DiceSpawner")) do
	SetupFlagChangeHandlers(spawner)
	StartSpawning(spawner)

	-- Connect ChildRemoved for existing spawners
	spawner.ChildRemoved:Connect(function(child)
		if child:GetAttribute("IsDie") then
			-- A die was removed, restart the spawning process if enabled
			if IsSpawnerEnabled(spawner) then
				StartSpawning(spawner)
			end
		end
	end)
end

return DiceSpawnerManager
