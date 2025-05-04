-- /ReplicatedStorage/Modules/Core/Boosters.lua
-- ModuleScript that defines all boosters and their properties
-- This is a module that works in both server and client contexts

local Boosters = {}

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Check if this is running on the server or client  
local IsServer = RunService:IsServer()

-- Booster Types for categorization
Boosters.BoosterTypes = {
	PLAYER = "PlayerBoost", -- Affects player character
	DICE = "DiceBoost",     -- Affects dice appearance or performance
	GLOBAL = "GlobalBoost"  -- Affects game-wide mechanics
}

-- Initialize the boosters table
Boosters.Items = {}

-- Path to booster modules
local BOOSTERS_PATH = ReplicatedStorage.Modules.Core:FindFirstChild("BoosterDefs")

-- Function to load an individual booster
local function loadBooster(name, module)
	local success, boosterData = pcall(require, module)

	if success then
		-- Map boosterType string to actual enum if needed
		if boosterData.boosterType and type(boosterData.boosterType) == "string" then
			for typeName, typeValue in pairs(Boosters.BoosterTypes) do
				if boosterData.boosterType == typeValue then
					boosterData.boosterType = Boosters.BoosterTypes[typeName]
					break
				end
			end
		end

		-- Add to the Items dictionary
		Boosters.Items[name] = boosterData
		print("Successfully loaded booster module: " .. name)
		return true
	else
		warn("Failed to load booster module " .. name .. ": " .. tostring(boosterData))
		return false
	end
end

-- Load individual booster modules from the Boosters folder
local function loadBoosterModules()
	-- Check if the Boosters folder exists
	if not BOOSTERS_PATH then
		error("Boosters folder not found at path: ReplicatedStorage.Modules.Core.Boosters")
		return
	end

	-- Iterate through all modules in the Boosters folder
	for _, module in pairs(BOOSTERS_PATH:GetChildren()) do
		if module:IsA("ModuleScript") then
			local boosterName = module.Name
			loadBooster(boosterName, module)
		end
	end

	-- Print summary of loaded boosters
	local boosterCount = 0
	for name, _ in pairs(Boosters.Items) do
		boosterCount = boosterCount + 1
	end
	print("Total boosters loaded:", boosterCount)
end

-- Initialize the boosters
loadBoosterModules()

