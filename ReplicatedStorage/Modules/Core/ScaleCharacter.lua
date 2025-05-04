-- /ReplicatedStorage/Modules/Core/ScaleCharacter.lua
-- ModuleScript that handles character scaling functionality using the Model:ScaleTo API
-- Supports both numeric scaling and preset string values
-- Works seamlessly from both client and server contexts

local ScaleCharacter = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

-- Import the Stat module for persistent storage
local Stat = require(ReplicatedStorage.Stat)

-- Determine if we're on the client or server
local IsServer = RunService:IsServer()
local IsClient = RunService:IsClient()

-- Scaling constraints
ScaleCharacter.MIN_SCALE = 0.25
ScaleCharacter.MAX_SCALE = 4.0

-- Values for testing
ScaleCharacter.BASE_SPEED = 16
ScaleCharacter.BASE_HEIGHT = 7.2
ScaleCharacter.BASE_POWER = 50

-- Preset scale values
ScaleCharacter.Presets = {
	small = 0.25,
	normal = 1.0,
	large = 2.0,
	huge = 5.0,
	giant = 10.0
}

-- Remote event for client-server communication
local remoteEvent

-- Initialize the module and set up the remote event
function ScaleCharacter.Initialize()
	-- Lazy load SizeSlider when needed
	if not SizeSlider then
		SizeSlider = require(ReplicatedStorage.Modules.Core.SizeSlider)
	end

	-- Only create the RemoteEvent on the server
	if IsServer then
		-- Ensure the path exists
		local eventsFolder = ReplicatedStorage:FindFirstChild("Events")
		if not eventsFolder then
			eventsFolder = Instance.new("Folder")
			eventsFolder.Name = "Events"
			eventsFolder.Parent = ReplicatedStorage
		end

		local coreFolder = eventsFolder:FindFirstChild("Core")
		if not coreFolder then
			coreFolder = Instance.new("Folder")
			coreFolder.Name = "Core"
			coreFolder.Parent = eventsFolder
		end

		-- Get or create the remote event
		remoteEvent = coreFolder:FindFirstChild("ScaleCharacter")
		if not remoteEvent then
			remoteEvent = Instance.new("RemoteEvent")
			remoteEvent.Name = "ScaleCharacter"
			remoteEvent.Parent = coreFolder
		end

		-- Connect the remote event to the handler
		remoteEvent.OnServerEvent:Connect(function(player, targetPlayer, scale)
			-- If targetPlayer is provided, only allow scaling other players if the requesting player has admin rights
			-- For this example, we'll just check if they're trying to scale themselves
			if targetPlayer and targetPlayer ~= player then
				-- Here you could add admin permission check
				-- For now, just prevent scaling other players from client
				warn("Player " .. player.Name .. " attempted to scale " .. targetPlayer.Name .. " but lacks permission")
				return
			end

			-- Scale the player who sent the request
			ScaleCharacter.SetScale(player, scale)
		end)

		print("ScaleCharacter module initialized on server")
	else
		-- On client, wait for the RemoteEvent to exist at the correct path
		local eventsFolder = ReplicatedStorage:WaitForChild("Events", 5)
		if not eventsFolder then
			warn("ScaleCharacter: Events folder not found in ReplicatedStorage")
			return false
		end

		local coreFolder = eventsFolder:WaitForChild("Core", 5)
		if not coreFolder then
			warn("ScaleCharacter: Core folder not found in Events")
			return false
		end

		remoteEvent = coreFolder:WaitForChild("ScaleCharacter", 5)
		if not remoteEvent then
			warn("ScaleCharacter RemoteEvent not found after waiting")
			return false
		else
			print("ScaleCharacter module initialized on client")
		end
	end

	return true
end

-- Helper function to convert scale parameter to numeric value
local function resolveScaleValue(scale)
	if type(scale) == "number" then
		return scale
	elseif type(scale) == "string" then
		local presetValue = ScaleCharacter.Presets[string.lower(scale)]
		if presetValue then
			return presetValue
		else
			warn("ScaleCharacter: Unknown preset '" .. scale .. "', using 'normal' instead")
			return ScaleCharacter.Presets.normal
		end
	else
		warn("ScaleCharacter: Invalid scale type, using 'normal' instead")
		return ScaleCharacter.Presets.normal
	end
end

-- Helper function to find the closest smaller preset name for a numeric scale value
local function findClosestPresetName(scaleValue)
	-- If the exact value exists, return its name
	for name, value in pairs(ScaleCharacter.Presets) do
		if value == scaleValue then
			return name
		end
	end

	-- Otherwise find the closest smaller preset
	local closestName = "normal" -- Default fallback
	local closestValue = 0

	for name, value in pairs(ScaleCharacter.Presets) do
		if value <= scaleValue and value > closestValue then
			closestName = name
			closestValue = value
		end
	end

	return closestName
end

