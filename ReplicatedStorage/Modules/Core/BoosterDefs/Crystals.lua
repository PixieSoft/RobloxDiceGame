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
local debugSystem = "Crystals" -- System name for debug logs

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

CrystalBooster.onActivate = function(player, qty)
	if not IsServer then 
		Utility.Log(debugSystem, "warn", "onActivate called on client - this should only run on server")
		return function() end 
	end

	-- Add this line to access the Boosters module
	local Boosters = require(ReplicatedStorage.Modules.Core.Boosters)

	Utility.Log(debugSystem, "info", "Crystal booster onActivate called for " .. player.Name .. " with quantity " .. qty)

	-- Now Boosters.SetSizeSliderVisibility will work
	Boosters.SetSizeSliderVisibility(player, true)

	-- Return cleanup function that handles BOTH slider and scaling
	return function()
		Utility.Log(debugSystem, "info", "Crystal booster cleanup function called for " .. player.Name)

		-- Hide the slider first
		Boosters.SetSizeSliderVisibility(player, false)

		-- Then handle our own scaling cleanup
		ScaleCharacter.SetScale(player, 1.0)

		Utility.Log(debugSystem, "info", "Crystal effect cleanup completed for " .. player.Name)
	end
end

return CrystalBooster
