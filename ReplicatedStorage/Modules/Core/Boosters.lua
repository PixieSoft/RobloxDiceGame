-- /ReplicatedStorage/Modules/Core/Boosters.lua
-- ModuleScript that defines all boosters and their properties
-- This is a module that works in both server and client contexts

local Boosters = {}

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")

-- Check if this is running on the server or client
local IsServer = RunService:IsServer()

local function getBoosterNameFromFunction(func)
	for name, item in pairs(Boosters.Items) do
		if item.onActivate == func then
			return name
		end
	end
	return "unknown booster"
end

-- Booster Types for categorization
Boosters.BoosterTypes = {
	PLAYER = "PlayerBoost", -- Affects player character
	DICE = "DiceBoost",     -- Affects dice appearance or performance
	GLOBAL = "GlobalBoost"  -- Affects game-wide mechanics
}

-- Booster definitions with all properties
Boosters.Items = {
	Crystals = {
		name = "Crystal",
		description = "Shrink for 10s per crystal used.",
		imageId = "rbxassetid://72049224483385",
		type = Boosters.BoosterTypes.PLAYER,
		duration = 10, -- 10 seconds per item used
		stacks = false, -- effect does not stack
		canCancel = true, -- can be canceled by player

		-- Function that runs when booster is activated
		onActivate = function(player, qty)
			-- This function only runs on the server
			if not IsServer then return function() end end

			-- DEBUG
			print(player .. " is using " .. qty .. " " .. Boosters.Items.Crystals.name)
			return true
		end
	},

	Mushrooms = {
		name = "Mushroom",
		description = "+1% jump height for 1 minute per mushroom",
		imageId = "rbxassetid://134097767361051",
		boosterType = Boosters.BoosterTypes.PLAYER,
		duration = 60, -- 1 minute in seconds
		stacks = true, -- Allow multiple mushrooms to stack
		canCancel = true,

		-- Function that runs when booster is activated
		onActivate = function(player, qty)
			-- This function only runs on the server
			if not IsServer then return function() end end

			-- DEBUG
			print(player .. " is using " .. qty .. " " .. Boosters.Items.Mushrooms.name)
			return true
		end
	},

	LavaBalls = {
		name = "Lava Ball",
		description = "Drops a block under your feet for 5s. Using 10 doubles the size. Using 100 triples the size.",
		imageId = "rbxassetid://73449632309262",
		boosterType = Boosters.BoosterTypes.PLAYER,
		duration = 300, -- 5 minutes in seconds
		stacks = false,
		canCancel = true,

		-- Function that runs when booster is activated
		onActivate = function(player, qty)
			-- This function only runs on the server
			if not IsServer then return function() end end

			-- DEBUG
			print(player .. " is using " .. qty .. " " .. Boosters.Items.LavaBalls.name)
			return true
		end
	},

	Fuel = {
		name = "Fuel",
		description = "Fills your fuel gauge for transportation.",
		imageId = "rbxassetid://7123456792", -- Replace with actual image ID
		boosterType = Boosters.BoosterTypes.PLAYER,
		stacks = false, -- Cannot stack, simply fills the gauge
		canCancel = false, -- Nothing to cancel

		-- Function that runs when booster is activated
		onActivate = function(player, qty)
			-- This function only runs on the server
			if not IsServer then return function() end end

			-- DEBUG
			print(player .. " is using " .. qty .. " " .. Boosters.Items.Fuel.name)
			return true
		end
	},

	Bugs = {
		name = "Bug",
		description = "Applies a glitch effect to your dice for 30 minutes",
		imageId = "rbxassetid://109760311419104",
		boosterType = Boosters.BoosterTypes.DICE,
		duration = 1800, -- 30 minutes in seconds
		stacks = false,
		canCancel = true,

		-- Function that runs when booster is activated
		onActivate = function(player, qty)
			-- This function only runs on the server
			if not IsServer then return function() end end

			-- DEBUG
			print(player .. " is using " .. qty .. " " .. Boosters.Items.Bugs.name)
			return true
		end
	},

	Pearls = {
		name = "Pearls",
		description = "Applies a glitch effect to your dice for 30 minutes",
		imageId = "rbxassetid://109760311419104z",
		boosterType = Boosters.BoosterTypes.DICE,
		duration = 1800, -- 30 minutes in seconds
		stacks = false,
		canCancel = true,

		-- Function that runs when booster is activated
		onActivate = function(player, qty)
			-- This function only runs on the server
			if not IsServer then return function() end end

			-- DEBUG
			print(player .. " is using " .. qty .. " " .. Boosters.Items.Pearls.name)
			return true
		end
	},
	
	-- Add more boosters here with the same structure
}

