-- /ReplicatedStorage/Modules/Core/PlayerStatsHandler.lua
-- Central handler for all player stat modifications (speed, jump power, etc.)

local PlayerStatsHandler = {}

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Module references
local Timers = require(ReplicatedStorage.Modules.Core.Timers)
local Utility = require(ReplicatedStorage.Modules.Core.Utility)

-- Debug settings
local debugSystem = "PlayerStatsHandler"
local DEBUG_ENABLED = true -- Set to false to disable all debug prints

-- Helper function for debug logging
local function DebugLog(level, message)
	if DEBUG_ENABLED then
		Utility.Log(debugSystem, level, message)
	end
end

-- Constants for default player stats
PlayerStatsHandler.DEFAULT_WALK_SPEED = 16
PlayerStatsHandler.DEFAULT_JUMP_POWER = 50

-- Track all active effects for each player
-- Format: { [userId] = { speed = { effectId = {amount, expiry} }, jump = { effectId = {amount, expiry} } } }
local activeEffects = {}

-- Initialize the handler
function PlayerStatsHandler.Initialize()
	DebugLog("info", "Initializing PlayerStatsHandler")

	-- Clean up when players leave
	Players.PlayerRemoving:Connect(function(player)
		DebugLog("info", "Player leaving: " .. player.Name)
		PlayerStatsHandler.CleanupAllEffects(player)
	end)

	-- Set up character added event for all existing players
	for _, player in pairs(Players:GetPlayers()) do
		PlayerStatsHandler.SetupCharacterAddedEvent(player)
	end

	-- Set up character added event for future players
	Players.PlayerAdded:Connect(function(player)
		DebugLog("info", "New player joined: " .. player.Name)
		PlayerStatsHandler.SetupCharacterAddedEvent(player)
	end)

	DebugLog("info", "PlayerStatsHandler initialized successfully")
	return true
end

-- Set up character added event for a player
function PlayerStatsHandler.SetupCharacterAddedEvent(player)
	player.CharacterAdded:Connect(function(character)
		DebugLog("info", "Character added for player: " .. player.Name)

		-- Re-apply any active effects when character respawns
		task.delay(0.5, function() -- Brief delay to ensure character is fully loaded
			if activeEffects[player.UserId] then
				DebugLog("info", "Re-applying active effects for respawned player: " .. player.Name)
				PlayerStatsHandler.UpdatePlayerStats(player)
			end
		end)
	end)
end

-- Register a new effect
-- effectType: "speed", "jump"
-- effectId: unique identifier for this effect (e.g., "mushroom_speed", "lightning_boost")
-- player: the player to apply the effect to
-- amount: the amount to modify the stat by
-- duration: how long the effect should last in seconds
-- visualCleanupFunc: optional function to run when effect expires (for cleanup)
function PlayerStatsHandler.ApplyEffect(effectType, effectId, player, amount, duration, visualCleanupFunc)
	if not player or not player.UserId then
		DebugLog("warn", "Invalid player provided to ApplyEffect")
		return false
	end

	if effectType ~= "speed" and effectType ~= "jump" then
		DebugLog("warn", "Invalid effect type: " .. tostring(effectType))
		return false
	end

	DebugLog("info", "Applying " .. effectType .. " effect '" .. effectId .. 
		"' to player " .. player.Name .. " with amount " .. amount .. " for " .. duration .. "s")

	-- Initialize player's effects table if needed
	if not activeEffects[player.UserId] then
		DebugLog("info", "Initializing effects table for player: " .. player.Name)
		activeEffects[player.UserId] = {
			speed = {},
			jump = {}
		}
	end

	-- Create a unique ID for this effect instance to allow stacking
	local uniqueEffectId = effectId .. "_" .. os.time() .. "_" .. math.random(1000, 9999)
	DebugLog("info", "Generated unique effect ID: " .. uniqueEffectId)

	-- Store the effect with the unique ID
	activeEffects[player.UserId][effectType][uniqueEffectId] = {
		amount = amount,
		expiry = os.time() + duration,
		cleanup = visualCleanupFunc,
		baseEffectId = effectId -- Store the original ID for reference
	}

	-- Create timer for auto-removal of effect
	local timerName = effectType .. "_" .. uniqueEffectId .. "_" .. player.UserId
	DebugLog("info", "Creating timer: " .. timerName)
	local timer = Timers.CreateTimer(player, timerName, duration, {
		onComplete = function()
			DebugLog("info", "Timer completed for effect: " .. uniqueEffectId)
			PlayerStatsHandler.RemoveEffect(effectType, uniqueEffectId, player)
		end
	})

	if not timer then
		DebugLog("warn", "Failed to create timer for effect: " .. uniqueEffectId)
	end

	-- Update the player's stats
	PlayerStatsHandler.UpdatePlayerStats(player)

	-- Print all active effects for debugging
	PlayerStatsHandler.DebugPrintActiveEffects(player)

	return uniqueEffectId -- Return the unique ID for potential manual removal later
end

