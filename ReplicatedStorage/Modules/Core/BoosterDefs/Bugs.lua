-- /ReplicatedStorage/Modules/Core/BoosterDefs/Bugs.lua
-- ModuleScript that defines the Bugs booster

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local IsServer = RunService:IsServer()

-- Import utility module
local Utility = require(ReplicatedStorage.Modules.Core.Utility)
-- Lazy load Timers to prevent circular dependency
local Timers = nil

-- Create a table that we can reference from within its own methods
local BugsBooster = {}

-- Define properties
BugsBooster.name = "Bugs"
BugsBooster.description = "+1% speed for 1 minute per bug."
BugsBooster.imageId = "rbxassetid://109760311419104"
BugsBooster.boosterType = "PlayerBoost" -- Will be mapped to Boosters.BoosterTypes.PLAYER
BugsBooster.duration = 60 -- 60 seconds (1 minute) per bug
BugsBooster.stacks = true -- Allows stacking multiple bugs at once for stronger effect
BugsBooster.canCancel = true

-- Function to calculate and return effect description
BugsBooster.calculateEffect = function(spendingAmount)
	if spendingAmount <= 0 then
		return "Select bugs to use"
	end

	local totalDuration = BugsBooster.duration * spendingAmount -- Self-reference to the duration property
	local timeText = Utility.FormatTimeDuration(totalDuration)

	local pluralText = spendingAmount > 1 and "bugs" or "bug"
	return "+" .. spendingAmount .. "% speed for " .. timeText .. " using " .. spendingAmount .. " " .. pluralText .. "."
end

-- Function that runs when booster is activated
BugsBooster.onActivate = function(player, qty)
	-- This function only runs on the server
	if not IsServer then return function() end end

	-- Lazy load Timers module
	if not Timers then
		Timers = require(ReplicatedStorage.Modules.Core.Timers)
	end

	-- Get the player's character and humanoid
	local character = player.Character
	if not character then return function() end end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return function() end end

	-- Store original walk speed
	local originalWalkSpeed = humanoid.WalkSpeed

	-- Increase walk speed by 1% for each bug used
	local percentBoost = originalWalkSpeed * (qty * 0.01)
	-- Ensure a minimum boost of +1
	local speedBoost = math.max(percentBoost, 1)
	humanoid.WalkSpeed = originalWalkSpeed + speedBoost

	-- Print feedback
	print("Activated Bug booster for " .. player.Name .. ": +" .. qty .. "% walkspeed (" .. 
		humanoid.WalkSpeed .. ") for " .. (qty * BugsBooster.duration) .. " seconds")

	-- Create a character added connection to handle respawns during the effect
	local characterAddedConnection
	characterAddedConnection = player.CharacterAdded:Connect(function(newCharacter)
		-- Wait for the humanoid to be added
		local newHumanoid = newCharacter:WaitForChild("Humanoid")

		-- Apply the speed boost to the new character
		if newHumanoid then
			newHumanoid.WalkSpeed = originalWalkSpeed + speedBoost
		end
	end)

	-- Create timer with callbacks
	local timerName = "Bugs"
	local totalDuration = qty * BugsBooster.duration

	local callbacks = {
		onStart = function(timer)
			print("Bugs speed boost started for " .. player.Name .. " - Duration: " .. totalDuration .. "s")
		end,

		onComplete = function(timer)
			-- Restore original walk speed
			local currentCharacter = player.Character
			if currentCharacter then
				local currentHumanoid = currentCharacter:FindFirstChildOfClass("Humanoid")
				if currentHumanoid then
					currentHumanoid.WalkSpeed = originalWalkSpeed
					print("Bug booster expired for " .. player.Name .. ": walkspeed restored to " .. originalWalkSpeed)
				end
			end

			-- Disconnect character added connection
			if characterAddedConnection then
				characterAddedConnection:Disconnect()
			end
		end,

		onCancel = function(timer)
			-- Restore original walk speed
			local currentCharacter = player.Character
			if currentCharacter then
				local currentHumanoid = currentCharacter:FindFirstChildOfClass("Humanoid")
				if currentHumanoid then
					currentHumanoid.WalkSpeed = originalWalkSpeed
					print("Bug booster canceled for " .. player.Name .. ": walkspeed restored to " .. originalWalkSpeed)
				end
			end

			-- Disconnect character added connection
			if characterAddedConnection then
				characterAddedConnection:Disconnect()
			end
		end
	}

	-- Create the timer
	local timer = Timers.CreateTimer(player, timerName, totalDuration, callbacks)

	-- Store bug count in timer using SetCustomValue
	if timer then
		Timers.SetCustomValue(player, timerName, "Count", qty, "IntValue")
	end

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
				print("Bug booster cleanup for " .. player.Name .. ": walkspeed restored to " .. originalWalkSpeed)
			end
		end

		-- Cancel the timer if it exists
		if Timers and Timers.TimerExists(player, timerName) then
			Timers.CancelTimer(player, timerName)
		end
	end
end

return BugsBooster
