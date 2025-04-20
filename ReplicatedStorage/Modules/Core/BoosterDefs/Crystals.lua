-- /ReplicatedStorage/Modules/Core/BoosterDefs/Crystals.lua
-- ModuleScript that defines the Crystal booster

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local IsServer = RunService:IsServer()

-- Import utility module
local Utility = require(ReplicatedStorage.Modules.Core.Utility)

-- Get the PlayerSize module if we're on the server
local PlayerSize
if IsServer then
	PlayerSize = require(game.ServerScriptService.Modules.Effects.PlayerSize)
end

-- Booster definition 
return {
	-- Shrink for 10s per crystal used. Stack duration only. Can cancel.
	name = "Crystal",
	description = "Shrink for 10s per crystal.",
	imageId = "rbxassetid://72049224483385",
	boosterType = "PlayerBoost", -- Will be mapped to Boosters.BoosterTypes.PLAYER
	duration = 10, -- 10 seconds per item used
	stacks = false, -- effect does not stack
	canCancel = true, -- can be canceled by player

	-- Function to calculate and return effect description
	calculateEffect = function(spendingAmount)
		if spendingAmount <= 0 then
			return "Select crystals to use"
		end

		local totalDuration = 10 * spendingAmount -- 10s per crystal
		local timeText = Utility.FormatTimeDuration(totalDuration)

		local pluralText = spendingAmount > 1 and "crystals" or "crystal"
		return "Shrink for " .. timeText .. " using " .. spendingAmount .. " " .. pluralText .. "."
	end,

	-- Function that runs when booster is activated
	onActivate = function(player, qty)
		-- This function only runs on the server
		if not IsServer then return function() end end

		-- Always force the player to small size
		PlayerSize.SetPlayerSize(player, "small")

		print("Crystal booster activated for " .. player.Name .. ": Shrunk for " .. (qty * 10) .. " seconds")

		-- Setup a tracker for if the player dies during effect
		local characterAddedConnection
		characterAddedConnection = player.CharacterAdded:Connect(function(newCharacter)
			-- Re-apply the shrink to the new character
			task.wait(0.5) -- Wait for the character to fully load
			PlayerSize.SetPlayerSize(player, "small")
		end)

		-- Return cleanup function that will run when the booster expires
		return function()
			-- Set size back to normal
			PlayerSize.SetPlayerSize(player, "normal")

			-- Disconnect the CharacterAdded event
			if characterAddedConnection then
				characterAddedConnection:Disconnect()
			end

			print("Crystal booster expired for " .. player.Name .. ": Size restored")
		end
	end
}