-- Print all active effects for a player (debug function)
function PlayerStatsHandler.DebugPrintActiveEffects(player)
	if not DEBUG_ENABLED then return end
	if not player or not player.UserId then return end

	if not activeEffects[player.UserId] then
		DebugLog("info", "No active effects for player: " .. player.Name)
		return
	end

	DebugLog("info", "--- ACTIVE EFFECTS FOR " .. player.Name .. " ---")

	local now = os.time()
	local effectCount = 0

	for effectType, effects in pairs(activeEffects[player.UserId]) do
		for uniqueId, effectData in pairs(effects) do
			local timeRemaining = effectData.expiry - now
			if timeRemaining > 0 then
				DebugLog("info", effectType .. " effect: " .. effectData.baseEffectId .. 
					" (ID: " .. uniqueId .. ") - Amount: " .. effectData.amount .. 
					", Time remaining: " .. timeRemaining .. "s")
				effectCount = effectCount + 1
			end
		end
	end

	DebugLog("info", "Total active effects: " .. effectCount)
	DebugLog("info", "-------------------------------")
end

-- Remove a specific effect
function PlayerStatsHandler.RemoveEffect(effectType, uniqueEffectId, player)
	if not player or not player.UserId then
		DebugLog("warn", "Invalid player provided to RemoveEffect")
		return false
	end

	-- Check if player has any effects
	if not activeEffects[player.UserId] or 
		not activeEffects[player.UserId][effectType] or
		not activeEffects[player.UserId][effectType][uniqueEffectId] then
		DebugLog("warn", "Effect not found: " .. effectType .. " / " .. uniqueEffectId)
		return false
	end

	-- Store base effect ID for logging
	local baseEffectId = activeEffects[player.UserId][effectType][uniqueEffectId].baseEffectId

	-- Call the cleanup function if it exists
	local effect = activeEffects[player.UserId][effectType][uniqueEffectId]
	if effect.cleanup and type(effect.cleanup) == "function" then
		DebugLog("info", "Running cleanup function for effect: " .. uniqueEffectId)
		-- Call the cleanup function, catching any errors
		local success, err = pcall(effect.cleanup)
		if not success then
			DebugLog("warn", "Error in cleanup function: " .. tostring(err))
		end
	end

	-- Remove the effect
	DebugLog("info", "Removing effect: " .. uniqueEffectId)
	activeEffects[player.UserId][effectType][uniqueEffectId] = nil

	-- Update the player's stats
	PlayerStatsHandler.UpdatePlayerStats(player)

	DebugLog("info", "Removed " .. effectType .. " effect '" .. baseEffectId .. 
		"' from player " .. player.Name)

	-- Print remaining active effects for debugging
	PlayerStatsHandler.DebugPrintActiveEffects(player)

	return true
end

-- Calculate total effect for a specific stat
local function calculateTotalEffect(userId, effectType)
	if not activeEffects[userId] or not activeEffects[userId][effectType] then
		return 0
	end

	local total = 0
	local now = os.time()
	local expired = {}

	for effectId, effectData in pairs(activeEffects[userId][effectType]) do
		-- Check if effect has expired
		if effectData.expiry <= now then
			-- Mark for removal if expired
			table.insert(expired, effectId)
		else
			-- Add to total if still active
			total = total + effectData.amount
		end
	end

	-- Clean up expired effects
	for _, expiredId in ipairs(expired) do
		DebugLog("info", "Removing expired effect during calculation: " .. expiredId)
		activeEffects[userId][effectType][expiredId] = nil
	end

	return total
end

-- Update a player's stats based on all active effects
function PlayerStatsHandler.UpdatePlayerStats(player)
	if not player or not player.UserId then return end

	local character = player.Character
	if not character then
		DebugLog("info", "No character found for player: " .. player.Name)
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		DebugLog("info", "No humanoid found for player: " .. player.Name)
		return
	end

	-- Calculate total effects
	local speedEffect = calculateTotalEffect(player.UserId, "speed")
	local jumpEffect = calculateTotalEffect(player.UserId, "jump")

	DebugLog("info", "Calculated total effects for " .. player.Name .. ": Speed +" .. 
		speedEffect .. ", Jump +" .. jumpEffect)

	-- Store original values if not already stored
	if not character:FindFirstChild("OriginalWalkSpeed") then
		DebugLog("info", "Storing original walk speed for " .. player.Name .. ": " .. humanoid.WalkSpeed)
		local val = Instance.new("NumberValue")
		val.Name = "OriginalWalkSpeed"
		val.Value = humanoid.WalkSpeed
		val.Parent = character
	end

	if not character:FindFirstChild("OriginalJumpPower") then
		DebugLog("info", "Storing original jump power for " .. player.Name .. ": " .. humanoid.JumpPower)
		local val = Instance.new("NumberValue")
		val.Name = "OriginalJumpPower"
		val.Value = humanoid.JumpPower
		val.Parent = character
	end

	-- Get original values
	local originalSpeed = character.OriginalWalkSpeed.Value
	local originalJump = character.OriginalJumpPower.Value

	-- Apply effects
	humanoid.WalkSpeed = originalSpeed + speedEffect
	humanoid.JumpPower = originalJump + jumpEffect

	DebugLog("info", "Updated stats for " .. player.Name .. ": Speed = " .. 
		humanoid.WalkSpeed .. " (+" .. speedEffect .. " from base " .. originalSpeed .. 
		"), Jump = " .. humanoid.JumpPower .. " (+" .. jumpEffect .. " from base " .. originalJump .. ")")