-- Function to ensure the scale-related stats exist for a player
local function ensureScaleStatsExist(player)
	if not IsServer then return end

	-- Wait for player data to load
	if not Stat.WaitForLoad(player) then
		warn("ScaleCharacter: Failed to wait for player data to load")
		return false
	end

	-- Get or create ScaleName stat (StringValue)
	local scaleNameStat = Stat.Get(player, "ScaleName")
	if not scaleNameStat then
		-- Find player data folder
		local playerData = Stat.GetDataFolder(player)
		if not playerData then
			warn("ScaleCharacter: Failed to get player data folder")
			return false
		end

		-- Create ScaleName stat directly under player data folder
		scaleNameStat = Instance.new("StringValue")
		scaleNameStat.Name = "ScaleName"
		scaleNameStat.Value = "normal" -- Default value
		scaleNameStat.Parent = playerData
		print("Created ScaleName stat for " .. player.Name .. " directly under player data folder")
	end

	-- Get or create ScaleValue stat (NumberValue)
	local scaleValueStat = Stat.Get(player, "ScaleValue")
	if not scaleValueStat then
		-- Find player data folder
		local playerData = Stat.GetDataFolder(player)

		-- Create ScaleValue stat directly under player data folder
		scaleValueStat = Instance.new("NumberValue")
		scaleValueStat.Name = "ScaleValue"
		scaleValueStat.Value = 1 -- Default value (normal scale)
		scaleValueStat.Parent = playerData
		print("Created ScaleValue stat for " .. player.Name .. " directly under player data folder")
	end

	return true
end

-- Scale a player's character to the specified scale
function ScaleCharacter.SetScale(player, scale)
	-- Handle context (client vs server)
	if IsClient and not IsServer then
		-- We're on the client, so use RemoteEvent to request scaling
		if remoteEvent then
			remoteEvent:FireServer(player, scale)
			return true
		else
			warn("ScaleCharacter: RemoteEvent not available on client")
			return false
		end
	end

	-- From this point on, we're on the server

	-- Validate player
	if not player or not player:IsA("Player") then
		warn("ScaleCharacter: Invalid player provided")
		return false
	end

	-- Resolve scale value (numeric or preset string)
	local numericScale = resolveScaleValue(scale)

	-- Clamp scale to allowed range
	numericScale = math.clamp(numericScale, ScaleCharacter.MIN_SCALE, ScaleCharacter.MAX_SCALE)

	-- Determine preset name to store
	local presetName = type(scale) == "string" and string.lower(scale) or findClosestPresetName(numericScale)

	-- Get player character
	local character = player.Character
	if not character then
		warn("ScaleCharacter: Character not found for " .. player.Name)
		return false
	end

	-- Scale the character using Model:ScaleTo API
	local success, errorMsg = pcall(function()
		character:ScaleTo(numericScale)
	end)

	if not success then
		warn("ScaleCharacter: Failed to scale character: " .. tostring(errorMsg))
		return false
	end

	-- Store values using Stat module (only if scaling succeeded)
	if IsServer then
		-- Ensure scale stats exist
		if ensureScaleStatsExist(player) then
			-- Update the values
			local scaleNameStat = Stat.Get(player, "ScaleName")
			local scaleValueStat = Stat.Get(player, "ScaleValue")

			if scaleNameStat and scaleValueStat then
				scaleNameStat.Value = presetName
				scaleValueStat.Value = numericScale
				print("Updated scale stats for " .. player.Name .. " to " .. presetName .. " (" .. numericScale .. ")")
			else
				warn("ScaleCharacter: Could not find ScaleName or ScaleValue stats for " .. player.Name .. " even after creation attempt")
			end
		end
	end

	return true
end

-- Get a player's current character scale information
-- Returns scaleValue, scaleName
function ScaleCharacter.GetScale(player)
	local scaleValue = ScaleCharacter.Presets.normal -- Default scale value
	local scaleName = "normal" -- Default scale name

	-- First try to get from stats if we're on the server
	if player and player:IsA("Player") then
		-- Ensure stats exist
		if IsServer then
			ensureScaleStatsExist(player)
		end

		-- Check if player data is loaded
		if Stat.WaitForLoad(player) then
			local scaleValueStat = Stat.Get(player, "ScaleValue")
			local scaleNameStat = Stat.Get(player, "ScaleName")

			-- Get scale value from stats
			if scaleValueStat and scaleValueStat.Value ~= 0 then
				scaleValue = scaleValueStat.Value
			end

			-- Get scale name from stats
			if scaleNameStat and scaleNameStat.Value ~= "" then
				scaleName = scaleNameStat.Value
				return scaleValue, scaleName -- Return both values if we have them from stats
			end
		end
	end

	-- Fall back to measuring the character and determining the closest preset
	local character = player and player.Character
	if character then
		-- Use the Model:GetScale() API
		local success, scale = pcall(function()
			return character:GetScale()
		end)

		if success and scale then
			scaleValue = scale
			scaleName = findClosestPresetName(scaleValue)
		end
	end

	return scaleValue, scaleName
end

return ScaleCharacter
-- /ReplicatedStorage/Modules/Core/ScaleCharacter.lua
