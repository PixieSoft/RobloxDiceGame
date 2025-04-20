-- /ReplicatedStorage/Modules/Core/BoosterDefs/Bugs.lua
-- ModuleScript that defines the Bugs booster

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local IsServer = RunService:IsServer()

-- Import utility module
local Utility = require(ReplicatedStorage.Modules.Core.Utility)

-- Booster definition 
return {
	-- Make this 1% for 1m per bug with a minimum of +1 speed
	name = "Bug",
	description = "+1 speed for 1 minute per bug.",
	imageId = "rbxassetid://109760311419104",
	boosterType = "PlayerBoost", -- Will be mapped to Boosters.BoosterTypes.PLAYER
	duration = 60, -- 60 seconds (1 minute) per bug
	stacks = true, -- Allows stacking multiple bugs at once for stronger effect
	canCancel = true,

	-- Function to calculate and return effect description
	calculateEffect = function(spendingAmount)
		if spendingAmount <= 0 then
			return "Select bugs to use"
		end

		local speedBoost = spendingAmount -- +1 walkspeed per bug
		local totalDuration = 60 * spendingAmount -- 60s per bug
		local timeText = Utility.FormatTimeDuration(totalDuration)

		local pluralText = spendingAmount > 1 and "bugs" or "bug"
		return "+" .. speedBoost .. " speed for " .. timeText .. " using " .. spendingAmount .. " " .. pluralText .. "."
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