end

-- Get all active effects for a player
function PlayerStatsHandler.GetPlayerEffects(player)
	if not player or not player.UserId then
		DebugLog("warn", "Invalid player provided to GetPlayerEffects")
		return nil
	end

	return activeEffects[player.UserId]
end

-- Check if a specific effect is active (checks for any instance of the base effect ID)
function PlayerStatsHandler.IsEffectActive(effectType, baseEffectId, player)
	if not player or not player.UserId then
		DebugLog("warn", "Invalid player provided to IsEffectActive")
		return false
	end

	if not activeEffects[player.UserId] or
		not activeEffects[player.UserId][effectType] then
		return false
	end

	-- Check all effects to see if any match the base ID
	local now = os.time()
	for uniqueId, effectData in pairs(activeEffects[player.UserId][effectType]) do
		if effectData.baseEffectId == baseEffectId and effectData.expiry > now then
			return true
		end
	end

	return false
end

-- Count how many instances of a specific effect type are active
function PlayerStatsHandler.CountActiveEffects(effectType, baseEffectId, player)
	if not player or not player.UserId then
		DebugLog("warn", "Invalid player provided to CountActiveEffects")
		return 0
	end

	if not activeEffects[player.UserId] or
		not activeEffects[player.UserId][effectType] then
		return 0
	end

	-- Count all effects that match the base ID
	local count = 0
	local now = os.time()
	for uniqueId, effectData in pairs(activeEffects[player.UserId][effectType]) do
		if effectData.baseEffectId == baseEffectId and effectData.expiry > now then
			count = count + 1
		end
	end

	DebugLog("info", "Counted " .. count .. " active instances of " .. 
		effectType .. " effect '" .. baseEffectId .. "' for player " .. player.Name)

	return count
end

-- Clean up all effects for a player
function PlayerStatsHandler.CleanupAllEffects(player)
	if not player or not player.UserId then
		DebugLog("warn", "Invalid player provided to CleanupAllEffects")
		return false
	end

	DebugLog("info", "Cleaning up all effects for player: " .. player.Name)

	-- Reset player stats if they have a character
	local character = player.Character
	if character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			-- Reset to original values if available
			local originalSpeed = character:FindFirstChild("OriginalWalkSpeed")
			if originalSpeed then
				DebugLog("info", "Resetting speed to original: " .. originalSpeed.Value)
				humanoid.WalkSpeed = originalSpeed.Value
				originalSpeed:Destroy()
			else
				DebugLog("info", "Resetting speed to default: " .. PlayerStatsHandler.DEFAULT_WALK_SPEED)
				humanoid.WalkSpeed = PlayerStatsHandler.DEFAULT_WALK_SPEED
			end

			local originalJump = character:FindFirstChild("OriginalJumpPower")
			if originalJump then
				DebugLog("info", "Resetting jump to original: " .. originalJump.Value)
				humanoid.JumpPower = originalJump.Value
				originalJump:Destroy()
			else
				DebugLog("info", "Resetting jump to default: " .. PlayerStatsHandler.DEFAULT_JUMP_POWER)
				humanoid.JumpPower = PlayerStatsHandler.DEFAULT_JUMP_POWER
			end
		end
	end

	-- Call all cleanup functions
	if activeEffects[player.UserId] then
		local effectCount = 0
		for effectType, effects in pairs(activeEffects[player.UserId]) do
			for uniqueEffectId, effectData in pairs(effects) do
				effectCount = effectCount + 1

				-- Call cleanup function
				if effectData.cleanup and type(effectData.cleanup) == "function" then
					DebugLog("info", "Running cleanup for effect: " .. uniqueEffectId)
					pcall(effectData.cleanup)
				end

				-- Cancel timers
				local timerName = effectType .. "_" .. uniqueEffectId .. "_" .. player.UserId
				if Timers.TimerExists(player, timerName) then
					DebugLog("info", "Canceling timer: " .. timerName)
					Timers.CancelTimer(player, timerName)
				end
			end
		end

		DebugLog("info", "Cleaned up " .. effectCount .. " effects for player: " .. player.Name)
		activeEffects[player.UserId] = nil
	else
		DebugLog("info", "No active effects to clean up for player: " .. player.Name)
	end

	return true
end

-- Toggle debug mode
function PlayerStatsHandler.SetDebugEnabled(enabled)
	DEBUG_ENABLED = enabled
	DebugLog("info", "Debug mode " .. (enabled and "enabled" or "disabled"))
	return DEBUG_ENABLED
end

-- Initialize the module
PlayerStatsHandler.Initialize()

return PlayerStatsHandler
