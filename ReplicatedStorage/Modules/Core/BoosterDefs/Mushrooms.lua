-- /ReplicatedStorage/Modules/Core/BoosterDefs/Mushrooms.lua
-- ModuleScript that defines the Mushroom booster behavior

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local IsServer = RunService:IsServer()

-- Import utility module
local Utility = require(ReplicatedStorage.Modules.Core.Utility)

-- Booster definition 
return {
	name = "Mushroom",
	description = "+1% jump height for 1 minute per mushroom.",
	imageId = "rbxassetid://134097767361051",
	boosterType = "PlayerBoost", -- Will be mapped to Boosters.BoosterTypes.PLAYER
	duration = 10, -- Was 60s, changed to 10s for testing.
	stacks = true, -- Allow multiple mushrooms to stack
	canCancel = true,

	-- Function to calculate and return effect description
	calculateEffect = function(spendingAmount)
		if spendingAmount <= 0 then
			return "Select mushrooms to use"
		end

		local jumpBoost = spendingAmount * 0.01 -- 1% per mushroom
		local totalDuration = 10 * spendingAmount -- 10s per mushroom (testing duration)
		local timeText = Utility.FormatTimeDuration(totalDuration)

		local pluralText = spendingAmount > 1 and "mushrooms" or "mushroom"
		return "+" .. (jumpBoost * 100) .. "% jump height for " .. timeText .. " using " .. spendingAmount .. " " .. pluralText .. "."
	end,

	-- Function that runs when booster is activated
	onActivate = function(player, qty)
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

		-- Calculate percentage boost (1% per mushroom used)
		local percentBoost = qty * 0.01 -- 1% per mushroom

		-- Apply jump boost based on rig type
		if humanoid.RigType == Enum.HumanoidRigType.R15 then
			-- For R15 characters, primarily use JumpHeight
			humanoid.JumpHeight = originalJumpHeight * (1 + percentBoost)

			-- Also set JumpPower as a fallback
			humanoid.JumpPower = originalJumpPower * (1 + percentBoost)
		else
			-- For R6 characters, only use JumpPower
			humanoid.JumpPower = originalJumpPower * (1 + percentBoost)
		end

		-- Print feedback
		print("Activated Mushroom booster for " .. player.Name .. ": +" .. 
			math.floor(percentBoost * 100) .. "% jump boost for " .. 
			(qty * 60) .. " seconds")

		-- Setup character added event in case player dies during effect
		local characterAddedConnection
		characterAddedConnection = player.CharacterAdded:Connect(function(newCharacter)
			-- Wait for the humanoid to be added
			local newHumanoid = newCharacter:WaitForChild("Humanoid")

			-- Re-apply the jump boost to the new character
			if newHumanoid then
				if newHumanoid.RigType == Enum.HumanoidRigType.R15 then
					newHumanoid.JumpHeight = originalJumpHeight * (1 + percentBoost)
					newHumanoid.JumpPower = originalJumpPower * (1 + percentBoost)
				else
					newHumanoid.JumpPower = originalJumpPower * (1 + percentBoost)
				end
			end
		end)

		-- Return cleanup function
		return function()
			-- Disconnect the CharacterAdded event
			if characterAddedConnection then
				characterAddedConnection:Disconnect()
			end

			-- Restore original jump values if the character still exists
			local currentCharacter = player.Character
			if currentCharacter then
				local currentHumanoid = currentCharacter:FindFirstChildOfClass("Humanoid")
				if currentHumanoid then
					currentHumanoid.JumpHeight = originalJumpHeight
					currentHumanoid.JumpPower = originalJumpPower
					print("Mushroom booster expired for " .. player.Name .. ": jump ability restored")
				end
			end
		end
	end
}
