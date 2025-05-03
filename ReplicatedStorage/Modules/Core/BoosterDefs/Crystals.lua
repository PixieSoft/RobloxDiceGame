-- /ReplicatedStorage/Modules/Core/BoosterDefs/Crystals.lua
-- ModuleScript that defines the Crystal booster with integrated size slider functionality

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local IsServer = RunService:IsServer()

-- Import modules
local Utility = require(ReplicatedStorage.Modules.Core.Utility)
local Stat = require(ReplicatedStorage.Stat)
-- Defer loading Timers to break circular dependency
local Timers = nil
local ScaleCharacter = require(ReplicatedStorage.Modules.Core.ScaleCharacter)

-- Create a table that we can reference from within its own methods
local CrystalBooster = {}

-- Debug settings
local debugSystem = "Boosters" -- System name for debug logs

-- Define properties
CrystalBooster.name = "Crystals"
CrystalBooster.description = "Activate crystal power for 10s per crystal. Allows size changing."
CrystalBooster.imageId = "rbxassetid://72049224483385"
CrystalBooster.boosterType = "PlayerBoost" -- Will be mapped to Boosters.BoosterTypes.PLAYER
CrystalBooster.duration = 10 -- 10 seconds per item used
CrystalBooster.stacks = false -- effect does not stack
CrystalBooster.canCancel = true -- can be canceled by player

-- Function to calculate and return effect description
CrystalBooster.calculateEffect = function(spendingAmount)
	if spendingAmount <= 0 then
		return "Select crystals to use"
	end

	local totalDuration = CrystalBooster.duration * spendingAmount -- Self-reference to duration property
	local timeText = Utility.FormatTimeDuration(totalDuration)

	local pluralText = spendingAmount > 1 and "crystals" or "crystal"
	return "Crystal power for " .. timeText .. " using " .. spendingAmount .. " " .. pluralText .. ". Allows size changing."
end

-- Helper function to ensure the required stats exist
local function ensureStats(player)
	if not IsServer then return false end

	-- Wait for player data to load
	if not Stat.WaitForLoad(player) then
		Utility.Log(debugSystem, "warn", "Failed to wait for player data to load")
		return false
	end

	-- Get or create the Boosters folder
	local playerData = Stat.GetDataFolder(player)
	if not playerData then return false end

	local boostersFolder = playerData:FindFirstChild("Boosters")
	if not boostersFolder then
		-- This should already exist, but create it if not
		boostersFolder = Instance.new("Folder")
		boostersFolder.Name = "Boosters"
		boostersFolder.Parent = playerData
	end

	-- Get or create CrystalsActive stat under Boosters
	local crystalsActiveStat = boostersFolder:FindFirstChild("CrystalsActive")
	if not crystalsActiveStat then
		crystalsActiveStat = Instance.new("BoolValue")
		crystalsActiveStat.Name = "CrystalsActive"
		crystalsActiveStat.Value = false
		crystalsActiveStat.Parent = boostersFolder
		Utility.Log(debugSystem, "info", "Created CrystalsActive stat for " .. player.Name)
	end

	return true
end

-- Get or create the size slider event (once, cached)
local sliderEvent
local function getOrCreateSliderEvent()
	if sliderEvent then return sliderEvent end

	local eventsFolder = ReplicatedStorage:FindFirstChild("Events")
	if not eventsFolder then
		eventsFolder = Instance.new("Folder")
		eventsFolder.Name = "Events"
		eventsFolder.Parent = ReplicatedStorage
		Utility.Log(debugSystem, "info", "Created Events folder in ReplicatedStorage")
	end

	local coreFolder = eventsFolder:FindFirstChild("Core")
	if not coreFolder then
		coreFolder = Instance.new("Folder")
		coreFolder.Name = "Core"
		coreFolder.Parent = eventsFolder
		Utility.Log(debugSystem, "info", "Created Core folder in Events")
	end

	sliderEvent = coreFolder:FindFirstChild("SizeSliderVisibility")
	if not sliderEvent then
		sliderEvent = Instance.new("RemoteEvent")
		sliderEvent.Name = "SizeSliderVisibility"
		sliderEvent.Parent = coreFolder
		Utility.Log(debugSystem, "info", "Created SizeSliderVisibility RemoteEvent")
	else
		Utility.Log(debugSystem, "info", "Found existing SizeSliderVisibility RemoteEvent")
	end

	return sliderEvent
end

