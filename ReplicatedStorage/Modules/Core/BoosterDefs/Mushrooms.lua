-- /ReplicatedStorage/Modules/Core/BoosterDefs/Mushrooms.lua
-- ModuleScript that defines the Mushroom booster behavior

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local IsServer = RunService:IsServer()

-- Import utility module
local Utility = require(ReplicatedStorage.Modules.Core.Utility)
local Timers = require(ReplicatedStorage.Modules.Core.Timers)

-- Create a table that we can reference from within its own methods
local MushroomBooster = {}

-- Define properties
MushroomBooster.name = "Shrooms"
MushroomBooster.description = "+1.0 jump height for 1 minute per mushroom."
MushroomBooster.imageId = "rbxassetid://134097767361051"
MushroomBooster.boosterType = "PlayerBoost" -- Will be mapped to Boosters.BoosterTypes.PLAYER
MushroomBooster.duration = 60 -- 60 seconds per mushroom
MushroomBooster.stacks = true -- Allow multiple mushrooms to stack
MushroomBooster.canCancel = true

-- Function to calculate and return effect description
MushroomBooster.calculateEffect = function(spendingAmount)
	if spendingAmount <= 0 then
		return "Select mushrooms to use"
	end

	local heightBoost = spendingAmount * 1.0 -- +1.0 stud per mushroom
	local totalDuration = MushroomBooster.duration * spendingAmount -- Use the self-referenced duration property
	local timeText = Utility.FormatTimeDuration(totalDuration)

	local pluralText = spendingAmount > 1 and "mushrooms" or "mushroom"
	return "+" .. heightBoost .. " jump height for " .. timeText .. " using " .. spendingAmount .. " " .. pluralText .. "."
end

-- Function that runs when booster is activated
MushroomBooster.onActivate = function(player, qty)
	-- This function only runs on the server
	if not IsServer then return function() end end

	-- Get the player's character and humanoid
	local character = player.Character
	if not character then return function() end end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return function() end end

	-- Store original jump values
	local originalJumpHeight = humanoid.JumpHeight
	local originalJumpPower = humanoid.JumpPower

	-- Calculate fixed height boost (+1.0 stud per mushroom)
	local heightBoost = qty * 1.0 -- +1.0 stud per mushroom
	local newJumpHeight = originalJumpHeight + heightBoost

	-- Calculate the appropriate jump power using the physics formula: JumpPower = sqrt(2 * gravity * jumpHeight)
	local gravity = workspace.Gravity
	local newJumpPower = math.sqrt(2 * gravity * newJumpHeight)

	-- Apply jump boost based on rig type
	if humanoid.RigType == Enum.HumanoidRigType.R15 then
		-- For R15 characters, set both JumpHeight and JumpPower
		humanoid.JumpHeight = newJumpHeight
		humanoid.JumpPower = newJumpPower
	else
		-- For R6 characters, only use JumpPower
		humanoid.JumpPower = newJumpPower
	end

	-- Print feedback
	print("Activated Mushroom booster for " .. player.Name .. ": +" .. 
		heightBoost .. " jump height boost (to " .. newJumpHeight .. 
		" studs) for " .. (qty * MushroomBooster.duration) .. " seconds")

	-- Create a timer to track duration and handle effect removal
	local timerName = "Mushrooms"
	local totalDuration = qty * MushroomBooster.duration

	-- Define timer callbacks
	local callbacks = {
		onStart = function(timer)
			print("Started Mushroom jump boost timer for " .. player.Name)
		end,

		onTick = function(timer)
			-- Optional: Could update UI here if needed
		end,

		onComplete = function(timer)
			-- Reset jump values when timer completes
			local currentCharacter = player.Character
			if currentCharacter then
				local currentHumanoid = currentCharacter:FindFirstChildOfClass("Humanoid")
				if currentHumanoid then
					currentHumanoid.JumpHeight = originalJumpHeight
					currentHumanoid.JumpPower = originalJumpPower
					print("Mushroom booster expired for " .. player.Name .. ": jump ability restored")
				end
			end
		end,

		onCancel = function(timer)
			-- Reset jump values if timer is canceled
			local currentCharacter = player.Character
			if currentCharacter then
				local currentHumanoid = currentCharacter:FindFirstChildOfClass("Humanoid")
				if currentHumanoid then
					currentHumanoid.JumpHeight = originalJumpHeight
					currentHumanoid.JumpPower = originalJumpPower
					print("Mushroom booster canceled for " .. player.Name .. ": jump ability restored")
				end
			end
		end
	}

	-- Create the timer
	local timer = Timers.CreateTimer(player, timerName, totalDuration, callbacks)
	if timer then
		-- Store the mushroom count as a custom value
		Timers.SetCustomValue(player, timerName, "Count", qty, "IntValue")
	end

	-- Setup character added event in case player dies during effect
	local characterAddedConnection
	characterAddedConnection = player.CharacterAdded:Connect(function(newCharacter)
		-- Wait for the humanoid to be added
		local newHumanoid = newCharacter:WaitForChild("Humanoid")

		-- Re-apply the jump boost to the new character
		if newHumanoid then
			if newHumanoid.RigType == Enum.HumanoidRigType.R15 then
				newHumanoid.JumpHeight = newJumpHeight
				newHumanoid.JumpPower = newJumpPower
			else
				newHumanoid.JumpPower = newJumpPower
			end
		end
	end)

	-- Return cleanup function
	return function()
		-- Disconnect the CharacterAdded event
		if characterAddedConnection then
			characterAddedConnection:Disconnect()
		end

		-- Cancel the timer if it exists
		if Timers.TimerExists(player, timerName) then
			Timers.CancelTimer(player, timerName)
		else
			-- If timer doesn't exist (e.g., it completed naturally), restore jump values manually
			local currentCharacter = player.Character
			if currentCharacter then
				local currentHumanoid = currentCharacter:FindFirstChildOfClass("Humanoid")
				if currentHumanoid then
					currentHumanoid.JumpHeight = originalJumpHeight
					currentHumanoid.JumpPower = originalJumpPower
					print("Mushroom booster cleanup: jump ability restored for " .. player.Name)
				end
			end
		end
	end
end

return MushroomBooster
