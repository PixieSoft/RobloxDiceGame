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
local BOOSTERS_PATH = ReplicatedStorage:FindFirstChild("Modules"):FindFirstChild("Core"):FindFirstChild("Boosters")

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
		warn("Boosters folder not found at path: ReplicatedStorage.Modules.Core.Boosters")
		return
	end

	print("Loading booster modules from:", BOOSTERS_PATH:GetFullName())

	-- Print all children of the Boosters folder to debug
	for _, child in pairs(BOOSTERS_PATH:GetChildren()) do
		print("Found module in Boosters folder:", child.Name)
	end

	-- Try to load the Crystals module specifically
	if BOOSTERS_PATH:FindFirstChild("Crystals") then
		print("Found Crystals module, attempting to load...")
		local success = loadBooster("Crystals", BOOSTERS_PATH.Crystals)
		if success then
			print("Crystals booster loaded successfully!")
		else
			warn("Failed to load Crystals booster")
		end
	else
		warn("Crystals module not found in " .. BOOSTERS_PATH:GetFullName())
	end

	-- Add more booster module loading here as you create them
	-- Example: if BOOSTERS_PATH:FindFirstChild("Mushrooms") then loadBooster("Mushrooms", BOOSTERS_PATH.Mushrooms) end
end

-- Define boosters that haven't been moved to their own modules yet
-- These will be combined with the dynamically loaded boosters
local function defineBuiltInBoosters()
	Boosters.Items.Bugs = {
		-- Make this 1% for 1m per bug with a minimum of +1 speed
		name = "Bug",
		description = "+1 walkspeed for 1 minute per bug used",
		imageId = "rbxassetid://109760311419104",
		boosterType = Boosters.BoosterTypes.PLAYER,
		duration = 60, -- 60 seconds (1 minute) per bug
		stacks = true, -- Allows stacking multiple bugs at once for stronger effect
		canCancel = true,

		-- Function that runs when booster is activated
		onActivate = function(player, qty)
			-- This function only runs on the server
			if not IsServer then return function() end end

			-- Get the player's character and humanoid
			local character = player.Character
			if not character then return function() end end

			local humanoid = character:FindFirstChildOfClass("Humanoid")
			if not humanoid then return function() end end

			-- Store original walk speed
			local originalWalkSpeed = humanoid.WalkSpeed

			-- Increase walk speed by 1 for each bug used
			humanoid.WalkSpeed = originalWalkSpeed + qty

			-- Print feedback
			print("Activated Bug booster for " .. player.Name .. ": +" .. qty .. " walkspeed for " .. (qty * 60) .. " seconds")

			-- Setup character added event in case player dies during effect
			local characterAddedConnection
			characterAddedConnection = player.CharacterAdded:Connect(function(newCharacter)
				-- Wait for the humanoid to be added
				local newHumanoid = newCharacter:WaitForChild("Humanoid")

				-- Apply the speed boost to the new character
				if newHumanoid then
					newHumanoid.WalkSpeed = originalWalkSpeed + qty
				end
			end)

			-- Return cleanup function
			return function()
				-- Disconnect the CharacterAdded event
				if characterAddedConnection then
					characterAddedConnection:Disconnect()
				end

				-- Restore original walk speed if the character still exists
				local currentCharacter = player.Character
				if currentCharacter then
					local currentHumanoid = currentCharacter:FindFirstChildOfClass("Humanoid")
					if currentHumanoid then
						currentHumanoid.WalkSpeed = originalWalkSpeed
						print("Bug booster expired for " .. player.Name .. ": walkspeed restored to " .. originalWalkSpeed)
					end
				end
			end
		end
	}

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

	Boosters.Items.Mushrooms = {
		-- Jump Height bonus. 7.2 base. 40 is comfy, 100 too much indoor. 100-200 outdoor gets on trees.
		-- can buy up base.
		-- +1m per item used.
		-- +0.5 per item used? gives noticable bonus.
		-- maybe 1.0 per item? spending 100 should get to treetops in swamp
		-- need to be able to get into trees to get Nyx. gathering 100 shrooms pretty quick.
		name = "Mushroom",
		description = "+1% jump height for 1 minute per mushroom",
		imageId = "rbxassetid://134097767361051",
		boosterType = Boosters.BoosterTypes.PLAYER,
		duration = 60, -- 1 minute = 60 seconds
		stacks = true, -- Allow multiple mushrooms to stack
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

	-- Add the Crystal booster directly as a fallback
	-- This ensures it's available even if module loading fails
	if not Boosters.Items.Crystals then
		print("Adding Crystal booster directly as fallback")
		Boosters.Items.Crystals = {
			name = "Crystal",
			description = "Shrink for 10s per crystal used.",
			imageId = "rbxassetid://72049224483385",
			boosterType = Boosters.BoosterTypes.PLAYER,
			duration = 10, -- 10 seconds per item used
			stacks = false, -- effect does not stack
			canCancel = true, -- can be canceled by player

			-- Function that runs when booster is activated
			onActivate = function(player, qty)
				-- This function only runs on the server
				if not IsServer then return function() end end

				-- Return a proper cleanup function
				if IsServer then
					-- Simple implementation until module loading is fixed
					local PlayerSize = require(game.ServerScriptService.Modules.Effects.PlayerSize)
					if PlayerSize then
						PlayerSize.TogglePlayerSize(player)

						-- Return cleanup function that will run when the booster expires
						return function()
							-- Toggle size back to normal
							PlayerSize.TogglePlayerSize(player)
						end
					end
				end

				return function() end
			end
		}
	end
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
