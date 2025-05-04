-- /ReplicatedStorage/Modules/Core/BoosterDefs/Crystals.lua
-- ModuleScript that defines the Crystal booster with integrated size slider functionality

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local IsServer = RunService:IsServer()

-- Import modules
local Utility = require(ReplicatedStorage.Modules.Core.Utility)
local ScaleCharacter = require(ReplicatedStorage.Modules.Core.ScaleCharacter)

-- Create a table that we can reference from within its own methods
local CrystalBooster = {}

-- Debug settings
local debugSystem = "Boosters" -- System name for debug logs

-- Define properties
CrystalBooster.name = "Crystals"
CrystalBooster.description = "Activate crystal power for 10s per crystal. Allows size changing."
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
	return "Crystal power for " .. timeText .. " using " .. spendingAmount .. " " .. pluralText .. ". Allows size changing."
end

-- Function that runs when booster is activated
CrystalBooster.onActivate = function(player, qty)
	-- This function only runs on the server
	if not IsServer then 
		Utility.Log(debugSystem, "warn", "onActivate called on client - this should only run on server")
		return function() end 
	end

	Utility.Log(debugSystem, "info", "Crystal booster onActivate called for " .. player.Name .. " with quantity " .. qty)

	-- NOTE: The size slider visibility is now handled centrally by Boosters.lua
	-- We no longer need to manage slider visibility here

	-- Return cleanup function that will run when the booster expires or is canceled
	-- This function is called by Boosters.lua when the timer completes or is canceled
	return function()
		Utility.Log(debugSystem, "info", "Crystal booster cleanup function called for " .. player.Name)

		-- Reset character to default size (1.0)
		ScaleCharacter.SetScale(player, 1.0)

		Utility.Log(debugSystem, "info", "Crystal effect cleanup completed for " .. player.Name)
	end
end

return CrystalBooster