-- Function that runs when booster is activated
CrystalBooster.onActivate = function(player, qty)
	-- This function only runs on the server
	if not IsServer then 
		Utility.Log(debugSystem, "warn", "onActivate called on client - this should only run on server")
		return function() end 
	end

	Utility.Log(debugSystem, "info", "Crystal booster onActivate called for " .. player.Name .. " with quantity " .. qty)

	-- Load Timers module when needed (to avoid circular dependency)
	if not Timers then
		Timers = require(ReplicatedStorage.Modules.Core.Timers)
	end

	-- Ensure stats exist
	if not ensureStats(player) then
		Utility.Log(debugSystem, "warn", "Failed to ensure stats for " .. player.Name)
		return function() end
	end

	-- Get or create the size slider event
	local sliderEvent = getOrCreateSliderEvent()

	-- Get stat references
	local playerData = Stat.GetDataFolder(player)
	local boostersFolder = playerData:FindFirstChild("Boosters")
	local crystalsActiveStat = boostersFolder:FindFirstChild("CrystalsActive")

	-- Calculate duration
	local totalDuration = qty * CrystalBooster.duration

	-- Set the crystal active status (important for IsBoosterActive function)
	crystalsActiveStat.Value = true

	-- Show the size slider
	Utility.Log(debugSystem, "info", "Firing SizeSliderVisibility event with value true to show slider")
	local success, err = pcall(function()
		sliderEvent:FireClient(player, true)
	end)

	if not success then
		Utility.Log(debugSystem, "warn", "Failed to show slider: " .. tostring(err))
	end

	Utility.Log(debugSystem, "info", "Crystal booster activated for " .. player.Name .. ": Active for " .. totalDuration .. " seconds")

	-- Create a timer with callbacks using the Timers module
	local timerName = "Crystals"

	-- Define callbacks for the timer
	local callbacks = {
		onTick = function(timer)
			-- The timer module will handle its own ticking debug messages
		end,

		onComplete = function(timer)
			-- First update the active status in the stats (do this FIRST to fix the "already active" bug)
			if crystalsActiveStat then
				crystalsActiveStat.Value = false
			end

			-- Hide the size slider
			Utility.Log(debugSystem, "info", "Firing SizeSliderVisibility event with value false to hide slider (onComplete)")
			local hideSuccess, hideErr = pcall(function()
				sliderEvent:FireClient(player, false)
			end)

			if not hideSuccess then
				Utility.Log(debugSystem, "warn", "Failed to hide slider in onComplete: " .. tostring(hideErr))
			end

			-- Reset character to default size (1.0)
			ScaleCharacter.SetScale(player, 1.0)

			Utility.Log(debugSystem, "info", "Crystal effect expired for " .. player.Name)
		end,

		onPause = function(timer)
			Utility.Log(debugSystem, "info", "Crystal effect paused for " .. player.Name .. " with " .. math.floor(timer.timeRemaining) .. " seconds remaining")
		end,

		onResume = function(timer)
			Utility.Log(debugSystem, "info", "Crystal effect resumed for " .. player.Name .. " with " .. math.floor(timer.timeRemaining) .. " seconds remaining")
		end,

		onCancel = function(timer)
			-- First update the active status in the stats (do this FIRST to fix the "already active" bug)
			if crystalsActiveStat then
				crystalsActiveStat.Value = false
			end

			-- Hide the size slider
			Utility.Log(debugSystem, "info", "Firing SizeSliderVisibility event with value false to hide slider (onCancel)")
			local hideSuccess, hideErr = pcall(function()
				sliderEvent:FireClient(player, false)
			end)

			if not hideSuccess then
				Utility.Log(debugSystem, "warn", "Failed to hide slider in onCancel: " .. tostring(hideErr))
			end

			-- Reset character to default size (1.0)
			ScaleCharacter.SetScale(player, 1.0)

			Utility.Log(debugSystem, "info", "Crystal effect canceled for " .. player.Name)
		end,

		onHalfway = function(timer)
			Utility.Log(debugSystem, "info", "Crystal effect halfway point reached for " .. player.Name)
		end,

		onLowTime = function(timer)
			Utility.Log(debugSystem, "info", "Crystal effect almost expired for " .. player.Name)
		end,

		onStart = function(timer)
			Utility.Log(debugSystem, "info", "Crystal effect started for " .. player.Name .. " with duration of " .. timer.duration .. " seconds")
		end,

		-- Set low time threshold to 2 seconds
		lowTimeThreshold = 2
	}

	-- Create the timer - the Timers module now uses player.UserId to prefix the timer name internally
	local timer = Timers.CreateTimer(player, timerName, totalDuration, callbacks)

	if not timer then
		Utility.Log(debugSystem, "warn", "Failed to create timer for " .. player.Name)
		return function() end
	end

	-- Add this line to store the crystal count
	Timers.SetCustomValue(player, timerName, "Count", qty, "IntValue")

	-- Return cleanup function that will run when the booster expires or is canceled
	return function()
		-- Make sure Timers is loaded
		if not Timers then
			Timers = require(ReplicatedStorage.Modules.Core.Timers)
		end

		Utility.Log(debugSystem, "info", "Cleanup function called for Crystal booster")

		-- First update the active status in the stats (do this FIRST to fix the "already active" bug)
		if crystalsActiveStat then
			crystalsActiveStat.Value = false
		end

		-- Hide the size slider
		Utility.Log(debugSystem, "info", "Firing SizeSliderVisibility event with value false to hide slider (cleanup)")
		local hideSuccess, hideErr = pcall(function()
			sliderEvent:FireClient(player, false)
		end)

		if not hideSuccess then
			Utility.Log(debugSystem, "warn", "Failed to hide slider in cleanup: " .. tostring(hideErr))
		end

		-- Reset character to default size (1.0)
		ScaleCharacter.SetScale(player, 1.0)

		-- Cancel the timer if it's still active
		if Timers.TimerExists(player, timerName) then
			Timers.CancelTimer(player, timerName)
		end

		Utility.Log(debugSystem, "info", "Crystal booster cleanup function called for " .. player.Name)
	end
end

return CrystalBooster