-- Only run server-side functionality if we're on the server
if IsServer then
	-- Active boosters storage
	Boosters.ActiveBoosters = {}

	-- Centralized Slider Visibility Control Function
	function Boosters.SetSizeSliderVisibility(player, visible)
		-- Load Utility for debug logging
		local Utility = require(ReplicatedStorage.Modules.Core.Utility)
		local debugSystem = "Boosters"

		-- Ensure remote event exists
		local sizeSliderEvent = Boosters.GetSizeSliderEvent()

		if not sizeSliderEvent then
			Utility.Log(debugSystem, "warn", "Failed to get size slider event")
			return false
		end

		-- Fire the visibility change event to the client
		Utility.Log(debugSystem, "info", "Attempting to fire size slider visibility event to " .. player.Name .. " with value: " .. tostring(visible))

		local success, err = pcall(function()
			sizeSliderEvent:FireClient(player, visible)
		end)

		if success then
			Utility.Log(debugSystem, "info", "Successfully fired size slider visibility event to " .. player.Name .. " with value: " .. tostring(visible))
		else
			Utility.Log(debugSystem, "warn", "Failed to fire size slider visibility event: " .. tostring(err))
			return false
		end

		return true
	end

	-- Helper function to get or create the size slider event
	function Boosters.GetSizeSliderEvent()
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

		local sizeSliderEvent = coreFolder:FindFirstChild("SizeSliderVisibility")
		if not sizeSliderEvent then
			sizeSliderEvent = Instance.new("RemoteEvent")
			sizeSliderEvent.Name = "SizeSliderVisibility"
			sizeSliderEvent.Parent = coreFolder
			print("[Boosters] Created SizeSliderVisibility RemoteEvent")
		end

		return sizeSliderEvent
	end

	-- Function to ensure all booster stats exist for a player
	function Boosters.EnsureBoosterStats(player)
		local Stat = require(game.ReplicatedStorage.Stat)

		-- Make sure player data is loaded
		if not Stat.WaitForLoad(player) then
			warn("Player data failed to load for", player.Name)
			return false
		end

		-- Try to get data folder
		local dataFolder = Stat.GetDataFolder(player)
		if not dataFolder then
			warn("Could not get data folder for player", player.Name)
			return false
		end

		-- Find or create Boosters folder
		local boostersFolder = dataFolder:FindFirstChild("Boosters")
		if not boostersFolder then
			boostersFolder = Instance.new("Folder")
			boostersFolder.Name = "Boosters"
			boostersFolder.Parent = dataFolder
		end

		-- Create stats for each booster type
		for boosterName, boosterInfo in pairs(Boosters.Items) do
			local boosterStat = Stat.Get(player, boosterName)

			if not boosterStat then
				-- Create new stat
				local newStat = Instance.new("NumberValue")
				newStat.Name = boosterName
				newStat.Value = 0 -- Start with 0 boosters
				newStat.Parent = boostersFolder
			end
		end

		return true
	end

	-- Central function to activate a booster for a player
	function Boosters.UseBooster(player, boosterName, quantity)
		-- Load Timers module
		local Timers = require(ReplicatedStorage.Modules.Core.Timers)

		-- Get booster configuration
		local booster = Boosters.Items[boosterName]
		if not booster then
			warn("Attempted to use unknown booster:", boosterName)
			return false
		end

		-- Check if this booster is already active using the Timers system
		if Timers.TimerExists(player, boosterName) then
			warn("Cannot activate booster while already active:", boosterName)
			return false
		end

		-- Call the booster's onActivate function to apply effects
		local cleanupFunction
		if type(booster.onActivate) == "function" then
			local success, result = pcall(function()
				return booster.onActivate(player, quantity)
			end)

			if success then
				cleanupFunction = result
			else
				warn("Failed to activate booster " .. boosterName .. ": " .. tostring(result))
				return false
			end
		else
			warn("Booster " .. boosterName .. " doesn't have an onActivate function")
			return false
		end

		-- Make sure cleanupFunction is actually a function
		if type(cleanupFunction) ~= "function" then
			cleanupFunction = function() end
		end

		-- Handle size slider visibility for Crystals
		if boosterName == "Crystals" then
			Boosters.SetSizeSliderVisibility(player, true)
		end

		-- Calculate total duration (base duration * quantity)
		local totalDuration = booster.duration * quantity

		-- Store the active booster with its expiration time and cleanup function
		local expirationTime = os.time() + totalDuration

		-- Initialize player's active boosters table if not exists
		if not Boosters.ActiveBoosters[player.UserId] then
			Boosters.ActiveBoosters[player.UserId] = {}
		end

		Boosters.ActiveBoosters[player.UserId][boosterName] = {
			expirationTime = expirationTime,
			cleanup = cleanupFunction
		}

		-- Create a timer to manage the booster
		local callbacks = {
			onTick = function(timer)
				-- Optional: Update UI or other systems
			end,

			onComplete = function(timer)
				-- Hide size slider before running cleanup
				if boosterName == "Crystals" then
					Boosters.SetSizeSliderVisibility(player, false)
				end

				-- Run cleanup when timer completes  
				Boosters.DeactivateBooster(player, boosterName)
			end,

			onCancel = function(timer)
				-- Hide size slider before running cleanup
				if boosterName == "Crystals" then
					Boosters.SetSizeSliderVisibility(player, false)
				end

				-- Run cleanup when timer is canceled
				Boosters.DeactivateBooster(player, boosterName)
			end,

			onStart = function(timer)
				-- Optional: Initialize any effects when timer starts
			end
		}

		-- Create the timer - this is the single source of truth for activation status
		local timer = Timers.CreateTimer(player, boosterName, totalDuration, callbacks)

		if not timer then
			warn("Failed to create timer for " .. boosterName)
			return false
		end

		-- Store the quantity as custom value in the timer
		Timers.SetCustomValue(player, boosterName, "Count", quantity, "IntValue")

		-- Fire event for UI updates or other systems
		local BoosterEvents = game.ReplicatedStorage:FindFirstChild("BoosterEvents")
		if BoosterEvents then
			local activatedEvent = BoosterEvents:FindFirstChild("BoosterActivated")
			if activatedEvent then
				activatedEvent:FireClient(player, boosterName, expirationTime)
			end
		end

		return true
	end

	-- Function to deactivate a booster
	function Boosters.DeactivateBooster(player, boosterName)
		if not Boosters.ActiveBoosters[player.UserId] or
			not Boosters.ActiveBoosters[player.UserId][boosterName] then
			return false
		end

		-- Run cleanup function safely
		if Boosters.ActiveBoosters[player.UserId][boosterName].cleanup then
			local success, errorMsg = pcall(function()
				Boosters.ActiveBoosters[player.UserId][boosterName].cleanup()
			end)

			if not success then
				warn("Error in cleanup function for booster", boosterName, ":", errorMsg)
			end
		end

		-- Remove from active boosters
		Boosters.ActiveBoosters[player.UserId][boosterName] = nil

		-- Fire event for UI updates
		local BoosterEvents = game.ReplicatedStorage:FindFirstChild("BoosterEvents")
		if BoosterEvents then
			local deactivatedEvent = BoosterEvents:FindFirstChild("BoosterDeactivated")
			if deactivatedEvent then
				deactivatedEvent:FireClient(player, boosterName)
			end
		end

		return true
	end

	-- Function to check if a specific booster is active
	function Boosters.IsBoosterActive(player, boosterName)
		-- Load Timers module
		local Timers = require(ReplicatedStorage.Modules.Core.Timers)

		if not player or not player.UserId then
			return false
		end

		-- Simply use Timers system to check if timer exists
		return Timers.TimerExists(player, boosterName)
	end

	-- Function to get remaining time for a booster
	function Boosters.GetRemainingTime(player, boosterName)
		-- Load Timers module
		local Timers = require(ReplicatedStorage.Modules.Core.Timers)

		-- Use Timers system to get remaining time
		return Timers.GetTimeRemaining(player, boosterName)
	end

	-- Function to get all active boosters for a player
	function Boosters.GetActiveBoosters(player)
		-- Load Timers module
		local Timers = require(ReplicatedStorage.Modules.Core.Timers)

		if not player or not player.UserId then
			return {}
		end

		local result = {}

		-- Get all active timers related to boosters
		local allTimers = Timers.GetAllPlayersTimers()
		local playerTimers = allTimers[player.UserId] or {}

		for timerName, timerData in pairs(playerTimers) do
			-- Check if this timer is for a booster
			if Boosters.Items[timerName] then
				result[timerName] = timerData.timeRemaining
			end
		end

		return result
	end

	-- Function to give booster items to a player
	function Boosters.GiveBooster(player, boosterName, amount)
		amount = amount or 1

		if not Boosters.Items[boosterName] then
			warn("Attempted to give unknown booster:", boosterName)
			return false
		end

		local Stat = require(game.ReplicatedStorage.Stat)
		local boosterStat = Stat.Get(player, boosterName)

		if not boosterStat then
			-- Try to create the stat if it doesn't exist
			Boosters.EnsureBoosterStats(player)
			boosterStat = Stat.Get(player, boosterName)

			if not boosterStat then
				warn("Could not create or find booster stat:", boosterName)
				return false
			end
		end

		boosterStat.Value = boosterStat.Value + amount
		return true
	end

	-- Function to clean up a player's boosters when they leave
	function Boosters.CleanupPlayerBoosters(player)
		-- Load Timers module
		local Timers = require(ReplicatedStorage.Modules.Core.Timers)

		if not player or not player.UserId then return end

		-- Clean up all active boosters for the player
		if Boosters.ActiveBoosters[player.UserId] then
			for boosterName, _ in pairs(Boosters.ActiveBoosters[player.UserId]) do
				-- Cancel any active timers
				if Timers.TimerExists(player, boosterName) then
					Timers.CancelTimer(player, boosterName)
				end
			end

			-- Clear the player's active boosters
			Boosters.ActiveBoosters[player.UserId] = nil
		end
	end

	-- Create necessary events when module is loaded
	local function SetupEvents()
		-- Create events folder if it doesn't exist
		local BoosterEvents = ReplicatedStorage:FindFirstChild("BoosterEvents")
		if not BoosterEvents then
			BoosterEvents = Instance.new("Folder")
			BoosterEvents.Name = "BoosterEvents"
			BoosterEvents.Parent = ReplicatedStorage
		end

		-- Create necessary events
		local events = {
			"BoosterActivated",   -- Fired when a booster is activated
			"BoosterDeactivated", -- Fired when a booster ends or is canceled
			"UseBooster"          -- Remote event for clients to request using a booster
		}

		for _, eventName in ipairs(events) do
			if not BoosterEvents:FindFirstChild(eventName) then
				local event = Instance.new("RemoteEvent")
				event.Name = eventName
				event.Parent = BoosterEvents
			end
		end

		-- Connect player leaving to cleanup
		Players.PlayerRemoving:Connect(function(player)
			Boosters.CleanupPlayerBoosters(player)
		end)

		-- Set up initial stats for existing players
		for _, player in ipairs(Players:GetPlayers()) do
			Boosters.EnsureBoosterStats(player)
		end

		-- Ensure new players get booster stats created
		Players.PlayerAdded:Connect(function(player)
			Boosters.EnsureBoosterStats(player)

			-- Check for active Crystals timer and sync slider visibility
			task.delay(1, function() -- Small delay to ensure player is fully loaded
				local Timers = require(ReplicatedStorage.Modules.Core.Timers)
				local Utility = require(ReplicatedStorage.Modules.Core.Utility)
				local debugSystem = "Boosters"

				if Timers.TimerExists(player, "Crystals") then
					Utility.Log(debugSystem, "info", "Player " .. player.Name .. " joined with active Crystals timer - showing slider")
					Boosters.SetSizeSliderVisibility(player, true)
				else
					Utility.Log(debugSystem, "info", "Player " .. player.Name .. " joined without active Crystals timer")
				end
			end)
		end)
	end

	-- Initialize events when module is required on the server
	SetupEvents()
end

return Boosters
