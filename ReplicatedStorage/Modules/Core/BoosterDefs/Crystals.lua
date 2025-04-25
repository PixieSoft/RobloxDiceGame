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

-- Create a table that we can reference from within its own methods
local CrystalBooster = {}

-- Define properties
CrystalBooster.name = "Crystals"
CrystalBooster.description = "Shrink for 10s per crystal."
CrystalBooster.imageId = "rbxassetid://72049224483385"
CrystalBooster.boosterType = "PlayerBoost" -- Will be mapped to Boosters.BoosterTypes.PLAYER
CrystalBooster.duration = 10 -- 10 seconds per item used
CrystalBooster.stacks = false -- effect does not stack
CrystalBooster.canCancel = true -- can be canceled by player

-- Function to calculate and return effect description
CrystalBooster.calculateEffect = function(spendingAmount)
	if spendingAmount <= 0 then
		return "Select crystals to use"
	end

	local totalDuration = CrystalBooster.duration * spendingAmount -- Self-reference to duration property
	local timeText = Utility.FormatTimeDuration(totalDuration)

	local pluralText = spendingAmount > 1 and "crystals" or "crystal"
	return "Shrink for " .. timeText .. " using " .. spendingAmount .. " " .. pluralText .. "."
end

-- Function that runs when booster is activated
CrystalBooster.onActivate = function(player, qty)
	-- This function only runs on the server
	if not IsServer then return function() end end

	-- Always force the player to small size
	PlayerSize.SetPlayerSize(player, "small")

	print("Crystal booster activated for " .. player.Name .. ": Shrunk for " .. (qty * CrystalBooster.duration) .. " seconds")

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

return CrystalBooster
