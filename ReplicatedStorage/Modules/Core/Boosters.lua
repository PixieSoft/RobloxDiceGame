-- /ReplicatedStorage/Modules/Core/Boosters.lua
-- ModuleScript that defines all boosters and their properties
-- This is a server-side module for managing booster functionality
-- See Boosters in OneNote for recent discussion notes

local Boosters = {}

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- Booster Types for categorization
Boosters.BoosterTypes = {
	PLAYER = "PlayerBoost", -- Affects player character
	DICE = "DiceBoost",     -- Affects dice appearance or performance
	GLOBAL = "GlobalBoost"  -- Affects game-wide mechanics
}

--mushrooms small
--bugs jump
--light crystals walk speed
--pearls swim speed
--lavaball drop a block
--fuel jetpack (maybe more)
-- come from object in world, pick up a thing from an object with a tag
-- that tag is the only thing that tells you the object can be picked up
-- whole world is build around this, do need it to work
-- e to pick up

-- alternative: affect dice game. all of dice, ui, frame other items that affect
-- dice game. these will be cards that spin around, not looking like part of the
-- scenery. float like a spinning hologram, like fruits but flat.
-- fruits, dice will look like part of the world. these will spin around flat.
-- betting, odds of face die, anything that affects with game within the game.


-- Booster definitions with all properties
Boosters.Boosters = {
	BeanBags = {
		name = "Bean Bags",
		description = "Increases player lounginess by 58% for 13 minutes",
		imageId = "rbxassetid://7123456789", -- Replace with actual image ID
		boosterType = Boosters.BoosterTypes.PLAYER,
		duration = 1800, -- 3 minutes in seconds
		stacks = false,
		canCancel = true,

		-- Function that runs when booster is activated
		onActivate = function(player)
			-- Get character and increase walk speed
			local character = player.Character or player.CharacterAdded:Wait()
			local humanoid = character:FindFirstChildOfClass("Humanoid")

			if humanoid then
				local originalSpeed = humanoid.WalkSpeed
				humanoid.WalkSpeed = originalSpeed * 1.25

				-- Return cleanup function that will run when effect ends or is canceled
				return function()
					-- Make sure character still exists
					if character and character.Parent and humanoid and humanoid.Parent then
						humanoid.WalkSpeed = originalSpeed
					end
				end
			end

			return function() end -- Return empty cleanup if no humanoid found
		end
	},

	LightCrystals = {
		name = "Light Crystal",
		description = "Increases player speed by 25% for 3 minutes",
		imageId = "rbxassetid://7123456789", -- Replace with actual image ID
		boosterType = Boosters.BoosterTypes.PLAYER,
		duration = 180, -- 3 minutes in seconds
		stacks = false,
		canCancel = true,

		-- Function that runs when booster is activated
		onActivate = function(player)
			-- Get character and increase walk speed
			local character = player.Character or player.CharacterAdded:Wait()
			local humanoid = character:FindFirstChildOfClass("Humanoid")

			if humanoid then
				local originalSpeed = humanoid.WalkSpeed
				humanoid.WalkSpeed = originalSpeed * 1.25

				-- Return cleanup function that will run when effect ends or is canceled
				return function()
					-- Make sure character still exists
					if character and character.Parent and humanoid and humanoid.Parent then
						humanoid.WalkSpeed = originalSpeed
					end
				end
			end

			return function() end -- Return empty cleanup if no humanoid found
		end
	},

	Mushrooms = {
		name = "Magic Mushroom",
		description = "Allows player to jump 50% higher for 2 minutes",
		imageId = "rbxassetid://7123456790", -- Replace with actual image ID
		boosterType = Boosters.BoosterTypes.PLAYER,
		duration = 120, -- 2 minutes in seconds
		stacks = false,
		canCancel = true,

		onActivate = function(player)
			local character = player.Character or player.CharacterAdded:Wait()
			local humanoid = character:FindFirstChildOfClass("Humanoid")

			if humanoid then
				local originalJumpPower = humanoid.JumpPower
				humanoid.JumpPower = originalJumpPower * 1.5

				return function()
					if character and character.Parent and humanoid and humanoid.Parent then
						humanoid.JumpPower = originalJumpPower
					end
				end
			end

			return function() end
		end
	},

	LavaBalls = {
		name = "Lava Ball",
		description = "Grants immunity to fire damage for 5 minutes",
		imageId = "rbxassetid://7123456791", -- Replace with actual image ID
		boosterType = Boosters.BoosterTypes.PLAYER,
		duration = 300, -- 5 minutes in seconds
		stacks = false,
		canCancel = true,

		onActivate = function(player)
			-- Set a player attribute to track fire immunity
			player:SetAttribute("FireImmune", true)

			-- Return cleanup function
			return function()
				player:SetAttribute("FireImmune", false)
			end
		end
	},

	Fuel = {
		name = "Rocket Fuel",
		description = "Doubles tycoon income for 10 minutes",
		imageId = "rbxassetid://7123456792", -- Replace with actual image ID
		boosterType = Boosters.BoosterTypes.TYCOON,
		duration = 600, -- 10 minutes in seconds
		stacks = true, -- Multiple fuel boosters can stack
		canCancel = false, -- Cannot be canceled once activated

		onActivate = function(player)
			-- Set multiplier attribute on player
			local currentMultiplier = player:GetAttribute("IncomeMultiplier") or 1
			player:SetAttribute("IncomeMultiplier", currentMultiplier * 2)

			-- Return cleanup function
			return function()
				local multiplier = player:GetAttribute("IncomeMultiplier") or 2
				player:SetAttribute("IncomeMultiplier", multiplier / 2)
			end
		end
	},

	Bugs = {
		name = "Glitch Bug",
		description = "Applies a glitch effect to your dice for 30 minutes",
		imageId = "rbxassetid://7123456793", -- Replace with actual image ID
		boosterType = Boosters.BoosterTypes.DICE,
		duration = 1800, -- 30 minutes in seconds
		stacks = false,
		canCancel = true,

		onActivate = function(player)
			-- Get player's dice inventory
			local diceInventory = player:FindFirstChild("DiceInventory")
			local affectedDice = {}

			-- Apply effect to all dice
			if diceInventory then
				for _, die in ipairs(diceInventory:GetChildren()) do
					if die:IsA("BasePart") and die:GetAttribute("IsDie") then
						die:SetAttribute("GlitchEffect", true)
						table.insert(affectedDice, die)
					end
				end
			end

			-- Return cleanup function
			return function()
				for _, die in ipairs(affectedDice) do
					if die and die.Parent then
						die:SetAttribute("GlitchEffect", false)
					end
				end
			end
		end
	}

	-- Add more boosters here with the same structure
}

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
	for boosterName, _ in pairs(Boosters.Boosters) do
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
	local booster = Boosters.Boosters[boosterName]
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

	if not Boosters.Boosters[boosterName] then
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

	local booster = Boosters.Boosters[boosterName]
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
		useBoosterEvent.OnServerEvent:Connect(function(player, boosterName)
			Boosters.ActivateBooster(player, boosterName)
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

-- Initialize events when module is required
SetupEvents()

return Boosters