-- Only run server-side functionality if we're on the server
if IsServer then
	-- Active boosters storage
	Boosters.ActiveBoosters = {}

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

				print("Created missing booster stat:", boosterName, "for player", player.Name)
			end
		end

		return true
	end

	-- Function to activate a booster for a player
	function Boosters.ActivateBooster(player, boosterName)
		local booster = Boosters.Items[boosterName]
		if not booster then
			warn("Attempted to activate unknown booster:", boosterName)
			return false
		end

		-- Check if player has the booster in their inventory
		local Stat = require(game.ReplicatedStorage.Stat)
		local boosterStat = Stat.Get(player, boosterName)

		if not boosterStat or boosterStat.Value <= 0 then
			warn("Player does not have this booster:", boosterName)
			return false
		end

		-- Initialize player's active boosters table if not exists
		if not Boosters.ActiveBoosters[player.UserId] then
			Boosters.ActiveBoosters[player.UserId] = {}
		end

		-- Check if this booster is already active and doesn't stack
		if not booster.stacks and Boosters.ActiveBoosters[player.UserId][boosterName] then
			warn("Cannot stack this booster:", boosterName)
			return false
		end

		-- Deduct one from player's booster count
		boosterStat.Value = boosterStat.Value - 1

		-- Run the booster's activation function
		local cleanupFunction = booster.onActivate(player)

		-- Store the active booster with its expiration time and cleanup function
		local expirationTime = os.time() + booster.duration

		Boosters.ActiveBoosters[player.UserId][boosterName] = {
			expirationTime = expirationTime,
			cleanup = cleanupFunction
		}

		-- Setup expiration timer
		task.delay(booster.duration, function()
			Boosters.DeactivateBooster(player, boosterName)
		end)

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

	-- Function to deactivate a booster
	function Boosters.DeactivateBooster(player, boosterName)
		if not Boosters.ActiveBoosters[player.UserId] or
			not Boosters.ActiveBoosters[player.UserId][boosterName] then
			return false
		end

		local booster = Boosters.Items[boosterName]
		if not booster.canCancel and os.time() < Boosters.ActiveBoosters[player.UserId][boosterName].expirationTime then
			-- Cannot cancel non-cancelable boosters before they expire
			return false
		end

		-- Run cleanup function
		if Boosters.ActiveBoosters[player.UserId][boosterName].cleanup then
			Boosters.ActiveBoosters[player.UserId][boosterName].cleanup()
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

	-- Function to get remaining time for an active booster
	function Boosters.GetRemainingTime(player, boosterName)
		if not Boosters.ActiveBoosters[player.UserId] or
			not Boosters.ActiveBoosters[player.UserId][boosterName] then
			return 0
		end

		local timeLeft = Boosters.ActiveBoosters[player.UserId][boosterName].expirationTime - os.time()
		return math.max(0, timeLeft)
	end

	-- Function to get all active boosters for a player
	function Boosters.GetActiveBoosters(player)
		if not Boosters.ActiveBoosters[player.UserId] then
			return {}
		end

		local result = {}
		local currentTime = os.time()

		for boosterName, boosterData in pairs(Boosters.ActiveBoosters[player.UserId]) do
			local timeLeft = boosterData.expirationTime - currentTime
			if timeLeft > 0 then
				result[boosterName] = timeLeft
			end
		end

		return result
	end

	-- Function to check if a specific booster is active
	function Boosters.IsBoosterActive(player, boosterName)
		if not Boosters.ActiveBoosters[player.UserId] or
			not Boosters.ActiveBoosters[player.UserId][boosterName] then
			return false
		end

		local timeLeft = Boosters.ActiveBoosters[player.UserId][boosterName].expirationTime - os.time()
		return timeLeft > 0
	end

	-- Cleanup function for when player leaves
	function Boosters.CleanupPlayerBoosters(player)
		if not Boosters.ActiveBoosters[player.UserId] then
			return
		end

		for boosterName, boosterData in pairs(Boosters.ActiveBoosters[player.UserId]) do
			if boosterData.cleanup then
				boosterData.cleanup()
			end
		end

		Boosters.ActiveBoosters[player.UserId] = nil
	end

	-- Create necessary events when module is loaded
	local function SetupEvents()
		local ReplicatedStorage = game:GetService("ReplicatedStorage")

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
				local eventType = eventName == "UseBooster" and "RemoteEvent" or "RemoteEvent"
				local event = Instance.new(eventType)
				event.Name = eventName
				event.Parent = BoosterEvents
			end
		end

		-- Connect UseBooster event to activation function
		local useBoosterEvent = BoosterEvents:FindFirstChild("UseBooster")
		if useBoosterEvent then
			useBoosterEvent.OnServerEvent:Connect(function(player, boosterName, count)
				count = count or 1 -- Default to 1 if no count provided
				for i = 1, count do
					if not Boosters.ActivateBooster(player, boosterName) then
						break -- Stop if activation fails (e.g., player ran out)
					end
				end
			end)
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
		end)
	end

	-- Initialize events when module is required on the server
	SetupEvents()
else
	-- Client-side functionality

	-- Define simple versions of functions for the client
	function Boosters.GetActiveBoosters(player)
		-- On the client, this just returns an empty table
		-- The actual data comes from the leaderstats
		return {}
	end

	function Boosters.IsBoosterActive(player, boosterName)
		-- On the client, check leaderstats for active indicator
		local leaderstats = player:FindFirstChild("leaderstats")
		if leaderstats then
			local boostersFolder = leaderstats:FindFirstChild("Boosters")
			if boostersFolder then
				local activeIndicator = boostersFolder:FindFirstChild(boosterName .. "_Active")
				return activeIndicator ~= nil and activeIndicator.Value > 0
			end
		end
		return false
	end
end

return Boosters
