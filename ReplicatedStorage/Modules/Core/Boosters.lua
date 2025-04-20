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

	-- Debug: Print the full path to the Boosters folder
	print("DEBUG - Loading booster modules from:", BOOSTERS_PATH:GetFullName())

	-- Debug: Check if the folder exists and what's in it
	if BOOSTERS_PATH then
		print("DEBUG - Boosters folder exists with " .. #BOOSTERS_PATH:GetChildren() .. " children")
		for i, child in ipairs(BOOSTERS_PATH:GetChildren()) do
			print("DEBUG - Child #" .. i .. ": " .. child.Name .. " (" .. child.ClassName .. ")")
		end
	else
		print("DEBUG - Boosters folder not found!")
	end

	-- Debug: Check specifically for Crystals module
	local crystalsModule = BOOSTERS_PATH and BOOSTERS_PATH:FindFirstChild("Crystals")
	if crystalsModule then
		print("DEBUG - Crystals module found! Attempting to load...")
	else
		print("DEBUG - Crystals module NOT found in Boosters folder!")
	end

	-- Iterate through all modules in the Boosters folder
	for _, module in pairs(BOOSTERS_PATH:GetChildren()) do
		if module:IsA("ModuleScript") then
			local boosterName = module.Name
			print("Loading booster module:", boosterName)

			-- Debug: More verbose loading process
			print("DEBUG - Attempting to load " .. boosterName .. "...")
			local success = loadBooster(boosterName, module)
			if success then
				print("DEBUG - Successfully loaded " .. boosterName .. "!")
			else
				print("DEBUG - Failed to load " .. boosterName .. "!")
			end
		end
	end

	-- Debug: Print all loaded boosters
	print("DEBUG - Loaded boosters in Boosters.Items:")
	for name, _ in pairs(Boosters.Items) do
		print("DEBUG - - " .. name)
	end

	-- Print summary of loaded boosters
	local boosterCount = 0
	for name, _ in pairs(Boosters.Items) do
		boosterCount = boosterCount + 1
	end
	print("Total boosters loaded:", boosterCount)
end

-- Define boosters that haven't been moved to their own modules yet
-- These will be combined with the dynamically loaded boosters
local function defineBuiltInBoosters()
	Boosters.Items.Fuel = {
		-- 1 fuel used per teleport
		-- 1 fuel to fill gauge for jetpack to fly, minecarts to go faster?
		-- make flowers grow?
		-- 100 poops to summon boss in greenhouse or somewhere?
		name = "Fuel",
		description = "Fills your fuel gauge for transportation.",
		imageId = "rbxassetid://7123456792", -- Replace with actual image ID
		boosterType = Boosters.BoosterTypes.PLAYER,
		duration = 60, -- Not really a duration-based booster, but set to 60 seconds
		stacks = false, -- Cannot stack, simply fills the gauge
		canCancel = false, -- Nothing to cancel

		-- Function that runs when booster is activated
		onActivate = function(player, qty)
			-- This function only runs on the server
			if not IsServer then return function() end end

			-- Return a proper cleanup function
			return function() end
		end
	}

	Boosters.Items.LavaBalls = {
		-- drop a lava block. 1x1 default. 2x2 if spend 10. 3x3 for 100. 4x4 for 1000.
		-- 5s per ball
		-- generally used for jump boosting
		-- use while jumping. summons in the air. can use this to hold yourself and jump again.
		-- comes into existence colliding only with player. anchors immediately. then becomes
		-- collidable with everything. keep it flat and aligned with the world. 
		name = "Lava Ball",
		description = "Drops a block under your feet for 5s. Using 10 doubles the size. Using 100 triples the size.",
		imageId = "rbxassetid://73449632309262",
		boosterType = Boosters.BoosterTypes.PLAYER,
		duration = 5, -- 5 seconds
		stacks = false,
		canCancel = true,

		-- Function that runs when booster is activated
		onActivate = function(player, qty)
			-- This function only runs on the server
			if not IsServer then return function() end end

			-- Return a proper cleanup function
			return function() end
		end
	}

	Boosters.Items.Pearls = {
		-- +1m underwater breathing (get 5m free) and a speed boost
		-- also can buy longer base water breathing time
		-- in center of game, there's a cup. it gets a pearl in it for every pearl people find.
		-- anyone can fight the boss. if you win, you get all the pearls. split if multiplayer.
		-- exclusive boss fights? optional for starter?
		name = "Pearls",
		description = "Applies a glitch effect to your dice for 30 minutes",
		imageId = "rbxassetid://109760311419104z",
		boosterType = Boosters.BoosterTypes.DICE,
		duration = 1800, -- 30 minutes = 1800 seconds
		stacks = false,
		canCancel = true,

		-- Function that runs when booster is activated
		onActivate = function(player, qty)
			-- This function only runs on the server
			if not IsServer then return function() end end

			-- Fire server event 
			local UsePearlEvent = ReplicatedStorage.Events.Core:WaitForChild("UsePearlEvent")
			UsePearlEvent:FireServer(player, qty)

			-- Return a proper cleanup function
			return function() end
		end
	}
end

-- Print the current module loading status
print("Initializing Boosters module...")

-- Initialize the boosters
defineBuiltInBoosters()
loadBoosterModules()

-- Print the number of booster types loaded
local boosterCount = 0
for name, _ in pairs(Boosters.Items) do
	boosterCount = boosterCount + 1
	print("Loaded booster: " .. name)
end
print("Total boosters loaded: " .. boosterCount)

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

				print("Created stat for booster: " .. boosterName)
			end
		end

		return true
	end

	-- Function to activate a booster for a player
	function Boosters.ActivateBooster(player, boosterName, quantity, cleanupFunction)
		-- Default quantity to 1 if not provided
		quantity = quantity or 1

		local booster = Boosters.Items[boosterName]
		if not booster then
			warn("Attempted to activate unknown booster:", boosterName)
			return false
		end

		-- Initialize player's active boosters table if not exists
		if not Boosters.ActiveBoosters[player.UserId] then
			Boosters.ActiveBoosters[player.UserId] = {}
		end

		-- Check if this booster is already active
		-- For all boosters (even those with stacks=true), prevent re-activation while active
		if Boosters.ActiveBoosters[player.UserId][boosterName] then
			warn("Cannot activate booster while already active:", boosterName)
			return false
		end

		-- Calculate total duration (base duration * quantity)
		local totalDuration = booster.duration * quantity

		-- Store the active booster with its expiration time and cleanup function
		local expirationTime = os.time() + totalDuration

		-- Make sure cleanupFunction is actually a function or set it to an empty function
		if type(cleanupFunction) ~= "function" then
			cleanupFunction = function() end
		end

		Boosters.ActiveBoosters[player.UserId][boosterName] = {
			expirationTime = expirationTime,
			cleanup = cleanupFunction
		}

		-- Setup expiration timer with the total duration
		task.delay(totalDuration, function()
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
		if not booster then return false end

		if not booster.canCancel and os.time() < Boosters.ActiveBoosters[player.UserId][boosterName].expirationTime then
			-- Cannot cancel non-cancelable boosters before they expire
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
		if not player or not player.UserId or not Boosters.ActiveBoosters[player.UserId] then
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
		if not player or not player.UserId or not Boosters.ActiveBoosters[player.UserId] or
			not Boosters.ActiveBoosters[player.UserId][boosterName] then
			return false
		end

		local timeLeft = Boosters.ActiveBoosters[player.UserId][boosterName].expirationTime - os.time()
		return timeLeft > 0
	end

	-- Cleanup function for when player leaves
	function Boosters.CleanupPlayerBoosters(player)
		if not player or not player.UserId or not Boosters.ActiveBoosters[player.UserId] then
			return
		end

		for boosterName, boosterData in pairs(Boosters.ActiveBoosters[player.UserId]) do
			if boosterData.cleanup and type(boosterData.cleanup) == "function" then
				local success, errorMsg = pcall(function()
					boosterData.cleanup()
				end)

				if not success then
					warn("Error in cleanup function for booster", boosterName, ":", errorMsg)
				end
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
